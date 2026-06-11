import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:field_guard_re/core/errors/app_exception.dart';
import 'package:field_guard_re/core/router/app_routes.dart';
import 'package:field_guard_re/core/theme/app_responsive.dart';
import 'package:field_guard_re/features/dashboard/data/models/dashboard_summary.dart';
import 'package:field_guard_re/features/dashboard/presentation/providers/dashboard_provider.dart';
import 'package:field_guard_re/features/notifications/presentation/providers/notifications_provider.dart';
import 'package:field_guard_re/features/tasks/data/models/task_model.dart';

const _kGreen = Color(0xFF157347);

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(dashboardSummaryProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F3EF),
      body: RefreshIndicator(
        color: _kGreen,
        onRefresh: () async {
          ref.invalidate(dashboardSummaryProvider);
          ref.invalidate(homePendingTasksProvider);
          ref.invalidate(todayTasksProgressProvider);
          await Future.wait([
            ref.read(dashboardSummaryProvider.future),
            ref.read(homePendingTasksProvider.future),
            ref.read(todayTasksProgressProvider.future),
          ]);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Header(summary: async.valueOrNull),
              if (async.isLoading && !async.hasValue)
                const _SkeletonBody()
              else if (async.hasError && !async.hasValue)
                _ErrorBody(
                  message: async.error is AppException
                      ? (async.error as AppException).message
                      : (async.error?.toString() ?? 'Something went wrong'),
                  onRetry: () => ref.invalidate(dashboardSummaryProvider),
                )
              else if (async.hasValue)
                _Body(summary: async.value!),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Notification bell ──────────────────────────────────────────────────────────

/// Bell icon that opens the inbox, with an unread-count badge driven by
/// [unreadNotificationCountProvider]. Watching the provider here also kicks off
/// the first inbox fetch on home load.
class _NotificationBell extends ConsumerWidget {
  const _NotificationBell();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(unreadNotificationCountProvider);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          onPressed: () => context.push(AppRoutes.notifications),
          icon: Icon(
            Icons.notifications_none,
            color: Colors.white,
            size: AppResponsive.r(context, 26),
          ),
        ),
        if (unread > 0)
          Positioned(
            right: 6,
            top: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
              decoration: BoxDecoration(
                color: const Color(0xFFDC2626),
                borderRadius: BorderRadius.circular(9),
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              child: Text(
                unread > 99 ? '99+' : '$unread',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  height: 1.2,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

/// Brand green→teal gradient header. Greeting + user name, notifications bell,
/// avatar (→ profile tab), and the 3 task-bucket stat tiles inside.
class _Header extends StatelessWidget {
  final DashboardSummary? summary;

  const _Header({required this.summary});

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good Morning';
    if (h < 17) return 'Good Afternoon';
    if (h < 21) return 'Good Evening';
    return 'Good Night';
  }

  String _initials(String name) {
    final parts = name.trim().split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final hPad = AppResponsive.horizontalPad(context);
    final user = summary?.user;
    final name = user?.fullName.isNotEmpty == true ? user!.fullName : '—';

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF134E40), Color(0xFF1B5E4F), Color(0xFF0D9488)],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            hPad,
            AppResponsive.vGap(context, 12),
            hPad,
            AppResponsive.vGap(context, 18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_greeting()},',
                          style: TextStyle(
                            fontSize: AppResponsive.sp(context, 14),
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: AppResponsive.sp(context, 22),
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Notifications (with unread badge)
                  const _NotificationBell(),
                  // Avatar → Profile tab
                  GestureDetector(
                    onTap: () => context.go(AppRoutes.profile),
                    child: _Avatar(
                      imageUrl: user?.profileImage,
                      initials: _initials(name),
                      size: AppResponsive.r(context, 44),
                    ),
                  ),
                ],
              ),
              SizedBox(height: AppResponsive.vGap(context, 18)),
              _StatsRow(summary: summary),
            ],
          ),
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String? imageUrl;
  final String initials;
  final double size;

  const _Avatar({
    required this.imageUrl,
    required this.initials,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = imageUrl != null && imageUrl!.isNotEmpty;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.4),
          width: 1.5,
        ),
      ),
      padding: const EdgeInsets.all(2),
      child: CircleAvatar(
        backgroundColor: Colors.white.withValues(alpha: 0.18),
        backgroundImage: hasImage ? NetworkImage(imageUrl!) : null,
        child: hasImage
            ? null
            : Text(
                initials,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: size * 0.34,
                ),
              ),
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final DashboardSummary? summary;

  const _StatsRow({required this.summary});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatTile(
            label: 'Pending',
            value: summary?.pendingTotal,
            icon: Icons.schedule,
          ),
        ),
        SizedBox(width: AppResponsive.r(context, 10)),
        Expanded(
          child: _StatTile(
            label: 'Active',
            value: summary?.inProgressTotal,
            icon: Icons.play_arrow_rounded,
          ),
        ),
        SizedBox(width: AppResponsive.r(context, 10)),
        Expanded(
          child: _StatTile(
            label: 'Done',
            value: summary?.completedTotal,
            icon: Icons.check_circle_outline,
          ),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final int? value;
  final IconData icon;

  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppResponsive.r(context, 12),
        vertical: AppResponsive.r(context, 12),
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: Colors.white.withValues(alpha: 0.85),
            size: AppResponsive.r(context, 18),
          ),
          SizedBox(height: AppResponsive.r(context, 8)),
          Text(
            value == null ? '—' : '$value',
            style: TextStyle(
              fontSize: AppResponsive.sp(context, 22),
              fontWeight: FontWeight.bold,
              color: Colors.white,
              height: 1,
            ),
          ),
          SizedBox(height: AppResponsive.r(context, 4)),
          Text(
            label,
            style: TextStyle(
              fontSize: AppResponsive.sp(context, 12),
              color: Colors.white.withValues(alpha: 0.82),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Body ──────────────────────────────────────────────────────────────────────

class _Body extends ConsumerWidget {
  final DashboardSummary summary;

  const _Body({required this.summary});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hPad = AppResponsive.horizontalPad(context);
    final pendingAsync = ref.watch(homePendingTasksProvider);
    final todayAsync = ref.watch(todayTasksProgressProvider);

    final overallTotal = summary.pendingTotal +
        summary.inProgressTotal +
        summary.completedTotal;
    final overallRate = overallTotal == 0
        ? 0.0
        : summary.completedTotal / overallTotal;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        hPad,
        AppResponsive.vGap(context, 18),
        hPad,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Progress rings ──
          _ProgressCard(
            todayAsync: todayAsync,
            overallRate: overallRate,
            overallCompleted: summary.completedTotal,
            overallTotal: overallTotal,
          ),
          SizedBox(height: AppResponsive.vGap(context, 22)),

          // ── Active visit ──
          _SectionTitle(text: 'Active Visit'),
          SizedBox(height: AppResponsive.r(context, 10)),
          _ActiveVisitCard(task: summary.inProgressTask),

          // ── Pending tasks ──
          SizedBox(height: AppResponsive.vGap(context, 22)),
          _SectionTitle(
            text: 'Pending Tasks',
            count: summary.pendingTotal,
            trailing: _ViewAllLink(
              label: 'View all',
              onTap: () => context.go(AppRoutes.tasks),
            ),
          ),
          SizedBox(height: AppResponsive.r(context, 10)),
          _PendingSection(async: pendingAsync),

          // ── Recently completed ──
          if (summary.completedTask != null) ...[
            SizedBox(height: AppResponsive.vGap(context, 22)),
            _SectionTitle(text: 'Recently Completed'),
            SizedBox(height: AppResponsive.r(context, 10)),
            _CompactTaskCard(
              task: summary.completedTask!,
              accent: const Color(0xFF22C55E),
              accentBg: const Color(0xFFF0FDF4),
              icon: Icons.check_circle_outline,
              ctaLabel: 'View',
              muted: true,
            ),
          ],

          // ── Live team (managers/admins typically) ──
          if (summary.liveEmployeesCount > 0) ...[
            SizedBox(height: AppResponsive.vGap(context, 22)),
            _LiveTeamCard(count: summary.liveEmployeesCount),
          ],
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  final int? count;
  final Widget? trailing;

  const _SectionTitle({required this.text, this.count, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          text,
          style: TextStyle(
            fontSize: AppResponsive.sp(context, 17),
            fontWeight: FontWeight.w700,
            color: const Color(0xFF111827),
          ),
        ),
        if (count != null && count! > 0) ...[
          SizedBox(width: AppResponsive.r(context, 8)),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: AppResponsive.r(context, 8),
              vertical: 2,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                fontSize: AppResponsive.sp(context, 11.5),
                fontWeight: FontWeight.w700,
                color: const Color(0xFFB45309),
              ),
            ),
          ),
        ],
        const Spacer(),
        ?trailing,
      ],
    );
  }
}

