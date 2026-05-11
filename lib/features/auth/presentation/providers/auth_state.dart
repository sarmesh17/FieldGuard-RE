import 'package:field_guard_re/features/auth/data/models/login_response.dart';

sealed class AuthState {
  const AuthState();
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthSuccess extends AuthState {
  const AuthSuccess(this.response);
  final LoginResponse response;
}

class AuthError extends AuthState {
  const AuthError(this.message);
  final String message;
}
