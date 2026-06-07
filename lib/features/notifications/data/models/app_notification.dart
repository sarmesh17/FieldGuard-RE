import 'dart:convert';

/// A single in-app notification from `GET /api/v1/notifications`.
///
/// Shape: `{ id, type, title, body, data, is_read, read_at, created_at }`.
/// [data] is the same deep-link payload that rides on the FCM push — e.g.
/// `{ "kind": "TASK_ASSIGNED", "taskId": 123, "shopId": 12, ... }`. In the
/// in-app JSON its ids are numbers; in a push they're strings — [_asInt]
/// handles both so callers don't have to care which source it came from.
class AppNotification {
  final int id;
  final String type;
  final String title;
  final String body;
  final Map<String, dynamic> data;
  final bool isRead;
  final DateTime? readAt;
  final DateTime createdAt;

  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.data,
    required this.isRead,
    required this.readAt,
    required this.createdAt,
  });

  /// The deep-link discriminator, e.g. `TASK_ASSIGNED` / `CHEQUE_RECEIVED`.
  String? get kind => data['kind']?.toString();
  int? get taskId => _asInt(data['taskId']);
  int? get shopId => _asInt(data['shopId']);

  AppNotification copyWith({bool? isRead, DateTime? readAt}) => AppNotification(
        id: id,
        type: type,
        title: title,
        body: body,
        data: data,
        isRead: isRead ?? this.isRead,
        readAt: readAt ?? this.readAt,
        createdAt: createdAt,
      );

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: _asInt(json['id']) ?? 0,
      type: json['type']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      body: json['body']?.toString() ?? '',
      data: _parseData(json['data']),
      isRead: json['is_read'] == true,
      readAt: _parseDate(json['read_at']),
      createdAt: _parseDate(json['created_at']) ?? DateTime.now(),
    );
  }

  /// `data` is a JSON object, but tolerate a stringified-JSON object too in
  /// case the backend serialises it that way.
  static Map<String, dynamic> _parseData(dynamic raw) {
    if (raw is Map) return Map<String, dynamic>.from(raw);
    if (raw is String && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map) return Map<String, dynamic>.from(decoded);
      } catch (_) {/* not JSON — ignore */}
    }
    return const {};
  }

  static int? _asInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v);
    return null;
  }

  static DateTime? _parseDate(dynamic v) {
    if (v is String && v.isNotEmpty) return DateTime.tryParse(v);
    return null;
  }
}

/// One page of the notification inbox plus the inbox-wide [unreadCount] (used
/// for the badge) and [total] (used to know when pagination is exhausted).
class NotificationsPage {
  final List<AppNotification> notifications;
  final int unreadCount;
  final int total;
  final int page;
  final int limit;

  const NotificationsPage({
    required this.notifications,
    required this.unreadCount,
    required this.total,
    required this.page,
    required this.limit,
  });

  factory NotificationsPage.fromJson(Map<String, dynamic> json) {
    final list = json['notifications'];
    return NotificationsPage(
      notifications: list is List
          ? list
              .whereType<Map>()
              .map((e) => AppNotification.fromJson(Map<String, dynamic>.from(e)))
              .toList()
          : const [],
      unreadCount: AppNotification._asInt(json['unreadCount']) ?? 0,
      total: AppNotification._asInt(json['total']) ?? 0,
      page: AppNotification._asInt(json['page']) ?? 1,
      limit: AppNotification._asInt(json['limit']) ?? 20,
    );
  }
}
