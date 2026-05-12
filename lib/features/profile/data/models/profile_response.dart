import 'package:json_annotation/json_annotation.dart';

part 'profile_response.g.dart';

@JsonSerializable(createToJson: false)
class ProfileResponse {
  final int id;

  @JsonKey(name: 'full_name')
  final String fullName;
  @JsonKey(name: 'phone_number')
  final String phoneNumber;

  final String email;
  final String role;

  @JsonKey(name: 'employee_code')
  final String employeeCode;
  @JsonKey(name: 'manager_id')
  final int? managerId;
  @JsonKey(name: 'is_active')
  final bool isActive;
  @JsonKey(name: 'profile_image')
  final String? profileImage;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  const ProfileResponse({
    required this.id,
    required this.fullName,
    required this.phoneNumber,
    required this.email,
    required this.role,
    required this.employeeCode,
    required this.managerId,
    required this.isActive,
    required this.profileImage,
    required this.createdAt,
  });

  factory ProfileResponse.fromJson(Map<String, dynamic> json) =>
      _$ProfileResponseFromJson(json);
}
