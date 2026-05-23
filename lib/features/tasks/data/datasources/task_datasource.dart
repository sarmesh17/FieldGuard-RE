import 'package:field_guard_re/core/utils/result.dart';
import 'package:field_guard_re/features/tasks/data/models/task_history_entry.dart';
import 'package:field_guard_re/features/tasks/data/models/task_model.dart';
import 'package:field_guard_re/features/tasks/data/models/update_task_request.dart';

abstract interface class TaskDataSource {
  Future<Result<List<TaskModel>>> getTasks({String? status});
  Future<Result<TaskModel>> getTaskById(int id);
  Future<Result<TaskModel>> updateTask(int id, UpdateTaskRequest request);
  Future<Result<List<TaskHistoryEntry>>> getTaskHistory(int taskId);
}
