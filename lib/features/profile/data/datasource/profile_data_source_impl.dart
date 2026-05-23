import 'package:dio/dio.dart';
import 'package:field_guard_re/core/constants/api_constant.dart';
import 'package:field_guard_re/core/network/api_runner.dart';
import 'package:field_guard_re/core/utils/result.dart';
import 'package:field_guard_re/features/profile/data/datasource/profile_data_source.dart';
import 'package:field_guard_re/features/profile/data/models/profile_response.dart';

class ProfileDataSourceImpl extends ProfileDataSource with ApiRunner {
  final Dio _dio;

  ProfileDataSourceImpl(this._dio);

  @override
  Future<Result<ProfileResponse>> getProfile() async => safeCall(() async {
    final response = await _dio.get(ApiConstant.authMeEndpoint);
    final body = response.data as Map<String, dynamic>;
    final data = body['user'] as Map<String, dynamic>? ??
        body['data'] as Map<String, dynamic>? ??
        body;
    return ProfileResponse.fromJson(data);
  });

  @override
  Future<Result<ProfileResponse>> updateProfile({
    String? fullName,
    String? email,
    String? imagePath,
  }) async =>
      safeCall(() async {
        final fields = <String, dynamic>{};
        if (fullName != null) fields['fullName'] = fullName;
        if (email != null) fields['email'] = email;
        if (imagePath != null) {
          fields['profileImage'] = await MultipartFile.fromFile(imagePath);
        }

        final response = await _dio.patch(
          ApiConstant.profileEndpoint,
          data: FormData.fromMap(fields),
        );
        final body = response.data as Map<String, dynamic>;
        return ProfileResponse.fromJson(body['employee'] as Map<String, dynamic>);
      });
}
