import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:field_guard_re/features/auth/presentation/providers/auth_provider.dart';
import 'package:field_guard_re/features/shops/data/datasources/shop_datasource.dart';
import 'package:field_guard_re/features/shops/data/datasources/shop_datasource_impl.dart';
import 'package:field_guard_re/features/shops/data/repositories/shop_repository_impl.dart';
import 'package:field_guard_re/features/shops/domain/repositories/shop_repository.dart';
import 'package:field_guard_re/features/shops/domain/usecases/create_shop_usecase.dart';
import 'package:field_guard_re/features/shops/domain/usecases/get_shops_usecase.dart';
import 'shop_notifier.dart';
import 'shop_state.dart';
import 'shops_list_notifier.dart';
import 'shops_list_state.dart';

export 'shop_state.dart';
export 'shop_notifier.dart';
export 'shops_list_state.dart';
export 'shops_list_notifier.dart';

final shopDataSourceProvider = Provider<ShopDataSource>(
  (ref) => ShopDataSourceImpl(ref.watch(dioProvider)),
);

final shopRepositoryProvider = Provider<ShopRepository>(
  (ref) => ShopRepositoryImpl(ref.watch(shopDataSourceProvider)),
);

final createShopUseCaseProvider = Provider<CreateShopUseCase>(
  (ref) => CreateShopUseCase(ref.watch(shopRepositoryProvider)),
);

final getShopsUseCaseProvider = Provider<GetShopsUseCase>(
  (ref) => GetShopsUseCase(ref.watch(shopRepositoryProvider)),
);

final shopNotifierProvider =
    StateNotifierProvider.autoDispose<ShopNotifier, ShopState>(
  (ref) => ShopNotifier(ref.watch(createShopUseCaseProvider)),
);

final shopsListNotifierProvider =
    StateNotifierProvider.autoDispose<ShopsListNotifier, ShopsListState>(
  (ref) => ShopsListNotifier(ref.watch(getShopsUseCaseProvider)),
);
