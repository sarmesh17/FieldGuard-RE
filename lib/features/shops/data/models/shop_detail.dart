/// A person linked to a shop — either an entry in the shop's `visibleTo`
/// list or its `creator`. Lightweight; not all fields are present on every
/// shape (e.g. `creator` omits `role`).
class ShopPerson {
  final int id;
  final String fullName;
  final String? role;
  final String? employeeCode;
  final String? profileImage;

  const ShopPerson({
    required this.id,
    required this.fullName,
    this.role,
    this.employeeCode,
    this.profileImage,
  });

  factory ShopPerson.fromJson(Map<String, dynamic> json) => ShopPerson(
        id: json['id'] as int,
        fullName: (json['full_name'] ?? '') as String,
        role: json['role'] as String?,
        employeeCode: json['employee_code'] as String?,
        profileImage: json['profile_image'] as String?,
      );
}

/// Full shop details from `GET /api/v1/shops/{id}` — richer than [ShopModel]:
/// includes `pan_number`, `updated_at`, the explicit `visibleTo` list, and the
/// `creator`.
class ShopDetail {
  final int id;
  final String name;
  final String address;
  final String? panNumber;
  final double latitude;
  final double longitude;
  final String contactName;
  final String contactPhone;
  final String? shopImage;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<ShopPerson> visibleTo;
  final ShopPerson? creator;

  const ShopDetail({
    required this.id,
    required this.name,
    required this.address,
    this.panNumber,
    required this.latitude,
    required this.longitude,
    required this.contactName,
    required this.contactPhone,
    this.shopImage,
    required this.isActive,
    this.createdAt,
    this.updatedAt,
    this.visibleTo = const [],
    this.creator,
  });

  factory ShopDetail.fromJson(Map<String, dynamic> json) {
    final rawVisible = json['visibleTo'] as List<dynamic>? ?? const [];
    return ShopDetail(
      id: json['id'] as int,
      name: (json['name'] ?? '') as String,
      address: (json['address'] ?? '') as String,
      panNumber: json['pan_number'] as String?,
      // API returns latitude/longitude as strings.
      latitude: double.tryParse((json['latitude'] ?? '') as String) ?? 0,
      longitude: double.tryParse((json['longitude'] ?? '') as String) ?? 0,
      contactName: (json['contact_name'] ?? '') as String,
      contactPhone: (json['contact_phone'] ?? '') as String,
      shopImage: json['shop_image'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
      visibleTo: rawVisible
          .map((e) => ShopPerson.fromJson(e as Map<String, dynamic>))
          .toList(),
      creator: json['creator'] is Map<String, dynamic>
          ? ShopPerson.fromJson(json['creator'] as Map<String, dynamic>)
          : null,
    );
  }
}
