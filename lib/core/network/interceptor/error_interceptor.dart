import 'package:dio/dio.dart';
import 'package:field_guard_re/core/constants/api_constant.dart';
import 'package:field_guard_re/core/router/app_router.dart';
import 'package:field_guard_re/core/router/app_routes.dart';
import 'package:field_guard_re/core/services/token_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

class ErrorInterceptor extends Interceptor {
  final Dio _dio;

  ErrorInterceptor(this._dio);

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode == 401) {
      try {
        final refreshToken = await TokenStorage.getRefreshToken();

        final response = await Dio().post(
          ApiConstant.refreshTokenEndpoint,
          data: {'refreshToken': refreshToken},
        );

        final newAccessToken = response.data['accessToken'] as String;
        final newRefreshToken = response.data['refreshToken'] as String;

        // Save the new tokens
        await TokenStorage.saveTokens(
          accessToken: newAccessToken,
          refreshToken: newRefreshToken,
        );

        // Retry the original request with the new access token
        err.requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';
        final retryResponse = await _dio.fetch(err.requestOptions);
        handler.resolve(
          retryResponse,
        ); // Return the successful response from the retried request
        return; // Exit the interceptor after handling the retry
      } catch (_) {
        // If token refresh fails, proceed with the original error

        await TokenStorage.clearTokens(); // Clear tokens on refresh failure

        AppRouter.navigatorKey.currentContext?.go(AppRoutes.login);
      }
    }

    if (kDebugMode) {
      debugPrint(
        '[HTTP ERR] ${err.type} | ${err.response?.statusCode} | ${err.message}',
      );
    }
    handler.next(err);
  }
}
