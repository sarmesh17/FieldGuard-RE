import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:field_guard_re/core/constants/api_constant.dart';
import 'package:field_guard_re/core/network/dio_client.dart';
import 'package:field_guard_re/core/router/app_router.dart';
import 'package:field_guard_re/core/router/app_routes.dart';
import 'package:field_guard_re/core/services/debug_log_service.dart';
import 'package:field_guard_re/core/services/notification_service.dart';
import 'package:field_guard_re/core/services/token_storage.dart';

/// Background message handler. Must be a top-level / static function annotated
/// with `@pragma('vm:entry-point')` — FCM spins up a fresh isolate to run it.
///
/// We only need this for *data-only* messages: a message carrying a
/// `notification` block is rendered in the system tray by the OS automatically
/// while the app is backgrounded/killed, so there's nothing to do for those.
/// Kept minimal until the backend starts sending data-only pushes.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // No-op: notification-type pushes are shown by the OS when backgrounded.
}

/// Owns the FCM lifecycle for the app:
///
///  * initialises Firebase Messaging (permission + handlers) at launch,
///  * fetches the device's FCM token and registers it with the backend once a
///    user session is active (`POST /api/v1/device/push-token`),
///  * re-registers automatically when FCM rotates the token,
///  * mirrors foreground pushes to a local notification (the OS suppresses the
///    system tray banner while the app is in the foreground).
///
/// Token registration is gated on an authenticated session: the backend
/// endpoint needs the bearer token, and a token belongs to a specific user.
/// Call [registerToken] right after login and after a session is restored.
class PushNotificationService {
  PushNotificationService._();
  static final PushNotificationService instance = PushNotificationService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  /// Set by the app (see MainShell) so a foreground push can refresh the in-app
  /// notification list + unread badge live. Fired on every foreground message.
  void Function()? onInboxChanged;

  /// Own Dio (auth + refresh interceptors) so registration works independent
  /// of any widget/provider being alive — mirrors [GeofenceVisitService].
  late final Dio _dio = DioClient.createDio();

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
  static const _kDeviceIdKey = 'push_device_id';

  bool _initialised = false;

  /// One-time setup: requests notification permission (iOS/APNs + Android 13+),
  /// registers the background handler, and wires the foreground + token-refresh
  /// listeners. Does NOT register the token — that waits for an active session
  /// (see [registerToken]). Safe to call more than once.
  Future<void> init() async {
    if (_initialised) return;
    _initialised = true;

    try {
      await _messaging.requestPermission();

      FirebaseMessaging.onBackgroundMessage(
        firebaseMessagingBackgroundHandler,
      );

      // Foreground: the system tray banner is suppressed, so surface it
      // ourselves via the local-notifications plugin.
      FirebaseMessaging.onMessage.listen(_onForegroundMessage);

      // FCM rotates tokens periodically and on app data restore — keep the
      // backend in sync (only fires the network call when signed in).
      _messaging.onTokenRefresh.listen((token) {
        unawaited(_sendToken(token));
      });

      // ── Deep-link: notification taps → in-app screen ────────────────────
      // Foreground: tapping the local notification we showed.
      NotificationService.instance.onTap = _onLocalNotificationTap;
      // Background (app alive): tapping the OS-rendered system push.
      FirebaseMessaging.onMessageOpenedApp.listen(
        (m) => _handleDeepLink(m.data),
      );
      // Terminated cold-start via a push tap — stash it and navigate once the
      // app is authenticated and on home (see [consumePendingDeepLink]).
      final initial = await _messaging.getInitialMessage();
      if (initial != null) _pendingDeepLink = initial.data;
    } catch (e, st) {
      _initialised = false; // let it retry next launch
      await DebugLogService.instance.log('[push] init FAILED err=$e $st');
    }
  }

  void _onForegroundMessage(RemoteMessage message) {
    final n = message.notification;
    final title = n?.title ?? message.data['title'] as String? ?? 'FieldGuard';
    final body = n?.body ?? message.data['body'] as String? ?? '';
    if (n == null && body.isEmpty) return; // nothing to show

    DebugLogService.instance.log('[push] foreground message title="$title"');
    // The backend also persisted this to the inbox — refresh list + badge.
    onInboxChanged?.call();
    NotificationService.instance.showPush(
      // Per-message id so distinct pushes stack instead of overwriting.
      id: DateTime.now().millisecondsSinceEpoch.remainder(1 << 31),
      title: title,
      body: body,
      // Carry the data map so a tap can deep-link (same shape as a system push).
      payload: message.data.isEmpty ? null : jsonEncode(message.data),
    );
  }

  // ── Deep-linking ──────────────────────────────────────────────────────────

  /// Set from a terminated-state launch ([FirebaseMessaging.getInitialMessage])
  /// and consumed once the app reaches an authenticated screen.
  Map<String, dynamic>? _pendingDeepLink;

