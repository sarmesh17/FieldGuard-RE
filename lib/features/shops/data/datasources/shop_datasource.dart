import 'package:field_guard_re/core/utils/result.dart';
import 'package:field_guard_re/features/shops/data/models/create_shop_request.dart';
import 'package:field_guard_re/features/shops/data/models/shop_model.dart';

abstract interface class ShopDataSource {
  Future<Result<void>> createShop(CreateShopRequest request);
  Future<Result<List<ShopModel>>> getShops();
}
