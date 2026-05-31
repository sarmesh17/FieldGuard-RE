/// One outbound SMS the backend rendered and sent as a side-effect of a
/// collection mutation. `body` is the authoritative, verbatim message the
/// shop owner received — the screen renders it as-is, no client templating.
///
/// The backend may return multiple previews per collection (e.g. one to the
/// shop, one to the manager); we let the UI decide which to display via
/// [kind].
class SmsPreview {
  /// e.g. `COLLECTION_RECEIPT_SHOP`. UI matches on this to pick which
  /// preview to render when more than one is returned.
  final String kind;
  final String recipient;
  final String body;

  const SmsPreview({
    required this.kind,
    required this.recipient,
    required this.body,
  });

  factory SmsPreview.fromJson(Map<String, dynamic> j) => SmsPreview(
        kind: (j['kind'] ?? '') as String,
        recipient: (j['recipient'] ?? '') as String,
        body: (j['body'] ?? '') as String,
      );
}
