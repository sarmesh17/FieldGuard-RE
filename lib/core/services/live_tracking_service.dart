import 'dart:async';
import 'dart:io' show Platform;

import 'package:geolocator/geolocator.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import 'package:field_guard_re/core/constants/api_constant.dart';
import 'package:field_guard_re/core/services/token_storage.dart';

/// Drives the real-time tracking flow over Socket.IO:
///
///  ② connect with the JWT (server joins the company room, broadcasts online)
///  ③ emit `tracking:start` once the socket is up (server opens a session)
///  ④ emit `location:update` every [_emitInterval] with the latest fix
///  ⑤ emit `tracking:stop` when the session ends
///  ⑥ disconnect (server broadcasts offline)
///
/// The location stream runs through geolocator's Android foreground service
/// (and iOS background-location mode) so updates keep flowing while the app
/// is backgrounded or the screen is locked.
class LiveTrackingService {
  LiveTrackingService._();
  static final LiveTrackingService instance = LiveTrackingService._();

  static const _emitInterval = Duration(seconds: 5);
  static const _connectTimeout = Duration(seconds: 15);

  io.Socket? _socket;
  StreamSubscription<Position>? _positionSub;
  Timer? _emitTimer;
  Position? _lastPosition;
  bool _trackingStarted = false;

  /// Live in-app notification pushed over this (tracking) socket. The server
  /// auto-joins the connection to the user's private room and emits
  /// `notification:new` with the same shape as a `GET /notifications` item.
  /// Wired by MainShell into the notifications provider. NOTE: this socket is
  /// only connected during a tracking session, so it's a foreground polish on
  /// top of FCM — not the primary delivery path.
  void Function(Map<String, dynamic> json)? onNotification;

  /// Fired on every socket (re)connect so the inbox can resync. The socket has
  /// no replay queue — anything that arrived while disconnected is only in the
  /// DB (and via FCM), so we refetch the list + unreadCount on (re)connect.
  void Function()? onSocketConnected;

  /// Set of active reasons keeping the tracking session alive.
  /// Sample reasons: `'manual'` (user toggle), `'task'` (active IN_PROGRESS task).
  /// The session stops when this set becomes empty.
  final Set<String> _reasons = <String>{};

  /// True while a tracking session (location streaming) is active. NOTE: the
  /// socket can be connected for notifications without tracking — use
  /// [isConnected] for raw connection state.
  bool get isRunning => _trackingStarted;
  bool get isConnected => _socket?.connected ?? false;
  bool isReasonActive(String reason) => _reasons.contains(reason);

  /// Guards against two sockets being created if connect()/start() race during
  /// the async token read.
  bool _creatingSocket = false;

  /// Completes when the current socket finishes (or fails) connecting — lets
  /// [start] surface a connection failure to the tracking toggle.
  Completer<void>? _connectCompleter;

  /// Opens the socket for live notifications + presence WITHOUT starting a
  /// tracking session. Call on login / session-restore / app-resume so
  /// `notification:new` arrives whenever the app is foreground — independent of
  /// tracking. Idempotent; silently no-ops if not authenticated.
  Future<void> connect() async {
    try {
      await _ensureSocket();
    } on StateError {
      // Not logged in — notifications need a session; skip quietly.
    }
  }

  /// Closes the socket completely (call on logout / session end). Ends any
  /// active tracking session too.
  Future<void> disconnect() async {
    _reasons.clear();
    _stopLocationStream();
    final socket = _socket;
    if (socket != null) {
      if (socket.connected && _trackingStarted) socket.emit('tracking:stop');
      socket.dispose();
    }
    _socket = null;
    _connectCompleter = null;
    _lastPosition = null;
    _trackingStarted = false;
  }

  /// Starts a tracking session (location streaming), connecting the socket first
  /// if it isn't already up. [reason] holds the session open; multiple reasons
  /// stack. Throws [StateError] if not authenticated or the connection fails.
  Future<void> start({String reason = 'manual'}) async {
    _reasons.add(reason);

    // Reuse an already-connected socket (e.g. the notifications one) — just
    // open the session.
    if (_socket?.connected ?? false) {
      _beginTrackingSession();
      return;
    }

    try {
      await _ensureSocket();
      final c = _connectCompleter;
      if (c != null && !c.isCompleted) {
        await c.future.timeout(_connectTimeout);
      }
    } catch (e) {
      _reasons.remove(reason);
      rethrow;
    }

    // Connected now — open the session (onConnect may have already done it).
    if (_socket?.connected ?? false) _beginTrackingSession();
  }

