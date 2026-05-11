import 'package:json_annotation/json_annotation.dart';
import 'package:field_guard_re/features/auth/domain/entities/auth_user.dart';

part 'login_response.g.dart';

@JsonSerializable(createToJson: false)
class LoginResponse {
  const LoginResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
  });

  final String accessToken;

  @JsonKey(defaultValue: '')
  final String refreshToken;

  @JsonKey(fromJson: _userFromJson)
  final AuthUser user;

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    // Unwrap "data" envelope if present, otherwise read from root.
    final body = json['data'] as Map<String, dynamic>? ?? json;
    return _$LoginResponseFromJson(body);
  }

  static AuthUser _userFromJson(Object? json) {
    if (json is Map<String, dynamic>) return AuthUser.fromJson(json);
    return const AuthUser(id: '', name: '', phone: '');
  }
}
