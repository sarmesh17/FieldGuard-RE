import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:field_guard_re/core/router/app_routes.dart';
import 'package:field_guard_re/features/shops/presentation/providers/shop_provider.dart';
import 'package:field_guard_re/features/tasks/data/models/task_model.dart';
import 'package:field_guard_re/features/tasks/data/models/update_task_request.dart';
import 'package:field_guard_re/features/tasks/presentation/providers/tasks_provider.dart';
import 'package:field_guard_re/features/tracking/presentation/providers/tracking_provider.dart';

class TaskDetailScreen extends ConsumerStatefulWidget {
  final int taskId;

  const TaskDetailScreen({super.key, required this.taskId});

  @override
  ConsumerState<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends ConsumerState<TaskDetailScreen> {
  void _openUpdateSheet(TaskModel task) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _UpdateBottomSheet(
        taskId: widget.taskId,
        currentStatus: task.status,
        currentRemarks: task.remarks,
        onSuccess: () {
          ref.invalidate(taskDetailProvider(widget.taskId));
        },
      ),
    );
  }

  /// Composes the floating actions on the detail screen. The "Navigate"
  /// action is gated on (a) the task being IN_PROGRESS and (b) shop
  /// coordinates being parseable — otherwise the route screen has nothing
  /// meaningful to show. "Collect Payment" is gated on (a) IN_PROGRESS and
  /// (b) the task having a shop attached — without a `shopId` the
  /// collections endpoint has nothing to charge against.
  Widget? _buildFabs(TaskModel task) {
    final isFinal = task.status == 'COMPLETED' || task.status == 'CANCELLED';
    final shopLat = double.tryParse(task.shopLatitude ?? '');
    final shopLng = double.tryParse(task.shopLongitude ?? '');
    final canNavigate = task.status == 'IN_PROGRESS' &&
        shopLat != null &&
        shopLng != null;
    final canCollect =
        task.status == 'IN_PROGRESS' && task.shop != null;

    if (isFinal && !canNavigate && !canCollect) return null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (canNavigate) ...[
          FloatingActionButton.extended(
            heroTag: 'task-navigate-fab',
            // Switch to the Route tab — the route screen renders this task's
            // pin + driving polyline + ETA on its own map (powered by
            // `activeInProgressTaskProvider`), so we don't need a separate
            // navigation screen.
            onPressed: () => context.go(AppRoutes.route),
            backgroundColor: const Color(0xFF1D4ED8),
            foregroundColor: Colors.white,
            icon: const Icon(Icons.navigation_outlined),
            label: const Text(
              'Navigate',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (canCollect) ...[
          FloatingActionButton.extended(
            heroTag: 'task-collect-fab',
            onPressed: () => context.push(
              AppRoutes.collectPayment,
              extra: AppRoutes.collectPaymentExtra(
                shopId: task.shop!.id,
                shopName: task.shop!.name,
                taskId: task.id,
              ),
            ),
            backgroundColor: const Color(0xFFB45309),
            foregroundColor: Colors.white,
            icon: const Icon(Icons.payments_outlined),
            label: const Text(
              'Collect Payment',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (!isFinal)
          FloatingActionButton.extended(
            heroTag: 'task-update-fab',
            onPressed: () => _openUpdateSheet(task),
            backgroundColor: const Color(0xFF1B5E4F),
            foregroundColor: Colors.white,
            icon: const Icon(Icons.edit_outlined),
            label: const Text(
              'Update',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(taskDetailProvider(widget.taskId));

    return Scaffold(
      backgroundColor: const Color(0xFFF5F3EF),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B5E4F),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Task Detail',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        actions: [
          state.whenOrNull(
                data: (task) => IconButton(
                  icon: const Icon(Icons.history_outlined),
                  tooltip: 'History',
                  onPressed: () => context.push(
                    '${AppRoutes.taskHistoryPath(widget.taskId)}?title=${Uri.encodeComponent(task.title)}',
                  ),
                ),
              ) ??
              const SizedBox.shrink(),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(taskDetailProvider(widget.taskId)),
          ),
        ],
      ),
      floatingActionButton: state.whenOrNull(
        data: (task) => _buildFabs(task),
      ),
      body: state.when(
        loading: () => const _DetailSkeleton(),
        error: (e, _) => _ErrorView(
          message: e.toString(),
          onRetry: () => ref.invalidate(taskDetailProvider(widget.taskId)),
        ),
        data: (task) => _DetailBody(task: task),
      ),
    );
  }
}

// ── Update bottom sheet ───────────────────────────────────────────────────────

// COMPLETED is intentionally absent: a task is only ever marked completed
// automatically when the agent leaves the shop's geofence (see
// `geofenceEventHandlerProvider`), never manually from this sheet.
const _kStatuses = [
  ('PENDING', 'Pending'),
  ('IN_PROGRESS', 'In Progress'),
  ('CANCELLED', 'Cancelled'),
];

class _UpdateBottomSheet extends ConsumerStatefulWidget {
  final int taskId;
  final String currentStatus;
  final String? currentRemarks;
  final VoidCallback onSuccess;

  const _UpdateBottomSheet({
    required this.taskId,
    required this.currentStatus,
    this.currentRemarks,
    required this.onSuccess,
  });

  @override
  ConsumerState<_UpdateBottomSheet> createState() =>
      _UpdateBottomSheetState();
}

class _UpdateBottomSheetState extends ConsumerState<_UpdateBottomSheet> {
  late String _selectedStatus;
  late final TextEditingController _remarksCtrl;
  late final TextEditingController _reasonCtrl;
  final _formKey = GlobalKey<FormState>();

  String? _selectedCancelReason;
  File? _cancelImageFile;
  bool _uploading = false;
  String? _cancelReasonError;
  String? _cancelImageError;
  bool _showTrackingWarning = false;

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.currentStatus;
    _remarksCtrl =
        TextEditingController(text: widget.currentRemarks ?? '');
    _reasonCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _remarksCtrl.dispose();
    _reasonCtrl.dispose();
    super.dispose();
  }

  bool get _needsChangeReason {
    if (_selectedStatus == 'CANCELLED') return _selectedCancelReason == 'OTHER';
    if (_selectedStatus == 'PENDING' && widget.currentStatus == 'IN_PROGRESS') {
      return true;
    }
    return false;
  }

  bool get _needsCancelImage =>
      _selectedStatus == 'CANCELLED' &&
      _selectedCancelReason != null &&
      _selectedCancelReason != 'OTHER';

  Future<void> _pickCancelImage(ImageSource source) async {
    final picked = await ImagePicker().pickImage(
      source: source,
      imageQuality: 80,
      maxWidth: 1280,
    );
    if (picked != null && mounted) {
      setState(() {
        _cancelImageFile = File(picked.path);
        _cancelImageError = null;
      });
    }
  }

  void _showImageSourceSheet() {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetCtx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Camera'),
              onTap: () {
                sheetCtx.pop();
                _pickCancelImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Gallery'),
              onTap: () {
                sheetCtx.pop();
                _pickCancelImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    // Gate: a task can only go IN_PROGRESS while Live Tracking is on. Without
    // tracking, the background geofence won't arm, the visit won't be
    // recorded, and auto-complete-on-exit can't fire — so we refuse the
    // transition up-front and tell the user to enable tracking first.
    if (_selectedStatus == 'IN_PROGRESS' &&
        widget.currentStatus != 'IN_PROGRESS' &&
        !ref.read(trackingNotifierProvider).isActive) {
      setState(() => _showTrackingWarning = true);
      return;
    }

    // Validate cancel-specific fields (outside the Form validator since they
    // use custom widgets, not TextFormFields).
    if (_selectedStatus == 'CANCELLED') {
      var valid = true;
      if (_selectedCancelReason == null) {
        setState(() => _cancelReasonError = 'Please select a cancel reason');
        valid = false;
      }
      if (_selectedCancelReason != null &&
          _selectedCancelReason != 'OTHER' &&
          _cancelImageFile == null) {
        setState(() => _cancelImageError = 'Photo is required');
        valid = false;
      }
      if (!valid) return;
    }

    // Capture inherited widgets up-front: we need to show the snackbar / pop
    // the sheet *after* a chain of awaits and tree mutations, by which point
    // `context` may no longer have a Scaffold or Navigator ancestor.
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    final tasksNotifier = ref.read(tasksNotifierProvider.notifier);
    final updateNotifier = ref.read(taskUpdateProvider.notifier);
    final onSuccess = widget.onSuccess;

    // Guard: only ONE task may be IN_PROGRESS at a time. If the user is
    // moving this task to IN_PROGRESS and another task is already in that
    // state, demote it to PENDING first (with a user-supplied reason).
    if (_selectedStatus == 'IN_PROGRESS' &&
        widget.currentStatus != 'IN_PROGRESS') {
      // Make sure we have a fresh list — without it, racing rebuilds could
      // leave the notifier in TasksLoading/Error and skip the guard, silently
      // allowing two tasks to be IN_PROGRESS at once.
      var tasksState = ref.read(tasksNotifierProvider);
      if (tasksState is! TasksSuccess) {
        await tasksNotifier.fetch();
        if (!mounted) return;
        tasksState = ref.read(tasksNotifierProvider);
      }
      final ongoing = tasksState is TasksSuccess
          ? tasksState.tasks
              .where(
                (t) => t.id != widget.taskId && t.status == 'IN_PROGRESS',
              )
              .toList()
          : const <TaskModel>[];

      if (ongoing.isNotEmpty) {
        final reason = await _askDemoteReason(ongoing);
        if (reason == null) return; // user cancelled
        if (!mounted) return;

        // Demote every existing IN_PROGRESS task to PENDING with the reason.
        // We intentionally do NOT refresh `tasksNotifierProvider` between the
        // demote(s) and the promote — flipping that provider to TasksLoading
        // mid-flow causes `activeInProgressTaskProvider` (and the route
        // screen's `ref.listen` callback) to fire transiently with `null`,
        // restructuring the route-screen tree while this sheet is still
        // mounted. The single fetch after `pop()` below covers it.
        for (final t in ongoing) {
          final ok = await updateNotifier.update(
            t.id,
            UpdateTaskRequest(status: 'PENDING', changeReason: reason),
          );
          if (!ok) {
            if (mounted) {
              messenger.showSnackBar(
                SnackBar(
                  content: Text('Failed to demote "${t.title}"'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
            return;
          }
        }
      }
    }

    // Upload cancel photo if required (non-OTHER reasons need evidence).
    String? cancelImageKey;
    if (_cancelImageFile != null) {
      setState(() => _uploading = true);
      try {
        cancelImageKey = await ref
            .read(uploadServiceProvider)
            .uploadCancelPhoto(_cancelImageFile!, widget.taskId);
      } catch (_) {
        if (mounted) setState(() => _uploading = false);
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Photo upload failed'),
            backgroundColor: Color(0xFFDC2626),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
      // Keep _uploading = true through the API call so the spinner stays
      // visible without a flash — the sheet pop on success unmounts the widget.
    }

    final request = UpdateTaskRequest(
      status: _selectedStatus,
      remarks: _remarksCtrl.text.trim().isEmpty ? null : _remarksCtrl.text.trim(),
      changeReason: _needsChangeReason ? _reasonCtrl.text.trim() : null,
      cancelReason: _selectedStatus == 'CANCELLED' ? _selectedCancelReason : null,
      cancelImage: cancelImageKey,
    );
    final success = await updateNotifier.update(widget.taskId, request);
    if (!success) {
      // Re-enable the button so the user can retry.
      if (mounted) setState(() => _uploading = false);
      return;
    }
    if (!mounted) return;

    // Pop the sheet FIRST, then defer every tree-mutating side-effect to the
    // next frame. `navigator.pop()` only *starts* the sheet's exit transition —
    // the modal route (and its Form, which owns `_formKey`) stays mounted in the
    // overlay until the animation settles. Invalidating `taskDetailProvider` /
    // `fetch()` synchronously here rebuilds the detail screen + route-tab tree
    // while that Form is still alive, so the GlobalKey lands in two live subtrees
    // for a frame → "Duplicate GlobalKeys detected". Running them post-frame lets
    // the sheet finish unmounting first.
    router.pop();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      onSuccess();
      // Fire-and-forget: keep the global tasks cache in sync (route screen,
      // schedule list, FAB gating) without blocking the snackbar.
      unawaited(tasksNotifier.fetch());
      messenger.showSnackBar(
        SnackBar(
          content: const Text('Task updated successfully'),
          backgroundColor: const Color(0xFF1B5E4F),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    });
  }

  /// Shows a confirmation dialog listing the task(s) that will be moved to
  /// PENDING and collects a required reason. Returns the trimmed reason on
  /// confirm, `null` if the user cancels.
  ///
  /// Uses a plain `TextField` + `StatefulBuilder` instead of `Form`/
  /// `TextFormField` + `GlobalKey<FormState>`. The `Form` widget creates a
  /// `_FormScope` InheritedWidget; when `formKey.currentState?.validate()`
  /// runs and then `Navigator.pop()` is called in the same handler, Flutter
  /// schedules a `setState` rebuild on `FormState` (to clear validation
  /// errors) while simultaneously unmounting the dialog. This can leave the
  /// `_FormScope` InheritedElement with active `TextFormField` dependents →
  /// `_dependents.isEmpty: is not true` assertion.
  Future<String?> _askDemoteReason(List<TaskModel> ongoing) async {
    final reasonCtrl = TextEditingController();

    var showError = false;
    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text(
              'Another task is in progress',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ongoing.length == 1
                      ? '"${ongoing.first.title}" is currently in progress and will be moved to Pending.'
                      : '${ongoing.length} tasks are currently in progress and will be moved to Pending.',
                  style: const TextStyle(
                    fontSize: 13.5,
                    color: Color(0xFF374151),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: reasonCtrl,
                  maxLines: 2,
                  autofocus: true,
                  onChanged: (_) {
                    if (showError) setDialogState(() => showError = false);
                  },
                  decoration: InputDecoration(
                    labelText: 'Reason *',
                    hintText: 'Why are you switching tasks?',
                    errorText: showError ? 'Reason is required' : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => ctx.pop(),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Color(0xFF6B7280)),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  if (reasonCtrl.text.trim().isEmpty) {
                    setDialogState(() => showError = true);
                    return;
                  }
                  ctx.pop(reasonCtrl.text.trim());
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1B5E4F),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text('Continue'),
              ),
            ],
          );
        },
      ),
    );

    // Defer disposal until after the dialog's exit transition completes.
    // `showDialog`'s future resolves the moment `Navigator.pop()` is called,
    // but the AlertDialog (and its TextField) keep rebuilding through the
    // fade-out animation (~150ms). Disposing `reasonCtrl` synchronously here
    // kills the controller mid-animation → "A TextEditingController was used
    // after being disposed" + a corrupted tree that surfaces as the
    // duplicate-GlobalKey / `_dependents.isEmpty` assertions.
    Future<void>.delayed(const Duration(milliseconds: 300), reasonCtrl.dispose);
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final updateState = ref.watch(taskUpdateProvider);
    final isLoading = updateState is TaskUpdateLoading || _uploading;
    final errorMsg =
        updateState is TaskUpdateError ? updateState.message : null;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE5E7EB),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.edit_outlined,
                      size: 18,
                      color: Color(0xFF1B5E4F),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Update Task',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF111827),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _FieldLabel('Status'),
                      const SizedBox(height: 6),
                      _StatusSelector(
                        selected: _selectedStatus,
                        onChanged: (v) => setState(() {
                          _selectedStatus = v;
                          _showTrackingWarning = false;
                          if (v != 'CANCELLED') {
                            _selectedCancelReason = null;
                            _cancelImageFile = null;
                            _cancelReasonError = null;
                            _cancelImageError = null;
                          }
                        }),
                      ),
                      if (_selectedStatus == 'CANCELLED') ...[
                        const SizedBox(height: 16),
                        const _FieldLabel('Cancel Reason *'),
                        const SizedBox(height: 6),
                        _CancelReasonSelector(
                          selected: _selectedCancelReason,
                          onChanged: (v) => setState(() {
                            _selectedCancelReason = v;
                            _cancelReasonError = null;
                            _cancelImageFile = null;
                            _cancelImageError = null;
                          }),
                        ),
                        if (_cancelReasonError != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            _cancelReasonError!,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFFDC2626),
                            ),
                          ),
                        ],
                      ],
                      if (_needsCancelImage) ...[
                        const SizedBox(height: 16),
                        const _FieldLabel('Cancel Photo *'),
                        const SizedBox(height: 6),
                        _CancelImagePicker(
                          file: _cancelImageFile,
                          error: _cancelImageError,
                          onTap: _showImageSourceSheet,
                        ),
                      ],
                      const SizedBox(height: 16),
                      const _FieldLabel('Remarks (optional)'),
                      const SizedBox(height: 6),
                      _StyledTextField(
                        controller: _remarksCtrl,
                        hint: 'Add any remarks...',
                        maxLines: 3,
                      ),
                      if (_needsChangeReason) ...[
                        const SizedBox(height: 16),
                        _FieldLabel(
                          _selectedStatus == 'CANCELLED'
                              ? 'Reason *'
                              : 'Change Reason *',
                        ),
                        const SizedBox(height: 6),
                        _StyledTextField(
                          controller: _reasonCtrl,
                          hint: _selectedStatus == 'CANCELLED'
                              ? 'Describe the reason...'
                              : 'e.g. Customer rescheduled...',
                          maxLines: 2,
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Required'
                              : null,
                        ),
                        const SizedBox(height: 16),
                      ],
                      if (_showTrackingWarning) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF7ED),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFFBBF24)),
                          ),
                          child: const Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.location_off_outlined,
                                  size: 16, color: Color(0xFFB45309)),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Live Tracking is off. Enable it on the Route screen before starting a task.',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF92400E),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      if (errorMsg != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF2F2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline,
                                  size: 16, color: Color(0xFFDC2626)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  errorMsg,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFFDC2626),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: isLoading
                                  ? null
                                  : () => context.pop(),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(
                                    color: Color(0xFFE5E7EB)),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(
                                    vertical: 14),
                              ),
                              child: const Text(
                                'Cancel',
                                style: TextStyle(
                                  color: Color(0xFF6B7280),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: isLoading ? null : _submit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1B5E4F),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(
                                    vertical: 14),
                              ),
                              child: isLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text(
                                      'Save Changes',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w600),
                                    ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Status selector ───────────────────────────────────────────────────────────

