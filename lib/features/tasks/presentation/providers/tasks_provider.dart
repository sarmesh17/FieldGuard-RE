import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:field_guard_re/core/errors/app_exception.dart';
import 'package:field_guard_re/core/services/background_location_service.dart';
import 'package:field_guard_re/core/utils/result.dart';
import 'package:field_guard_re/features/auth/presentation/providers/auth_provider.dart';
import 'package:field_guard_re/features/tasks/data/datasources/task_datasource.dart';
import 'package:field_guard_re/features/tasks/data/datasources/task_datasource_impl.dart';
import 'package:field_guard_re/features/tasks/data/models/task_model.dart';
import 'package:field_guard_re/features/tasks/data/models/task_history_entry.dart';
import 'package:field_guard_re/features/tasks/data/models/update_task_request.dart';
import 'package:field_guard_re/features/tracking/presentation/providers/tracking_provider.dart';

// ── State ─────────────────────────────────────────────────────────────────────

sealed class TasksState {
  const TasksState();
}

class TasksInitial extends TasksState {
  const TasksInitial();
}

class TasksLoading extends TasksState {
  const TasksLoading();
}

class TasksSuccess extends TasksState {
  final List<TaskModel> tasks;
  const TasksSuccess(this.tasks);
}

class TasksError extends TasksState {
  final String message;
  const TasksError(this.message);
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class TasksNotifier extends StateNotifier<TasksState> {
  TasksNotifier(this._dataSource) : super(const TasksInitial()) {
    fetch();
  }

  final TaskDataSource _dataSource;

  Future<void> fetch({String? status}) async {
    state = const TasksLoading();
    final result = await _dataSource.getTasks(status: status);
    state = switch (result) {
      Success(:final data) => TasksSuccess(data),
      Failure(:final exception) => TasksError(
          exception is AppException ? exception.message : exception.toString(),
        ),
    };
  }
}

// ── Providers ─────────────────────────────────────────────────────────────────

final taskDataSourceProvider = Provider<TaskDataSource>(
  (ref) => TaskDataSourceImpl(ref.watch(dioProvider)),
);

/// Intentionally NOT autoDispose: this is the app's single source of truth
/// for the user's task list. Multiple long-lived consumers depend on it being
/// continuously available (e.g. `activeInProgressTaskProvider` →
/// `geofenceVisitSyncProvider` for arming the background geofence, and the
/// task-update sheet's "only one IN_PROGRESS at a time" guard). With
/// autoDispose, navigating away from a tab let the notifier dispose; the next
/// rebuild constructed a fresh one that started in `TasksLoading`, which
/// silently disarmed the geofence and let the demote-reason guard skip,
/// allowing two tasks to be IN_PROGRESS at once.
final tasksNotifierProvider =
    StateNotifierProvider<TasksNotifier, TasksState>(
  (ref) => TasksNotifier(ref.watch(taskDataSourceProvider)),
);

final taskDetailProvider =
    FutureProvider.autoDispose.family<TaskModel, int>((ref, id) async {
  final ds = ref.watch(taskDataSourceProvider);
  final result = await ds.getTaskById(id);
  return switch (result) {
    Success(:final data) => data,
    Failure(:final exception) => throw exception,
  };
});

// ── Update state ──────────────────────────────────────────────────────────────

sealed class TaskUpdateState {
  const TaskUpdateState();
}

class TaskUpdateIdle extends TaskUpdateState {
  const TaskUpdateIdle();
}

class TaskUpdateLoading extends TaskUpdateState {
  const TaskUpdateLoading();
}

class TaskUpdateSuccess extends TaskUpdateState {
  final TaskModel task;
  const TaskUpdateSuccess(this.task);
}

class TaskUpdateError extends TaskUpdateState {
  final String message;
  const TaskUpdateError(this.message);
}

// ── Update notifier ───────────────────────────────────────────────────────────

class TaskUpdateNotifier extends StateNotifier<TaskUpdateState> {
  TaskUpdateNotifier(this._dataSource) : super(const TaskUpdateIdle());

  final TaskDataSource _dataSource;

  Future<bool> update(int id, UpdateTaskRequest request) async {
    state = const TaskUpdateLoading();
    final result = await _dataSource.updateTask(id, request);
    state = switch (result) {
      Success(:final data) => TaskUpdateSuccess(data),
      Failure(:final exception) => TaskUpdateError(
          exception is AppException ? exception.message : exception.toString(),
        ),
    };
    return state is TaskUpdateSuccess;
  }

