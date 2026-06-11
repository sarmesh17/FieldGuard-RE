import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:field_guard_re/core/services/push_notification_service.dart';
import 'package:field_guard_re/core/theme/app_colors.dart';
import 'package:field_guard_re/core/theme/app_responsive.dart';
import 'package:field_guard_re/core/theme/app_text_styles.dart';
import 'package:field_guard_re/features/notifications/data/models/app_notification.dart';
import 'package:field_guard_re/features/notifications/presentation/providers/notifications_provider.dart';
import 'components/notification_card.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  final _scrollController = ScrollController();
  bool _unreadOnly = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // Pull fresh on open — the provider may hold a stale list from app launch.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(notificationsNotifierProvider.notifier).refresh();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 300) {
      ref.read(notificationsNotifierProvider.notifier).loadMore();
    }
  }

  Future<void> _onTapNotification(AppNotification n) async {
    final notifier = ref.read(notificationsNotifierProvider.notifier);
    await notifier.markRead(n.id);
    // Reuse the exact push deep-link routing (TASK_ASSIGNED → task detail).
    if (n.data.isNotEmpty) {
      PushNotificationService.instance.openFromData(n.data);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hPad = AppResponsive.horizontalPad(context);
    final state = ref.watch(notificationsNotifierProvider);

    final visible = _unreadOnly
        ? state.items.where((n) => !n.isRead).toList()
        : state.items;

    return Scaffold(
      backgroundColor: AppColors.backgroundBeige,
      appBar: AppBar(
        backgroundColor: AppColors.cardWhite,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primaryGreen),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Notifications',
          style: AppTextStyles.heading1R(context).copyWith(
            fontSize: AppResponsive.sp(context, 20),
            fontWeight: FontWeight.bold,
            color: AppColors.primaryGreen,
          ),
        ),
        centerTitle: false,
        actions: [
          if (state.unreadCount > 0)
            TextButton(
              onPressed: () =>
                  ref.read(notificationsNotifierProvider.notifier).markAllRead(),
              child: Text(
                'Mark all read',
                style: AppTextStyles.linkR(context).copyWith(
                  color: AppColors.primaryGreen,
                  fontSize: AppResponsive.sp(context, 13),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // All / Unread filter.
          Container(
            color: AppColors.cardWhite,
            padding: EdgeInsets.fromLTRB(hPad, 8, hPad, 16),
            child: Row(
              children: [
                _FilterChip(
                  label: 'All',
                  selected: !_unreadOnly,
                  onTap: () => setState(() => _unreadOnly = false),
                ),
                const SizedBox(width: 12),
                _FilterChip(
                  label: state.unreadCount > 0
                      ? 'Unread (${state.unreadCount})'
                      : 'Unread',
                  selected: _unreadOnly,
                  onTap: () => setState(() => _unreadOnly = true),
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              color: AppColors.primaryGreen,
              onRefresh: () =>
                  ref.read(notificationsNotifierProvider.notifier).refresh(),
              child: _buildBody(context, state, visible, hPad),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    NotificationsState state,
    List<AppNotification> visible,
    double hPad,
  ) {
    // First load with nothing yet.
    if (state.isLoading && state.items.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primaryGreen),
      );
    }

    // Hard error with nothing to show.
    if (state.error != null && state.items.isEmpty) {
      return _MessageState(
        scrollable: true,
        icon: Icons.cloud_off_rounded,
        title: 'Couldn’t load notifications',
        subtitle: state.error!,
        actionLabel: 'Retry',
        onAction: () =>
            ref.read(notificationsNotifierProvider.notifier).refresh(),
      );
    }

    if (visible.isEmpty) {
      return _MessageState(
        scrollable: true,
        icon: Icons.notifications_off_outlined,
        title: _unreadOnly ? 'No unread notifications' : 'No notifications yet',
        subtitle: _unreadOnly
            ? "You're all caught up."
            : 'Task and account updates will show up here.',
      );
    }

    return ListView.separated(
      controller: _scrollController,
      padding: EdgeInsets.all(hPad),
      itemCount: visible.length + (state.isLoadingMore ? 1 : 0),
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        if (i >= visible.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: CircularProgressIndicator(color: AppColors.primaryGreen),
            ),
          );
        }
        final n = visible[i];
        final v = _visual(n);
        return NotificationCard(
          icon: v.icon,
          iconColor: v.color,
          iconBgColor: v.bg,
          borderColor: v.color,
          title: n.title.isNotEmpty ? n.title : 'Notification',
          description: n.body,
          time: _relativeTime(n.createdAt),
          isUnread: !n.isRead,
          onTap: () => _onTapNotification(n),
        );
      },
    );
  }

  // Icon/colour by notification kind.
  ({IconData icon, Color color, Color bg}) _visual(AppNotification n) {
    switch (n.kind) {
      case 'TASK_ASSIGNED':
        return (
          icon: Icons.assignment_outlined,
          color: const Color(0xFF157347),
          bg: const Color(0xFFD1FAE5),
        );
      case 'CHEQUE_RECEIVED':
        return (
          icon: Icons.payments_outlined,
          color: const Color(0xFFF59E0B),
          bg: const Color(0xFFFEF3C7),
        );
      default:
        return (
          icon: Icons.notifications_none,
          color: AppColors.textGray,
          bg: const Color(0xFFF3F4F6),
        );
    }
  }

  String _relativeTime(DateTime dt) {
    final d = DateTime.now().difference(dt.toLocal());
    if (d.inSeconds < 60) return 'Just now';
    if (d.inMinutes < 60) return '${d.inMinutes}m ago';
    if (d.inHours < 24) return '${d.inHours}h ago';
    if (d.inDays < 7) return '${d.inDays}d ago';
    return DateFormat('d MMM').format(dt.toLocal());
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(
        label,
        style: AppTextStyles.labelR(context).copyWith(
          fontWeight: FontWeight.w600,
          color: selected ? AppColors.buttonTextWhite : AppColors.textGray,
          fontSize: AppResponsive.sp(context, 13),
        ),
      ),
      selected: selected,
      selectedColor: AppColors.primaryGreen,
      backgroundColor: AppColors.backgroundBeige,
      side: selected
          ? BorderSide.none
          : const BorderSide(color: AppColors.inputBorder),
      onSelected: (_) => onTap(),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      labelPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
    );
  }
}

/// Centred empty/error placeholder that still scrolls so pull-to-refresh works.
class _MessageState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool scrollable;

  const _MessageState({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
    this.scrollable = false,
  });

  @override
  Widget build(BuildContext context) {
    final content = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 56, color: AppColors.textLight),
        const SizedBox(height: 16),
        Text(
          title,
          textAlign: TextAlign.center,
          style: AppTextStyles.heading1R(context).copyWith(
            fontSize: AppResponsive.sp(context, 16),
            fontWeight: FontWeight.w700,
            color: AppColors.textGray,
          ),
        ),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Text(
            subtitle,
            textAlign: TextAlign.center,
            style: AppTextStyles.subtitleR(context).copyWith(
              fontSize: AppResponsive.sp(context, 13),
              color: AppColors.textLight,
            ),
          ),
        ),
        if (actionLabel != null) ...[
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: onAction,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
              foregroundColor: AppColors.buttonTextWhite,
            ),
            child: Text(actionLabel!),
          ),
        ],
      ],
    );

    if (!scrollable) return Center(child: content);

    // Wrap so RefreshIndicator has a scrollable even when "empty".
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 48),
              child: content,
            ),
          ),
        ),
      ),
    );
  }
}
