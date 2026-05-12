import 'package:dio/dio.dart';
import 'package:field_guard_re/core/constants/app_strings.dart';
import 'package:field_guard_re/core/errors/app_exception.dart';

class NetworkExceptionMapper {
  const NetworkExceptionMapper._();

  static AppException map(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return const NetworkException(AppStrings.networkError);
      default:
        final status = e.response?.statusCode;
        if (status == 401) {
          return const UnauthorizedException(AppStrings.invalidCredentials);
        }
        final apiMessage = _extractApiMessage(e.response?.data);
        if (apiMessage != null) return ValidationException(apiMessage);
        return const ServerException(AppStrings.serverError);
    }
  }

  static String? _extractApiMessage(Object? body) {
    if (body is! Map<String, dynamic>) return null;
    final errors = body['errors'];
    if (errors is List && errors.isNotEmpty) {
      final msg = errors.first['message'];
      if (msg is String && msg.isNotEmpty) return msg;
    }
    final msg = body['message'];
    return msg is String && msg.isNotEmpty ? msg : null;
  }
}
