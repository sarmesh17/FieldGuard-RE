import 'package:field_guard_re/features/tasks/data/models/task_model.dart';

/// Consolidated home-dashboard payload from `GET /api/v1/dashboard/summary`.
///
/// Bundles the user profile, one task of each status (PENDING / IN_PROGRESS /
/// COMPLETED) with their totals, and the live-tracking summary — so the home
/// screen reads everything it needs in one round-trip.
class DashboardSummary {
  final DashboardUser user;

  /// Totals come from each block's `pagination.total` — the *real* count of
  /// tasks in that bucket. The `tasks[]` array is capped at 1 (a preview).
  final int pendingTotal;
  final int inProgressTotal;
  final int completedTotal;

  /// The single preview task for each bucket, if any.
  final TaskModel? pendingTask;
  final TaskModel? inProgressTask;
  final TaskModel? completedTask;

  /// Number of teammates currently sharing live location. Typically 0 for an
  /// EMPLOYEE viewer; non-zero is interesting on a MANAGER/ADMIN dashboard.
  final int liveEmployeesCount;

  const DashboardSummary({
    required this.user,
    required this.pendingTotal,
    required this.inProgressTotal,
    required this.completedTotal,
    required this.pendingTask,
    required this.inProgressTask,
    required this.completedTask,
    required this.liveEmployeesCount,
  });

  factory DashboardSummary.fromJson(Map<String, dynamic> j) {
    final me = j['me'] is Map
        ? Map<String, dynamic>.from(j['me'] as Map)
        : const <String, dynamic>{};
    final userJson = me['user'] is Map
        ? Map<String, dynamic>.from(me['user'] as Map)
        : const <String, dynamic>{};

    int totalFor(String key) {
      final block = j[key];
      if (block is! Map) return 0;
      final pagination = block['pagination'];
      if (pagination is! Map) return 0;
      final v = pagination['total'];
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse(v?.toString() ?? '') ?? 0;
    }

    TaskModel? firstTaskFor(String key) {
      final block = j[key];
      if (block is! Map) return null;
      final list = block['tasks'];
      if (list is! List || list.isEmpty) return null;
      final first = list.first;
      if (first is! Map) return null;
      try {
        return TaskModel.fromJson(Map<String, dynamic>.from(first));
      } catch (_) {
        // Tolerate a single bad row — the rest of the dashboard still renders.
        return null;
      }
    }

    final live = j['liveEmployees'];
    final liveCount = (live is Map && live['count'] is num)
        ? (live['count'] as num).toInt()
        : 0;

    return DashboardSummary(
      user: DashboardUser.fromJson(userJson),
      pendingTotal: totalFor('pendingTasks'),
      inProgressTotal: totalFor('inProgressTasks'),
      completedTotal: totalFor('completedTasks'),
      pendingTask: firstTaskFor('pendingTasks'),
      inProgressTask: firstTaskFor('inProgressTasks'),
      completedTask: firstTaskFor('completedTasks'),
      liveEmployeesCount: liveCount,
    );
  }
}

/// Today's task progress from `GET /api/v1/dashboard/today-tasks`.
class TodayTaskStats {
  final String date;
  final int pendingTotal;
  final int inProgressTotal;
  final int completedTotal;

  const TodayTaskStats({
    required this.date,
    required this.pendingTotal,
    required this.inProgressTotal,
    required this.completedTotal,
  });

  int get totalCount => pendingTotal + inProgressTotal + completedTotal;

  double get completionRate =>
      totalCount == 0 ? 0 : completedTotal / totalCount;

  factory TodayTaskStats.fromJson(Map<String, dynamic> j) {
    int totalFor(String key) {
      final block = j[key];
      if (block is! Map) return 0;
      final pagination = block['pagination'];
      if (pagination is! Map) return 0;
      final v = pagination['total'];
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse(v?.toString() ?? '') ?? 0;
    }

    return TodayTaskStats(
      date: (j['date'] as String?) ?? '',
      pendingTotal: totalFor('pendingTasks'),
      inProgressTotal: totalFor('inProgressTasks'),
      completedTotal: totalFor('completedTasks'),
    );
  }
}

/// Slim view of `me.user` — only the fields the home header actually renders.
/// Kept separate from the full `ProfileResponse` so dashboard changes don't
/// ripple through profile parsing.
class DashboardUser {
  final int id;
  final String fullName;
  final String? email;
  final String? profileImage;
  final String role;
  final String? employeeCode;

  const DashboardUser({
    required this.id,
    required this.fullName,
    required this.email,
    required this.profileImage,
    required this.role,
    required this.employeeCode,
  });

  factory DashboardUser.fromJson(Map<String, dynamic> j) => DashboardUser(
    id: (j['id'] is num) ? (j['id'] as num).toInt() : 0,
    fullName: (j['full_name'] ?? '') as String,
    email: j['email'] as String?,
    profileImage: j['profile_image'] as String?,
    role: (j['role'] ?? '') as String,
    employeeCode: j['employee_code'] as String?,
  );
}
