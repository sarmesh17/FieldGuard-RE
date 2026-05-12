import 'package:field_guard_re/features/profile/data/models/profile_response.dart';

sealed class ProfileState {
  const ProfileState();
}

class ProfileInitial extends ProfileState {
  const ProfileInitial();
}

class ProfileLoading extends ProfileState {
  const ProfileLoading();
}

class ProfileSuccess extends ProfileState {
  const ProfileSuccess(this.response);
  final ProfileResponse response;
}

class ProfileError extends ProfileState {
  const ProfileError(this.message);

  final String message;
}
