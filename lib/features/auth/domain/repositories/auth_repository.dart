import 'package:field_guard_re/features/auth/data/models/login_request.dart';
import 'package:field_guard_re/features/auth/data/models/login_response.dart';

abstract class AuthRepository {
  Future<LoginResponse> login(LoginRequest request);
}
