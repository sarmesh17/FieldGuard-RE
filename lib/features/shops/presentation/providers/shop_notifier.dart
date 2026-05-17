import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:field_guard_re/core/errors/app_exception.dart';
import 'package:field_guard_re/core/utils/result.dart';
import 'package:field_guard_re/features/shops/data/models/create_shop_request.dart';
import 'package:field_guard_re/features/shops/domain/usecases/create_shop_usecase.dart';
import 'shop_state.dart';

class ShopNotifier extends StateNotifier<ShopState> {
  ShopNotifier(this._createShopUseCase) : super(const ShopInitial());

  final CreateShopUseCase _createShopUseCase;

  Future<bool> createShop(CreateShopRequest request) async {
    state = const ShopLoading();
    final result = await _createShopUseCase(request);
    switch (result) {
      case Success():
        state = const ShopSuccess();
        return true;
      case Failure(:final exception):
        state = ShopError(
          exception is AppException ? exception.message : 'Something went wrong',
        );
        return false;
    }
  }

  void reset() => state = const ShopInitial();
}
