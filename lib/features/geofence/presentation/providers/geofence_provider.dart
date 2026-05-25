import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:field_guard_re/core/services/background_location_service.dart';
import 'package:field_guard_re/core/services/debug_log_service.dart';
import 'package:field_guard_re/core/services/notification_service.dart';
import 'package:field_guard_re/features/tasks/data/models/task_model.dart';
import 'package:field_guard_re/features/tasks/presentation/providers/tasks_provider.dart';
import 'package:field_guard_re/features/tracking/presentation/providers/tracking_provider.dart';

void _log(String msg) {
  if (kDebugMode) debugPrint('[geofence-event] $msg');
  DebugLogService.instance.log('[geofence-event] $msg');
}

/// The last arm command the UI computed, so it can be re-sent to the service
/// isolate the moment that isolate signals it's ready (its listeners are up).
/// `null` means "disarm".
({
  int taskId,
  int? shopId,
  double lat,
  double lng,
  String? title,
  String? shopName,
})? _lastArm;
bool _bgReadyListenerWired = false;

/// Sends the current desired arm/disarm to the background service isolate.
void _applyArm() {
  final a = _lastArm;
  if (a == null) {
    BackgroundLocationService.disarm();
  } else {
    BackgroundLocationService.arm(
      taskId: a.taskId,
      shopId: a.shopId,
      shopLat: a.lat,
      shopLng: a.lng,
      taskTitle: a.title,
      shopName: a.shopName,
    );
  }
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
  // Wire the readiness handshake exactly once. The isolate drops any `arm`
  // sent before its listeners exist (invoke has no buffering), so when it
  // emits `bg-ready` we re-send whatever the current arm state is.
  if (!_bgReadyListenerWired) {
    _bgReadyListenerWired = true;
    BackgroundLocationService.onReady().listen((_) {
      _log('bg-service ready — re-applying arm state');
      _applyArm();
    });
  }

  final tasksState = ref.watch(tasksNotifierProvider);
  if (tasksState is! TasksSuccess) return; // don't toggle on Loading/Error.

  // Tracking-off disarms — even if a task is IN_PROGRESS, the user has
  // explicitly opted out of location for now. (`taskTrackingSyncProvider`
  // also stops the background service in this state, so disarm is largely
  // belt-and-braces — but keeps state consistent if the user re-enables.)
  final trackingOn = ref.watch(
    trackingNotifierProvider.select((s) => s.isActive),
  );

  final task =
      trackingOn ? ref.watch(activeInProgressTaskProvider) : null;
  final lat = double.tryParse(task?.shopLatitude ?? '');
  final lng = double.tryParse(task?.shopLongitude ?? '');

  _lastArm = (task != null && lat != null && lng != null)
      ? (
          taskId: task.id,
          shopId: task.shop?.id,
          lat: lat,
          lng: lng,
          title: task.title,
          shopName: task.shop?.name,
        )
      : null;
  _applyArm();
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
    // A solid buzz on arrival — the agent often has the phone in a pocket
    // and won't be staring at the screen when they reach the shop.
    HapticFeedback.heavyImpact();
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
    // Only react if this is the task we actually reached.
    if (ref.read(reachedDestinationTaskIdProvider) != taskId) {
      _log('skip: reached marker != $taskId');
      return;
    }
    ref.read(reachedDestinationTaskIdProvider.notifier).state = null;

    final shopName = taskById(taskId)?.shop?.name ?? 'the location';
    await NotificationService.instance.show(
      id: _kGeofenceNotifId,
      title: 'Task completed',
      body: 'You left $shopName — the task was marked completed.',
    );

    // NOTE: the app no longer PATCHes the task COMPLETED itself. The backend
    // auto-completes the task when it receives the visit upload (which the
    // retry queue guarantees, online or after reconnect). We just refresh so
    // the COMPLETED status surfaces — if the visit already uploaded (online
    // exit) the task is done now; if it's still queued (offline), the
    // `handleUploaded` refresh below catches up once it lands.
    await ref.read(tasksNotifierProvider.notifier).fetch();
  }

  /// A queued visit just uploaded → the backend has (auto-)completed that
  /// task server-side. Refresh so the COMPLETED status surfaces, the geofence
  /// disarms, and the route card clears. This is the offline path: the visit
  /// sat in the retry queue until the network came back, then this fired.
  Future<void> handleUploaded(int taskId) async {
    _log('visit uploaded for task=$taskId — refreshing for backend completion');
    await ref.read(tasksNotifierProvider.notifier).fetch();
  }

  final sub = BackgroundLocationService.geofenceEvents().listen((event) {
    if (event == null) return;
    final type = event['type'] as String?;
    final taskId = (event['taskId'] as num?)?.toInt();
    if (taskId == null) return;
    switch (type) {
      case 'enter':
        handleEnter(taskId);
      case 'exit':
        handleExit(taskId);
      case 'uploaded':
        handleUploaded(taskId);
    }
  });

  ref.onDispose(sub.cancel);
});

const _kGeofenceNotifId = 7001;
