class ProfileUser {
  final String fullName;
  final String phoneNumber;
  final String email;
  final String role;
  final String employeeCode;
  final String managerId;
  final bool isActive;
  final String profileImage;
  final DateTime createdAt;

  const ProfileUser({
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
}
