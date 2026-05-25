import 'package:field_guard_re/core/utils/result.dart';
import 'package:field_guard_re/features/profile/data/datasource/profile_data_source.dart';
import 'package:field_guard_re/features/profile/data/models/profile_response.dart';
import 'package:field_guard_re/features/profile/domain/repositories/profile_repo.dart';

class ProfileRepositoryImpl extends ProfileRepo {
  final ProfileDataSource _dataSource;

  ProfileRepositoryImpl(this._dataSource);

  @override
  Future<Result<ProfileResponse>> getProfile() => _dataSource.getProfile();

  @override
  Future<Result<ProfileResponse>> updateProfile({
    String? fullName,
    String? email,
    String? imagePath,
  }) =>
      _dataSource.updateProfile(
        fullName: fullName,
        email: email,
        imagePath: imagePath,
      );
}
