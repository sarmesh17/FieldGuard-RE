import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:field_guard_re/core/router/app_routes.dart';
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

    return Scaffold(
      backgroundColor: const Color(0xFFF5F3EF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'My Tasks',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1B5E4F),
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF1B5E4F)),
            onPressed: _refresh,
          ),
        ],
      ),
      body: Column(
        children: [
          _FilterBar(
            selectedIndex: _selectedFilter,
            onSelected: _applyFilter,
          ),
          Expanded(
            child: switch (state) {
              TasksInitial() || TasksLoading() => const _LoadingView(),
              TasksError(:final message) => _ErrorView(
                  message: message,
                  onRetry: _refresh,
                ),
              TasksSuccess(:final tasks) => tasks.isEmpty
                  ? const _EmptyView()
                  : _TaskList(tasks: tasks, onRefresh: _refresh),
            },
          ),
        ],
      ),
    );
  }
}

// ── Filter Bar ────────────────────────────────────────────────────────────────

class _FilterBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const _FilterBar({required this.selectedIndex, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(_filters.length, (i) {
            final selected = i == selectedIndex;
            return Padding(
              padding: const EdgeInsets.only(right: 10),
              child: ChoiceChip(
                label: Text(
                  _filters[i].label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: selected
                        ? Colors.white
                        : const Color(0xFF6B7280),
                  ),
                ),
                selected: selected,
                selectedColor: const Color(0xFF1B5E4F),
                backgroundColor: Colors.white,
                side: selected
                    ? BorderSide.none
                    : const BorderSide(color: Color(0xFFE5E7EB)),
                onSelected: (_) => onSelected(i),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                labelPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 2,
                ),
              ),
            );
          }),
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
    return RefreshIndicator(
      color: const Color(0xFF1B5E4F),
      onRefresh: onRefresh,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        itemCount: tasks.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, i) => _TaskCard(
          task: tasks[i],
          onTap: () => context.push(AppRoutes.taskDetailPath(tasks[i].id)),
        ),
      ),
    );
  }
}

// ── Task Card ─────────────────────────────────────────────────────────────────

class _TaskCard extends StatelessWidget {
  final TaskModel task;
  final VoidCallback onTap;

  const _TaskCard({required this.task, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final statusStyle = _statusStyle(task.status);
    final priorityStyle = _priorityStyle(task.priority);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title row + badges
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Task icon
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: statusStyle.iconBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.task_alt_outlined,
                    color: statusStyle.iconColor,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          _Badge(
                            label: _statusLabel(task.status),
                            color: statusStyle.badgeColor,
                            textColor: statusStyle.badgeText,
                          ),
                          const SizedBox(width: 8),
                          _Badge(
                            label: task.priority,
                            color: priorityStyle.badgeColor,
                            textColor: priorityStyle.badgeText,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            if (task.description.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                task.description,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF6B7280),
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],

            // Items
            if (task.items.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: task.items
                    .map(
                      (item) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFBBF7D0)),
                        ),
                        child: Text(
                          item,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF166534),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],

            const SizedBox(height: 12),
            const Divider(height: 1, color: Color(0xFFF3F4F6)),
            const SizedBox(height: 10),

            // Footer row
            Row(
              children: [
                if (task.dueDate != null) ...[
                  const Icon(
                    Icons.calendar_today_outlined,
                    size: 13,
                    color: Color(0xFF9CA3AF),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    DateFormat('d MMM yyyy').format(task.dueDate!.toLocal()),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                if (task.creator != null) ...[
                  const Icon(
                    Icons.person_outline,
                    size: 13,
                    color: Color(0xFF9CA3AF),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      task.creator!.fullName,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B7280),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
        ),
      ),
    );
  }

  static String _statusLabel(String status) => switch (status) {
        'IN_PROGRESS' => 'In Progress',
        'COMPLETED' => 'Completed',
        'CANCELLED' => 'Cancelled',
        _ => 'Pending',
      };

  static _StatusStyle _statusStyle(String status) => switch (status) {
        'IN_PROGRESS' => const _StatusStyle(
            iconBg: Color(0xFFEFF6FF),
            iconColor: Color(0xFF3B82F6),
            badgeColor: Color(0xFFDBEAFE),
            badgeText: Color(0xFF1D4ED8),
          ),
        'COMPLETED' => const _StatusStyle(
            iconBg: Color(0xFFF0FDF4),
            iconColor: Color(0xFF22C55E),
            badgeColor: Color(0xFFDCFCE7),
            badgeText: Color(0xFF166534),
          ),
        'CANCELLED' => const _StatusStyle(
            iconBg: Color(0xFFF9FAFB),
            iconColor: Color(0xFF9CA3AF),
            badgeColor: Color(0xFFF3F4F6),
            badgeText: Color(0xFF6B7280),
          ),
        _ => const _StatusStyle(
            iconBg: Color(0xFFFFFBEB),
            iconColor: Color(0xFFF59E0B),
            badgeColor: Color(0xFFFEF3C7),
            badgeText: Color(0xFFB45309),
          ),
      };

  static _PriorityStyle _priorityStyle(String priority) => switch (priority) {
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
}

class _StatusStyle {
  final Color iconBg;
  final Color iconColor;
  final Color badgeColor;
  final Color badgeText;
  const _StatusStyle({
    required this.iconBg,
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

// ── Badge ─────────────────────────────────────────────────────────────────────

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  final Color textColor;

  const _Badge({
    required this.label,
    required this.color,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }
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
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (_, _) => AnimatedBuilder(
        animation: _ctrl,
        builder: (_, _) {
          final c = Color.lerp(
            const Color(0xFFE5E7EB),
            const Color(0xFFF3F4F6),
            _ctrl.value,
          )!;
          return Container(
            height: 110,
            padding: const EdgeInsets.all(16),
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
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: c,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            height: 14,
                            decoration: BoxDecoration(
                              color: c,
                              borderRadius: BorderRadius.circular(7),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            height: 11,
                            width: 120,
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
                const SizedBox(height: 12),
                Container(
                  height: 11,
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
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFFFEF2F2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline,
                size: 40,
                color: Color(0xFFDC2626),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
            ),
            const SizedBox(height: 20),
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
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Color(0xFFF0FDF4),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.task_outlined,
                size: 48,
                color: Color(0xFF1B5E4F),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'No tasks found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tasks assigned to you will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
            ),
          ],
        ),
      ),
    );
  }
}
