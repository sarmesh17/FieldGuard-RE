import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:field_guard_re/core/services/live_tracking_service.dart';
import 'tracking_state.dart';

/// Storage key that remembers the user's last Live Tracking choice across
/// process restarts. The flag is an *intent* — the actual session is only
/// active if permissions still hold at restore time.
const _kTrackingDesiredKey = 'tracking_desired_active';

const _trackingStorage = FlutterSecureStorage(
  aOptions: AndroidOptions(encryptedSharedPreferences: true),
);

class TrackingNotifier extends StateNotifier<TrackingState> {
  TrackingNotifier(this._service) : super(const TrackingState());

  final LiveTrackingService _service;

  /// Flips the live-tracking session. Turning on requests location
  /// permissions, connects the socket and starts streaming; turning off
  /// ends the session and disconnects. Returns a message for the UI
  /// snackbar on success, or null on failure (state.error holds the reason).
  Future<String?> toggle() async {
    if (state.isLoading) return null;

    final wantActive = !state.isActive;
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      if (wantActive) {
        final permissionError = await _ensurePermissions();
        if (permissionError != null) {
          state = state.copyWith(isLoading: false, error: permissionError);
          return null;
        }
        await _service.start();
        state = state.copyWith(isActive: true, isLoading: false);
        await _writeDesired(true);
        return 'Live tracking started';
      } else {
        await _service.stop();
        state = state.copyWith(isActive: false, isLoading: false);
        await _writeDesired(false);
        return 'Live tracking stopped';
      }
    } catch (e) {
      // Roll back to a safe state — if start failed the session is not live.
      await _service.stop();
      state = state.copyWith(
        isActive: false,
        isLoading: false,
        error: e is StateError ? e.message : 'Tracking failed. Try again.',
      );
      await _writeDesired(false);
      return null;
    }
  }

  /// Re-applies the user's last Live Tracking choice across process restarts.
  /// If they last left it ON, this re-checks permissions and restarts the
  /// session (and therefore the background-location service via
  /// `taskTrackingSyncProvider`). Silently no-ops if the user never enabled
  /// it, if permissions are now missing, or if it's already active.
  ///
  /// Call once at startup (e.g. from MainShell) AFTER providers are mounted.
  Future<void> restore() async {
    if (state.isActive || state.isLoading) return;
    final desired = await _trackingStorage.read(key: _kTrackingDesiredKey);
    if (desired != 'true') return;
    if (kDebugMode) {
      debugPrint('[tracking] restoring last session (desired=ON)');
    }
    await toggle();
  }

  /// Persists the user's tracking intent so we can restore it on next launch.
  /// Best-effort — storage failures must never block the toggle itself.
  Future<void> _writeDesired(bool active) async {
    try {
      await _trackingStorage.write(
        key: _kTrackingDesiredKey,
        value: active ? 'true' : 'false',
      );
    } catch (e) {
      if (kDebugMode) debugPrint('[tracking] persist failed: $e');
    }
  }

  /// Returns a user-facing message if tracking cannot start, else null.
  Future<String?> _ensurePermissions() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      return 'Location is off. Turn on GPS to start tracking.';
    }

    var whenInUse = await Permission.locationWhenInUse.status;
    if (!whenInUse.isGranted) {
      whenInUse = await Permission.locationWhenInUse.request();
    }
    if (!whenInUse.isGranted) {
      return 'Location permission is required for tracking.';
    }

    // NOTE: deliberately NOT requesting Permission.locationAlways
    // (ACCESS_BACKGROUND_LOCATION). The manifest doesn't declare it (see the
    // long comment in AndroidManifest.xml) — requesting it here would auto-
    // deny and only confuse the user. Tracking runs inside a foreground
    // service, which Android treats as foreground for permission purposes.

    // Android 13+ needs this for the foreground-service notification.
    if (!await Permission.notification.isGranted) {
      await Permission.notification.request();
    }

    return null;
  }

  @override
  void dispose() {
    _service.stop();
    super.dispose();
  }
}
