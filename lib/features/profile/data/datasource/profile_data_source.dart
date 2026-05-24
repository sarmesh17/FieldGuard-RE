import 'package:field_guard_re/core/utils/result.dart';
import 'package:field_guard_re/features/profile/data/models/profile_response.dart';

abstract class ProfileDataSource {
  Future<Result<ProfileResponse>> getProfile();

  /// Updates the authenticated employee's profile. The image is *not*
  /// uploaded here — the caller uploads via [UploadService] first and passes
  /// the resulting `imageKey` string (S3 object key) for the backend to wire
  /// to the profile record.
  Future<Result<ProfileResponse>> updateProfile({
    String? fullName,
    String? email,
    String? imageKey,
  });
}
