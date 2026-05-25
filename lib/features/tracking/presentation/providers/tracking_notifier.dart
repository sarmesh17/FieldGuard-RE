import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:field_guard_re/core/services/live_tracking_service.dart';
import 'tracking_state.dart';

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
        return 'Live tracking started';
      } else {
        await _service.stop();
        state = state.copyWith(isActive: false, isLoading: false);
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
      return null;
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

    // Background location must be requested after foreground on Android.
    // Best-effort: tracking still works in foreground if this is denied.
    if (!await Permission.locationAlways.isGranted) {
      await Permission.locationAlways.request();
    }

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
