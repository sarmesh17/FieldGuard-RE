import 'package:field_guard_re/core/utils/result.dart';
import 'package:field_guard_re/features/profile/data/models/profile_response.dart';

abstract class ProfileDataSource {
  Future<Result<ProfileResponse>> getProfile();
  Future<Result<ProfileResponse>> updateProfile({
    String? fullName,
    String? email,
    String? imagePath,
  });
}
