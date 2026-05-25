import 'package:field_guard_re/core/utils/result.dart';
import 'package:field_guard_re/features/shops/data/models/shop_detail.dart';
import 'package:field_guard_re/features/shops/domain/repositories/shop_repository.dart';

class GetShopDetailUseCase {
  const GetShopDetailUseCase(this._repository);

  final ShopRepository _repository;

  Future<Result<ShopDetail>> call(int id) => _repository.getShopById(id);
}
