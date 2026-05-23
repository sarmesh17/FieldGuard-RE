import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:field_guard_re/features/tasks/data/models/task_history_entry.dart';
import 'package:field_guard_re/features/tasks/presentation/providers/tasks_provider.dart';

class TaskHistoryScreen extends ConsumerWidget {
  final int taskId;
  final String taskTitle;

  const TaskHistoryScreen({
    super.key,
    required this.taskId,
    required this.taskTitle,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(taskHistoryProvider(taskId));

    return Scaffold(
      backgroundColor: const Color(0xFFF5F3EF),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B5E4F),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Task History',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            Text(
              taskTitle,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white70,
                fontWeight: FontWeight.w400,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(taskHistoryProvider(taskId)),
          ),
        ],
      ),
      body: state.when(
        loading: () => const _HistorySkeleton(),
        error: (e, _) => _ErrorView(
          message: e.toString(),
          onRetry: () => ref.invalidate(taskHistoryProvider(taskId)),
        ),
        data: (entries) => entries.isEmpty
            ? const _EmptyView()
            : _HistoryTimeline(entries: entries),
      ),
    );
  }
}

// ── Timeline ──────────────────────────────────────────────────────────────────

class _HistoryTimeline extends StatelessWidget {
  final List<TaskHistoryEntry> entries;

  const _HistoryTimeline({required this.entries});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
      itemCount: entries.length,
      itemBuilder: (_, i) => _TimelineItem(
        entry: entries[i],
        isLast: i == entries.length - 1,
      ),
    );
  }
}

class _TimelineItem extends StatelessWidget {
  final TaskHistoryEntry entry;
  final bool isLast;

  const _TimelineItem({required this.entry, required this.isLast});

  @override
  Widget build(BuildContext context) {
    final roleColor = _roleColor(entry.performer.role);
    final roleBg = _roleBg(entry.performer.role);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Timeline spine ───────────────────────────────────────────
          SizedBox(
            width: 40,
            child: Column(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: roleBg,
                    shape: BoxShape.circle,
                    border: Border.all(color: roleColor, width: 1.5),
                  ),
                  child: Center(
                    child: Text(
                      _initials(entry.performer.fullName),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: roleColor,
                      ),
                    ),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: const Color(0xFFE5E7EB),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          // ── Card ─────────────────────────────────────────────────────
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
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
                    // Header: performer + timestamp
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                entry.performer.fullName,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF111827),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: roleBg,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  entry.performer.role,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: roleColor,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          _formatDate(entry.createdAt),
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF9CA3AF),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),
                    const Divider(height: 1, color: Color(0xFFF3F4F6)),
                    const SizedBox(height: 10),

                    // Changes
                    ..._buildChanges(entry.oldValues, entry.newValues),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildChanges(
    Map<String, dynamic> oldVals,
    Map<String, dynamic> newVals,
  ) {
    final widgets = <Widget>[];
    final allKeys = {...oldVals.keys, ...newVals.keys}
        .where((k) => k != 'changeReason')
        .toList();

    for (final key in allKeys) {
      final oldV = oldVals[key];
      final newV = newVals[key];
      if (oldV == newV) continue;
      widgets.add(_ChangeRow(
        field: _fieldLabel(key),
        oldValue: _formatValue(key, oldV),
        newValue: _formatValue(key, newV),
      ));
      widgets.add(const SizedBox(height: 6));
    }

    // Change reason at the bottom if present
    final reason = newVals['changeReason'] as String?;
    if (reason != null && reason.isNotEmpty) {
      if (widgets.isNotEmpty) {
        widgets.add(const SizedBox(height: 2));
        widgets.add(Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF7ED),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFFED7AA)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.notes_outlined,
                  size: 14, color: Color(0xFFEA580C)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  reason,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF92400E),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
        ));
      }
    }

    if (widgets.isEmpty) {
      widgets.add(const Text(
        'No field changes recorded',
        style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
      ));
    }

    return widgets;
  }

  static String _fieldLabel(String key) => switch (key) {
        'status' => 'Status',
        'remarks' => 'Remarks',
        'priority' => 'Priority',
        'due_date' => 'Due Date',
        _ => key,
      };

  static String _formatValue(String key, dynamic value) {
    if (value == null) return '—';
    if (key == 'due_date') {
      final dt = DateTime.tryParse(value.toString());
      if (dt != null) return DateFormat('d MMM yyyy').format(dt.toLocal());
    }
    if (key == 'status') return _statusLabel(value.toString());
    return value.toString();
  }

  static String _statusLabel(String s) => switch (s) {
        'IN_PROGRESS' => 'In Progress',
        'COMPLETED' => 'Completed',
        'CANCELLED' => 'Cancelled',
        _ => 'Pending',
      };

  static String _formatDate(DateTime dt) {
    final local = dt.toLocal();
    return DateFormat('d MMM, hh:mm a').format(local);
  }

  static String _initials(String name) {
    final parts = name.trim().split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  static Color _roleColor(String role) => switch (role) {
        'MANAGER' => const Color(0xFF92400E),
        'ADMIN' => const Color(0xFF1D4ED8),
        _ => const Color(0xFF166534),
      };

  static Color _roleBg(String role) => switch (role) {
        'MANAGER' => const Color(0xFFFEF3C7),
        'ADMIN' => const Color(0xFFDBEAFE),
        _ => const Color(0xFFDCFCE7),
      };
}

// ── Change row ────────────────────────────────────────────────────────────────

class _ChangeRow extends StatelessWidget {
  final String field;
  final String oldValue;
  final String newValue;

  const _ChangeRow({
    required this.field,
    required this.oldValue,
    required this.newValue,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 64,
          child: Text(
            field,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF9CA3AF),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 4,
            runSpacing: 4,
            children: [
              _ValueChip(label: oldValue, isOld: true),
              const Icon(Icons.arrow_forward, size: 12, color: Color(0xFF9CA3AF)),
              _ValueChip(label: newValue, isOld: false),
            ],
          ),
        ),
      ],
    );
  }
}

class _ValueChip extends StatelessWidget {
  final String label;
  final bool isOld;

  const _ValueChip({required this.label, required this.isOld});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isOld ? const Color(0xFFF3F4F6) : const Color(0xFFDCFCE7),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: isOld ? const Color(0xFF6B7280) : const Color(0xFF166534),
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Color(0xFFF3F4F6),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.history_toggle_off_outlined,
              size: 40,
              color: Color(0xFF9CA3AF),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'No history yet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Changes to this task will appear here.',
            style: TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
          ),
        ],
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
              child: const Icon(Icons.error_outline,
                  size: 40, color: Color(0xFFDC2626)),
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
                    borderRadius: BorderRadius.circular(12)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Skeleton ──────────────────────────────────────────────────────────────────

class _HistorySkeleton extends StatefulWidget {
  const _HistorySkeleton();

  @override
  State<_HistorySkeleton> createState() => _HistorySkeletonState();
}

class _HistorySkeletonState extends State<_HistorySkeleton>
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
      builder: (_, child) {
        final c = Color.lerp(
          const Color(0xFFE5E7EB),
          const Color(0xFFF3F4F6),
          _ctrl.value,
        )!;
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
          itemCount: 4,
          itemBuilder: (context, i) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SkeletonBox(color: c, width: 32, height: 32, radius: 16),
                const SizedBox(width: 10),
                Expanded(
                  child: _SkeletonBox(color: c, height: 90, radius: 14),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SkeletonBox extends StatelessWidget {
  final Color color;
  final double height;
  final double? width;
  final double radius;

  const _SkeletonBox({
    required this.color,
    required this.height,
    this.width,
    required this.radius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}
