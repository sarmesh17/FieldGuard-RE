import 'package:dio/dio.dart';
import 'package:field_guard_re/core/constants/api_constant.dart';
import 'package:field_guard_re/core/network/api_runner.dart';
import 'package:field_guard_re/core/utils/result.dart';
import 'package:field_guard_re/features/tasks/data/models/task_history_entry.dart';
import 'package:field_guard_re/features/tasks/data/models/task_model.dart';
import 'package:field_guard_re/features/tasks/data/models/update_task_request.dart';
import 'task_datasource.dart';

class TaskDataSourceImpl with ApiRunner implements TaskDataSource {
  const TaskDataSourceImpl(this._dio);

  final Dio _dio;

  @override
  Future<Result<List<TaskModel>>> getTasks({String? status}) =>
      safeCall(() async {
        final response = await _dio.get(
          ApiConstant.tasksEndpoint,
          queryParameters: status != null ? {'status': status} : null,
        );
        final body = response.data as Map<String, dynamic>;
        final list = body['tasks'] as List<dynamic>;
        return list
            .map((e) => TaskModel.fromJson(e as Map<String, dynamic>))
            .toList();
      });

  @override
  Future<Result<TaskModel>> getTaskById(int id) => safeCall(() async {
        final response = await _dio.get(ApiConstant.taskDetailEndpoint(id));
        final body = response.data as Map<String, dynamic>;
        final taskJson = body['task'] as Map<String, dynamic>? ?? body;
        return TaskModel.fromJson(taskJson);
      });

  @override
  Future<Result<TaskModel>> updateTask(
    int id,
    UpdateTaskRequest request,
  ) =>
      safeCall(() async {
        final response = await _dio.patch(
          ApiConstant.taskUpdateEndpoint(id),
          data: request.toJson(),
        );
        final body = response.data as Map<String, dynamic>;
        final taskJson = body['task'] as Map<String, dynamic>? ?? body;
        return TaskModel.fromJson(taskJson);
      });

  @override
  Future<Result<List<TaskHistoryEntry>>> getTaskHistory(int taskId) =>
      safeCall(() async {
        final response = await _dio.get(
          ApiConstant.taskHistoryEndpoint,
          queryParameters: {'taskId': taskId},
        );
        final body = response.data as Map<String, dynamic>;
        final list = body['history'] as List<dynamic>;
        return list
            .map((e) => TaskHistoryEntry.fromJson(e as Map<String, dynamic>))
            .toList();
      });
}