class _StatusSelector extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;

  const _StatusSelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _kStatuses.map((s) {
        final isSelected = s.$1 == selected;
        return ChoiceChip(
          label: Text(
            s.$2,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : const Color(0xFF6B7280),
            ),
          ),
          selected: isSelected,
          selectedColor: _statusColor(s.$1),
          backgroundColor: Colors.white,
          side: isSelected
              ? BorderSide.none
              : const BorderSide(color: Color(0xFFE5E7EB)),
          onSelected: (_) => onChanged(s.$1),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          labelPadding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
        );
      }).toList(),
    );
  }

  static Color _statusColor(String s) => switch (s) {
        'IN_PROGRESS' => const Color(0xFF3B82F6),
        'COMPLETED' => const Color(0xFF22C55E),
        'CANCELLED' => const Color(0xFF9CA3AF),
        _ => const Color(0xFFF59E0B),
      };
}

// ── Cancel reason selector ────────────────────────────────────────────────────

const _kCancelReasons = [
  ('SHOP_CLOSED', 'Shop Closed'),
  ('SHOP_RELOCATED', 'Shop Relocated'),
  ('SHOP_PERMANENTLY_CLOSED', 'Perm. Closed'),
  ('SHOP_NOT_FOUND', 'Not Found'),
  ('OTHER', 'Other'),
];

