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

  // Pure-Dart fromJson — no json_annotation dependency on the domain entity.
  factory AuthUser.fromJson(Map<String, dynamic> json) => AuthUser(
        id: json['id']?.toString() ?? '',
        name: (json['name'] ?? json['fullName'] ?? '') as String,
        phone: (json['phone'] ?? '') as String,
        role: json['role'] as String?,
      );
}
