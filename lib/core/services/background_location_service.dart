import 'dart:async';
import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:geolocator/geolocator.dart';

import 'package:field_guard_re/core/services/debug_log_service.dart';

/// Foreground background-service that keeps a high-accuracy location stream
/// alive in a SEPARATE Dart isolate — surviving the UI being backgrounded or
/// the app process being killed (unlike the in-UI `LiveTrackingService`).
///
/// PHASE 2a (current): the isolate only *streams + logs* fixes, to verify that
/// `geolocator` and on-device storage actually work off the UI isolate, even
/// when the app is swipe-killed. Geofence detection still runs in the UI for
/// now; Phase 2b moves it here.
///
/// Isolate model: [_onStart] runs in its own isolate with its own memory — it
/// does NOT share the UI's singletons. UI ↔ service talk over
/// `service.invoke()` / `service.on()`.
class BackgroundLocationService {
  BackgroundLocationService._();

  /// Dedicated foreground-service notification channel. Distinct from the
  /// `geofence_alerts` channel so the persistent "tracking" notification and
  /// the transient enter/exit alerts don't collide.
  static const channelId = 'fg_location_service';
  static const _notifId = 9911;

  /// Call once in `main()` BEFORE `runApp`. Registers the isolate entry point.
  /// `autoStart: false` — we only run the service while a task is IN_PROGRESS
  /// (started/stopped from the task-tracking sync).
  static Future<void> initialize() async {
    final service = FlutterBackgroundService();
    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: _onStart,
        autoStart: false,
        isForegroundMode: true,
        notificationChannelId: channelId,
        initialNotificationTitle: 'FieldGuard tracking',
        initialNotificationContent: 'Monitoring your location for tasks.',
        foregroundServiceNotificationId: _notifId,
        foregroundServiceTypes: [AndroidForegroundType.location],
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: _onStart,
        onBackground: _onIosBackground,
      ),
    );
  }

  static Future<bool> isRunning() => FlutterBackgroundService().isRunning();

  /// Starts the foreground service (no-op if already running).
  static Future<void> start() async {
    final service = FlutterBackgroundService();
    if (await service.isRunning()) return;
    await service.startService();
  }

  /// Asks the isolate to stop itself.
  static void stop() => FlutterBackgroundService().invoke('stopService');
}

/// iOS background-fetch hook — required by the plugin even if unused for now.
@pragma('vm:entry-point')
Future<bool> _onIosBackground(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  return true;
}

/// Service isolate entry point. Runs independently of the UI; keep everything
/// here self-contained (no UI singletons).
@pragma('vm:entry-point')
void _onStart(ServiceInstance service) async {
  // Plugins must be re-registered in this isolate (geolocator, path_provider…).
  DartPluginRegistrant.ensureInitialized();

  // The on-device log lives in a file, so it's reachable from this isolate too.
  await DebugLogService.instance.init();
  await DebugLogService.instance.log('[bg-service] isolate started');

  StreamSubscription<Position>? sub;

  service.on('stopService').listen((_) async {
    await DebugLogService.instance.log('[bg-service] stopService received');
    await sub?.cancel();
    await service.stopSelf();
  });

  // High-accuracy stream; distanceFilter 0 so we keep getting fixes even when
  // stationary (needed later for geofence dwell detection).
  sub = Geolocator.getPositionStream(
    locationSettings: const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 0,
    ),
  ).listen(
    (pos) {
      DebugLogService.instance.log(
        '[bg-service] fix lat=${pos.latitude.toStringAsFixed(6)} '
        'lng=${pos.longitude.toStringAsFixed(6)} '
        'acc=${pos.accuracy.toStringAsFixed(0)}m',
      );
      // Forward to the UI isolate too (only delivered while UI is alive).
      service.invoke('location', {
        'lat': pos.latitude,
        'lng': pos.longitude,
        'acc': pos.accuracy,
        'ts': pos.timestamp.toUtc().toIso8601String(),
      });
    },
    onError: (e) =>
        DebugLogService.instance.log('[bg-service] stream error: $e'),
  );
}
