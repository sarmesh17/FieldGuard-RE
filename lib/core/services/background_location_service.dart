import 'dart:async';
import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:geolocator/geolocator.dart';

import 'package:field_guard_re/core/services/debug_log_service.dart';
import 'package:field_guard_re/core/services/geofence_visit_service.dart';

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
        initialNotificationTitle: 'FieldGuard',
        initialNotificationContent: 'Sharing your location for your active task.',
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

  /// Tells the service isolate which task's shop geofence to watch. The UI
  /// knows the active task; detection itself runs in the isolate.
  static void arm({
    required int taskId,
    int? shopId,
    required double shopLat,
    required double shopLng,
  }) =>
      FlutterBackgroundService().invoke('arm', {
        'taskId': taskId,
        'shopId': shopId,
        'shopLat': shopLat,
        'shopLng': shopLng,
      });

  /// Tells the service isolate to stop watching (no active task).
  static void disarm() => FlutterBackgroundService().invoke('disarm');

  /// Stream of geofence transitions forwarded from the isolate. Each event is
  /// `{type: 'enter'|'exit', taskId: int}`. Only delivered while the UI is
  /// alive — missed events don't lose the visit (persisted in the isolate).
  static Stream<Map<String, dynamic>?> geofenceEvents() =>
      FlutterBackgroundService().on('geofence-event');

  /// Fires once the service isolate has finished registering its listeners.
  /// The UI must (re)send the current arm state on this signal, because a
  /// prior `arm()` invoke during the isolate's cold start is silently dropped
  /// (invoke has no buffering). Without this handshake the geofence can stay
  /// disarmed forever even though a task is IN_PROGRESS.
  static Stream<Map<String, dynamic>?> onReady() =>
      FlutterBackgroundService().on('bg-ready');
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

  // Detection runs HERE, in the service isolate — so enter/exit + visit
  // persistence/upload survive the UI being killed. This is a separate
  // GeofenceVisitService instance from the UI one (isolates don't share
  // memory); the UI's instance stays idle and only consumes forwarded events.
  final geofence = GeofenceVisitService.instance;

  // NOTE: recover() is deliberately NOT called here. The persisted open-visit
  // + upload queue live on shared disk, and the UI isolate already runs
  // recover() on launch. Running it in both isolates would race on the same
  // storage with no cross-isolate lock. The isolate detects + closes visits
  // live; stale opens from a full process death are reconciled by the UI's
  // recover() on next app open.

  // Forward live transitions to the UI (delivered only while the UI is alive;
  // missed events are fine — the visit itself is persisted + uploaded here).
  geofence.onEnter = (taskId) =>
      service.invoke('geofence-event', {'type': 'enter', 'taskId': taskId});
  geofence.onRealExit = (taskId) =>
      service.invoke('geofence-event', {'type': 'exit', 'taskId': taskId});

  // The UI tells us which task's shop to watch (it knows the active task).
  service.on('arm').listen((data) {
    if (data == null) return;
    final taskId = data['taskId'] as int?;
    final shopLat = (data['shopLat'] as num?)?.toDouble();
    final shopLng = (data['shopLng'] as num?)?.toDouble();
    if (taskId == null || shopLat == null || shopLng == null) return;
    geofence.arm(
      taskId: taskId,
      shopId: data['shopId'] as int?,
      shopLat: shopLat,
      shopLng: shopLng,
    );
  });
  service.on('disarm').listen((_) => geofence.disarm());

  // Listeners are now registered. Tell the UI we're ready so it can (re)send
  // the current arm state — `invoke` is fire-and-forget with no buffering, so
  // an `arm` sent before this point during a cold start would have been lost.
  service.invoke('bg-ready');
  await DebugLogService.instance.log('[bg-service] ready — requested arm state');

  StreamSubscription<Position>? sub;
  Timer? retryTimer;

  // Start the location stream — but ONLY once permission is actually granted.
  // The service often boots (it's sticky: stopWithTask=false) before the user
  // grants "Allow all the time", and getPositionStream errors out + dies on a
  // denied permission with no retry. So we gate on permission and keep
  // re-checking until it's granted, then (re)subscribe. If the stream errors
  // or ends, we drop the sub so the watchdog restarts it.
  Future<void> startStreamIfPermitted() async {
    if (sub != null) return; // already streaming

    final perm = await Geolocator.checkPermission();
    final ok = perm == LocationPermission.always ||
        perm == LocationPermission.whileInUse;
    if (!ok) {
      await DebugLogService.instance
          .log('[bg-service] waiting for location permission ($perm)');
      return;
    }

    await DebugLogService.instance.log('[bg-service] starting position stream');
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
        geofence.onPositionUpdate(pos);
      },
      onError: (e) async {
        await DebugLogService.instance.log('[bg-service] stream error: $e');
        // Drop the dead subscription so the watchdog re-subscribes once
        // conditions recover (e.g. permission granted, GPS turned back on).
        await sub?.cancel();
        sub = null;
      },
      onDone: () async {
        await sub?.cancel();
        sub = null;
      },
      cancelOnError: true,
    );
  }

  // Watchdog: every 10s, (re)start the stream if it isn't running. Covers the
  // boot-before-permission case and any later stream death.
  retryTimer = Timer.periodic(
    const Duration(seconds: 10),
    (_) => startStreamIfPermitted(),
  );
  await startStreamIfPermitted();

  service.on('stopService').listen((_) async {
    await DebugLogService.instance.log('[bg-service] stopService received');
    retryTimer?.cancel();
    await sub?.cancel();
    await service.stopSelf();
  });
}
