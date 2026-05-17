import 'package:field_guard_re/features/shops/data/models/shop_model.dart';

sealed class ShopsListState {
  const ShopsListState();
}

class ShopsListInitial extends ShopsListState {
  const ShopsListInitial();
}

class ShopsListLoading extends ShopsListState {
  const ShopsListLoading();
}

class ShopsListSuccess extends ShopsListState {
  final List<ShopModel> shops;
  const ShopsListSuccess(this.shops);
}

class ShopsListError extends ShopsListState {
  final String message;
  const ShopsListError(this.message);
}
