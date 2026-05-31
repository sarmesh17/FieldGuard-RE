import 'package:dio/dio.dart';

import 'package:field_guard_re/core/constants/api_constant.dart';
import 'package:field_guard_re/features/tasks/data/models/task_model.dart';
import '../models/geofence_visit.dart';

/// Outcome of a single upload attempt.
enum SubmitResult {
  /// Stored by the backend (or recognised as an idempotent duplicate) — the
  /// record can be dropped from the queue.
  success,

  /// Worth retrying later — network failure, timeout, auth, or a 5xx.
  transient,

  /// Will never succeed — the payload was rejected as malformed/invalid.
  permanent,
}

/// Result of a visit upload: the [outcome], plus the server's updated [task]
/// when the backend auto-completed it on this write (it returns the full task
/// in `{ visit, task }`). [task] is null on failure, on a duplicate that
/// didn't complete, or when the task wasn't completed.
typedef SubmitResponse = ({SubmitResult outcome, TaskModel? task});

/// Posts completed shop visits to `POST /api/v1/geofence-visits`.
///
/// Returns `201` for both a first write and an idempotent duplicate retry
/// (deduped on `visitId`), so any 2xx is treated as success. The body is
/// `{ "visit": {...}, "task": {...} }`; we parse `task` so the app can refresh
/// straight from the response instead of issuing its own PATCH.
class GeofenceVisitDataSource {
  GeofenceVisitDataSource(this._dio);

  final Dio _dio;

  Future<SubmitResponse> submit(GeofenceVisit visit) async {
    try {
      final res = await _dio.post(
        ApiConstant.geofenceVisitsEndpoint,
        data: visit.toPayload(),
      );
      TaskModel? task;
      final body = res.data;
      if (body is Map && body['task'] is Map) {
        try {
          task = TaskModel.fromJson(
            Map<String, dynamic>.from(body['task'] as Map),
          );
        } catch (_) {
          task = null; // unexpected shape — ignore, the 2xx still counts
        }
      }
      return (outcome: SubmitResult.success, task: task);
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      // 400/422 = malformed or invalid payload — a retry can't fix that.
      if (status == 400 || status == 422) {
        return (outcome: SubmitResult.permanent, task: null);
      }
      // Auth (401/403), 404, 5xx, timeouts and offline are all retryable.
      return (outcome: SubmitResult.transient, task: null);
    } catch (_) {
      return (outcome: SubmitResult.transient, task: null);
    }
  }
}
