/// Payment method on a collection. `cash` clears immediately on the backend;
/// `cheque` is stored as PENDING until it clears.
enum CollectionMethod {
  cash('CASH'),
  cheque('CHEQUE');

  final String wire;
  const CollectionMethod(this.wire);
}

/// Request body for `POST /api/v1/collections`.
///
/// The cheque fields are required when [method] is [CollectionMethod.cheque]
/// and must be omitted otherwise — the backend rejects extra cheque fields
/// on a CASH payment.
class CollectionRequest {
  final int shopId;

  /// Task this collection is being recorded under, if the screen was opened
  /// from a task. Optional and backward-compatible: when omitted the backend
  /// SMSes only admins + org manager; when sent, the task's responsible
  /// manager is also notified. Must belong to [shopId].
  final int? taskId;
  final double amount;
  final CollectionMethod method;
  final String? chequeNumber;
  final String? chequeBank;

  /// Date printed on the cheque — sent as `YYYY-MM-DD` (no time component).
  final DateTime? chequeDate;
  final String? notes;

  const CollectionRequest({
    required this.shopId,
    this.taskId,
    required this.amount,
    required this.method,
    this.chequeNumber,
    this.chequeBank,
    this.chequeDate,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    final body = <String, dynamic>{
      'shopId': shopId,
      'amount': amount,
      'method': method.wire,
    };
    if (taskId != null) {
      body['taskId'] = taskId;
    }
    if (method == CollectionMethod.cheque) {
      if (chequeNumber != null && chequeNumber!.isNotEmpty) {
        body['chequeNumber'] = chequeNumber;
      }
      if (chequeBank != null && chequeBank!.isNotEmpty) {
        body['chequeBank'] = chequeBank;
      }
      if (chequeDate != null) {
        body['chequeDate'] =
            '${chequeDate!.year.toString().padLeft(4, '0')}-'
            '${chequeDate!.month.toString().padLeft(2, '0')}-'
            '${chequeDate!.day.toString().padLeft(2, '0')}';
      }
    }
    if (notes != null && notes!.isNotEmpty) {
      body['notes'] = notes;
    }
    return body;
  }
}
