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
        return _parseProfile(response.data as Map<String, dynamic>);
      });

  /// PATCH /api/v1/employees/profile — the "Update own profile (EMPLOYEE
  /// only)" endpoint. Accepts `fullName`, `email` and `imageKey` together in
  /// one JSON body; `imageKey` is the S3 key from the presigned-upload flow
  /// (the endpoint does not take a file). Only non-null fields are sent so an
  /// absent field stays unchanged on the server.
  @override
  Future<Result<ProfileResponse>> updateProfile({
    String? fullName,
    String? email,
    String? imageKey,
  }) async =>
      safeCall(() async {
        final body = <String, dynamic>{};
        if (fullName != null) body['fullName'] = fullName;
        if (email != null) body['email'] = email;
        if (imageKey != null) body['imageKey'] = imageKey;

        final response = await _dio.patch(
          ApiConstant.profileEndpoint,
          data: body,
        );
        return _parseProfile(response.data as Map<String, dynamic>);
      });

  /// The PATCH and GET endpoints wrap the employee under slightly different
  /// keys (`employee`, `user`, `data`, or root). Try them in order rather
  /// than locking to one shape.
  ProfileResponse _parseProfile(Map<String, dynamic> body) {
    final data = body['employee'] as Map<String, dynamic>? ??
        body['user'] as Map<String, dynamic>? ??
        body['data'] as Map<String, dynamic>? ??
        body;
    return ProfileResponse.fromJson(data);
  }
}
