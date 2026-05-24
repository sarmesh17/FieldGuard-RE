import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:field_guard_re/core/errors/app_exception.dart';
import 'package:field_guard_re/core/services/background_location_service.dart';
import 'package:field_guard_re/core/services/live_tracking_service.dart';
import 'package:field_guard_re/core/utils/result.dart';
import 'package:field_guard_re/features/auth/presentation/providers/auth_provider.dart';
import 'package:field_guard_re/features/tasks/data/datasources/task_datasource.dart';
import 'package:field_guard_re/features/tasks/data/datasources/task_datasource_impl.dart';
import 'package:field_guard_re/features/tasks/data/models/task_model.dart';
import 'package:field_guard_re/features/tasks/data/models/task_history_entry.dart';
import 'package:field_guard_re/features/tasks/data/models/update_task_request.dart';

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

final tasksNotifierProvider =
    StateNotifierProvider.autoDispose<TasksNotifier, TasksState>(
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
  TaskUpdateNotifier(this._dataSource, this._ref) : super(const TaskUpdateIdle());

  final TaskDataSource _dataSource;
  final Ref _ref;

  Future<bool> update(int id, UpdateTaskRequest request) async {
    state = const TaskUpdateLoading();
    final result = await _dataSource.updateTask(id, request);
    state = switch (result) {
      Success(:final data) => TaskUpdateSuccess(data),
      Failure(:final exception) => TaskUpdateError(
          exception is AppException ? exception.message : exception.toString(),
        ),
    };
    if (state is TaskUpdateSuccess) {
      await _syncTaskTracking(updatedTaskId: id, newStatus: request.status);
    }
    return state is TaskUpdateSuccess;
  }

  /// Reflects the server-side `active_tasks:employee:{id}` set on the client:
  /// keep the live socket open while the employee has at least one task in
  /// IN_PROGRESS, tear it down (for the `'task'` reason) otherwise. The manual
  /// toggle holds its own reason so it isn't affected.
  Future<void> _syncTaskTracking({
    required int updatedTaskId,
    required String? newStatus,
  }) async {
    if (newStatus == 'IN_PROGRESS') {
      try {
        await LiveTrackingService.instance.start(reason: 'task');
      } catch (_) {/* permission/network failures shouldn't block the update */}
      return;
    }

    // Transitioning away from IN_PROGRESS: only release the 'task' reason if
    // no other task is still IN_PROGRESS. We rely on the locally cached task
    // list when available; otherwise we conservatively release.
    final tasksState = _ref.read(tasksNotifierProvider);
    final stillActive = tasksState is TasksSuccess &&
        tasksState.tasks.any(
          (t) => t.id != updatedTaskId && t.status == 'IN_PROGRESS',
        );
    if (!stillActive) {
      await LiveTrackingService.instance.stop(reason: 'task');
    }
  }

  void reset() => state = const TaskUpdateIdle();
}

final taskUpdateProvider =
    StateNotifierProvider.autoDispose<TaskUpdateNotifier, TaskUpdateState>(
  (ref) => TaskUpdateNotifier(ref.watch(taskDataSourceProvider), ref),
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

/// Watches the tasks list and keeps `LiveTrackingService` aligned with the
/// server's `active_tasks:employee:{id}` set: starts the socket while at
/// least one task is IN_PROGRESS, releases the `'task'` reason otherwise.
/// Mount this provider once near the top of the app (e.g. `MainShell`) so it
/// survives tab/navigation changes.
final taskTrackingSyncProvider = Provider<void>((ref) {
  // ref.watch keeps tasksNotifierProvider alive for the lifetime of this sync.
  final tasksState = ref.watch(tasksNotifierProvider);
  if (tasksState is! TasksSuccess) return;

  final hasActive = tasksState.tasks.any((t) => t.status == 'IN_PROGRESS');
  if (hasActive) {
    LiveTrackingService.instance.start(reason: 'task').catchError((_) {});
    // Also run the kill-proof foreground location service (Phase 2a: streams
    // + logs fixes off the UI isolate; detection moves here in Phase 2b).
    BackgroundLocationService.start();
  } else {
    LiveTrackingService.instance.stop(reason: 'task');
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
