/// A single collection row as returned by the backend.
///
/// We model only the fields the UI actually uses today. The backend payload
/// has extras (`settled_by`, `settler`, `provider_*`, …) which we ignore —
/// kept lean so backend additions don't force a model change.
class Collection {
  final int id;
  final int shopId;
  final double amount;
  final String method; // 'CASH' | 'CHEQUE'
  final String status; // 'CLEARED' | 'PENDING'
  final String? chequeNumber;
  final String? chequeBank;
  final DateTime? chequeDate;
  final String? notes;
  final DateTime createdAt;
  final DateTime? clearedAt;
  final CollectionPerson? collector;
  final CollectionShop? shop;

  const Collection({
    required this.id,
    required this.shopId,
    required this.amount,
    required this.method,
    required this.status,
    this.chequeNumber,
    this.chequeBank,
    this.chequeDate,
    this.notes,
    required this.createdAt,
    this.clearedAt,
    this.collector,
    this.shop,
  });

  factory Collection.fromJson(Map<String, dynamic> j) => Collection(
        id: j['id'] as int,
        shopId: j['shop_id'] as int,
        amount: _parseAmount(j['amount']),
        method: (j['method'] ?? '') as String,
        status: (j['status'] ?? '') as String,
        chequeNumber: j['cheque_number'] as String?,
        chequeBank: j['cheque_bank'] as String?,
        chequeDate: _parseDate(j['cheque_date']),
        notes: j['notes'] as String?,
        createdAt: _parseDateTime(j['created_at']) ?? DateTime.now(),
        clearedAt: _parseDateTime(j['cleared_at']),
        collector: j['collector'] is Map
            ? CollectionPerson.fromJson(
                Map<String, dynamic>.from(j['collector'] as Map))
            : null,
        shop: j['shop'] is Map
            ? CollectionShop.fromJson(
                Map<String, dynamic>.from(j['shop'] as Map))
            : null,
      );

  static double _parseAmount(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }

  static DateTime? _parseDateTime(dynamic v) {
    if (v is! String || v.isEmpty) return null;
    return DateTime.tryParse(v);
  }

  static DateTime? _parseDate(dynamic v) {
    if (v is! String || v.isEmpty) return null;
    // Cheque dates arrive as `YYYY-MM-DD` (no time).
    return DateTime.tryParse(v);
  }
}

class CollectionPerson {
  final int id;
  final String fullName;
  final String? role;
  final String? employeeCode;

  const CollectionPerson({
    required this.id,
    required this.fullName,
    this.role,
    this.employeeCode,
  });

  factory CollectionPerson.fromJson(Map<String, dynamic> j) => CollectionPerson(
        id: j['id'] as int,
        fullName: (j['full_name'] ?? '') as String,
        role: j['role'] as String?,
        employeeCode: j['employee_code'] as String?,
      );
}

class CollectionShop {
  final int id;
  final String name;

  const CollectionShop({required this.id, required this.name});

  factory CollectionShop.fromJson(Map<String, dynamic> j) => CollectionShop(
        id: j['id'] as int,
        name: (j['name'] ?? '') as String,
      );
}
