import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:field_guard_re/core/services/debug_log_service.dart';
import 'package:field_guard_re/core/services/geofence_visit_service.dart';
import 'package:field_guard_re/core/services/notification_service.dart';
import 'package:field_guard_re/core/utils/result.dart';
import 'package:field_guard_re/features/tasks/data/models/task_model.dart';
import 'package:field_guard_re/features/tasks/data/models/update_task_request.dart';
import 'package:field_guard_re/features/tasks/presentation/providers/tasks_provider.dart';

void _log(String msg) {
  if (kDebugMode) debugPrint('[geofence-event] $msg');
  DebugLogService.instance.log('[geofence-event] $msg');
}

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

/// The id of the task whose shop the agent has currently *reached* (is inside
/// the geofence of), or `null` when not inside any. The route screen watches
/// this to swap the "navigating / ETA" card for a "you've arrived" state.
/// Cleared automatically on real exit (the task auto-completes then).
final reachedDestinationTaskIdProvider = StateProvider<int?>((ref) => null);

/// Bridges [GeofenceVisitService]'s enter/exit callbacks into app behaviour:
///
///  * ENTER  → fire a "you reached your destination" notification and mark
///    [reachedDestinationTaskIdProvider] so the map UI updates.
///  * EXIT   → fire a "left location" notification, AUTO-COMPLETE the task
///    (PATCH status=COMPLETED with an auto remark), and clear the reached
///    marker. The completion flips the task out of IN_PROGRESS, so
///    [geofenceVisitSyncProvider] disarms the fence on the next rebuild.
///
/// Mount once near the top of the app (see `MainShell`) alongside
/// [geofenceVisitSyncProvider].
final geofenceEventHandlerProvider = Provider<void>((ref) {
  final service = GeofenceVisitService.instance;

  TaskModel? taskById(int id) {
    final state = ref.read(tasksNotifierProvider);
    if (state is! TasksSuccess) return null;
    for (final t in state.tasks) {
      if (t.id == id) return t;
    }
    return null;
  }

  service.onEnter = (taskId) {
    _log('onEnter fired for task=$taskId — reached marker set');
    ref.read(reachedDestinationTaskIdProvider.notifier).state = taskId;
    final title = taskById(taskId)?.shop?.name ?? 'your destination';
    NotificationService.instance.show(
      id: _kGeofenceNotifId,
      title: 'You reached your destination',
      body: 'You have arrived at $title.',
    );
  };

  service.onRealExit = (taskId) async {
    _log('onRealExit fired for task=$taskId '
        '(reached=${ref.read(reachedDestinationTaskIdProvider)})');
    // Only the task we actually reached should auto-complete.
    if (ref.read(reachedDestinationTaskIdProvider) != taskId) {
      _log('skip auto-complete: reached marker != $taskId');
      return;
    }
    ref.read(reachedDestinationTaskIdProvider.notifier).state = null;

    final shopName = taskById(taskId)?.shop?.name ?? 'the location';
    NotificationService.instance.show(
      id: _kGeofenceNotifId,
      title: 'Task completed',
      body: 'You left $shopName — the task was marked completed.',
    );

    // Auto-complete directly via the data source (not the autoDispose update
    // notifier — nothing is watching it here, so it could dispose mid-await).
    final result = await ref.read(taskDataSourceProvider).updateTask(
          taskId,
          const UpdateTaskRequest(
            status: 'COMPLETED',
            remarks: 'Auto-completed on geofence exit',
          ),
        );
    switch (result) {
      case Success():
        _log('auto-complete PATCH ok for task=$taskId — refreshing list');
        // Refresh so activeInProgressTaskProvider recomputes → geofence
        // disarms, tracking 'task' reason releases, route card clears.
        await ref.read(tasksNotifierProvider.notifier).fetch();
      case Failure(:final exception):
        _log('auto-complete PATCH FAILED for task=$taskId: $exception');
        // Re-arm the reached marker so a later retry/exit can complete it.
        ref.read(reachedDestinationTaskIdProvider.notifier).state = taskId;
    }
  };

  ref.onDispose(() {
    service.onEnter = null;
    service.onRealExit = null;
  });
});

const _kGeofenceNotifId = 7001;
