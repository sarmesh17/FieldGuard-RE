import 'package:field_guard_re/core/utils/result.dart';
import 'package:field_guard_re/features/profile/data/models/profile_response.dart';
import 'package:field_guard_re/features/profile/domain/repositories/profile_repo.dart';

class UpdateProfileUseCase {
  const UpdateProfileUseCase(this._repository);

  final ProfileRepo _repository;

  Future<Result<ProfileResponse>> call({
    String? fullName,
    String? email,
    String? imagePath,
  }) =>
      _repository.updateProfile(
        fullName: fullName,
        email: email,
        imagePath: imagePath,
      );
}
