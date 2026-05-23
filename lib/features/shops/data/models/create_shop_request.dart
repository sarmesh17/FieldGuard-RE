import 'dart:io';

class CreateShopRequest {
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final String contactName;
  final String contactPhone;
  final String? panNumber;

  /// Local file chosen by the user — uploaded to S3 before the API call.
  /// Not included in [toJson]; set [imageKey] after upload instead.
  final File? photoFile;

  /// S3 image key returned by the presigned-URL upload flow.
  /// Included in [toJson] only when non-null.
  final String? imageKey;

  const CreateShopRequest({
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.contactName,
    required this.contactPhone,
    this.panNumber,
    this.photoFile,
    this.imageKey,
  });

  /// Returns a copy with the given [imageKey] set (used after upload).
  CreateShopRequest withImageKey(String key) => CreateShopRequest(
        name: name,
        address: address,
        latitude: latitude,
        longitude: longitude,
        contactName: contactName,
        contactPhone: contactPhone,
        panNumber: panNumber,
        photoFile: photoFile,
        imageKey: key,
      );

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'name': name,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'contactName': contactName,
      'contactPhone': contactPhone,
    };
    if (panNumber != null && panNumber!.isNotEmpty) {
      map['panNumber'] = panNumber;
    }
    if (imageKey != null && imageKey!.isNotEmpty) {
      map['imageKey'] = imageKey;
    }
    return map;
  }
}
