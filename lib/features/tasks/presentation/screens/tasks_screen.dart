import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:field_guard_re/core/router/app_routes.dart';
import 'package:field_guard_re/core/theme/app_responsive.dart';
import 'package:field_guard_re/features/tasks/data/models/task_model.dart';
import 'package:field_guard_re/features/tasks/presentation/providers/tasks_provider.dart';

// ── Status filter definition ──────────────────────────────────────────────────

class _Filter {
  final String label;
  final String? value;
  const _Filter(this.label, this.value);
}

const _filters = [
  _Filter('All', null),
  _Filter('Pending', 'PENDING'),
  _Filter('In Progress', 'IN_PROGRESS'),
  _Filter('Completed', 'COMPLETED'),
  _Filter('Cancelled', 'CANCELLED'),
];

// ── Screen ────────────────────────────────────────────────────────────────────

class TasksScreen extends ConsumerStatefulWidget {
  const TasksScreen({super.key});

  @override
  ConsumerState<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends ConsumerState<TasksScreen> {
  int _selectedFilter = 0;

  void _applyFilter(int index) {
    if (_selectedFilter == index) return;
    setState(() => _selectedFilter = index);
    ref
        .read(tasksNotifierProvider.notifier)
        .fetch(status: _filters[index].value);
  }

  Future<void> _refresh() async {
    await ref
        .read(tasksNotifierProvider.notifier)
        .fetch(status: _filters[_selectedFilter].value);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(tasksNotifierProvider);
    final count = state is TasksSuccess ? state.tasks.length : null;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F3EF),
      body: Column(
        children: [
          _GradientHeader(
            count: count,
            selectedFilter: _selectedFilter,
            onSelected: _applyFilter,
            onRefresh: _refresh,
          ),
          Expanded(
            child: switch (state) {
              TasksInitial() || TasksLoading() => const _LoadingView(),
              TasksError(:final message) => _ErrorView(
                message: message,
                onRetry: _refresh,
              ),
              TasksSuccess(:final tasks) =>
                tasks.isEmpty
                    ? const _EmptyView()
                    : _TaskList(tasks: tasks, onRefresh: _refresh),
            },
          ),
        ],
      ),
    );
  }
}

// ── Gradient Header ─────────────────────────────────────────────────────────

/// Brand green→teal header band carrying the title, task-count pill, refresh,
/// and the status filter chips. Same gradient as the login/profile screens so
/// the app reads as one family. Rounded bottom so the beige list below tucks
/// under it.
class _GradientHeader extends StatelessWidget {
  final int? count;
  final int selectedFilter;
  final ValueChanged<int> onSelected;
  final VoidCallback onRefresh;

  const _GradientHeader({
    required this.count,
    required this.selectedFilter,
    required this.onSelected,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final hPad = AppResponsive.horizontalPad(context);

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF134E40), Color(0xFF1B5E4F), Color(0xFF0D9488)],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            hPad,
            AppResponsive.vGap(context, 8),
            hPad,
            AppResponsive.vGap(context, 14),
          ),
          child: Column(
            children: [
              // Title row
              Row(
                children: [
                  Text(
                    'My Tasks',
                    style: TextStyle(
                      fontSize: AppResponsive.sp(context, 22),
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  if (count != null) ...[
                    SizedBox(width: AppResponsive.r(context, 10)),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppResponsive.r(context, 10),
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        count == 1 ? '1 task' : '$count tasks',
                        style: TextStyle(
                          fontSize: AppResponsive.sp(context, 12),
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.95),
                        ),
                      ),
                    ),
                  ],
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.refresh, color: Colors.white),
                    onPressed: onRefresh,
                  ),
                ],
              ),
              SizedBox(height: AppResponsive.vGap(context, 6)),
              // Filter chips — Wrap (not a horizontal scroll) so every filter,
              // incl. "Cancelled", is always visible; they flow onto a second
              // row on narrow screens instead of scrolling off-edge.
              Wrap(
                spacing: AppResponsive.r(context, 8),
                runSpacing: AppResponsive.r(context, 8),
                children: List.generate(
                  _filters.length,
                  (i) => _FilterPill(
                    label: _filters[i].label,
                    selected: i == selectedFilter,
                    onTap: () => onSelected(i),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A single status filter pill on the gradient header. Custom-built (not a
/// ChoiceChip) so the on-gradient colours are explicit — Material's chip
/// theming was rendering the unselected state as a solid white blob with
/// invisible white text. AnimatedContainer gives a smooth select transition.
class _FilterPill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        padding: EdgeInsets.symmetric(
          horizontal: AppResponsive.r(context, 16),
          vertical: AppResponsive.r(context, 9),
        ),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.white.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: selected
                ? Colors.transparent
                : Colors.white.withValues(alpha: 0.4),
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 220),
          style: TextStyle(
            fontSize: AppResponsive.sp(context, 13),
            fontWeight: FontWeight.w600,
            color: selected ? const Color(0xFF1B5E4F) : Colors.white,
          ),
          child: Text(label),
        ),
      ),
    );
  }
}

