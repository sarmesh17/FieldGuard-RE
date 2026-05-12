import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:field_guard_re/core/constants/app_strings.dart';
import 'package:field_guard_re/core/errors/app_exception.dart';
import 'package:field_guard_re/core/services/token_storage.dart';
import 'package:field_guard_re/core/utils/result.dart';
import 'package:field_guard_re/features/auth/data/models/login_response.dart';
import 'package:field_guard_re/features/auth/domain/usecases/login_usecase.dart';
import 'auth_state.dart';

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._loginUseCase) : super(const AuthInitial());

  final LoginUseCase _loginUseCase;

  Future<void> login(String phone, String password) async {
    state = const AuthLoading();

    final result = await _loginUseCase(phone: phone, password: password);

    if (result is Success<LoginResponse>) {
      final role = _roleFromToken(result.data.accessToken);
      if (role != null && role.toUpperCase() != 'EMPLOYEE') {
        await TokenStorage.clearTokens();
        state = const AuthError(
          'Access denied. This app is for field employees only.',
        );
        return;
      }
    }

    state = switch (result) {
      Success(:final data) => AuthSuccess(data),
      Failure(:final exception) => AuthError(
          exception is AppException
              ? exception.message
              : AppStrings.serverError,
        ),
    };
  }

  void reset() => state = const AuthInitial();

  String? _roleFromToken(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      final payload = utf8.decode(
        base64Url.decode(base64Url.normalize(parts[1])),
      );
      final map = jsonDecode(payload) as Map<String, dynamic>;
      return map['role'] as String?;
    } catch (_) {
      return null;
    }
  }
}
