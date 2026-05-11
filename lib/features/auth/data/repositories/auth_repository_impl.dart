import 'package:dio/dio.dart';
import 'package:field_guard_re/core/constants/api_constant.dart';
import 'package:field_guard_re/core/constants/app_strings.dart';
import 'package:field_guard_re/core/services/token_storage.dart';
import 'package:field_guard_re/features/auth/data/models/login_request.dart';
import 'package:field_guard_re/features/auth/data/models/login_response.dart';
import 'package:field_guard_re/features/auth/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl(this._dio);

  final Dio _dio;

  @override
  Future<LoginResponse> login(LoginRequest request) async {
    try {
      final response = await _dio.post(
        ApiConstant.loginEndpoint,
        data: request.toJson(),
      );
      final loginResponse = LoginResponse.fromJson(
        response.data as Map<String, dynamic>,
      );
      await TokenStorage.saveTokens(
        accessToken: loginResponse.accessToken,
        refreshToken: loginResponse.refreshToken,
      );
      return loginResponse;
    } on DioException catch (e) {
      throw Exception(_mapDioError(e));
    }
  }

  String _mapDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return AppStrings.networkError;
      default:
        // Extract message directly from API response body when available.
        final body = e.response?.data;
        if (body is Map<String, dynamic>) {
          // Prefer the first field-level error, fall back to top-level message.
          final errors = body['errors'];
          if (errors is List && errors.isNotEmpty) {
            final msg = errors.first['message'];
            if (msg is String && msg.isNotEmpty) return msg;
          }
          final msg = body['message'];
          if (msg is String && msg.isNotEmpty) return msg;
        }
        final status = e.response?.statusCode;
        if (status == 401) return AppStrings.invalidCredentials;
        return AppStrings.serverError;
    }
  }
}
