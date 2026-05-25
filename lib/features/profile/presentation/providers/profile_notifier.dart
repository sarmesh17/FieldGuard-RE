import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:field_guard_re/core/constants/app_strings.dart';
import 'package:field_guard_re/core/errors/app_exception.dart';
import 'package:field_guard_re/core/services/upload_service.dart';
import 'package:field_guard_re/core/utils/result.dart';
import 'package:field_guard_re/features/profile/data/models/profile_response.dart';
import 'package:field_guard_re/features/profile/domain/usecases/get_profile_usecase.dart';
import 'package:field_guard_re/features/profile/domain/usecases/update_profile_usecase.dart';
import 'profile_state.dart';

class ProfileNotifier extends StateNotifier<ProfileState> {
  ProfileNotifier(
    this._getProfileUseCase,
    this._updateProfileUseCase,
    this._uploadService,
  ) : super(const ProfileInitial()) {
    fetchProfile();
  }

  final GetProfileUseCase _getProfileUseCase;
  final UpdateProfileUseCase _updateProfileUseCase;
  final UploadService _uploadService;

  Future<void> fetchProfile() async {
    state = const ProfileLoading();
    final result = await _getProfileUseCase();
    state = switch (result) {
      Success(:final data) => ProfileSuccess(data),
      Failure(:final exception) => ProfileError(
          exception is AppException
              ? exception.message
              : AppStrings.serverError,
        ),
    };
  }

  /// Updates the profile via `PATCH /api/v1/employees/profile`. When
  /// [imageFile] is supplied it is first uploaded via the presigned-URL flow
  /// and the resulting `imageKey` is sent in the JSON body — the PATCH
  /// endpoint itself does not accept files. Returns the [Result] so the UI
  /// can show feedback. On success, state is refreshed so any listeners see
  /// the new data without an extra GET.
  Future<Result<ProfileResponse>> updateProfile({
    String? fullName,
    String? email,
    File? imageFile,
  }) async {
    String? imageKey;
    if (imageFile != null) {
      // The backend confirm step (validateAndConfirmImageKey) ties the upload
      // to the caller's own id, so the presigned key must embed it — entityId
      // 0 fails with 403. Use the loaded profile's id; fall back to 0 only if
      // the profile somehow isn't loaded yet.
      final userId = switch (state) {
        ProfileSuccess(:final response) => response.id,
        _ => 0,
      };
      try {
        imageKey = await _uploadService.uploadProfilePhoto(imageFile, userId);
      } catch (e) {
        return Failure(
          e is AppException
              ? e
              : const ServerException('Photo upload failed. Please try again.'),
        );
      }
    }

    final result = await _updateProfileUseCase(
      fullName: fullName,
      email: email,
      imageKey: imageKey,
    );
    if (result is Success<ProfileResponse>) {
      state = ProfileSuccess(result.data);
    }
    return result;
  }
}
