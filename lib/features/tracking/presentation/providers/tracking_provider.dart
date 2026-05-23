import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:field_guard_re/core/services/live_tracking_service.dart';
import 'tracking_notifier.dart';
import 'tracking_state.dart';

export 'tracking_state.dart';
export 'tracking_notifier.dart';

final trackingNotifierProvider =
    StateNotifierProvider<TrackingNotifier, TrackingState>(
  (ref) => TrackingNotifier(LiveTrackingService.instance),
);
