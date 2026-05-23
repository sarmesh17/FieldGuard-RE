import 'package:dio/dio.dart';
import 'package:field_guard_re/core/router/app_router.dart';
import 'package:field_guard_re/core/router/app_routes.dart';
import 'package:field_guard_re/core/services/geofence_visit_service.dart';
import 'package:field_guard_re/core/services/token_refresh_service.dart';
import 'package:field_guard_re/core/services/token_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

class ErrorInterceptor extends Interceptor {
  ErrorInterceptor(this._dio);

  final Dio _dio;

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final status = err.response?.statusCode;
    final requestPath = err.requestOptions.path;
    final isRefreshCall = requestPath.contains('/auth/refresh-token');
    final isLoginCall = requestPath.contains('/auth/login');

    // Only attempt silent refresh on 401 for non-auth endpoints, and only
    // once per request (avoid infinite loops if the retry also fails).
    final alreadyRetried = err.requestOptions.extra['__retried__'] == true;

    if (status == 401 && !isRefreshCall && !isLoginCall && !alreadyRetried) {
      try {
        // Delegate to the shared service (single-flight is managed there).
        final newAccessToken = await TokenRefreshService.forceRefresh();

        if (newAccessToken == null) {
          await _logout();
          return handler.next(err);
        }

        // Retry the original request with the new access token.
        err.requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';
        err.requestOptions.extra['__retried__'] = true;
        final retryResponse = await _dio.fetch(err.requestOptions);
        return handler.resolve(retryResponse);
      } on DioException catch (e) {
        // If the retry itself returned 401/403, the session is truly dead.
        final retryStatus = e.response?.statusCode;
        if (retryStatus == 401 || retryStatus == 403) {
          await _logout();
        }
        return handler.next(e);
      } catch (_) {
        // Unknown failure during refresh/retry: don't nuke the session on
        // transient issues; just propagate the original error.
        return handler.next(err);
      }
    }

    if (kDebugMode) {
      debugPrint(
        '[HTTP ERR] ${err.type} | $status | ${err.message}',
      );
    }
    handler.next(err);
  }

  Future<void> _logout() async {
    // Halt geofence detection/uploads for the dead session (persisted visit +
    // queue survive on disk and resume after re-login).
    GeofenceVisitService.instance.stop();
    await TokenStorage.clearTokens();
    AppRouter.navigatorKey.currentContext?.go(AppRoutes.login);
  }
}
