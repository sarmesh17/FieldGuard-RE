/// Outstanding balance summary for a single shop, returned by
/// `GET /api/v1/collections/shops/{shopId}/outstanding`.
///
/// The backend sends all amounts as **strings** (`Decimal` on the server) —
/// we parse them once here so the UI can deal in `double`.
class ShopOutstanding {
  final int shopId;
  final String shopName;

  /// Total amount the shop owes us across all orders.
  final double totalDue;

  /// What we've already collected (cleared cash + cleared cheques).
  final double collected;

  /// Cheques recorded but not yet cleared by the bank.
  final double pendingCheques;

  /// `totalDue - collected` (i.e. what's still recoverable). This is the
  /// number we headline on the collection screen.
  final double outstanding;

  const ShopOutstanding({
    required this.shopId,
    required this.shopName,
    required this.totalDue,
    required this.collected,
    required this.pendingCheques,
    required this.outstanding,
  });

  factory ShopOutstanding.fromJson(Map<String, dynamic> j) => ShopOutstanding(
        shopId: j['shop_id'] as int,
        shopName: (j['shop_name'] ?? '') as String,
        totalDue: _parseAmount(j['total_due']),
        collected: _parseAmount(j['collected']),
        pendingCheques: _parseAmount(j['pending_cheques']),
        outstanding: _parseAmount(j['outstanding']),
      );

  /// Amounts arrive as decimal-formatted strings (e.g. `"6499.50"`). We
  /// tolerate numbers too in case the contract loosens later.
  static double _parseAmount(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }
}