// ── Task List ─────────────────────────────────────────────────────────────────

class _TaskList extends StatelessWidget {
  final List<TaskModel> tasks;
  final Future<void> Function() onRefresh;

  const _TaskList({required this.tasks, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final hPad = AppResponsive.horizontalPad(context);
    final gap = AppResponsive.r(context, 12);
    final padding = EdgeInsets.fromLTRB(
      hPad,
      AppResponsive.r(context, 16),
      hPad,
      AppResponsive.r(context, 32),
    );

    // Wide screens (tablet / landscape) waste width on a single column, so lay
    // cards out in 2 columns there. We use a Wrap (not GridView) so each card
    // keeps its natural height — task cards vary (description, item chips), and
    // a fixed grid cell height would clip or overflow on the tall ones.
    final width = MediaQuery.sizeOf(context).width;
    final wide = width >= 600;

    return RefreshIndicator(
      color: const Color(0xFF1B5E4F),
      onRefresh: onRefresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: padding,
        child: wide
            ? _wrapGrid(context, hPad, gap, width)
            : Column(
                children: [
                  for (int i = 0; i < tasks.length; i++) ...[
                    if (i > 0) SizedBox(height: gap),
                    _card(context, tasks[i], i),
                  ],
                ],
              ),
      ),
    );
  }

  Widget _wrapGrid(
    BuildContext context,
    double hPad,
    double gap,
    double width,
  ) {
    // Two columns; each card takes half the available width minus the gap.
    final available = width - hPad * 2;
    final cardWidth = (available - gap) / 2;
    return Wrap(
      spacing: gap,
      runSpacing: gap,
      children: [
        for (int i = 0; i < tasks.length; i++)
          SizedBox(width: cardWidth, child: _card(context, tasks[i], i)),
      ],
    );
  }

  Widget _card(BuildContext context, TaskModel task, int index) => _TaskCard(
    task: task,
    index: index,
    onTap: () => context.push(AppRoutes.taskDetailPath(task.id)),
  );
}

// ── Task Card ─────────────────────────────────────────────────────────────────

// Top-level status/priority resolution — shared by the card and its pills.

String _statusLabel(String status) => switch (status) {
  'IN_PROGRESS' => 'In Progress',
  'COMPLETED' => 'Completed',
  'CANCELLED' => 'Cancelled',
  _ => 'Pending',
};

_StatusStyle _statusStyle(String status) => switch (status) {
  'IN_PROGRESS' => const _StatusStyle(
    iconColor: Color(0xFF3B82F6),
    badgeColor: Color(0xFFDBEAFE),
    badgeText: Color(0xFF1D4ED8),
  ),
  'COMPLETED' => const _StatusStyle(
    iconColor: Color(0xFF22C55E),
    badgeColor: Color(0xFFDCFCE7),
    badgeText: Color(0xFF166534),
  ),
  'CANCELLED' => const _StatusStyle(
    iconColor: Color(0xFF9CA3AF),
    badgeColor: Color(0xFFF3F4F6),
    badgeText: Color(0xFF6B7280),
  ),
  _ => const _StatusStyle(
    iconColor: Color(0xFFF59E0B),
    badgeColor: Color(0xFFFEF3C7),
    badgeText: Color(0xFFB45309),
  ),
};

_PriorityStyle _priorityStyle(String priority) => switch (priority) {
  'HIGH' => const _PriorityStyle(
    badgeColor: Color(0xFFFEE2E2),
    badgeText: Color(0xFFDC2626),
  ),
  'LOW' => const _PriorityStyle(
    badgeColor: Color(0xFFF0FDF4),
    badgeText: Color(0xFF16A34A),
  ),
  _ => const _PriorityStyle(
    badgeColor: Color(0xFFFFF7ED),
    badgeText: Color(0xFFEA580C),
  ),
};