  /// Tap on a foreground local notification — its payload is the JSON data map.
  void _onLocalNotificationTap(String payload) {
    try {
      final data = jsonDecode(payload);
      if (data is Map) _handleDeepLink(Map<String, dynamic>.from(data));
    } catch (e) {
      DebugLogService.instance.log('[push] tap payload parse failed: $e');
    }
  }

  /// Public entry so the in-app notification list can route a tapped item
  /// through the exact same logic as a push tap.
  void openFromData(Map<String, dynamic> data) => _handleDeepLink(data);

  /// Navigates to the screen a notification points at. [data] is the FCM data
  /// map (values are strings in a push, but may be ints from the in-app JSON —
  /// [_asInt] handles both).
  void _handleDeepLink(Map<String, dynamic> data) {
    final kind = data['kind']?.toString();
    DebugLogService.instance.log('[push] deep-link kind=$kind');
    switch (kind) {
      case 'TASK_ASSIGNED':
        final taskId = _asInt(data['taskId']);
        if (taskId != null) {
          unawaited(AppRouter.router.push(AppRoutes.taskDetailPath(taskId)));
        }
      default:
        // Other kinds (e.g. CHEQUE_RECEIVED) target the manager app.
        break;
    }
  }

  /// Consume a deep-link captured from a terminated-state launch. Call once the
  /// app has navigated to an authenticated screen (see the splash screen).
  void consumePendingDeepLink() {
    final data = _pendingDeepLink;
    if (data == null) return;
    _pendingDeepLink = null;
    _handleDeepLink(data);
  }

  static int? _asInt(dynamic v) {
    if (v is int) return v;
    if (v is String) return int.tryParse(v);
    return null;
  }

  /// Fetches the current FCM token and registers it with the backend.
  /// No-op when there's no signed-in user. Call after login + session restore.
  Future<void> registerToken() async {
    if (!await _isAuthenticated()) return;
    try {
      final token = await _messaging.getToken();
      if (token == null || token.isEmpty) {
        await DebugLogService.instance.log('[push] getToken returned null');
        return;
      }
      await _sendToken(token);
    } catch (e, st) {
      await DebugLogService.instance.log('[push] registerToken FAILED $e $st');
    }
  }

  /// Removes this device's push token from the backend so it stops receiving
  /// pushes for the user who is signing out. MUST be called *before* tokens are
  /// cleared — the endpoint needs the bearer token. The FCM token itself is
  /// left intact (only the backend mapping is dropped); re-login re-registers
  /// it under the same [deviceId], so no duplicate rows accumulate.
  Future<void> unregisterToken() async {
    if (!await _isAuthenticated()) return;
    try {
      await _dio.delete(
        ApiConstant.pushTokenEndpoint,
        data: {'deviceId': await _deviceId()},
      );
      await DebugLogService.instance.log('[push] token unregistered');
    } on DioException catch (e) {
      await DebugLogService.instance.log(
        '[push] token unregister HTTP ${e.response?.statusCode} ${e.message}',
      );
    } catch (e, st) {
      await DebugLogService.instance.log('[push] token unregister FAILED $e $st');
    }
  }

  Future<void> _sendToken(String pushToken) async {
    if (!await _isAuthenticated()) return; // only for a signed-in user
    try {
      final info = await PackageInfo.fromPlatform();
      await _dio.post(
        ApiConstant.pushTokenEndpoint,
        data: {
          'deviceId': await _deviceId(),
          'pushToken': pushToken,
          'platform': _platform(),
          'appVersion': info.version,
        },
      );
      await DebugLogService.instance.log('[push] token registered');
    } on DioException catch (e) {
      await DebugLogService.instance
          .log('[push] token register HTTP ${e.response?.statusCode} ${e.message}');
    } catch (e, st) {
      await DebugLogService.instance.log('[push] token register FAILED $e $st');
    }
  }

  Future<bool> _isAuthenticated() async {
    final token = await TokenStorage.getAccessToken();
    return token != null && token.isNotEmpty;
  }

  String _platform() {
    if (Platform.isAndroid) return 'ANDROID';
    if (Platform.isIOS) return 'IOS';
    return 'UNKNOWN';
  }

  /// A stable per-install device id, generated once and persisted. Survives
  /// app restarts; a reinstall (which clears secure storage) yields a new one,
  /// which is fine — the backend keys device rows on it.
  Future<String> _deviceId() async {
    final existing = await _storage.read(key: _kDeviceIdKey);
    if (existing != null && existing.isNotEmpty) return existing;
    final id = _uuidV4();
    await _storage.write(key: _kDeviceIdKey, value: id);
    return id;
  }

  static String _uuidV4() {
    final rng = Random.secure();
    final b = List<int>.generate(16, (_) => rng.nextInt(256));
    b[6] = (b[6] & 0x0f) | 0x40; // version 4
    b[8] = (b[8] & 0x3f) | 0x80; // variant 1
    final h = b.map((x) => x.toRadixString(16).padLeft(2, '0')).join();
    return '${h.substring(0, 8)}-${h.substring(8, 12)}-'
        '${h.substring(12, 16)}-${h.substring(16, 20)}-${h.substring(20)}';
  }
}
