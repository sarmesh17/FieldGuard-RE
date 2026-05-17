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
  });

  factory ShopModel.fromJson(Map<String, dynamic> json) => ShopModel(
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
      );
}