  /// Releases the given [reason]. The tracking session is torn down when no
  /// reasons remain (or [force] is true) — but the socket STAYS connected for
  /// notifications. Use [disconnect] (logout) to actually close it.
  Future<void> stop({String reason = 'manual', bool force = false}) async {
    if (force) {
      _reasons.clear();
    } else {
      _reasons.remove(reason);
      if (_reasons.isNotEmpty) return; // still wanted by another caller
    }
    _stopTrackingSession();
  }

  /// Lazily creates + connects the shared socket (notifications + tracking) and
  /// registers the connect / notification listeners. Idempotent.
  Future<void> _ensureSocket() async {
    if (_socket != null || _creatingSocket) return;
    _creatingSocket = true;
    try {
      final token = await TokenStorage.getAccessToken();
      if (token == null || token.isEmpty) {
        throw StateError('Not authenticated — please log in again.');
      }

      final socket = io.io(
        ApiConstant.baseUrl,
        io.OptionBuilder()
            .setTransports(['websocket'])
            .setAuth({'token': token})
            .disableAutoConnect()
            .enableReconnection()
            .build(),
      );
      _socket = socket;
      final connected = Completer<void>();
      _connectCompleter = connected;

      socket.onConnect((_) {
        // Resync the inbox on every (re)connect — no server-side replay queue.
        onSocketConnected?.call();
        // (Re)open the tracking session if one is wanted. On a transient
        // reconnect _trackingStarted stays true, so the server resumes the
        // existing session and we don't re-emit / re-stream.
        if (_reasons.isNotEmpty && !_trackingStarted) _beginTrackingSession();
        if (!connected.isCompleted) connected.complete();
      });

      socket.onConnectError((Object? err) {
        if (!connected.isCompleted) {
          connected.completeError(
            StateError('Could not connect to tracking server.'),
          );
        }
      });

      // Real-time in-app notifications over the same connection. Silent (no
      // banner) — only updates the list + badge; the heads-up banner comes from
      // FCM, so a foreground push + socket event don't double-notify.
      socket.on('notification:new', (Object? data) {
        if (data is Map) {
          onNotification?.call(Map<String, dynamic>.from(data));
        }
      });

      socket.connect();
    } finally {
      _creatingSocket = false;
    }
  }

  /// Opens the tracking session (emit `tracking:start` + stream location), once
  /// — guarded so reconnects / duplicate calls don't restart it.
  void _beginTrackingSession() {
    if (_trackingStarted) return;
    final socket = _socket;
    if (socket == null || !socket.connected) return;
    _trackingStarted = true;
    socket.emit('tracking:start');
    _beginLocationStream();
  }

  /// Ends the tracking session (emit `tracking:stop` + stop streaming) but keeps
  /// the socket connected for notifications.
  void _stopTrackingSession() {
    _stopLocationStream();
    final socket = _socket;
    if (socket != null && socket.connected && _trackingStarted) {
      socket.emit('tracking:stop');
    }
    _trackingStarted = false;
    _lastPosition = null;
  }

  void _stopLocationStream() {
    _emitTimer?.cancel();
    _emitTimer = null;
    _positionSub?.cancel();
    _positionSub = null;
  }

  void _beginLocationStream() {
    _positionSub =
        Geolocator.getPositionStream(locationSettings: _locationSettings())
            .listen(
      (pos) {
        _lastPosition = pos;
        // NOTE: geofence detection no longer runs here. It runs in the
        // background-service isolate (see BackgroundLocationService), so it
        // survives the app being killed. This UI stream only feeds the live
        // tracking socket.
      },
      onError: (_) {/* transient GPS errors — keep the session alive */},
    );

    // Decoupled from GPS event cadence so an update is sent on a steady
    // interval even when the device is stationary.
    _emitTimer = Timer.periodic(_emitInterval, (_) => _emitLocation());
  }

  void _emitLocation() {
    final pos = _lastPosition;
    final socket = _socket;
    if (pos == null || socket == null || !socket.connected) return;

    socket.emit('location:update', {
      'latitude': pos.latitude,
      'longitude': pos.longitude,
      'accuracy': pos.accuracy,
      'speed': pos.speed,
      'bearing': pos.heading,
      'timestamp': pos.timestamp.toUtc().toIso8601String(),
    });
  }

  LocationSettings _locationSettings() {
    if (Platform.isAndroid) {
      return AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 0,
        intervalDuration: _emitInterval,
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationTitle: 'Live tracking active',
          notificationText: 'FieldGuard is sharing your location.',
          enableWakeLock: true,
        ),
      );
    }
    if (Platform.isIOS) {
      return AppleSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 0,
        pauseLocationUpdatesAutomatically: false,
        allowBackgroundLocationUpdates: true,
        showBackgroundLocationIndicator: true,
      );
    }
    return const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 0,
    );
  }
}
