import 'package:dio/dio.dart';
import 'package:field_guard_re/core/constants/api_constant.dart';
import 'package:field_guard_re/core/network/api_runner.dart';
import 'package:field_guard_re/core/utils/result.dart';
import 'package:field_guard_re/features/auth/data/models/login_request.dart';
import 'package:field_guard_re/features/auth/data/models/login_response.dart';
import 'auth_remote_datasource.dart';

class AuthRemoteDataSourceImpl with ApiRunner implements AuthRemoteDataSource {
  const AuthRemoteDataSourceImpl(this._dio);

  final Dio _dio;

  @override
  Future<Result<LoginResponse>> login(LoginRequest request) =>
      safeCall(() async {
        final response = await _dio.post(
          ApiConstant.loginEndpoint,
          data: request.toJson(),
        );
        return LoginResponse.fromJson(response.data as Map<String, dynamic>);
      });
}
