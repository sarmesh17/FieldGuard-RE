import 'package:dio/dio.dart';

import 'package:field_guard_re/core/constants/api_constant.dart';
import 'package:field_guard_re/core/network/api_runner.dart';
import 'package:field_guard_re/core/utils/result.dart';

import '../models/app_notification.dart';

/// Talks to the in-app notification inbox.
///
///   * [getNotifications] — `GET /notifications?page&limit&unreadOnly`.
///   * [markRead] — `PATCH /notifications/:id/read` (no bulk endpoint exists,
///     so "mark all" is done by the notifier looping over unread ids).
///
/// Auth + refresh are handled by the interceptors on the injected [Dio];
/// failures funnel through [ApiRunner.safeCall] into a typed [Result].
class NotificationsDataSource with ApiRunner {
  const NotificationsDataSource(this._dio);

  final Dio _dio;

  Future<Result<NotificationsPage>> getNotifications({
    int page = 1,
    int limit = 20,
    bool unreadOnly = false,
  }) =>
      safeCall(() async {
        final res = await _dio.get(
          ApiConstant.notificationsEndpoint,
          queryParameters: {
            'page': page,
            'limit': limit,
            'unreadOnly': unreadOnly,
          },
        );
        final body = res.data;
        return NotificationsPage.fromJson(
          body is Map ? Map<String, dynamic>.from(body) : const {},
        );
      });

  Future<Result<void>> markRead(int id) => safeCall(() async {
        await _dio.patch(ApiConstant.notificationReadEndpoint(id));
      });
}
