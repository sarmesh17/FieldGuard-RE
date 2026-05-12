import 'package:field_guard_re/core/utils/result.dart';
import 'package:field_guard_re/features/auth/data/models/login_request.dart';
import 'package:field_guard_re/features/auth/data/models/login_response.dart';

abstract class AuthRemoteDataSource {
  Future<Result<LoginResponse>> login(LoginRequest request);
}
