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
  Future<Result<List<ShopModel>>> getShops(
          {String? source, String? currentUserRole}) =>
      safeCall(() async {
        final response = await _dio.get(
          ApiConstant.shopsEndpoint,
          queryParameters: source != null ? {'source': source} : null,
        );
        final body = response.data as Map<String, dynamic>;
        final result = <ShopModel>[];

        if (body.containsKey('source')) {
          // ── Filtered response: { source, shops[{...creator{role}}] } ──
          // creator.role is embedded — ShopModel.fromJson reads it directly.
          final shops = (body['shops'] as List<dynamic>?) ?? [];
          for (final e in shops) {
            result.add(ShopModel.fromJson(e as Map<String, dynamic>));
          }
        } else if (body.containsKey('myShops')) {
          // ── MANAGER / ADMIN "All" shape: { myShops, sharedWithMe, team } ──
          final myShops = (body['myShops'] as List<dynamic>?) ?? [];
          for (final e in myShops) {
            result.add(ShopModel.fromJson(
              e as Map<String, dynamic>,
              createdByRoleOverride: currentUserRole,
            ));
          }

          final sharedWithMe =
              (body['sharedWithMe'] as List<dynamic>?) ?? [];
          for (final e in sharedWithMe) {
            result.add(ShopModel.fromJson(e as Map<String, dynamic>));
          }

          final team = (body['team'] as List<dynamic>?) ?? [];
          for (final entry in team) {
            final teamMap = entry as Map<String, dynamic>;
            final shops = (teamMap['shops'] as List<dynamic>?) ?? [];
            for (final e in shops) {
              result.add(ShopModel.fromJson(
                e as Map<String, dynamic>,
                createdByRoleOverride: 'EMPLOYEE',
              ));
            }
          }
        } else {
          // ── EMPLOYEE "All" shape: { shops: [...] } ──
          final shops = (body['shops'] as List<dynamic>?) ?? [];
          for (final e in shops) {
            result.add(ShopModel.fromJson(e as Map<String, dynamic>));
          }
        }

        return result;
      });
}
