import 'package:json_annotation/json_annotation.dart';

part 'login_request.g.dart';

@JsonSerializable(createFactory: false)
class LoginRequest {
  const LoginRequest({required this.phone, required this.password});

  @JsonKey(name: 'phoneNumber')
  final String phone;

  final String password;

  Map<String, dynamic> toJson() => _$LoginRequestToJson(this);
}
