import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:field_guard_re/core/router/app_routes.dart';
import 'package:field_guard_re/core/theme/app_colors.dart';
import 'package:field_guard_re/core/theme/app_responsive.dart';
import 'package:field_guard_re/core/theme/app_text_styles.dart';
import 'package:field_guard_re/features/auth/presentation/providers/auth_provider.dart';
import 'package:field_guard_re/features/collections/data/models/collection_request.dart';
import 'package:field_guard_re/features/collections/presentation/providers/collections_provider.dart';
import 'package:field_guard_re/features/tasks/presentation/providers/tasks_provider.dart';

/// Cash / cheque collection screen.
///
/// Reached from `TaskDetailScreen` (FAB) for the shop attached to the active
/// task. The screen:
///   1. Pulls the outstanding ledger summary for [shopId] via
///      `shopOutstandingProvider` and headlines `outstanding`.
///   2. Lets the rep enter an amount + pick method (CASH / CHEQUE). For
///      CHEQUE, three extra fields appear (number / bank / date) — the API
///      stores cheques as PENDING until they clear.
///   3. Submits via `collectionSubmitProvider`. On success the backend sends
///      the verification SMS, we invalidate outstanding + task caches, and
///      navigate to `SmsSentScreen`.
///
/// The route passes [shopId], [shopName] and [taskId] via `extra`; `taskId`
/// is optional so we can later open this screen from a shop-only entry
/// point (e.g. a standalone "Collect" action on `ShopDetailScreen`).
class CollectPaymentScreen extends ConsumerStatefulWidget {
  final int shopId;
  final String shopName;
  final int? taskId;

  const CollectPaymentScreen({
    super.key,
    required this.shopId,
    required this.shopName,
    this.taskId,
  });

  @override
  ConsumerState<CollectPaymentScreen> createState() =>
      _CollectPaymentScreenState();
}

class _CollectPaymentScreenState extends ConsumerState<CollectPaymentScreen> {
  final _amountCtl = TextEditingController();
  final _chequeNumberCtl = TextEditingController();
  final _chequeBankCtl = TextEditingController();
  final _notesCtl = TextEditingController();

  CollectionMethod _method = CollectionMethod.cash;
  DateTime? _chequeDate;
  double _amount = 0;

