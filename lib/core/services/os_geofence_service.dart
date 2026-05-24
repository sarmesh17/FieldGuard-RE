import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'package:field_guard_re/core/services/debug_log_service.dart';

/// PHASE 3 PROOF (branch feat/os-geofence-wake):
///
/// Thin bridge to the platform's OS Geofencing API (Android GeofencingClient
/// via [MethodChannel]). The OS monitors the fence and delivers ENTER/EXIT to
/// a native BroadcastReceiver even when the Flutter app is fully killed —
/// which the sticky foreground service can't survive.
///
/// For now the native side just posts a notification on transition so we can
/// confirm on-device that the OS wakes us. iOS is a no-op until wired.
class OsGeofenceService {
  OsGeofenceService._();

  static const _channel = MethodChannel('field_guard/os_geofence');

  /// Registers (or replaces) the single OS geofence at the shop.
  static Future<void> register({
    required double lat,
    required double lng,
    double radius = 30.0,
  }) async {
    if (!_isAndroid) return;
    try {
      await _channel.invokeMethod('registerGeofence', {
        'lat': lat,
        'lng': lng,
        'radius': radius,
      });
      await DebugLogService.instance
          .log('[os-geofence] registered @($lat,$lng) r=${radius}m');
    } catch (e) {
      await DebugLogService.instance.log('[os-geofence] register failed: $e');
    }
  }

  /// Removes the OS geofence (no active task).
  static Future<void> remove() async {
    if (!_isAndroid) return;
    try {
      await _channel.invokeMethod('removeGeofence');
      await DebugLogService.instance.log('[os-geofence] removed');
    } catch (e) {
      await DebugLogService.instance.log('[os-geofence] remove failed: $e');
    }
  }

  static bool get _isAndroid =>
      defaultTargetPlatform == TargetPlatform.android;
}
