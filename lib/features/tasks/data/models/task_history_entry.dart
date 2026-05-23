class TaskHistoryPerformer {
  final int id;
  final String fullName;
  final String role;

  const TaskHistoryPerformer({
    required this.id,
    required this.fullName,
    required this.role,
  });

  factory TaskHistoryPerformer.fromJson(Map<String, dynamic> json) =>
      TaskHistoryPerformer(
        id: json['id'] as int,
        fullName: json['full_name'] as String? ?? json['fullName'] as String? ?? '',
        role: json['role'] as String? ?? '',
      );
}

class TaskHistoryEntry {
  final int id;
  final String action;
  final Map<String, dynamic> oldValues;
  final Map<String, dynamic> newValues;
  final String? ipAddress;
  final DateTime createdAt;
  final TaskHistoryPerformer performer;

  const TaskHistoryEntry({
    required this.id,
    required this.action,
    required this.oldValues,
    required this.newValues,
    this.ipAddress,
    required this.createdAt,
    required this.performer,
  });

  factory TaskHistoryEntry.fromJson(Map<String, dynamic> json) =>
      TaskHistoryEntry(
        id: json['id'] as int,
        action: json['action'] as String? ?? '',
        oldValues: json['old_values'] as Map<String, dynamic>? ?? {},
        newValues: json['new_values'] as Map<String, dynamic>? ?? {},
        ipAddress: json['ip_address'] as String?,
        createdAt: DateTime.tryParse(
                (json['created_at'] ?? '') as String) ??
            DateTime.now(),
        performer: TaskHistoryPerformer.fromJson(
          json['performer'] as Map<String, dynamic>? ?? {},
        ),
      );
}
