import 'package:field_guard_re/core/utils/result.dart';
import 'package:field_guard_re/features/profile/data/models/profile_response.dart';
import 'package:field_guard_re/features/profile/domain/repositories/profile_repo.dart';

class GetProfileUseCase {
  const GetProfileUseCase(this._repository);

  final ProfileRepo _repository;

  Future<Result<ProfileResponse>> call() => _repository.getProfile();
}
