import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'package:field_guard_re/core/services/background_location_service.dart';
import 'package:field_guard_re/core/services/debug_log_service.dart';

/// Thin wrapper around [FlutterLocalNotificationsPlugin] for the immediate,
/// non-scheduled notifications this app fires — currently the geofence
/// enter/exit alerts. Single source of truth so channel setup and permission
/// requests live in one place.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  /// Shared id for the transient geofence enter/exit alert. The same id is
  /// used whether the alert is fired from the UI isolate or the background
  /// service isolate, so the two never stack a duplicate — a later `show`
  /// with this id overwrites the earlier one.
  static const int geofenceAlertId = 7001;

  /// Android channel for geofence arrival/departure alerts. High importance so
  /// it surfaces a heads-up banner even when the app is backgrounded.
  static const _channel = AndroidNotificationChannel(
    'geofence_alerts',
    'Geofence Alerts',
    description: 'Notifies when you reach or leave a task location.',
    importance: Importance.high,
  );

  /// Low-importance channel for the persistent background-location foreground
  /// service notification (the always-on "tracking" banner). Low importance so
  /// it stays silent and unobtrusive.
  static final _fgServiceChannel = AndroidNotificationChannel(
    BackgroundLocationService.channelId,
    'Location Tracking',
    description: 'Keeps your location updating for assigned tasks.',
    importance: Importance.low,
  );

  bool _initialised = false;

  /// One-time setup: registers the channel and requests notification
  /// permission (Android 13+ / iOS). Safe to call more than once.
  Future<void> init() async {
    if (_initialised) return;
    _initialised = true;

    try {
      const androidInit =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosInit = DarwinInitializationSettings();
      await _plugin.initialize(
        const InitializationSettings(android: androidInit, iOS: iosInit),
      );

      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (android != null) {
        await android.createNotificationChannel(_channel);
        await android.createNotificationChannel(_fgServiceChannel);
        final granted = await android.requestNotificationsPermission();
        await DebugLogService.instance
            .log('[notification] init ok android permission=$granted');
      }
    } catch (e, st) {
      // Don't leave _initialised=true if init crashed — let it retry next time.
      _initialised = false;
      await DebugLogService.instance
          .log('[notification] init FAILED err=$e $st');
      rethrow;
    }

    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    await ios?.requestPermissions(alert: true, badge: true, sound: true);
  }

  /// Shows an immediate notification. [id] lets callers overwrite their own
  /// prior alert (e.g. enter then exit) instead of stacking duplicates.
  Future<void> show({
    required int id,
    required String title,
    required String body,
  }) async {
    // init() can throw in a background-service isolate (plugin quirks /
    // no Activity for a permission prompt). Don't let that bubble out and get
    // swallowed by the microtask that fires geofence alerts — log it and
    // still attempt the show; the channel was already created by the UI
    // isolate's init() at app launch, so the alert usually lands anyway.
    if (!_initialised) {
      try {
        await init();
      } catch (e) {
        await DebugLogService.instance.log(
          '[notification] init() failed inside show() — attempting anyway: $e',
        );
      }
    }
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channel.id,
        _channel.name,
        channelDescription: _channel.description,
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: const DarwinNotificationDetails(),
    );
    try {
      await _plugin.show(id, title, body, details);
      await DebugLogService.instance
          .log('[notification] shown id=$id title="$title"');
    } catch (e, st) {
      if (kDebugMode) debugPrint('[notification] show failed: $e');
      await DebugLogService.instance
          .log('[notification] show FAILED id=$id title="$title" err=$e $st');
    }
  }
}
