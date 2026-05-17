import 'package:field_guard_re/core/utils/result.dart';
import 'package:field_guard_re/features/shops/data/datasources/shop_datasource.dart';
import 'package:field_guard_re/features/shops/data/models/create_shop_request.dart';
import 'package:field_guard_re/features/shops/data/models/shop_model.dart';
import 'package:field_guard_re/features/shops/domain/repositories/shop_repository.dart';

class ShopRepositoryImpl implements ShopRepository {
  const ShopRepositoryImpl(this._dataSource);

  final ShopDataSource _dataSource;

  @override
  Future<Result<void>> createShop(CreateShopRequest request) =>
      _dataSource.createShop(request);

  @override
  Future<Result<List<ShopModel>>> getShops() => _dataSource.getShops();
}