  static final _money = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹ ',
    decimalDigits: 2,
  );

  @override
  void initState() {
    super.initState();
    _amountCtl.addListener(() {
      final parsed = double.tryParse(_amountCtl.text.trim()) ?? 0;
      if (parsed != _amount) setState(() => _amount = parsed);
    });
  }

  @override
  void dispose() {
    _amountCtl.dispose();
    _chequeNumberCtl.dispose();
    _chequeBankCtl.dispose();
    _notesCtl.dispose();
    super.dispose();
  }

  // ── Submission ──────────────────────────────────────────────────────────

  bool get _canSubmit {
    if (_amount <= 0) return false;
    if (_method == CollectionMethod.cheque) {
      if (_chequeNumberCtl.text.trim().isEmpty) return false;
      if (_chequeBankCtl.text.trim().isEmpty) return false;
      if (_chequeDate == null) return false;
    }
    return true;
  }

  Future<void> _onConfirm() async {
    if (!_canSubmit) return;
    FocusScope.of(context).unfocus();

    final req = CollectionRequest(
      shopId: widget.shopId,
      amount: _amount,
      method: _method,
      chequeNumber: _method == CollectionMethod.cheque
          ? _chequeNumberCtl.text.trim()
          : null,
      chequeBank: _method == CollectionMethod.cheque
          ? _chequeBankCtl.text.trim()
          : null,
      chequeDate: _method == CollectionMethod.cheque ? _chequeDate : null,
      notes: _notesCtl.text.trim().isEmpty ? null : _notesCtl.text.trim(),
    );

    await ref.read(collectionSubmitProvider.notifier).submit(req);
  }

  void _onSubmitStateChange(CollectionSubmitState? prev,
      CollectionSubmitState next) {
    if (next is CollectionSubmitSuccess) {
      // Outstanding is stale now — refetch on next view. Also invalidate the
      // task so any "collected so far" indicator can pick up the change.
      ref.invalidate(shopOutstandingProvider(widget.shopId));
      if (widget.taskId != null) {
        ref.invalidate(taskDetailProvider(widget.taskId!));
      }

      // Pull rep name from auth so the SMS preview matches what the
      // backend actually sent. Phone we don't have on this screen — pass
      // a placeholder; the SMS Sent screen treats it as display-only.
      final auth = ref.read(authNotifierProvider);
      final repName = auth is AuthSuccess ? auth.response.user.name : 'Rep';
      final time = DateFormat('HH:mm').format(DateTime.now());

      context.pushReplacement(AppRoutes.smsSent, extra: <String, String>{
        'shopName': widget.shopName,
        'phoneNumber': '',
        'amount': _amount.toStringAsFixed(2),
        'repName': repName,
        'time': time,
      });

      // Reset for safety — the notifier auto-disposes anyway but if the
      // screen rebuilds before disposal we don't want to re-trigger.
      ref.read(collectionSubmitProvider.notifier).reset();
    } else if (next is CollectionSubmitError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(next.message),
          backgroundColor: Colors.red.shade700,
        ),
      );
      ref.read(collectionSubmitProvider.notifier).reset();
    }
  }

  // ── Build ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    ref.listen<CollectionSubmitState>(
      collectionSubmitProvider,
      _onSubmitStateChange,
    );

    final hPad = AppResponsive.horizontalPad(context);
    final submitState = ref.watch(collectionSubmitProvider);
    final outstandingAsync = ref.watch(shopOutstandingProvider(widget.shopId));
    final isLoading = submitState is CollectionSubmitLoading;

    return Scaffold(
      backgroundColor: AppColors.backgroundBeige,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => context.pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Collect Payment',
              style: AppTextStyles.heading1R(context).copyWith(
                fontSize: AppResponsive.sp(context, 20),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              widget.shopName,
              style: AppTextStyles.subtitleR(context).copyWith(
                fontSize: AppResponsive.sp(context, 13),
              ),
            ),
          ],
        ),
        centerTitle: false,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 8),
              child: Column(
                children: [
                  _OutstandingCard(
                    async: outstandingAsync,
                    money: _money,
                    onRetry: () => ref
                        .invalidate(shopOutstandingProvider(widget.shopId)),
                  ),
                  SizedBox(height: AppResponsive.r(context, 16)),
                  _HandoverNotice(),
                  SizedBox(height: AppResponsive.r(context, 16)),
                  _AmountAndMethodCard(
                    amountCtl: _amountCtl,
                    method: _method,
                    onMethodChange: (m) => setState(() => _method = m),
                    chequeNumberCtl: _chequeNumberCtl,
                    chequeBankCtl: _chequeBankCtl,
                    chequeDate: _chequeDate,
                    onPickChequeDate: _pickChequeDate,
                    notesCtl: _notesCtl,
                  ),
                ],
              ),
            ),
          ),
          // Confirm button — pinned to bottom, disabled until the form is
          // valid for the current method.
          Padding(
            padding: EdgeInsets.all(AppResponsive.r(context, 16)),
            child: SizedBox(
              width: double.infinity,
              height: AppResponsive.r(context, 54),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  disabledBackgroundColor:
                      AppColors.primaryGreen.withValues(alpha: 0.4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: (_canSubmit && !isLoading) ? _onConfirm : null,
                child: isLoading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        'Confirm & Send SMS',
                        style: AppTextStyles.buttonTextR(context).copyWith(
                          fontSize: AppResponsive.sp(context, 16),
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickChequeDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _chequeDate ?? now,
      // Cheques are typically dated within a few months either side — give
      // a generous window without being silly.
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 1),
    );
    if (picked != null) setState(() => _chequeDate = picked);
  }
}

// ─── Outstanding card ─────────────────────────────────────────────────────

