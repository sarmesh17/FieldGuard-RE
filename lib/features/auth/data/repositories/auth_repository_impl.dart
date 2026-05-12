import 'package:field_guard_re/core/services/token_storage.dart';
import 'package:field_guard_re/core/utils/result.dart';
import 'package:field_guard_re/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:field_guard_re/features/auth/data/models/login_request.dart';
import 'package:field_guard_re/features/auth/data/models/login_response.dart';
import 'package:field_guard_re/features/auth/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl(this._dataSource);

  final AuthRemoteDataSource _dataSource;

  @override
  Future<Result<LoginResponse>> login({
    required String phone,
    required String password,
  }) async {
    final result = await _dataSource.login(
      LoginRequest(phone: phone, password: password),
    );
    if (result is Success<LoginResponse>) {
      await TokenStorage.saveTokens(
        accessToken: result.data.accessToken,
        refreshToken: result.data.refreshToken,
      );
    }
    return result;
  }
}