  // NOTE: previously this notifier auto-started/stopped LiveTrackingService
  // on task status changes (`'task'` reason). That's gone now — Live Tracking
  // is solely user-controlled via the Route screen toggle, and the task-
  // update sheet refuses to flip a task to IN_PROGRESS while tracking is off.
  // Keeping the auto-start would silently re-enable a session the user
  // explicitly turned off.

  void reset() => state = const TaskUpdateIdle();
}

final taskUpdateProvider =
    StateNotifierProvider.autoDispose<TaskUpdateNotifier, TaskUpdateState>(
  (ref) => TaskUpdateNotifier(ref.watch(taskDataSourceProvider)),
);

// ── Active task selector ──────────────────────────────────────────────────────

/// Tasks whose `dueDate` falls within the current local day, sorted so the
/// employee's eyes land on the active work first:
///   IN_PROGRESS → PENDING → COMPLETED → CANCELLED
/// and within each group, earliest due time first.
///
/// Used by the Route screen's "Today's Schedule" list and the AppBar
/// counter, so both stay in sync with a single computation.
final todayTasksProvider = Provider<List<TaskModel>>((ref) {
  final state = ref.watch(tasksNotifierProvider);
  if (state is! TasksSuccess) return const [];

  final now = DateTime.now();
  final dayStart = DateTime(now.year, now.month, now.day);
  final dayEnd = dayStart.add(const Duration(days: 1));

  final today = <TaskModel>[];
  for (final t in state.tasks) {
    final due = t.dueDate?.toLocal();
    if (due == null) continue;
    if (due.isBefore(dayStart)) continue;
    if (!due.isBefore(dayEnd)) continue;
    today.add(t);
  }

  int rank(String s) => switch (s) {
        'IN_PROGRESS' => 0,
        'PENDING' => 1,
        'COMPLETED' => 2,
        'CANCELLED' => 3,
        _ => 4,
      };
  today.sort((a, b) {
    final r = rank(a.status).compareTo(rank(b.status));
    if (r != 0) return r;
    return a.dueDate!.compareTo(b.dueDate!);
  });
  return today;
});

/// Picks the single task the employee is "currently doing" — the first
/// IN_PROGRESS task that has parseable shop coordinates. Returns `null` when
/// nothing is in progress, which the route screen uses to fall back to a
/// plain "show me on the map" view.
final activeInProgressTaskProvider = Provider<TaskModel?>((ref) {
  final state = ref.watch(tasksNotifierProvider);
  if (state is! TasksSuccess) return null;
  for (final t in state.tasks) {
    if (t.status != 'IN_PROGRESS') continue;
    if (double.tryParse(t.shopLatitude ?? '') == null) continue;
    if (double.tryParse(t.shopLongitude ?? '') == null) continue;
    return t;
  }
  return null;
});

// ── Task tracking sync ────────────────────────────────────────────────────────

/// Drives the kill-proof background location service. It runs ONLY when both
/// are true:
///   * Live Tracking is ON (the user is the master switch), and
///   * at least one task is IN_PROGRESS (otherwise there's nothing to watch).
///
/// We deliberately do NOT auto-start `LiveTrackingService` on task progress
/// any more — the user is the master switch for tracking, and the task-update
/// sheet refuses to flip a task to IN_PROGRESS while tracking is off.
///
/// Mount once near the top of the app (e.g. `MainShell`) so it survives
/// tab/navigation changes.
final taskTrackingSyncProvider = Provider<void>((ref) {
  // ref.watch keeps tasksNotifierProvider alive for the lifetime of this sync.
  final tasksState = ref.watch(tasksNotifierProvider);
  if (tasksState is! TasksSuccess) return;

  final trackingOn = ref.watch(trackingNotifierProvider).isActive;
  final hasActive = tasksState.tasks.any((t) => t.status == 'IN_PROGRESS');

  if (trackingOn && hasActive) {
    BackgroundLocationService.start();
  } else {
    BackgroundLocationService.stop();
  }
});

// ── History provider ──────────────────────────────────────────────────────────

final taskHistoryProvider =
    FutureProvider.autoDispose.family<List<TaskHistoryEntry>, int>(
  (ref, taskId) async {
    final ds = ref.watch(taskDataSourceProvider);
    final result = await ds.getTaskHistory(taskId);
    return switch (result) {
      Success(:final data) => data,
      Failure(:final exception) => throw exception,
    };
  },
);
