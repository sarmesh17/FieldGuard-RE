import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Thin wrapper around [FlutterLocalNotificationsPlugin] for the immediate,
/// non-scheduled notifications this app fires — currently the geofence
/// enter/exit alerts. Single source of truth so channel setup and permission
/// requests live in one place.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  /// Android channel for geofence arrival/departure alerts. High importance so
  /// it surfaces a heads-up banner even when the app is backgrounded.
  static const _channel = AndroidNotificationChannel(
    'geofence_alerts',
    'Geofence Alerts',
    description: 'Notifies when you reach or leave a task location.',
    importance: Importance.high,
  );

  bool _initialised = false;

  /// One-time setup: registers the channel and requests notification
  /// permission (Android 13+ / iOS). Safe to call more than once.
  Future<void> init() async {
    if (_initialised) return;
    _initialised = true;

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
      await android.requestNotificationsPermission();
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
    if (!_initialised) await init();
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
    } catch (e) {
      if (kDebugMode) debugPrint('[notification] show failed: $e');
    }
  }
}
