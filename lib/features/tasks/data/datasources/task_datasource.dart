import 'package:field_guard_re/core/utils/result.dart';
import 'package:field_guard_re/features/tasks/data/models/task_history_entry.dart';
import 'package:field_guard_re/features/tasks/data/models/task_model.dart';
import 'package:field_guard_re/features/tasks/data/models/update_task_request.dart';

abstract interface class TaskDataSource {
  Future<Result<List<TaskModel>>> getTasks({String? status});
  Future<Result<TaskModel>> getTaskById(int id);
  Future<Result<TaskModel>> updateTask(int id, UpdateTaskRequest request);

  /// Toggle one checklist item's done-state. Assignee-only; the backend
  /// rejects it on a COMPLETED/CANCELLED task. Returns the refreshed task.
  Future<Result<TaskModel>> updateTaskItem(int taskId, int itemId, bool done);

  Future<Result<List<TaskHistoryEntry>>> getTaskHistory(int taskId);
}
