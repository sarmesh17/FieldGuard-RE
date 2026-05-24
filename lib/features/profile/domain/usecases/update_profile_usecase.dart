import 'package:field_guard_re/core/utils/result.dart';
import 'package:field_guard_re/features/profile/data/models/profile_response.dart';
import 'package:field_guard_re/features/profile/domain/repositories/profile_repo.dart';

/// PATCH /api/v1/employees/profile. The image, if any, is expected to have
/// already been uploaded (see `UploadService.uploadProfilePhoto`) and is
/// referenced by its returned `imageKey` string.
class UpdateProfileUseCase {
  const UpdateProfileUseCase(this._repository);

  final ProfileRepo _repository;

  Future<Result<ProfileResponse>> call({
    String? fullName,
    String? email,
    String? imageKey,
  }) =>
      _repository.updateProfile(
        fullName: fullName,
        email: email,
        imageKey: imageKey,
      );
}
