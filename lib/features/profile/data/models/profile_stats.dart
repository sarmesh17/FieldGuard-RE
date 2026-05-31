/// Current-month profile stats from `GET /api/v1/auth/me/stats`.
///
/// All figures are scoped to the current Nepali month (Asia/Kathmandu) and
/// reset when the month rolls over — so the UI labels them "This Month".
/// `collected` arrives as a decimal-formatted string (NPR), summing only
/// CLEARED collections; we parse it once here.
class ProfileStats {
  /// `YYYY-MM` of the Nepali month these figures cover.
  final String month;
  final int visits;
  final double collected;
  final int tasksCompleted;

  const ProfileStats({
    required this.month,
    required this.visits,
    required this.collected,
    required this.tasksCompleted,
  });

  factory ProfileStats.fromJson(Map<String, dynamic> j) => ProfileStats(
    month: (j['month'] ?? '') as String,
    visits: _parseInt(j['visits']),
    collected: _parseAmount(j['collected']),
    tasksCompleted: _parseInt(j['tasks_completed']),
  );

  static int _parseInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v?.toString() ?? '') ?? 0;
  }

  static double _parseAmount(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }
}
