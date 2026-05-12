import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:field_guard_re/core/constants/app_strings.dart';
import 'package:field_guard_re/core/errors/app_exception.dart';
import 'package:field_guard_re/core/utils/result.dart';
import 'package:field_guard_re/features/profile/data/models/profile_response.dart';
import 'package:field_guard_re/features/profile/domain/usecases/get_profile_usecase.dart';
import 'package:field_guard_re/features/profile/domain/usecases/update_profile_usecase.dart';
import 'profile_state.dart';

class ProfileNotifier extends StateNotifier<ProfileState> {
  ProfileNotifier(this._getProfileUseCase, this._updateProfileUseCase)
      : super(const ProfileInitial()) {
    fetchProfile();
  }

  final GetProfileUseCase _getProfileUseCase;
  final UpdateProfileUseCase _updateProfileUseCase;

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

  /// Calls PATCH /api/v1/employees/profile. Returns the [Result] so the UI
  /// can show feedback. On success, state is updated so ProfileScreen reflects
  /// the new data without an extra GET.
  Future<Result<ProfileResponse>> updateProfile({
    String? fullName,
    String? email,
    String? imagePath,
  }) async {
    final result = await _updateProfileUseCase(
      fullName: fullName,
      email: email,
      imagePath: imagePath,
    );
    if (result is Success<ProfileResponse>) {
      state = ProfileSuccess(result.data);
    }
    return result;
  }
}
