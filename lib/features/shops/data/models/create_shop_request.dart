class CreateShopRequest {
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final String contactName;
  final String contactPhone;

  const CreateShopRequest({
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.contactName,
    required this.contactPhone,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'address': address,
        'latitude': latitude,
        'longitude': longitude,
        'contactName': contactName,
        'contactPhone': contactPhone,
      };
}
