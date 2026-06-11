import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../../core/router/app_routes.dart';
import '../../../../../core/theme/app_responsive.dart';
import '../../../../tasks/data/models/task_model.dart';
import '../../../../tasks/presentation/providers/tasks_provider.dart';

/// Today's tasks ordered by status (active first) then by due time.
/// Driven by `tasksNotifierProvider`; tapping an item opens its detail screen.
class ScheduleList extends ConsumerWidget {
  const ScheduleList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // The full-list state still drives loading / error rows; the actual data
    // shown is the today-filtered, status-sorted list from the shared
    // `todayTasksProvider` (which the AppBar counter also reads).
    final state = ref.watch(tasksNotifierProvider);
    return switch (state) {
      TasksInitial() || TasksLoading() => const _LoadingRow(),
      TasksError(:final message) => _ErrorRow(
        message: message,
        onRetry: () => ref.read(tasksNotifierProvider.notifier).fetch(),
      ),
      TasksSuccess() => _ScheduleContent(tasks: ref.watch(todayTasksProvider)),
    };
  }
}

// ── Content states ────────────────────────────────────────────────────────────

class _ScheduleContent extends StatelessWidget {
  final List<TaskModel> tasks;
  const _ScheduleContent({required this.tasks});

  @override
  Widget build(BuildContext context) {
    if (tasks.isEmpty) return const _EmptyRow();
    return Column(
      children: [
        for (var i = 0; i < tasks.length; i++)
          _ScheduleItem(task: tasks[i], index: i + 1),
      ],
    );
  }
}

class _ScheduleItem extends StatelessWidget {
  final TaskModel task;
  final int index;

  const _ScheduleItem({required this.task, required this.index});

