import 'package:dio/dio.dart';
import 'package:field_guard_re/core/constants/api_constant.dart';
import 'package:field_guard_re/core/network/api_runner.dart';
import 'package:field_guard_re/core/utils/result.dart';
import 'package:field_guard_re/features/shops/data/models/create_shop_request.dart';
import 'package:field_guard_re/features/shops/data/models/shop_model.dart';
import 'shop_datasource.dart';

class ShopDataSourceImpl with ApiRunner implements ShopDataSource {
  const ShopDataSourceImpl(this._dio);

  final Dio _dio;

  @override
  Future<Result<void>> createShop(CreateShopRequest request) =>
      safeCall(() async {
        await _dio.post(
          ApiConstant.shopsEndpoint,
          data: request.toJson(),
        );
      });

  @override
  Future<Result<List<ShopModel>>> getShops() => safeCall(() async {
        final response = await _dio.get(ApiConstant.shopsEndpoint);
        final body = response.data as Map<String, dynamic>;
        final list = body['shops'] as List<dynamic>;
        return list
            .map((e) => ShopModel.fromJson(e as Map<String, dynamic>))
            .toList();
      });
}