class _ViewAllLink extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _ViewAllLink({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
        minimumSize: const Size(0, 32),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: AppResponsive.sp(context, 13),
              color: _kGreen,
              fontWeight: FontWeight.w600,
            ),
          ),
          Icon(
            Icons.arrow_forward,
            size: AppResponsive.r(context, 14),
            color: _kGreen,
          ),
        ],
      ),
    );
  }
}

// ── Active visit card ───────────────────────────────────────────────────────

class _ActiveVisitCard extends StatelessWidget {
  final TaskModel? task;

  const _ActiveVisitCard({required this.task});

  @override
  Widget build(BuildContext context) {
    if (task == null) return _ActiveVisitEmpty();
    return _ActiveVisitActive(task: task!);
  }
}

class _ActiveVisitActive extends StatelessWidget {
  final TaskModel task;

  const _ActiveVisitActive({required this.task});

  @override
  Widget build(BuildContext context) {
    final shopName = task.shop?.name;
    return GestureDetector(
      onTap: () => context.push(AppRoutes.taskDetailPath(task.id)),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1B5E4F), Color(0xFF2D9B83)],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1B5E4F).withValues(alpha: 0.25),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        padding: EdgeInsets.all(AppResponsive.r(context, 18)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'IN PROGRESS',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                          fontSize: AppResponsive.sp(context, 10),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: AppResponsive.r(context, 12)),
            Text(
              task.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: AppResponsive.sp(context, 18),
                height: 1.2,
              ),
            ),
            if (shopName != null && shopName.isNotEmpty) ...[
              SizedBox(height: AppResponsive.r(context, 6)),
              Row(
                children: [
                  Icon(
                    Icons.storefront_outlined,
                    color: Colors.white.withValues(alpha: 0.85),
                    size: AppResponsive.r(context, 16),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      shopName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.92),
                        fontSize: AppResponsive.sp(context, 13),
                      ),
                    ),
                  ),
                ],
              ),
            ],
            SizedBox(height: AppResponsive.r(context, 14)),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () =>
                        context.push(AppRoutes.taskDetailPath(task.id)),
                    icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                    label: const Text(
                      'Open Task',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: _kGreen,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: EdgeInsets.symmetric(
                        vertical: AppResponsive.r(context, 12),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: AppResponsive.r(context, 10)),
                OutlinedButton.icon(
                  onPressed: () => context.go(AppRoutes.route),
                  icon: const Icon(Icons.navigation_outlined, size: 18),
                  label: const Text('Route'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(
                      color: Colors.white.withValues(alpha: 0.55),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: EdgeInsets.symmetric(
                      horizontal: AppResponsive.r(context, 14),
                      vertical: AppResponsive.r(context, 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ActiveVisitEmpty extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(AppResponsive.r(context, 20)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: AppResponsive.r(context, 44),
            height: AppResponsive.r(context, 44),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.coffee_outlined,
              color: const Color(0xFF6B7280),
              size: AppResponsive.r(context, 22),
            ),
          ),
          SizedBox(height: AppResponsive.r(context, 10)),
          Text(
            'No active visit',
            style: TextStyle(
              fontSize: AppResponsive.sp(context, 16),
              fontWeight: FontWeight.bold,
              color: const Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Start a task to begin your visit.',
            style: TextStyle(
              fontSize: AppResponsive.sp(context, 13),
              color: const Color(0xFF6B7280),
            ),
          ),
          SizedBox(height: AppResponsive.r(context, 12)),
          OutlinedButton.icon(
            onPressed: () => context.go(AppRoutes.tasks),
            icon: const Icon(Icons.list_alt, size: 18),
            label: const Text('View Tasks'),
            style: OutlinedButton.styleFrom(
              foregroundColor: _kGreen,
              side: const BorderSide(color: _kGreen),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: EdgeInsets.symmetric(
                horizontal: AppResponsive.r(context, 16),
                vertical: AppResponsive.r(context, 10),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Compact task card (Next up / Recently completed) ────────────────────────

class _CompactTaskCard extends StatelessWidget {
  final TaskModel task;
  final Color accent;
  final Color accentBg;
  final IconData icon;
  final String ctaLabel;
  final bool muted;

  const _CompactTaskCard({
    required this.task,
    required this.accent,
    required this.accentBg,
    required this.icon,
    required this.ctaLabel,
    this.muted = false,
  });

  @override
  Widget build(BuildContext context) {
    final shopName = task.shop?.name;
    return GestureDetector(
      onTap: () => context.push(AppRoutes.taskDetailPath(task.id)),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        padding: EdgeInsets.all(AppResponsive.r(context, 14)),
        child: Row(
          children: [
            Container(
              width: AppResponsive.r(context, 42),
              height: AppResponsive.r(context, 42),
              decoration: BoxDecoration(
                color: accentBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: accent,
                size: AppResponsive.r(context, 22),
              ),
            ),
            SizedBox(width: AppResponsive.r(context, 12)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: AppResponsive.sp(context, 14.5),
                      fontWeight: FontWeight.w700,
                      color: muted
                          ? const Color(0xFF6B7280)
                          : const Color(0xFF111827),
                      decoration: muted ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  if (shopName != null && shopName.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      shopName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: AppResponsive.sp(context, 12),
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(width: AppResponsive.r(context, 8)),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: AppResponsive.r(context, 10),
                vertical: AppResponsive.r(context, 6),
              ),
              decoration: BoxDecoration(
                color: accentBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                ctaLabel,
                style: TextStyle(
                  fontSize: AppResponsive.sp(context, 12),
                  fontWeight: FontWeight.w700,
                  color: accent,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Pending tasks section ────────────────────────────────────────────────────

/// Renders the full pending-tasks list with three states: shimmering skeleton
/// rows while loading, a friendly "all caught up" empty state, or a stack of
/// animated [_PendingTaskRow]s. Errors fall back to a small inline message so a
/// failed fetch doesn't blank out the rest of the home screen.
class _PendingSection extends StatelessWidget {
  final AsyncValue<List<TaskModel>> async;

  const _PendingSection({required this.async});

  @override
  Widget build(BuildContext context) {
    if (async.isLoading && !async.hasValue) {
      return Column(
        children: List.generate(
          3,
          (i) => Padding(
            padding: EdgeInsets.only(bottom: AppResponsive.r(context, 10)),
            child: const _PendingSkeletonRow(),
          ),
        ),
      );
    }
    if (async.hasError && !async.hasValue) {
      return Container(
        padding: EdgeInsets.all(AppResponsive.r(context, 14)),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF2F2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFFECACA)),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: Color(0xFFB91C1C), size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Could not load pending tasks',
                style: TextStyle(
                  fontSize: AppResponsive.sp(context, 12.5),
                  color: const Color(0xFF7F1D1D),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }
    final tasks = async.valueOrNull ?? const <TaskModel>[];
    if (tasks.isEmpty) return const _PendingEmpty();
    return Column(
      children: [
        for (int i = 0; i < tasks.length; i++) ...[
          if (i > 0) SizedBox(height: AppResponsive.r(context, 10)),
          _PendingTaskRow(task: tasks[i], index: i),
        ],
      ],
    );
  }
}

/// A single pending task row — clean white card with a coloured status dot,
/// title + shop/due meta, priority pill, and a chevron. Staggered fade+slide
/// entrance (delay by [index], capped) and a press-scale on tap.
class _PendingTaskRow extends StatefulWidget {
  final TaskModel task;
  final int index;

  const _PendingTaskRow({required this.task, required this.index});

  @override
  State<_PendingTaskRow> createState() => _PendingTaskRowState();
}

class _PendingTaskRowState extends State<_PendingTaskRow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entry;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _entry = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    _fade = CurvedAnimation(parent: _entry, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _entry, curve: Curves.easeOutCubic));

    final steps = widget.index.clamp(0, 10);
    Future.delayed(Duration(milliseconds: steps * 55), () {
      if (mounted) _entry.forward();
    });
  }

  @override
  void dispose() {
    _entry.dispose();
    super.dispose();
  }

  String? _subtitle() {
    final shop = widget.task.shop?.name;
    final due = widget.task.dueDate;
    final parts = <String>[];
    if (shop != null && shop.isNotEmpty) parts.add(shop);
    if (due != null) {
      parts.add(_formatDue(due.toLocal()));
    }
    return parts.isEmpty ? null : parts.join(' · ');
  }

  static String _formatDue(DateTime due) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return 'Due ${due.day} ${months[due.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    final task = widget.task;
    final sub = _subtitle();
    final (priorityBg, priorityFg) = _priorityColors(task.priority);

    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: GestureDetector(
          onTapDown: (_) => setState(() => _pressed = true),
          onTapUp: (_) {
            setState(() => _pressed = false);
            context.push(AppRoutes.taskDetailPath(task.id));
          },
          onTapCancel: () => setState(() => _pressed = false),
          child: AnimatedScale(
            scale: _pressed ? 0.97 : 1.0,
            duration: const Duration(milliseconds: 120),
            curve: Curves.easeOut,
            child: Container(
              padding: EdgeInsets.all(AppResponsive.r(context, 14)),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: AppResponsive.r(context, 10),
                    height: AppResponsive.r(context, 10),
                    decoration: const BoxDecoration(
                      color: Color(0xFFF59E0B),
                      shape: BoxShape.circle,
                    ),
                  ),
                  SizedBox(width: AppResponsive.r(context, 12)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: AppResponsive.sp(context, 14.5),
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF111827),
                          ),
                        ),
                        if (sub != null) ...[
                          const SizedBox(height: 3),
                          Text(
                            sub,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: AppResponsive.sp(context, 12),
                              color: const Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  SizedBox(width: AppResponsive.r(context, 8)),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppResponsive.r(context, 8),
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: priorityBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      task.priority,
                      style: TextStyle(
                        fontSize: AppResponsive.sp(context, 10.5),
                        fontWeight: FontWeight.w700,
                        color: priorityFg,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                  SizedBox(width: AppResponsive.r(context, 6)),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: AppResponsive.r(context, 20),
                    color: const Color(0xFF9CA3AF),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static (Color bg, Color fg) _priorityColors(String p) => switch (p) {
    'HIGH' => (const Color(0xFFFEE2E2), const Color(0xFFDC2626)),
    'LOW' => (const Color(0xFFF0FDF4), const Color(0xFF16A34A)),
    _ => (const Color(0xFFFFF7ED), const Color(0xFFEA580C)),
  };
}

class _PendingSkeletonRow extends StatefulWidget {
  const _PendingSkeletonRow();

  @override
  State<_PendingSkeletonRow> createState() => _PendingSkeletonRowState();
}

class _PendingSkeletonRowState extends State<_PendingSkeletonRow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, _) {
        final c = Color.lerp(
          const Color(0xFFE5E7EB),
          const Color(0xFFF3F4F6),
          _ctrl.value,
        )!;
        return Container(
          padding: EdgeInsets.all(AppResponsive.r(context, 14)),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: AppResponsive.r(context, 10),
                height: AppResponsive.r(context, 10),
                decoration: BoxDecoration(color: c, shape: BoxShape.circle),
              ),
              SizedBox(width: AppResponsive.r(context, 12)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: AppResponsive.r(context, 12),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: c,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    SizedBox(height: AppResponsive.r(context, 6)),
                    Container(
                      height: AppResponsive.r(context, 10),
                      width: AppResponsive.r(context, 140),
                      decoration: BoxDecoration(
                        color: c,
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: AppResponsive.r(context, 8)),
              Container(
                width: AppResponsive.r(context, 40),
                height: AppResponsive.r(context, 18),
                decoration: BoxDecoration(
                  color: c,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PendingEmpty extends StatelessWidget {
  const _PendingEmpty();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: AppResponsive.r(context, 18),
        vertical: AppResponsive.r(context, 22),
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFBBF7D0)),
      ),
      child: Row(
        children: [
          Container(
            width: AppResponsive.r(context, 40),
            height: AppResponsive.r(context, 40),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_rounded, color: _kGreen, size: 24),
          ),
          SizedBox(width: AppResponsive.r(context, 12)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'All caught up!',
                  style: TextStyle(
                    fontSize: AppResponsive.sp(context, 15),
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF064E3B),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'No pending tasks right now.',
                  style: TextStyle(
                    fontSize: AppResponsive.sp(context, 12.5),
                    color: const Color(0xFF065F46),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LiveTeamCard extends StatelessWidget {
  final int count;

  const _LiveTeamCard({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppResponsive.r(context, 14)),
      decoration: BoxDecoration(
        color: const Color(0xFFEFFCF6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFBCE9D5)),
      ),
      child: Row(
        children: [
          Container(
            width: AppResponsive.r(context, 10),
            height: AppResponsive.r(context, 10),
            decoration: const BoxDecoration(
              color: _kGreen,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: AppResponsive.r(context, 10)),
          Expanded(
            child: Text(
              count == 1
                  ? '1 teammate is sharing live location'
                  : '$count teammates are sharing live location',
              style: TextStyle(
                fontSize: AppResponsive.sp(context, 13.5),
                color: const Color(0xFF064E3B),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Progress rings card ───────────────────────────────────────────────────────

class _ProgressCard extends StatelessWidget {
  final AsyncValue<TodayTaskStats> todayAsync;
  final double overallRate;
  final int overallCompleted;
  final int overallTotal;

  const _ProgressCard({
    required this.todayAsync,
    required this.overallRate,
    required this.overallCompleted,
    required this.overallTotal,
  });

  // Parse "2026-05-30" → "Saturday, 30 May"
  String _formatDate(String isoDate) {
    try {
      final d = DateTime.parse(isoDate);
      const days = [
        'Monday', 'Tuesday', 'Wednesday', 'Thursday',
        'Friday', 'Saturday', 'Sunday',
      ];
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
      ];
      return '${days[d.weekday - 1]}, ${d.day} ${months[d.month - 1]}';
    } catch (_) {
      return isoDate;
    }
  }

  @override
  Widget build(BuildContext context) {
    return todayAsync.when(
      loading: () => _ProgressCardShell(
        dateLabel: '',
        todayRate: 0,
        todayCompleted: 0,
        todayTotal: 0,
        overallRate: overallRate,
        overallCompleted: overallCompleted,
        overallTotal: overallTotal,
        loading: true,
      ),
      error: (_, __) => _ProgressCardShell(
        dateLabel: '',
        todayRate: 0,
        todayCompleted: 0,
        todayTotal: 0,
        overallRate: overallRate,
        overallCompleted: overallCompleted,
        overallTotal: overallTotal,
        loading: false,
      ),
      data: (stats) => _ProgressCardShell(
        dateLabel: _formatDate(stats.date),
        todayRate: stats.completionRate,
        todayCompleted: stats.completedTotal,
        todayTotal: stats.totalCount,
        overallRate: overallRate,
        overallCompleted: overallCompleted,
        overallTotal: overallTotal,
        loading: false,
      ),
    );
  }
}

class _ProgressCardShell extends StatelessWidget {
  final String dateLabel;
  final double todayRate;
  final int todayCompleted;
  final int todayTotal;
  final double overallRate;
  final int overallCompleted;
  final int overallTotal;
  final bool loading;

  const _ProgressCardShell({
    required this.dateLabel,
    required this.todayRate,
    required this.todayCompleted,
    required this.todayTotal,
    required this.overallRate,
    required this.overallCompleted,
    required this.overallTotal,
    required this.loading,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (dateLabel.isNotEmpty) ...[
          Row(
            children: [
              const Icon(Icons.calendar_today_outlined, size: 13, color: Color(0xFF6B7280)),
              const SizedBox(width: 5),
              Text(
                dateLabel,
                style: TextStyle(
                  fontSize: AppResponsive.sp(context, 12.5),
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF6B7280),
                ),
              ),
            ],
          ),
          SizedBox(height: AppResponsive.r(context, 10)),
        ],
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF134E40), Color(0xFF1B5E4F), Color(0xFF1E7A60)],
              ),
            ),
            child: Stack(
              children: [
                // Decorative blobs
                Positioned(
                  left: -20,
                  top: -20,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.06),
                    ),
                  ),
                ),
                Positioned(
                  left: 20,
                  bottom: -30,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.04),
                    ),
                  ),
                ),
                // Ring content
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppResponsive.r(context, 24),
                    vertical: AppResponsive.r(context, 24),
                  ),
                  child: IntrinsicHeight(
                    child: Row(
                      children: [
                        Expanded(
                          child: _RingSection(
                            label: 'Today',
                            rate: loading ? 0 : todayRate,
                            completed: todayCompleted,
                            total: todayTotal,
                            loading: loading,
                          ),
                        ),
                        VerticalDivider(
                          width: AppResponsive.r(context, 32),
                          thickness: 1,
                          color: Colors.white.withValues(alpha: 0.18),
                        ),
                        Expanded(
                          child: _RingSection(
                            label: 'Overall',
                            rate: overallRate,
                            completed: overallCompleted,
                            total: overallTotal,
                            loading: false,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _RingSection extends StatelessWidget {
  final String label;
  final double rate;
  final int completed;
  final int total;
  final bool loading;

  const _RingSection({
    required this.label,
    required this.rate,
    required this.completed,
    required this.total,
    required this.loading,
  });

  @override
  Widget build(BuildContext context) {
    final ringSize = AppResponsive.r(context, 96);
    final pct = (rate * 100).round();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: ringSize,
          height: ringSize,
          child: CustomPaint(
            painter: _RingPainter(
              progress: loading ? 0 : rate,
              trackColor: Colors.white.withValues(alpha: 0.15),
              progressColor: const Color(0xFF4ADE80),
              strokeWidth: ringSize * 0.09,
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    loading ? '—' : '$pct%',
                    style: TextStyle(
                      fontSize: AppResponsive.sp(context, 18),
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    loading ? '' : '$completed/$total',
                    style: TextStyle(
                      fontSize: AppResponsive.sp(context, 11),
                      color: Colors.white.withValues(alpha: 0.75),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        SizedBox(height: AppResponsive.r(context, 10)),
        Text(
          label,
          style: TextStyle(
            fontSize: AppResponsive.sp(context, 13),
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color trackColor;
  final Color progressColor;
  final double strokeWidth;

  const _RingPainter({
    required this.progress,
    required this.trackColor,
    required this.progressColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Track (full circle)
    canvas.drawArc(
      rect,
      0,
      2 * math.pi,
      false,
      Paint()
        ..color = trackColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round,
    );

    if (progress <= 0) return;

    // Progress arc — starts from top (-π/2), sweeps clockwise
    canvas.drawArc(
      rect,
      -math.pi / 2,
      2 * math.pi * progress.clamp(0.0, 1.0),
      false,
      Paint()
        ..color = progressColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress ||
      old.trackColor != trackColor ||
      old.progressColor != progressColor ||
      old.strokeWidth != strokeWidth;
}

// ── Skeleton + error ──────────────────────────────────────────────────────────

class _SkeletonBody extends StatefulWidget {
  const _SkeletonBody();

  @override
  State<_SkeletonBody> createState() => _SkeletonBodyState();
}

class _SkeletonBodyState extends State<_SkeletonBody>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hPad = AppResponsive.horizontalPad(context);
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, _) {
        final c = Color.lerp(
          const Color(0xFFE5E7EB),
          const Color(0xFFF3F4F6),
          _ctrl.value,
        )!;
        return Padding(
          padding: EdgeInsets.fromLTRB(
            hPad,
            AppResponsive.vGap(context, 18),
            hPad,
            0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _bone(c, height: 14, width: 110, radius: 7),
              const SizedBox(height: 12),
              _bone(c, height: AppResponsive.r(context, 150), radius: 18),
              const SizedBox(height: 22),
              _bone(c, height: 14, width: 90, radius: 7),
              const SizedBox(height: 12),
              _bone(c, height: AppResponsive.r(context, 70), radius: 14),
            ],
          ),
        );
      },
    );
  }

  Widget _bone(
    Color c, {
    required double height,
    double? width,
    double radius = 8,
  }) => Container(
    height: height,
    width: width ?? double.infinity,
    decoration: BoxDecoration(
      color: c,
      borderRadius: BorderRadius.circular(radius),
    ),
  );
}

class _ErrorBody extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorBody({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final hPad = AppResponsive.horizontalPad(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        hPad,
        AppResponsive.vGap(context, 24),
        hPad,
        0,
      ),
      child: Container(
        padding: EdgeInsets.all(AppResponsive.r(context, 18)),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF2F2),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFFECACA)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.error_outline, color: Color(0xFFB91C1C)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Could not load dashboard',
                    style: TextStyle(
                      fontSize: AppResponsive.sp(context, 14),
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF7F1D1D),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              message,
              style: TextStyle(
                fontSize: AppResponsive.sp(context, 12.5),
                color: const Color(0xFF7F1D1D),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFB91C1C),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 10,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
