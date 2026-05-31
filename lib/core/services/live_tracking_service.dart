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

  /// Set of active reasons keeping the tracking session alive.
  /// Sample reasons: `'manual'` (user toggle), `'task'` (active IN_PROGRESS task).
  /// The session stops when this set becomes empty.
  final Set<String> _reasons = <String>{};

  bool get isRunning => _socket?.connected ?? false;
  bool isReasonActive(String reason) => _reasons.contains(reason);

  /// Connects, starts the session and begins streaming location.
  /// Completes once the socket is connected and `tracking:start` is emitted;
  /// throws [StateError] if not authenticated or the connection fails.
  /// [reason] tracks why the session is active; multiple reasons can hold
  /// the session open at the same time.
  Future<void> start({String reason = 'manual'}) async {
    _reasons.add(reason);
    if (_socket != null) return; // already running / starting

    final token = await TokenStorage.getAccessToken();
    if (token == null || token.isEmpty) {
      throw StateError('Not authenticated — please log in again.');
    }

    final connected = Completer<void>();

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

    socket.onConnect((_) {
      // Open the session only on the first connect of this run; on later
      // reconnects the server resumes the existing session and we just
      // keep streaming location, avoiding duplicate sessions.
      if (!_trackingStarted) {
        _trackingStarted = true;
        socket.emit('tracking:start');
        _beginLocationStream();
      }
      if (!connected.isCompleted) connected.complete();
    });

    socket.onConnectError((Object? err) {
      if (!connected.isCompleted) {
        connected.completeError(
          StateError('Could not connect to tracking server.'),
        );
      }
    });

    socket.connect();

    try {
      await connected.future.timeout(_connectTimeout);
    } catch (e) {
      await stop(force: true);
      rethrow;
    }
  }

  /// Releases the given [reason]. The session is only torn down when no
  /// reasons remain (or when [force] is true).
  Future<void> stop({String reason = 'manual', bool force = false}) async {
    if (force) {
      _reasons.clear();
    } else {
      _reasons.remove(reason);
      if (_reasons.isNotEmpty) return; // still wanted by another caller
    }

    _emitTimer?.cancel();
    _emitTimer = null;

    await _positionSub?.cancel();
    _positionSub = null;

    final socket = _socket;
    if (socket != null) {
      if (socket.connected && _trackingStarted) {
        socket.emit('tracking:stop');
      }
      socket.dispose();
    }
    _socket = null;
    _lastPosition = null;
    _trackingStarted = false;
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
