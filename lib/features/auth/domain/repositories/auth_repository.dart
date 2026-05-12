import 'package:field_guard_re/core/utils/result.dart';
import 'package:field_guard_re/features/auth/data/models/login_response.dart';

abstract class AuthRepository {
  Future<Result<LoginResponse>> login({
    required String phone,
    required String password,
  });
}
