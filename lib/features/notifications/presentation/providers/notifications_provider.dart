import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:field_guard_re/core/errors/app_exception.dart';
import 'package:field_guard_re/core/utils/result.dart';
import 'package:field_guard_re/features/auth/presentation/providers/auth_provider.dart';
import 'package:field_guard_re/features/notifications/data/datasources/notifications_datasource.dart';
import 'package:field_guard_re/features/notifications/data/models/app_notification.dart';

// ── State ─────────────────────────────────────────────────────────────────────

/// One immutable snapshot of the inbox. A single state object (rather than
/// sealed variants) keeps both the list screen and the home badge reading the
/// same source — [unreadCount] drives the badge, [items] drive the list.
class NotificationsState {
  final List<AppNotification> items;
  final int unreadCount;
  final int total;
  final int page; // highest page loaded (0 = nothing yet)
  final bool isLoading; // first load / refresh in flight
  final bool isLoadingMore; // pagination append in flight
  final String? error; // last load error (shown only when [items] is empty)

  const NotificationsState({
    this.items = const [],
    this.unreadCount = 0,
    this.total = 0,
    this.page = 0,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
  });

  bool get hasMore => items.length < total;

  NotificationsState copyWith({
    List<AppNotification>? items,
    int? unreadCount,
    int? total,
    int? page,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    bool clearError = false,
  }) =>
      NotificationsState(
        items: items ?? this.items,
        unreadCount: unreadCount ?? this.unreadCount,
        total: total ?? this.total,
        page: page ?? this.page,
        isLoading: isLoading ?? this.isLoading,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
        error: clearError ? null : (error ?? this.error),
      );
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class NotificationsNotifier extends StateNotifier<NotificationsState> {
  NotificationsNotifier(this._ds) : super(const NotificationsState()) {
    refresh();
  }

  final NotificationsDataSource _ds;
  static const _limit = 20;

  /// (Re)load the first page, replacing the list. Used on init, pull-to-refresh
  /// and when a foreground push arrives.
  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, clearError: true);
    final result = await _ds.getNotifications(page: 1, limit: _limit);
    state = switch (result) {
      Success(:final data) => state.copyWith(
          items: data.notifications,
          unreadCount: data.unreadCount,
          total: data.total,
          page: 1,
          isLoading: false,
          clearError: true,
        ),
      Failure(:final exception) => state.copyWith(
          isLoading: false,
          error: exception is AppException
              ? exception.message
              : exception.toString(),
        ),
    };
  }

  /// Append the next page. No-op while a load is in flight or the list is
  /// already complete.
  Future<void> loadMore() async {
    if (state.isLoading || state.isLoadingMore || !state.hasMore) return;
    state = state.copyWith(isLoadingMore: true);
    final next = state.page + 1;
    final result = await _ds.getNotifications(page: next, limit: _limit);
    state = switch (result) {
      Success(:final data) => state.copyWith(
          items: [...state.items, ...data.notifications],
          unreadCount: data.unreadCount,
          total: data.total,
          page: next,
          isLoadingMore: false,
        ),
      Failure() => state.copyWith(isLoadingMore: false),
    };
  }

  /// Mark one notification read — optimistic, rolled back if the PATCH fails.
  Future<void> markRead(int id) async {
    final idx = state.items.indexWhere((n) => n.id == id);
    if (idx < 0 || state.items[idx].isRead) return;

    final optimistic = [...state.items];
    optimistic[idx] =
        optimistic[idx].copyWith(isRead: true, readAt: DateTime.now());
    state = state.copyWith(
      items: optimistic,
      unreadCount: (state.unreadCount - 1).clamp(0, 1 << 30),
    );

    final result = await _ds.markRead(id);
    if (result is Failure) {
      final revert = [...state.items];
      final i = revert.indexWhere((n) => n.id == id);
      if (i >= 0) revert[i] = revert[i].copyWith(isRead: false);
      state = state.copyWith(items: revert, unreadCount: state.unreadCount + 1);
    }
  }

  /// No bulk endpoint exists — loop over the currently-loaded unread ids.
  Future<void> markAllRead() async {
    final unread =
        state.items.where((n) => !n.isRead).map((n) => n.id).toList();
    for (final id in unread) {
      await markRead(id);
    }
  }

  /// A notification pushed live over the socket (`notification:new`). Prepend it
  /// and bump the unread count. Deduped by id so it can't clash with a parallel
  /// FCM-triggered refresh that already fetched the same row. A later refresh()
  /// reconciles total/unreadCount with the server, so transient drift is fine.
  void addRealtime(Map<String, dynamic> json) {
    final n = AppNotification.fromJson(json);
    if (n.id != 0 && state.items.any((e) => e.id == n.id)) return; // already have it
    state = state.copyWith(
      items: [n, ...state.items],
      total: state.total + 1,
      unreadCount: n.isRead ? state.unreadCount : state.unreadCount + 1,
    );
  }
}

// ── Providers ─────────────────────────────────────────────────────────────────

final notificationsDataSourceProvider = Provider<NotificationsDataSource>(
  (ref) => NotificationsDataSource(ref.watch(dioProvider)),
);

/// Single app-wide source of truth (NOT autoDispose): the home badge and the
/// inbox screen both watch it, and it must stay alive between visits so the
/// badge survives navigating away from the notifications screen.
final notificationsNotifierProvider =
    StateNotifierProvider<NotificationsNotifier, NotificationsState>(
  (ref) => NotificationsNotifier(ref.watch(notificationsDataSourceProvider)),
);

/// Unread count for the home bell badge.
final unreadNotificationCountProvider = Provider<int>(
  (ref) => ref.watch(notificationsNotifierProvider).unreadCount,
);