  @override
  Widget build(BuildContext context) {
    final theme = _ThemeFor(task.status);
    final dueLocal = task.dueDate!.toLocal();
    final timeText = DateFormat('h:mm a').format(dueLocal);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push(AppRoutes.taskDetailPath(task.id)),
        child: Container(
          margin: EdgeInsets.symmetric(
            horizontal: AppResponsive.horizontalPad(context),
            vertical: AppResponsive.r(context, 6),
          ),
          padding: EdgeInsets.all(AppResponsive.r(context, 16)),
          decoration: BoxDecoration(
            color: theme.background,
            borderRadius: BorderRadius.circular(16),
            border: theme.borderColor == null
                ? null
                : Border.all(color: theme.borderColor!, width: 2),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: AppResponsive.r(context, 20),
                backgroundColor: theme.avatarBackground,
                child: theme.avatarIcon != null
                    ? Icon(
                        theme.avatarIcon,
                        color: theme.avatarFg,
                        size: AppResponsive.r(context, 18),
                      )
                    : Text(
                        '$index',
                        style: TextStyle(
                          color: theme.avatarFg,
                          fontWeight: FontWeight.bold,
                          fontSize: AppResponsive.sp(context, 14),
                        ),
                      ),
              ),
              SizedBox(width: AppResponsive.r(context, 14)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: AppResponsive.sp(context, 16),
                        fontWeight: theme.titleStrike
                            ? FontWeight.w500
                            : FontWeight.bold,
                        color: theme.titleColor,
                        decoration: theme.titleStrike
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(
                          theme.subtitleIcon,
                          size: AppResponsive.r(context, 14),
                          color: theme.subtitleColor,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            theme.subtitle(timeText),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: AppResponsive.sp(context, 12),
                              color: theme.subtitleColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: theme.chevronColor,
                size: AppResponsive.r(context, 24),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Visual themes per status ──────────────────────────────────────────────────

class _ThemeFor {
  final Color background;
  final Color? borderColor;
  final Color avatarBackground;
  final Color avatarFg;
  final IconData? avatarIcon;
  final Color titleColor;
  final bool titleStrike;
  final IconData subtitleIcon;
  final Color subtitleColor;
  final Color chevronColor;
  final String Function(String time) subtitle;

  factory _ThemeFor(String status) {
    switch (status) {
      case 'IN_PROGRESS':
        return _ThemeFor._(
          background: Colors.white,
          borderColor: const Color(0xFF157347),
          avatarBackground: const Color(0xFF157347),
          avatarFg: Colors.white,
          avatarIcon: Icons.directions_walk,
          titleColor: const Color(0xFF111827),
          titleStrike: false,
          subtitleIcon: Icons.timelapse,
          subtitleColor: const Color(0xFF157347),
          chevronColor: const Color(0xFF157347),
          subtitle: (t) => 'In progress · $t',
        );
      case 'COMPLETED':
        return _ThemeFor._(
          background: const Color(0xFFD1FADF),
          borderColor: null,
          avatarBackground: Colors.white,
          avatarFg: const Color(0xFF157347),
          avatarIcon: Icons.check,
          titleColor: const Color(0xFF6B7280),
          titleStrike: true,
          subtitleIcon: Icons.check_circle,
          subtitleColor: const Color(0xFF157347),
          chevronColor: const Color(0xFF6B7280),
          subtitle: (t) => 'Completed',
        );
      case 'CANCELLED':
        return _ThemeFor._(
          background: const Color(0xFFFEE2E2),
          borderColor: null,
          avatarBackground: Colors.white,
          avatarFg: const Color(0xFFB91C1C),
          avatarIcon: Icons.close,
          titleColor: const Color(0xFF6B7280),
          titleStrike: true,
          subtitleIcon: Icons.cancel_outlined,
          subtitleColor: const Color(0xFFB91C1C),
          chevronColor: const Color(0xFF6B7280),
          subtitle: (t) => 'Cancelled',
        );
      default: // PENDING
        return _ThemeFor._(
          background: Colors.white,
          borderColor: const Color(0xFFD1FADF),
          avatarBackground: const Color(0xFFD1FADF),
          avatarFg: const Color(0xFF157347),
          avatarIcon: null,
          titleColor: const Color(0xFF111827),
          titleStrike: false,
          subtitleIcon: Icons.schedule,
          subtitleColor: const Color(0xFF6B7280),
          chevronColor: const Color(0xFF157347),
          subtitle: (t) => 'Due $t',
        );
    }
  }

  _ThemeFor._({
    required this.background,
    required this.borderColor,
    required this.avatarBackground,
    required this.avatarFg,
    required this.avatarIcon,
    required this.titleColor,
    required this.titleStrike,
    required this.subtitleIcon,
    required this.subtitleColor,
    required this.chevronColor,
    required this.subtitle,
  });
}

// ── Loading / empty / error rows ──────────────────────────────────────────────

class _LoadingRow extends StatelessWidget {
  const _LoadingRow();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppResponsive.horizontalPad(context),
        vertical: AppResponsive.r(context, 12),
      ),
      child: Container(
        height: AppResponsive.r(context, 64),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: SizedBox(
            width: AppResponsive.r(context, 22),
            height: AppResponsive.r(context, 22),
            child: const CircularProgressIndicator(
              strokeWidth: 2.4,
              color: Color(0xFF157347),
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyRow extends StatelessWidget {
  const _EmptyRow();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppResponsive.horizontalPad(context),
        vertical: AppResponsive.r(context, 8),
      ),
      child: Container(
        padding: EdgeInsets.all(AppResponsive.r(context, 16)),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.event_available_outlined,
              color: Color(0xFF6B7280),
            ),
            SizedBox(width: AppResponsive.r(context, 12)),
            Expanded(
              child: Text(
                'No tasks scheduled for today',
                style: TextStyle(
                  fontSize: AppResponsive.sp(context, 14),
                  color: const Color(0xFF6B7280),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorRow extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorRow({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppResponsive.horizontalPad(context),
        vertical: AppResponsive.r(context, 8),
      ),
      child: Container(
        padding: EdgeInsets.all(AppResponsive.r(context, 14)),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF2F2),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFFECACA)),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: Color(0xFFB91C1C)),
            SizedBox(width: AppResponsive.r(context, 10)),
            Expanded(
              child: Text(
                message,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: AppResponsive.sp(context, 12),
                  color: const Color(0xFF7F1D1D),
                ),
              ),
            ),
            TextButton(
              onPressed: onRetry,
              child: Text(
                'Retry',
                style: TextStyle(
                  color: const Color(0xFFB91C1C),
                  fontWeight: FontWeight.bold,
                  fontSize: AppResponsive.sp(context, 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
