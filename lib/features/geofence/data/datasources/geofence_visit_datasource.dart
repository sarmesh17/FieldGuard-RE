import 'package:dio/dio.dart';

import 'package:field_guard_re/core/constants/api_constant.dart';
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

/// Posts completed shop visits to `POST /api/v1/geofence-visits`.
///
/// The endpoint returns `201` for both a first write and an idempotent
/// duplicate retry (deduped on `visitId`), so any 2xx is treated as success.
class GeofenceVisitDataSource {
  GeofenceVisitDataSource(this._dio);

  final Dio _dio;

  Future<SubmitResult> submit(GeofenceVisit visit) async {
    try {
      await _dio.post(
        ApiConstant.geofenceVisitsEndpoint,
        data: visit.toPayload(),
      );
      return SubmitResult.success;
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      // 400/422 = malformed or invalid payload — a retry can't fix that.
      if (status == 400 || status == 422) return SubmitResult.permanent;
      // Auth (401/403), 404, 5xx, timeouts and offline are all retryable.
      return SubmitResult.transient;
    } catch (_) {
      return SubmitResult.transient;
    }
  }
}