class _CancelReasonSelector extends StatelessWidget {
  final String? selected;
  final ValueChanged<String> onChanged;

  const _CancelReasonSelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _kCancelReasons.map((r) {
        final isSelected = r.$1 == selected;
        return ChoiceChip(
          label: Text(
            r.$2,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : const Color(0xFF6B7280),
            ),
          ),
          selected: isSelected,
          selectedColor: const Color(0xFFDC2626),
          backgroundColor: Colors.white,
          side: isSelected
              ? BorderSide.none
              : const BorderSide(color: Color(0xFFE5E7EB)),
          onSelected: (_) => onChanged(r.$1),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          labelPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        );
      }).toList(),
    );
  }
}

// ── Cancel image picker ───────────────────────────────────────────────────────

class _CancelImagePicker extends StatelessWidget {
  final File? file;
  final String? error;
  final VoidCallback onTap;

  const _CancelImagePicker({
    required this.file,
    required this.error,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            height: 120,
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: error != null
                    ? const Color(0xFFDC2626)
                    : const Color(0xFFE5E7EB),
              ),
            ),
            child: file == null
                ? const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add_a_photo_outlined,
                            size: 28, color: Color(0xFF9CA3AF)),
                        SizedBox(height: 6),
                        Text(
                          'Tap to add photo',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF9CA3AF),
                          ),
                        ),
                      ],
                    ),
                  )
                : ClipRRect(
                    borderRadius: BorderRadius.circular(11),
                    child: Image.file(
                      file!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                    ),
                  ),
          ),
        ),
        if (error != null) ...[
          const SizedBox(height: 4),
          Text(
            error!,
            style: const TextStyle(fontSize: 12, color: Color(0xFFDC2626)),
          ),
        ],
      ],
    );
  }
}

