import 'package:field_guard_re/core/utils/result.dart';
import 'package:field_guard_re/features/shops/data/models/create_shop_request.dart';
import 'package:field_guard_re/features/shops/domain/repositories/shop_repository.dart';

class CreateShopUseCase {
  const CreateShopUseCase(this._repository);

  final ShopRepository _repository;

  Future<Result<void>> call(CreateShopRequest request) =>
      _repository.createShop(request);
}
