import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:field_guard_re/features/auth/presentation/providers/auth_provider.dart';
import 'package:field_guard_re/features/profile/data/datasource/profile_data_source.dart';
import 'package:field_guard_re/features/profile/data/datasource/profile_data_source_impl.dart';
import 'package:field_guard_re/features/profile/data/repositories/profile_repository_impl.dart';
import 'package:field_guard_re/features/profile/domain/repositories/profile_repo.dart';
import 'package:field_guard_re/features/profile/domain/usecases/get_profile_usecase.dart';
import 'package:field_guard_re/features/profile/domain/usecases/update_profile_usecase.dart';
import 'profile_notifier.dart';
import 'profile_state.dart';

export 'profile_state.dart';
export 'profile_notifier.dart';

final profileDataSourceProvider = Provider<ProfileDataSource>(
  (ref) => ProfileDataSourceImpl(ref.watch(dioProvider)),
);

final profileRepositoryProvider = Provider<ProfileRepo>(
  (ref) => ProfileRepositoryImpl(ref.watch(profileDataSourceProvider)),
);

final getProfileUseCaseProvider = Provider<GetProfileUseCase>(
  (ref) => GetProfileUseCase(ref.watch(profileRepositoryProvider)),
);

final updateProfileUseCaseProvider = Provider<UpdateProfileUseCase>(
  (ref) => UpdateProfileUseCase(ref.watch(profileRepositoryProvider)),
);

final profileNotifierProvider =
    StateNotifierProvider.autoDispose<ProfileNotifier, ProfileState>(
  (ref) => ProfileNotifier(
    ref.watch(getProfileUseCaseProvider),
    ref.watch(updateProfileUseCaseProvider),
  ),
);
