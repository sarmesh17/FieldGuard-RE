class ShopModel {
  final int id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final String contactName;
  final String contactPhone;
  final bool isActive;
  final DateTime? createdAt;
  final String? createdByRole;
  final String? shopImage;

  const ShopModel({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.contactName,
    required this.contactPhone,
    required this.isActive,
    this.createdAt,
    this.createdByRole,
    this.shopImage,
  });

  factory ShopModel.fromJson(
    Map<String, dynamic> json, {
    String? createdByRoleOverride,
  }) =>
      ShopModel(
        id: json['id'] as int,
        name: json['name'] as String,
        address: json['address'] as String,
        // API returns latitude/longitude as strings
        latitude: double.parse(json['latitude'] as String),
        longitude: double.parse(json['longitude'] as String),
        contactName: json['contact_name'] as String,
        contactPhone: json['contact_phone'] as String,
        isActive: json['is_active'] as bool? ?? true,
        createdAt: json['created_at'] != null
            ? DateTime.tryParse(json['created_at'] as String)
            : null,
        createdByRole: createdByRoleOverride ??
            json['created_by_role'] as String? ??
            (json['creator'] as Map<String, dynamic>?)?['role'] as String?,
        shopImage: json['shop_image'] as String?,
      );
}