class _OutstandingCard extends StatelessWidget {
  final AsyncValue async;
  final NumberFormat money;
  final VoidCallback onRetry;

  const _OutstandingCard({
    required this.async,
    required this.money,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: const Border(
          left: BorderSide(color: AppColors.primaryGreen, width: 5),
        ),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: AppResponsive.r(context, 20),
        vertical: AppResponsive.r(context, 18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'OUTSTANDING BALANCE',
            style: AppTextStyles.labelR(context).copyWith(
              color: AppColors.textGray,
              fontWeight: FontWeight.w600,
              fontSize: AppResponsive.sp(context, 12),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          async.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primaryGreen,
                ),
              ),
            ),
            error: (_, _) => Row(
              children: [
                Expanded(
                  child: Text(
                    'Could not load balance',
                    style: TextStyle(
                      color: Colors.red.shade700,
                      fontSize: AppResponsive.sp(context, 14),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: onRetry,
                  child: const Text('Retry'),
                ),
              ],
            ),
            data: (data) {
              final outstanding = data.outstanding as double;
              final pendingCheques = data.pendingCheques as double;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    money.format(outstanding),
                    style: TextStyle(
                      color: outstanding > 0
                          ? Colors.red
                          : AppColors.primaryGreen,
                      fontWeight: FontWeight.bold,
                      fontSize: AppResponsive.sp(context, 32),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    pendingCheques > 0
                        ? '${money.format(pendingCheques)} in pending cheques'
                        : 'As of today',
                    style: AppTextStyles.subtitleR(context).copyWith(
                      color: AppColors.textLight,
                      fontSize: AppResponsive.sp(context, 13),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

// ─── Handover notice ──────────────────────────────────────────────────────

class _HandoverNotice extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFD1FADF),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: AppResponsive.r(context, 16),
        vertical: AppResponsive.r(context, 14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            color: AppColors.primaryGreen,
            size: AppResponsive.r(context, 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Hand the phone to the shopkeeper. They will enter the amount they are paying.',
              style: AppTextStyles.subtitleR(context).copyWith(
                color: AppColors.primaryGreen,
                fontSize: AppResponsive.sp(context, 13),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Amount + method card ─────────────────────────────────────────────────

class _AmountAndMethodCard extends StatelessWidget {
  final TextEditingController amountCtl;
  final CollectionMethod method;
  final ValueChanged<CollectionMethod> onMethodChange;
  final TextEditingController chequeNumberCtl;
  final TextEditingController chequeBankCtl;
  final DateTime? chequeDate;
  final VoidCallback onPickChequeDate;
  final TextEditingController notesCtl;

  const _AmountAndMethodCard({
    required this.amountCtl,
    required this.method,
    required this.onMethodChange,
    required this.chequeNumberCtl,
    required this.chequeBankCtl,
    required this.chequeDate,
    required this.onPickChequeDate,
    required this.notesCtl,
  });

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('d MMM yyyy');

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: EdgeInsets.symmetric(
        horizontal: AppResponsive.r(context, 20),
        vertical: AppResponsive.r(context, 18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionLabel(text: 'ENTER AMOUNT'),
          const SizedBox(height: 8),
          TextField(
            controller: amountCtl,
            // Allow up to 2 decimals; the backend stores Decimal.
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
            ],
            style: AppTextStyles.inputTextR(context).copyWith(
              fontSize: AppResponsive.sp(context, 28),
              fontWeight: FontWeight.bold,
            ),
            decoration: InputDecoration(
              prefixText: '₹ ',
              prefixStyle: AppTextStyles.inputTextR(context).copyWith(
                fontSize: AppResponsive.sp(context, 28),
                fontWeight: FontWeight.bold,
                color: AppColors.textLight,
              ),
              hintText: '0',
              hintStyle: AppTextStyles.inputHintR(context).copyWith(
                fontSize: AppResponsive.sp(context, 28),
                fontWeight: FontWeight.bold,
              ),
              border: _border(),
              enabledBorder: _border(),
              focusedBorder: _border(focused: true),
              contentPadding: const EdgeInsets.symmetric(
                vertical: 8,
                horizontal: 16,
              ),
            ),
          ),
          SizedBox(height: AppResponsive.r(context, 18)),
          _SectionLabel(text: 'PAYMENT METHOD'),
          const SizedBox(height: 10),
          Wrap(
            spacing: AppResponsive.r(context, 10),
            runSpacing: 8,
            children: [
              for (final m in CollectionMethod.values)
                ChoiceChip(
                  label: Text(
                    _methodLabel(m),
                    style: AppTextStyles.labelR(context).copyWith(
                      fontWeight: FontWeight.w600,
                      color: m == method
                          ? AppColors.buttonTextWhite
                          : AppColors.textGray,
                      fontSize: AppResponsive.sp(context, 14),
                    ),
                  ),
                  selected: m == method,
                  selectedColor: AppColors.primaryGreen,
                  backgroundColor: AppColors.cardWhite,
                  side: m == method
                      ? BorderSide.none
                      : const BorderSide(color: AppColors.inputBorder),
                  onSelected: (_) => onMethodChange(m),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(22),
                  ),
                  labelPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 2,
                  ),
                ),
            ],
          ),
          // Cheque-only fields. AnimatedSize keeps the layout smooth when
          // toggling between CASH and CHEQUE.
          AnimatedSize(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            child: method == CollectionMethod.cheque
                ? Padding(
                    padding: const EdgeInsets.only(top: 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SectionLabel(text: 'CHEQUE NUMBER'),
                        const SizedBox(height: 6),
                        TextField(
                          controller: chequeNumberCtl,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          decoration: InputDecoration(
                            hintText: 'e.g. 100234',
                            border: _border(),
                            enabledBorder: _border(),
                            focusedBorder: _border(focused: true),
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 12,
                              horizontal: 16,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        _SectionLabel(text: 'BANK'),
                        const SizedBox(height: 6),
                        TextField(
                          controller: chequeBankCtl,
                          textCapitalization: TextCapitalization.words,
                          decoration: InputDecoration(
                            hintText: 'e.g. Nepal Bank Ltd',
                            border: _border(),
                            enabledBorder: _border(),
                            focusedBorder: _border(focused: true),
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 12,
                              horizontal: 16,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        _SectionLabel(text: 'CHEQUE DATE'),
                        const SizedBox(height: 6),
                        InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: onPickChequeDate,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.inputBorder,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.calendar_today_outlined,
                                  size: 18,
                                  color: AppColors.textGray,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  chequeDate == null
                                      ? 'Select date'
                                      : dateFmt.format(chequeDate!),
                                  style: TextStyle(
                                    fontSize:
                                        AppResponsive.sp(context, 15),
                                    color: chequeDate == null
                                        ? AppColors.textLight
                                        : Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          SizedBox(height: AppResponsive.r(context, 18)),
          _SectionLabel(text: 'NOTES (OPTIONAL)'),
          const SizedBox(height: 6),
          TextField(
            controller: notesCtl,
            maxLines: 2,
            decoration: InputDecoration(
              hintText: 'Add any note for this collection…',
              border: _border(),
              enabledBorder: _border(),
              focusedBorder: _border(focused: true),
              contentPadding: const EdgeInsets.symmetric(
                vertical: 12,
                horizontal: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _methodLabel(CollectionMethod m) => switch (m) {
        CollectionMethod.cash => 'Cash',
        CollectionMethod.cheque => 'Cheque',
      };

  static OutlineInputBorder _border({bool focused = false}) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: focused
            ? const BorderSide(color: AppColors.primaryGreen, width: 1.5)
            : const BorderSide(color: AppColors.inputBorder),
      );
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTextStyles.labelR(context).copyWith(
        color: AppColors.textGray,
        fontWeight: FontWeight.w600,
        fontSize: AppResponsive.sp(context, 12),
        letterSpacing: 0.5,
      ),
    );
  }
}
