import 'collection.dart';
import 'shop_outstanding.dart';
import 'sms_preview.dart';

/// Response envelope for both `POST /collections` and
/// `PATCH /collections/:id/settle`. The backend bundles three things so the
/// app needs exactly one round-trip:
///
///   * [collection] — the row that was just written / mutated
///   * [outstanding] — the shop's refreshed ledger summary
///   * [smsPreview] — the SMS(es) the backend rendered and dispatched.
///     The shop-facing receipt is the one the UI displays after a
///     successful collection; use [shopReceipt] to pull it out without
///     hardcoding an index.
class CollectionResponse {
  final Collection collection;
  final ShopOutstanding outstanding;
  final List<SmsPreview> smsPreview;

  const CollectionResponse({
    required this.collection,
    required this.outstanding,
    required this.smsPreview,
  });

  /// The shop-receipt SMS, if the backend sent one. Falls back to the first
  /// preview so we still show *something* on a future schema change rather
  /// than a blank screen.
  SmsPreview? get shopReceipt {
    for (final p in smsPreview) {
      if (p.kind == 'COLLECTION_RECEIPT_SHOP') return p;
    }
    return smsPreview.isEmpty ? null : smsPreview.first;
  }

  factory CollectionResponse.fromJson(Map<String, dynamic> j) {
    final collectionJson = Map<String, dynamic>.from(j['collection'] as Map);
    final outstandingJson = Map<String, dynamic>.from(j['outstanding'] as Map);
    final previews = (j['smsPreview'] as List<dynamic>? ?? [])
        .whereType<Map>()
        .map((m) => SmsPreview.fromJson(Map<String, dynamic>.from(m)))
        .toList();
    return CollectionResponse(
      collection: Collection.fromJson(collectionJson),
      outstanding: ShopOutstanding.fromJson(outstandingJson),
      smsPreview: previews,
    );
  }
}
