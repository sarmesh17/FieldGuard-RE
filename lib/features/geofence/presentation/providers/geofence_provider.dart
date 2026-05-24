import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:field_guard_re/core/services/background_location_service.dart';
import 'package:field_guard_re/core/services/debug_log_service.dart';
import 'package:field_guard_re/core/services/notification_service.dart';
import 'package:field_guard_re/core/utils/result.dart';
import 'package:field_guard_re/features/tasks/data/models/task_model.dart';
import 'package:field_guard_re/features/tasks/data/models/update_task_request.dart';
import 'package:field_guard_re/features/tasks/presentation/providers/tasks_provider.dart';
import 'package:field_guard_re/features/tracking/presentation/providers/tracking_provider.dart';

void _log(String msg) {
  if (kDebugMode) debugPrint('[geofence-event] $msg');
  DebugLogService.instance.log('[geofence-event] $msg');
}

/// Points the geofence at the shop of whatever task is currently IN_PROGRESS,
/// and clears it when none is.
///
/// Detection runs in the BACKGROUND SERVICE isolate (so it survives the app
/// being killed), not here — so this provider just relays arm/disarm to that
/// isolate via [BackgroundLocationService]. The isolate's own
/// GeofenceVisitService does the actual enter/exit + visit persistence.
///
/// Gated on `TasksSuccess`: while the task list is loading or errored we
/// neither arm nor disarm — flipping the geofence on a transient empty list
/// would silently disarm a real in-progress task and lose enter/exit events.
///
/// Mount once near the top of the app (see `MainShell`).
final geofenceVisitSyncProvider = Provider<void>((ref) {
  final tasksState = ref.watch(tasksNotifierProvider);
  if (tasksState is! TasksSuccess) return; // don't toggle on Loading/Error.

  // Tracking-off disarms — even if a task is IN_PROGRESS, the user has
  // explicitly opted out of location for now. (`taskTrackingSyncProvider`
  // also stops the background service in this state, so disarm is largely
  // belt-and-braces — but keeps state consistent if the user re-enables.)
  final trackingOn = ref.watch(
    trackingNotifierProvider.select((s) => s.isActive),
  );
  if (!trackingOn) {
    BackgroundLocationService.disarm();
    return;
  }

  final task = ref.watch(activeInProgressTaskProvider);

  if (task == null) {
    BackgroundLocationService.disarm();
    return;
  }

  // `activeInProgressTaskProvider` already filters to parseable coords, but
  // re-parse defensively — a task without a valid shop location is skipped.
  final lat = double.tryParse(task.shopLatitude ?? '');
  final lng = double.tryParse(task.shopLongitude ?? '');
  if (lat == null || lng == null) {
    BackgroundLocationService.disarm();
    return;
  }

  BackgroundLocationService.arm(
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

/// Bridges geofence enter/exit events (forwarded from the background service
/// isolate via [BackgroundLocationService.geofenceEvents]) into app behaviour:
///
///  * ENTER  → fire a "you reached your destination" notification and mark
///    [reachedDestinationTaskIdProvider] so the map UI updates.
///  * EXIT   → fire a "left location" notification, AUTO-COMPLETE the task
///    (PATCH status=COMPLETED with an auto remark), and clear the reached
///    marker. The completion flips the task out of IN_PROGRESS, so
///    [geofenceVisitSyncProvider] disarms the fence on the next rebuild.
///
/// These events only arrive while the UI is alive. If the app was killed
/// during an exit, the visit itself is still persisted + uploaded by the
/// isolate; the auto-complete just won't fire until the app reopens (a future
/// reconcile-on-launch can cover that gap).
///
/// Mount once near the top of the app (see `MainShell`) alongside
/// [geofenceVisitSyncProvider].
final geofenceEventHandlerProvider = Provider<void>((ref) {
  TaskModel? taskById(int id) {
    final state = ref.read(tasksNotifierProvider);
    if (state is! TasksSuccess) return null;
    for (final t in state.tasks) {
      if (t.id == id) return t;
    }
    return null;
  }

  Future<void> handleEnter(int taskId) async {
    _log('enter event for task=$taskId — reached marker set');
    ref.read(reachedDestinationTaskIdProvider.notifier).state = taskId;
    final title = taskById(taskId)?.shop?.name ?? 'your destination';
    await NotificationService.instance.show(
      id: _kGeofenceNotifId,
      title: 'You reached your destination',
      body: 'You have arrived at $title.',
    );
  }

  Future<void> handleExit(int taskId) async {
    _log('exit event for task=$taskId '
        '(reached=${ref.read(reachedDestinationTaskIdProvider)})');
    // Only the task we actually reached should auto-complete.
    if (ref.read(reachedDestinationTaskIdProvider) != taskId) {
      _log('skip auto-complete: reached marker != $taskId');
      return;
    }
    ref.read(reachedDestinationTaskIdProvider.notifier).state = null;

    final shopName = taskById(taskId)?.shop?.name ?? 'the location';
    await NotificationService.instance.show(
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
  }

  final sub = BackgroundLocationService.geofenceEvents().listen((event) {
    if (event == null) return;
    final type = event['type'] as String?;
    final taskId = (event['taskId'] as num?)?.toInt();
    if (taskId == null) return;
    if (type == 'enter') {
      handleEnter(taskId);
    } else if (type == 'exit') {
      handleExit(taskId);
    }
  });

  ref.onDispose(sub.cancel);
});

const _kGeofenceNotifId = 7001;
