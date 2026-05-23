import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:field_guard_re/core/constants/app_strings.dart';
import 'package:field_guard_re/core/errors/app_exception.dart';
import 'package:field_guard_re/core/services/token_storage.dart';
import 'package:field_guard_re/core/utils/result.dart';
import 'package:field_guard_re/features/auth/data/models/login_response.dart';
import 'package:field_guard_re/features/auth/domain/entities/auth_user.dart';
import 'package:field_guard_re/features/auth/domain/usecases/login_usecase.dart';
import 'auth_state.dart';

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._loginUseCase) : super(const AuthInitial());

  final LoginUseCase _loginUseCase;

  Future<void> login(String phone, String password) async {
    state = const AuthLoading();

    final result = await _loginUseCase(phone: phone, password: password);

    if (result is Success<LoginResponse>) {
      final tokenRole = _roleFromToken(result.data.accessToken);
      if (tokenRole != null && tokenRole.toUpperCase() != 'EMPLOYEE') {
        await TokenStorage.clearTokens();
        state = const AuthError(
          'Access denied. This app is for field employees only.',
        );
        return;
      }

      // Inject the role decoded from the JWT into the user object so that
      // any screen can read currentUser.role reliably.
      if (tokenRole != null) {
        final u = result.data.user;
        final enriched = LoginResponse(
          accessToken: result.data.accessToken,
          refreshToken: result.data.refreshToken,
          user: AuthUser(
            id: u.id,
            name: u.name,
            phone: u.phone,
            role: tokenRole,
          ),
        );
        state = AuthSuccess(enriched);
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

  /// Rebuilds an [AuthSuccess] state from the saved JWT after an app restart.
  /// Returns true when a valid session was restored.
  Future<bool> restoreSession() async {
    final token = await TokenStorage.getAccessToken();
    if (token == null || token.isEmpty) return false;

    final payload = _decodePayload(token);
    if (payload == null) return false;

    final role = payload['role'] as String?;
    final userId = payload['userId']?.toString() ?? '';

    state = AuthSuccess(LoginResponse(
      accessToken: token,
      refreshToken: await TokenStorage.getRefreshToken() ?? '',
      user: AuthUser(
        id: userId,
        name: '',
        phone: '',
        role: role,
      ),
    ));
    return true;
  }

  String? _roleFromToken(String token) =>
      _decodePayload(token)?['role'] as String?;

  Map<String, dynamic>? _decodePayload(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      final payload = utf8.decode(
        base64Url.decode(base64Url.normalize(parts[1])),
      );
      return jsonDecode(payload) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }
}
