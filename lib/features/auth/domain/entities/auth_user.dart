class AuthUser {
  const AuthUser({
    required this.id,
    required this.name,
    required this.phone,
    this.role,
  });

  final String id;
  final String name;
  final String phone;
  final String? role;
}
