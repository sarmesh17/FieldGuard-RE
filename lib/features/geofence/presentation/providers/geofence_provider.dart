import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:field_guard_re/core/services/geofence_visit_service.dart';
import 'package:field_guard_re/features/tasks/presentation/providers/tasks_provider.dart';

/// Keeps [GeofenceVisitService] armed to the shop of whatever task is
/// currently IN_PROGRESS, and disarmed when none is.
///
/// Mount this once near the top of the app (see `MainShell`) so the geofence
/// follows the active task regardless of which tab is on screen. Detection
/// itself runs off [LiveTrackingService]'s position stream — this provider
/// only points it at the right shop.
final geofenceVisitSyncProvider = Provider<void>((ref) {
  final task = ref.watch(activeInProgressTaskProvider);
  final service = GeofenceVisitService.instance;

  if (task == null) {
    service.disarm();
    return;
  }

  // `activeInProgressTaskProvider` already filters to parseable coords, but
  // re-parse defensively — a task without a valid shop location is skipped.
  final lat = double.tryParse(task.shopLatitude ?? '');
  final lng = double.tryParse(task.shopLongitude ?? '');
  if (lat == null || lng == null) {
    service.disarm();
    return;
  }

  service.arm(
    taskId: task.id,
    shopId: task.shop?.id,
    shopLat: lat,
    shopLng: lng,
  );
});
