class TaskCreator {
  final int id;
  final String fullName;

  const TaskCreator({required this.id, required this.fullName});

  factory TaskCreator.fromJson(Map<String, dynamic> json) => TaskCreator(
        id: json['id'] as int,
        fullName: (json['full_name'] ?? '') as String,
      );
}

/// Lightweight shop snapshot embedded on every task response.
/// Null on legacy tasks created before the backend started attaching it —
/// always access via `task.shop?.name`.
class TaskShop {
  final int id;
  final String name;
  final String? shopImage;

  const TaskShop({required this.id, required this.name, this.shopImage});

  factory TaskShop.fromJson(Map<String, dynamic> json) => TaskShop(
        id: json['id'] as int,
        name: (json['name'] ?? '') as String,
        shopImage: json['shop_image'] as String?,
      );
}

/// A single completed shop visit detected by the geofence tracker, as
/// returned in the task detail response (`geofence_visits`, ascending by
/// enter time). Lat/long are Decimal strings from the backend — parse before
/// plotting.
class TaskGeofenceVisit {
  final String id;
  final String visitId;
  final int? shopId;
  final DateTime enteredAt;
  final DateTime exitedAt;
  final int stayDurationSeconds;
  final String enterLatitude;
  final String enterLongitude;
  final String exitLatitude;
  final String exitLongitude;

  /// True when the exit wasn't observed directly (app-kill / permission loss)
  /// and was estimated from the last known in-geofence fix.
  final bool exitEstimated;

  const TaskGeofenceVisit({
    required this.id,
    required this.visitId,
    this.shopId,
    required this.enteredAt,
    required this.exitedAt,
    required this.stayDurationSeconds,
    required this.enterLatitude,
    required this.enterLongitude,
    required this.exitLatitude,
    required this.exitLongitude,
    required this.exitEstimated,
  });

  factory TaskGeofenceVisit.fromJson(Map<String, dynamic> json) =>
      TaskGeofenceVisit(
        id: (json['id'] ?? '').toString(),
        visitId: (json['visit_id'] ?? '').toString(),
        shopId: json['shop_id'] as int?,
        enteredAt:
            DateTime.tryParse((json['entered_at'] ?? '') as String) ??
                DateTime.now(),
        exitedAt: DateTime.tryParse((json['exited_at'] ?? '') as String) ??
            DateTime.now(),
        stayDurationSeconds: (json['stay_duration_seconds'] as num?)?.toInt() ?? 0,
        enterLatitude: (json['enter_latitude'] ?? '').toString(),
        enterLongitude: (json['enter_longitude'] ?? '').toString(),
        exitLatitude: (json['exit_latitude'] ?? '').toString(),
        exitLongitude: (json['exit_longitude'] ?? '').toString(),
        exitEstimated: json['exit_estimated'] as bool? ?? false,
      );
}

class TaskModel {
  final int id;
  final String title;
  final String description;
  final List<String> items;
  final String status;
  final String priority;
  final String? shopLatitude;
  final String? shopLongitude;
  final DateTime? dueDate;
  final DateTime? completedAt;
  final String? remarks;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final TaskCreator? creator;
  final TaskCreator? assignee;
  final TaskCreator? manager;
  final TaskShop? shop;
  final String? cancelReason;
  final String? cancelImage;
  final List<TaskGeofenceVisit> geofenceVisits;

  const TaskModel({
    required this.id,
    required this.title,
    required this.description,
    required this.items,
    required this.status,
    required this.priority,
    this.shopLatitude,
    this.shopLongitude,
    this.dueDate,
    this.completedAt,
    this.remarks,
    required this.createdAt,
    this.updatedAt,
    this.creator,
    this.assignee,
    this.manager,
    this.shop,
    this.cancelReason,
    this.cancelImage,
    this.geofenceVisits = const [],
  });

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>? ?? [];
    return TaskModel(
      id: json['id'] as int,
      title: (json['title'] ?? '') as String,
      description: (json['description'] ?? '') as String,
      items: rawItems.map((e) => e.toString()).toList(),
      status: (json['status'] ?? 'PENDING') as String,
      priority: (json['priority'] ?? 'MEDIUM') as String,
      shopLatitude: json['shop_latitude'] as String?,
      shopLongitude: json['shop_longitude'] as String?,
      dueDate: json['due_date'] != null
          ? DateTime.tryParse(json['due_date'] as String)
          : null,
      completedAt: json['completed_at'] != null
          ? DateTime.tryParse(json['completed_at'] as String)
          : null,
      remarks: json['remarks'] as String?,
      createdAt: DateTime.tryParse(
              (json['created_at'] ?? '') as String) ??
          DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
      creator: json['creator'] is Map<String, dynamic>
          ? TaskCreator.fromJson(json['creator'] as Map<String, dynamic>)
          : null,
      assignee: json['assignee'] is Map<String, dynamic>
          ? TaskCreator.fromJson(json['assignee'] as Map<String, dynamic>)
          : null,
      manager: json['manager'] is Map<String, dynamic>
          ? TaskCreator.fromJson(json['manager'] as Map<String, dynamic>)
          : null,
      shop: json['shop'] is Map<String, dynamic>
          ? TaskShop.fromJson(json['shop'] as Map<String, dynamic>)
          : null,
      cancelReason: json['cancel_reason'] as String?,
      cancelImage: json['cancel_image'] as String?,
      geofenceVisits: (json['geofence_visits'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(TaskGeofenceVisit.fromJson)
          .toList(),
    );
  }
}