/// Modern, animated task card.
///
/// * Entrance: fades + slides up on first build, staggered by [index] so the
///   list cascades in (delay capped so a long list's tail doesn't lag).
/// * Press: scales down briefly on tap for tactile feedback.
/// * Look: a clean white card with a bold status-coloured left bar (Linear /
///   Todoist style) — title + priority pill on top, a status pill (dot +
///   label) below, then description / item chips / footer meta.
class _TaskCard extends StatefulWidget {
  final TaskModel task;
  final int index;
  final VoidCallback onTap;

  const _TaskCard({
    required this.task,
    required this.index,
    required this.onTap,
  });

  @override
  State<_TaskCard> createState() => _TaskCardState();
}

class _TaskCardState extends State<_TaskCard>
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
      duration: const Duration(milliseconds: 420),
    );
    _fade = CurvedAnimation(parent: _entry, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _entry, curve: Curves.easeOutCubic));

    // Stagger by list position, capped so the tail of a long list doesn't
    // wait seconds (and those cards are off-screen anyway).
    final steps = widget.index.clamp(0, 12);
    Future.delayed(Duration(milliseconds: steps * 55), () {
      if (mounted) _entry.forward();
    });
  }

  @override
  void dispose() {
    _entry.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final task = widget.task;
    final status = _statusStyle(task.status);
    final priority = _priorityStyle(task.priority);

    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: GestureDetector(
          onTapDown: (_) => setState(() => _pressed = true),
          onTapUp: (_) {
            setState(() => _pressed = false);
            widget.onTap();
          },
          onTapCancel: () => setState(() => _pressed = false),
          child: AnimatedScale(
            scale: _pressed ? 0.97 : 1.0,
            duration: const Duration(milliseconds: 120),
            curve: Curves.easeOut,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Bold status-coloured left accent bar (full card height).
                      Container(
                        width: AppResponsive.r(context, 6),
                        color: status.iconColor,
                      ),
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.all(AppResponsive.r(context, 16)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Title + priority
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Text(
                                      task.title,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: AppResponsive.sp(context, 16),
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF111827),
                                        height: 1.2,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: AppResponsive.r(context, 8)),
                                  _PriorityPill(
                                    label: task.priority,
                                    bg: priority.badgeColor,
                                    textColor: priority.badgeText,
                                  ),
                                ],
                              ),
                              SizedBox(height: AppResponsive.r(context, 8)),
                              _StatusPill(
                                label: _statusLabel(task.status),
                                dotColor: status.iconColor,
                                bg: status.badgeColor,
                                textColor: status.badgeText,
                              ),
                              if (task.description.isNotEmpty) ...[
                                SizedBox(height: AppResponsive.r(context, 10)),
                                Text(
                                  task.description,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: AppResponsive.sp(context, 13),
                                    color: const Color(0xFF6B7280),
                                    height: 1.4,
                                  ),
                                ),
                              ],
                              if (task.items.isNotEmpty) ...[
                                SizedBox(height: AppResponsive.r(context, 12)),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  children: task.items
                                      .map(
                                        (item) => Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: AppResponsive.r(
                                              context,
                                              10,
                                            ),
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFF9FAFB),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            border: Border.all(
                                              color: const Color(0xFFE5E7EB),
                                            ),
                                          ),
                                          child: Text(
                                            item,
                                            style: TextStyle(
                                              fontSize: AppResponsive.sp(
                                                context,
                                                12,
                                              ),
                                              color: const Color(0xFF374151),
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      )
                                      .toList(),
                                ),
                              ],
                              SizedBox(height: AppResponsive.r(context, 14)),
                              const Divider(
                                height: 1,
                                color: Color(0xFFF1F1F1),
                              ),
                              SizedBox(height: AppResponsive.r(context, 10)),
                              Row(
                                children: [
                                  if (task.dueDate != null) ...[
                                    Icon(
                                      Icons.calendar_today_outlined,
                                      size: AppResponsive.r(context, 13),
                                      color: const Color(0xFF9CA3AF),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      DateFormat(
                                        'd MMM yyyy',
                                      ).format(task.dueDate!.toLocal()),
                                      style: TextStyle(
                                        fontSize: AppResponsive.sp(context, 12),
                                        color: const Color(0xFF6B7280),
                                      ),
                                    ),
                                    SizedBox(
                                      width: AppResponsive.r(context, 12),
                                    ),
                                  ],
                                  if (task.creator != null) ...[
                                    Icon(
                                      Icons.person_outline,
                                      size: AppResponsive.r(context, 13),
                                      color: const Color(0xFF9CA3AF),
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        task.creator!.fullName,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: AppResponsive.sp(
                                            context,
                                            12,
                                          ),
                                          color: const Color(0xFF6B7280),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Status indicator pill: a coloured dot + label on a tinted background.
class _StatusPill extends StatelessWidget {
  final String label;
  final Color dotColor;
  final Color bg;
  final Color textColor;

  const _StatusPill({
    required this.label,
    required this.dotColor,
    required this.bg,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppResponsive.r(context, 10),
        vertical: AppResponsive.r(context, 5),
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: AppResponsive.r(context, 7),
            height: AppResponsive.r(context, 7),
            decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
          ),
          SizedBox(width: AppResponsive.r(context, 6)),
          Text(
            label,
            style: TextStyle(
              fontSize: AppResponsive.sp(context, 11.5),
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}

/// Priority pill — compact, no dot.
class _PriorityPill extends StatelessWidget {
  final String label;
  final Color bg;
  final Color textColor;

  const _PriorityPill({
    required this.label,
    required this.bg,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppResponsive.r(context, 10),
        vertical: AppResponsive.r(context, 5),
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: AppResponsive.sp(context, 11),
          fontWeight: FontWeight.w700,
          color: textColor,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

class _StatusStyle {
  final Color iconColor;
  final Color badgeColor;
  final Color badgeText;
  const _StatusStyle({
    required this.iconColor,
    required this.badgeColor,
    required this.badgeText,
  });
}

class _PriorityStyle {
  final Color badgeColor;
  final Color badgeText;
  const _PriorityStyle({required this.badgeColor, required this.badgeText});
}

// ── Loading ───────────────────────────────────────────────────────────────────

class _LoadingView extends StatefulWidget {
  const _LoadingView();

  @override
  State<_LoadingView> createState() => _LoadingViewState();
}

class _LoadingViewState extends State<_LoadingView>
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
    return ListView.separated(
      padding: EdgeInsets.all(hPad),
      itemCount: 5,
      separatorBuilder: (_, _) =>
          SizedBox(height: AppResponsive.r(context, 12)),
      itemBuilder: (_, _) => AnimatedBuilder(
        animation: _ctrl,
        builder: (_, _) {
          final c = Color.lerp(
            const Color(0xFFE5E7EB),
            const Color(0xFFF3F4F6),
            _ctrl.value,
          )!;
          return Container(
            height: AppResponsive.r(context, 110),
            padding: EdgeInsets.all(AppResponsive.r(context, 16)),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: AppResponsive.r(context, 42),
                      height: AppResponsive.r(context, 42),
                      decoration: BoxDecoration(
                        color: c,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    SizedBox(width: AppResponsive.r(context, 12)),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            height: AppResponsive.r(context, 14),
                            decoration: BoxDecoration(
                              color: c,
                              borderRadius: BorderRadius.circular(7),
                            ),
                          ),
                          SizedBox(height: AppResponsive.r(context, 8)),
                          Container(
                            height: AppResponsive.r(context, 11),
                            width: AppResponsive.r(context, 120),
                            decoration: BoxDecoration(
                              color: c,
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: AppResponsive.r(context, 12)),
                Container(
                  height: AppResponsive.r(context, 11),
                  decoration: BoxDecoration(
                    color: c,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ── Error ─────────────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(AppResponsive.r(context, 32)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(AppResponsive.r(context, 20)),
              decoration: const BoxDecoration(
                color: Color(0xFFFEF2F2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline,
                size: AppResponsive.r(context, 40),
                color: const Color(0xFFDC2626),
              ),
            ),
            SizedBox(height: AppResponsive.r(context, 16)),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: AppResponsive.sp(context, 14),
                color: const Color(0xFF6B7280),
              ),
            ),
            SizedBox(height: AppResponsive.r(context, 20)),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1B5E4F),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Empty ─────────────────────────────────────────────────────────────────────

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(AppResponsive.r(context, 32)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(AppResponsive.r(context, 24)),
              decoration: const BoxDecoration(
                color: Color(0xFFF0FDF4),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.task_outlined,
                size: AppResponsive.r(context, 48),
                color: const Color(0xFF1B5E4F),
              ),
            ),
            SizedBox(height: AppResponsive.r(context, 20)),
            Text(
              'No tasks found',
              style: TextStyle(
                fontSize: AppResponsive.sp(context, 18),
                fontWeight: FontWeight.bold,
                color: const Color(0xFF111827),
              ),
            ),
            SizedBox(height: AppResponsive.r(context, 8)),
            Text(
              'Tasks assigned to you will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: AppResponsive.sp(context, 14),
                color: const Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
