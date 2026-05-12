import 'package:field_guard_re/core/utils/result.dart';
import 'package:field_guard_re/features/auth/data/models/login_response.dart';
import 'package:field_guard_re/features/auth/domain/repositories/auth_repository.dart';

class LoginUseCase {
  const LoginUseCase(this._repository);

  final AuthRepository _repository;

  Future<Result<LoginResponse>> call({
    required String phone,
    required String password,
  }) =>
      _repository.login(phone: phone, password: password);
}
