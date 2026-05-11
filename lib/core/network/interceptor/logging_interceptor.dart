import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint('┌─────────────────────────────────────────');
      debugPrint('│ [REQUEST] ${options.method} ${options.uri}');
      debugPrint('│ Headers : ${options.headers}');
      debugPrint('│ Body    : ${options.data}');
      debugPrint('└─────────────────────────────────────────');
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint('┌─────────────────────────────────────────');
      debugPrint('│ [RESPONSE] ${response.statusCode} ${response.requestOptions.uri}');
      debugPrint('│ Body : ${response.data}');
      debugPrint('└─────────────────────────────────────────');
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint('┌─────────────────────────────────────────');
      debugPrint('│ [ERROR] ${err.type}');
      debugPrint('│ URL    : ${err.requestOptions.uri}');
      debugPrint('│ Status : ${err.response?.statusCode}');
      debugPrint('│ Body   : ${err.response?.data}');
      debugPrint('└─────────────────────────────────────────');
    }
    handler.next(err);
  }
}