// ── Field helpers ─────────────────────────────────────────────────────────────

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Color(0xFF374151),
        ),
      );
}

class _StyledTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final int maxLines;
  final String? Function(String?)? validator;

  const _StyledTextField({
    required this.controller,
    required this.hint,
    this.maxLines = 1,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: validator,
      style: const TextStyle(fontSize: 14, color: Color(0xFF111827)),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle:
            const TextStyle(fontSize: 14, color: Color(0xFF9CA3AF)),
        filled: true,
        fillColor: const Color(0xFFF9FAFB),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF1B5E4F), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFDC2626)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: Color(0xFFDC2626), width: 1.5),
        ),
      ),
    );
  }
}

// ── Detail body ───────────────────────────────────────────────────────────────

class _DetailBody extends StatelessWidget {
  final TaskModel task;

  const _DetailBody({required this.task});

  @override
  Widget build(BuildContext context) {
    final statusStyle = _statusStyle(task.status);
    final priorityStyle = _priorityStyle(task.priority);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Hero card ────────────────────────────────────────────────────
          _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 10),
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
                if (task.description.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    task.description,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF374151),
                      height: 1.5,
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 12),

          // ── Checklist items ──────────────────────────────────────────────
          if (task.items.isNotEmpty) ...[
            _SectionHeader(label: 'Checklist', icon: Icons.checklist_rounded),
            _Card(
              child: Column(
                children: task.items.asMap().entries.map((entry) {
                  final isLast = entry.key == task.items.length - 1;
                  return Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: const Color(0xFF1B5E4F),
                                width: 1.5,
                              ),
                              borderRadius: BorderRadius.circular(6),
                              color: task.status == 'COMPLETED'
                                  ? const Color(0xFF1B5E4F)
                                  : Colors.transparent,
                            ),
                            child: task.status == 'COMPLETED'
                                ? const Icon(
                                    Icons.check,
                                    size: 14,
                                    color: Colors.white,
                                  )
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              entry.value,
                              style: TextStyle(
                                fontSize: 14,
                                color: task.status == 'COMPLETED'
                                    ? const Color(0xFF9CA3AF)
                                    : const Color(0xFF374151),
                                decoration: task.status == 'COMPLETED'
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (!isLast) ...[
                        const SizedBox(height: 10),
                        const Divider(height: 1, color: Color(0xFFF3F4F6)),
                        const SizedBox(height: 10),
                      ],
                    ],
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 12),
          ],

          // ── Dates ────────────────────────────────────────────────────────
          _SectionHeader(label: 'Timeline', icon: Icons.schedule_outlined),
          _Card(
            child: Column(
              children: [
                _InfoRow(
                  icon: Icons.calendar_today_outlined,
                  label: 'Due Date',
                  value: task.dueDate != null
                      ? DateFormat('d MMMM yyyy').format(task.dueDate!.toLocal())
                      : '—',
                ),
                if (task.completedAt != null) ...[
                  const SizedBox(height: 10),
                  const Divider(height: 1, color: Color(0xFFF3F4F6)),
                  const SizedBox(height: 10),
                  _InfoRow(
                    icon: Icons.check_circle_outline,
                    label: 'Completed',
                    value: DateFormat('d MMM yyyy, hh:mm a')
                        .format(task.completedAt!.toLocal()),
                    valueColor: const Color(0xFF166534),
                  ),
                ],
                const SizedBox(height: 10),
                const Divider(height: 1, color: Color(0xFFF3F4F6)),
                const SizedBox(height: 10),
                _InfoRow(
                  icon: Icons.access_time_outlined,
                  label: 'Created',
                  value: DateFormat('d MMM yyyy, hh:mm a')
                      .format(task.createdAt.toLocal()),
                ),
                if (task.updatedAt != null) ...[
                  const SizedBox(height: 10),
                  const Divider(height: 1, color: Color(0xFFF3F4F6)),
                  const SizedBox(height: 10),
                  _InfoRow(
                    icon: Icons.update_outlined,
                    label: 'Updated',
                    value: DateFormat('d MMM yyyy, hh:mm a')
                        .format(task.updatedAt!.toLocal()),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 12),

          // ── Shop ─────────────────────────────────────────────────────────
          _SectionHeader(label: 'Shop', icon: Icons.storefront_outlined),
          _Card(
            child: Row(
              children: [
                _ShopImage(url: task.shop?.shopImage),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Shop',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF9CA3AF),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        task.shop?.name ?? 'Shop info unavailable',
                        style: TextStyle(
                          fontSize: 14,
                          color: task.shop == null
                              ? const Color(0xFF9CA3AF)
                              : const Color(0xFF111827),
                          fontWeight: FontWeight.w600,
                          fontStyle: task.shop == null
                              ? FontStyle.italic
                              : FontStyle.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ── Location ─────────────────────────────────────────────────────
          if (task.shopLatitude != null && task.shopLongitude != null) ...[
            _SectionHeader(
                label: 'Location', icon: Icons.location_on_outlined),
            _Card(
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.my_location,
                      size: 20,
                      color: Color(0xFF1B5E4F),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Shop Coordinates',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF9CA3AF),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${task.shopLatitude}, ${task.shopLongitude}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF374151),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // ── Cancellation ─────────────────────────────────────────────────
          if (task.status == 'CANCELLED' && task.cancelReason != null) ...[
            _SectionHeader(
              label: 'Cancellation',
              icon: Icons.cancel_outlined,
            ),
            _Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _InfoRow(
                    icon: Icons.info_outline,
                    label: 'Reason',
                    value: _cancelReasonLabel(task.cancelReason!),
                  ),
                  if (task.cancelImage != null &&
                      task.cancelImage!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const Divider(height: 1, color: Color(0xFFF3F4F6)),
                    const SizedBox(height: 12),
                    const Text(
                      'Evidence Photo',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF9CA3AF),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        task.cancelImage!,
                        height: 160,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Container(
                          height: 160,
                          color: const Color(0xFFF3F4F6),
                          child: const Center(
                            child: Icon(Icons.broken_image_outlined,
                                color: Color(0xFF9CA3AF)),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // ── Remarks ──────────────────────────────────────────────────────
          if (task.remarks != null && task.remarks!.isNotEmpty) ...[
            _SectionHeader(label: 'Remarks', icon: Icons.notes_outlined),
            _Card(
              child: Text(
                task.remarks!,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF374151),
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],

          // ── People ───────────────────────────────────────────────────────
          _SectionHeader(label: 'People', icon: Icons.people_outline),
          _Card(
            child: Column(
              children: [
                if (task.creator != null)
                  _PersonRow(
                    role: 'Created by',
                    name: task.creator!.fullName,
                    color: const Color(0xFF1D4ED8),
                    bg: const Color(0xFFDBEAFE),
                    icon: Icons.person_outline,
                  ),
                if (task.assignee != null) ...[
                  if (task.creator != null) ...[
                    const SizedBox(height: 10),
                    const Divider(height: 1, color: Color(0xFFF3F4F6)),
                    const SizedBox(height: 10),
                  ],
                  _PersonRow(
                    role: 'Assigned to',
                    name: task.assignee!.fullName,
                    color: const Color(0xFF166534),
                    bg: const Color(0xFFDCFCE7),
                    icon: Icons.assignment_ind_outlined,
                  ),
                ],
                if (task.manager != null) ...[
                  if (task.creator != null || task.assignee != null) ...[
                    const SizedBox(height: 10),
                    const Divider(height: 1, color: Color(0xFFF3F4F6)),
                    const SizedBox(height: 10),
                  ],
                  _PersonRow(
                    role: 'Manager',
                    name: task.manager!.fullName,
                    color: const Color(0xFF92400E),
                    bg: const Color(0xFFFEF3C7),
                    icon: Icons.supervisor_account_outlined,
                  ),
                ],
                if (task.creator == null &&
                    task.assignee == null &&
                    task.manager == null)
                  const Text(
                    'No people assigned',
                    style: TextStyle(fontSize: 14, color: Color(0xFF9CA3AF)),
                  ),
              ],
            ),
          ),

          // ── Visit history (geofence) ─────────────────────────────────────
          if (task.geofenceVisits.isNotEmpty) ...[
            const SizedBox(height: 12),
            _SectionHeader(
              label: 'Visit History',
              icon: Icons.pin_drop_outlined,
            ),
            _Card(
              child: Column(
                children: task.geofenceVisits.asMap().entries.map((entry) {
                  final isLast =
                      entry.key == task.geofenceVisits.length - 1;
                  return Column(
                    children: [
                      _VisitRow(visit: entry.value),
                      if (!isLast) ...[
                        const SizedBox(height: 12),
                        const Divider(height: 1, color: Color(0xFFF3F4F6)),
                        const SizedBox(height: 12),
                      ],
                    ],
                  );
                }).toList(),
              ),
            ),
          ],

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  static String _statusLabel(String s) => switch (s) {
        'IN_PROGRESS' => 'In Progress',
        'COMPLETED' => 'Completed',
        'CANCELLED' => 'Cancelled',
        _ => 'Pending',
      };

  static String _cancelReasonLabel(String r) => switch (r) {
        'SHOP_CLOSED' => 'Shop Closed',
        'SHOP_RELOCATED' => 'Shop Relocated',
        'SHOP_PERMANENTLY_CLOSED' => 'Permanently Closed',
        'SHOP_NOT_FOUND' => 'Shop Not Found',
        'OTHER' => 'Other',
        _ => r,
      };

  static _SS _statusStyle(String s) => switch (s) {
        'IN_PROGRESS' =>
          const _SS(badgeColor: Color(0xFFDBEAFE), badgeText: Color(0xFF1D4ED8)),
        'COMPLETED' =>
          const _SS(badgeColor: Color(0xFFDCFCE7), badgeText: Color(0xFF166534)),
        'CANCELLED' =>
          const _SS(badgeColor: Color(0xFFF3F4F6), badgeText: Color(0xFF6B7280)),
        _ =>
          const _SS(badgeColor: Color(0xFFFEF3C7), badgeText: Color(0xFFB45309)),
      };

  static _SS _priorityStyle(String p) => switch (p) {
        'HIGH' =>
          const _SS(badgeColor: Color(0xFFFEE2E2), badgeText: Color(0xFFDC2626)),
        'LOW' =>
          const _SS(badgeColor: Color(0xFFF0FDF4), badgeText: Color(0xFF16A34A)),
        _ =>
          const _SS(badgeColor: Color(0xFFFFF7ED), badgeText: Color(0xFFEA580C)),
      };
}

class _SS {
  final Color badgeColor;
  final Color badgeText;
  const _SS({required this.badgeColor, required this.badgeText});
}

// ── Reusable widgets ──────────────────────────────────────────────────────────

class _Card extends StatelessWidget {
  final Widget child;

  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  final IconData icon;

  const _SectionHeader({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: const Color(0xFF1B5E4F)),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1B5E4F),
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF9CA3AF)),
        const SizedBox(width: 10),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF6B7280),
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: valueColor ?? const Color(0xFF111827),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ShopImage extends StatelessWidget {
  final String? url;
  const _ShopImage({required this.url});

  @override
  Widget build(BuildContext context) {
    final hasUrl = url != null && url!.isNotEmpty;
    // DecorationImage is used instead of Image.network to avoid registering
    // a dependency on the parent Scrollable's InheritedElement via
    // ScrollAwareImageProvider — that dependency can trip the
    // `_dependents.isEmpty` assertion when the Scrollable's sub-tree is
    // rapidly restructured during the demote-then-promote task update flow.
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: const Color(0xFFECFDF5),
        borderRadius: BorderRadius.circular(10),
        image: hasUrl
            ? DecorationImage(
                image: NetworkImage(url!),
                fit: BoxFit.cover,
                onError: (_, _) {},
              )
            : null,
      ),
      child: hasUrl
          ? null
          : const Center(
              child: Icon(
                Icons.storefront_outlined,
                size: 22,
                color: Color(0xFF1B5E4F),
              ),
            ),
    );
  }
}

class _PersonRow extends StatelessWidget {
  final String role;
  final String name;
  final Color color;
  final Color bg;
  final IconData icon;

  const _PersonRow({
    required this.role,
    required this.name,
    required this.color,
    required this.bg,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              role,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF9CA3AF),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              name,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF111827),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _VisitRow extends StatelessWidget {
  final TaskGeofenceVisit visit;

  const _VisitRow({required this.visit});

  String _durationLabel(int seconds) {
    if (seconds < 60) return '${seconds}s';
    final mins = (seconds / 60).round();
    if (mins < 60) return '$mins min';
    final h = mins ~/ 60;
    final m = mins % 60;
    return m == 0 ? '${h}h' : '${h}h ${m}m';
  }

  @override
  Widget build(BuildContext context) {
    final enter = visit.enteredAt.toLocal();
    final exit = visit.exitedAt.toLocal();
    final sameDay = enter.year == exit.year &&
        enter.month == exit.month &&
        enter.day == exit.day;
    final dateLabel = DateFormat('d MMM yyyy').format(enter);
    final enterTime = DateFormat('hh:mm a').format(enter);
    final exitTime = sameDay
        ? DateFormat('hh:mm a').format(exit)
        : DateFormat('d MMM, hh:mm a').format(exit);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: const BoxDecoration(
            color: Color(0xFFECFDF5),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.place_outlined,
            size: 18,
            color: Color(0xFF1B5E4F),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    dateLabel,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _durationLabel(visit.stayDurationSeconds),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF166534),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '$enterTime → $exitTime',
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF6B7280),
                ),
              ),
              if (visit.exitEstimated) ...[
                const SizedBox(height: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.info_outline,
                          size: 12, color: Color(0xFFB45309)),
                      SizedBox(width: 4),
                      Text(
                        'Exit ~approx',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFB45309),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }
}

// ── Skeleton ──────────────────────────────────────────────────────────────────

class _DetailSkeleton extends StatefulWidget {
  const _DetailSkeleton();

  @override
  State<_DetailSkeleton> createState() => _DetailSkeletonState();
}

class _DetailSkeletonState extends State<_DetailSkeleton>
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
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _SkeletonBox(color: c, height: 120, radius: 16),
              const SizedBox(height: 12),
              _SkeletonBox(color: c, height: 80, radius: 16),
              const SizedBox(height: 12),
              _SkeletonBox(color: c, height: 100, radius: 16),
              const SizedBox(height: 12),
              _SkeletonBox(color: c, height: 80, radius: 16),
            ],
          ),
        );
      },
    );
  }
}

class _SkeletonBox extends StatelessWidget {
  final Color color;
  final double height;
  final double radius;

  const _SkeletonBox({
    required this.color,
    required this.height,
    required this.radius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
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
