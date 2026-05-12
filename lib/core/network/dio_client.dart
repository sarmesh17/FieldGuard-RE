import 'package:dio/dio.dart';
import 'package:field_guard_re/core/constants/api_constant.dart';
import 'interceptor/auth_interceptor.dart';
import 'interceptor/logging_interceptor.dart';
import 'interceptor/error_interceptor.dart';

class DioClient {
  static Dio createDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: ApiConstant.baseUrl,
        connectTimeout: Duration(seconds: ApiConstant.connectTimeout),
        receiveTimeout: Duration(seconds: ApiConstant.receiveTimeout),
      ),
    );
    dio.interceptors.addAll([
      AuthInterceptor(),
      LoggingInterceptor(),
      ErrorInterceptor(dio),
    ]);
    return dio;
  }
}
