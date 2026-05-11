import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:field_guard_re/features/auth/data/models/login_request.dart';
import 'package:field_guard_re/features/auth/domain/repositories/auth_repository.dart';
import 'auth_state.dart';

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._repository) : super(const AuthInitial());

  final AuthRepository _repository;

  Future<void> login(String phone, String password) async {
    state = const AuthLoading();
    try {
      final response = await _repository.login(
        LoginRequest(phone: phone, password: password),
      );
      state = AuthSuccess(response);
    } catch (e) {
      state = AuthError(e.toString().replaceAll('Exception: ', ''));
    }
  }

  void reset() => state = const AuthInitial();
}
