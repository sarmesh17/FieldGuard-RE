import 'package:field_guard_re/core/utils/result.dart';
import 'package:field_guard_re/features/shops/data/models/shop_model.dart';
import 'package:field_guard_re/features/shops/domain/repositories/shop_repository.dart';

class GetShopsUseCase {
  const GetShopsUseCase(this._repository);

  final ShopRepository _repository;

  Future<Result<List<ShopModel>>> call(
          {String? source, String? currentUserRole}) =>
      _repository.getShops(source: source, currentUserRole: currentUserRole);
}
