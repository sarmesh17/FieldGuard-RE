import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:field_guard_re/core/constants/api_constant.dart';
import 'package:field_guard_re/core/network/network_exception_mapper.dart';
import 'package:field_guard_re/features/auth/presentation/providers/auth_provider.dart';
import 'package:field_guard_re/features/dashboard/data/models/dashboard_summary.dart';
import 'package:field_guard_re/features/tasks/data/models/task_model.dart';

/// One consolidated read for the home screen — profile, task previews, and
/// live tracking. autoDispose so leaving the home tab and coming back gets a
/// fresh fetch (live counts move as the day goes on). Errors are mapped to
/// typed `AppException`s so the UI can render the message verbatim.
final dashboardSummaryProvider = FutureProvider.autoDispose<DashboardSummary>((
  ref,
) async {
  final dio = ref.watch(dioProvider);
  try {
    final res = await dio.get(ApiConstant.dashboardSummaryEndpoint);
    final body = res.data;
    if (body is! Map) {
      throw DioException(
        requestOptions: res.requestOptions,
        response: res,
        type: DioExceptionType.badResponse,
        error: 'Unexpected /dashboard/summary response shape',
      );
    }
    return DashboardSummary.fromJson(Map<String, dynamic>.from(body));
  } on DioException catch (e) {
    throw NetworkExceptionMapper.map(e);
  }
});

/// Today's task progress (Nepal calendar day) for the progress rings card.
final todayTasksProgressProvider =
    FutureProvider.autoDispose<TodayTaskStats>((ref) async {
  final dio = ref.watch(dioProvider);
  try {
    final res = await dio.get(ApiConstant.dashboardTodayTasksEndpoint);
    final body = res.data;
    if (body is! Map) {
      throw DioException(
        requestOptions: res.requestOptions,
        response: res,
        type: DioExceptionType.badResponse,
        error: 'Unexpected /dashboard/today-tasks response shape',
      );
    }
    return TodayTaskStats.fromJson(Map<String, dynamic>.from(body));
  } on DioException catch (e) {
    throw NetworkExceptionMapper.map(e);
  }
});

/// Full list of the current user's PENDING tasks for the home screen. The
/// dashboard summary only previews one task per status; this fetches the
/// complete pending bucket so the home can render the whole queue.
/// autoDispose so it refetches on tab return.
final homePendingTasksProvider = FutureProvider.autoDispose<List<TaskModel>>((
  ref,
) async {
  final dio = ref.watch(dioProvider);
  try {
    final res = await dio.get(
      ApiConstant.tasksEndpoint,
      queryParameters: const {'status': 'PENDING'},
    );
    final body = res.data;
    if (body is! Map) {
      throw DioException(
        requestOptions: res.requestOptions,
        response: res,
        type: DioExceptionType.badResponse,
        error: 'Unexpected /my-tasks response shape',
      );
    }
    final list = body['tasks'];
    if (list is! List) return const [];
    return list
        .whereType<Map>()
        .map((m) => TaskModel.fromJson(Map<String, dynamic>.from(m)))
        .toList();
  } on DioException catch (e) {
    throw NetworkExceptionMapper.map(e);
  }
});
