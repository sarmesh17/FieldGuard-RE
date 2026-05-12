import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:field_guard_re/core/network/dio_client.dart';
import 'package:field_guard_re/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:field_guard_re/features/auth/data/datasources/auth_remote_datasource_impl.dart';
import 'package:field_guard_re/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:field_guard_re/features/auth/domain/repositories/auth_repository.dart';
import 'package:field_guard_re/features/auth/domain/usecases/login_usecase.dart';
import 'auth_notifier.dart';
import 'auth_state.dart';

export 'auth_state.dart';
export 'auth_notifier.dart';

final dioProvider = Provider<Dio>((ref) => DioClient.createDio());

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>(
  (ref) => AuthRemoteDataSourceImpl(ref.watch(dioProvider)),
);

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepositoryImpl(ref.watch(authRemoteDataSourceProvider)),
);

final loginUseCaseProvider = Provider<LoginUseCase>(
  (ref) => LoginUseCase(ref.watch(authRepositoryProvider)),
);

final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(ref.watch(loginUseCaseProvider)),
);
