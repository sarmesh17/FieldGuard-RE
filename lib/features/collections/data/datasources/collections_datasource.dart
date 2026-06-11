import 'package:dio/dio.dart';

import 'package:field_guard_re/core/constants/api_constant.dart';
import 'package:field_guard_re/core/network/network_exception_mapper.dart';

import '../models/collection_request.dart';
import '../models/collection_response.dart';
import '../models/shop_outstanding.dart';

/// Talks to `/api/v1/collections`.
///
/// Two operations:
///   1. [submit] — `POST /collections` records a cash or cheque collection.
///      Backend returns 201 with `{ collection, outstanding, smsPreview[] }`
///      — the full envelope we model in [CollectionResponse]. Bundled so the
///      UI doesn't need a follow-up GET for outstanding or sms-logs.
///   2. [getOutstanding] — `GET /collections/shops/{id}/outstanding` returns
///      the ledger summary, used when the screen is reopened and the
///      cache is stale.
///
/// Dio failures are funnelled through [NetworkExceptionMapper.map] so they
/// surface as typed `AppException`s — same pattern as the auth/shop
/// datasources.
class CollectionsDataSource {
  CollectionsDataSource(this._dio);

  final Dio _dio;

  Future<CollectionResponse> submit(CollectionRequest req) async {
    try {
      final res = await _dio.post(
        ApiConstant.collectionsEndpoint,
        data: req.toJson(),
      );
      final body = res.data;
      if (body is! Map) {
        throw DioException(
          requestOptions: res.requestOptions,
          response: res,
          type: DioExceptionType.badResponse,
          error: 'Unexpected /collections response shape',
        );
      }
      return CollectionResponse.fromJson(Map<String, dynamic>.from(body));
    } on DioException catch (e) {
      throw NetworkExceptionMapper.map(e);
    }
  }

  Future<ShopOutstanding> getOutstanding(int shopId) async {
    try {
      final res = await _dio.get(ApiConstant.shopOutstandingEndpoint(shopId));
      final body = res.data;
      if (body is! Map) {
        // Defensive — shouldn't happen with a healthy backend, but cheaper
        // than letting a downstream cast blow up with a worse message.
        throw DioException(
          requestOptions: res.requestOptions,
          response: res,
          type: DioExceptionType.badResponse,
          error: 'Unexpected outstanding response shape',
        );
      }
      return ShopOutstanding.fromJson(Map<String, dynamic>.from(body));
    } on DioException catch (e) {
      throw NetworkExceptionMapper.map(e);
    }
  }
}
