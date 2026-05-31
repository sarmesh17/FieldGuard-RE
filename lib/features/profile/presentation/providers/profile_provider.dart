import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:field_guard_re/core/constants/api_constant.dart';
import 'package:field_guard_re/core/network/network_exception_mapper.dart';
import 'package:field_guard_re/features/auth/presentation/providers/auth_provider.dart';
import 'package:field_guard_re/features/profile/data/datasource/profile_data_source.dart';
import 'package:field_guard_re/features/profile/data/models/profile_stats.dart';
import 'package:field_guard_re/features/shops/presentation/providers/shop_provider.dart'
    show uploadServiceProvider;
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
        ref.watch(uploadServiceProvider),
      ),
    );

/// Current-month profile stats for the header tiles (`GET /auth/me/stats`).
///
/// A lightweight standalone fetch rather than a full datasource/repo/usecase
/// stack — it's a single read-only call whose only consumer is the profile
/// header. autoDispose so it re-fetches each time the screen is opened
/// (figures change as the agent works and reset monthly). EMPLOYEE-only on the
/// backend; ADMIN/MANAGER get a 403, which surfaces as an error the tiles
/// fall back to '—' for.
final profileStatsProvider = FutureProvider.autoDispose<ProfileStats>((
  ref,
) async {
  final dio = ref.watch(dioProvider);
  try {
    final res = await dio.get(ApiConstant.authMeStatsEndpoint);
    final body = res.data;
    if (body is! Map) {
      throw DioException(
        requestOptions: res.requestOptions,
        response: res,
        type: DioExceptionType.badResponse,
        error: 'Unexpected /auth/me/stats response shape',
      );
    }
    return ProfileStats.fromJson(Map<String, dynamic>.from(body));
  } on DioException catch (e) {
    throw NetworkExceptionMapper.map(e);
  }
});
