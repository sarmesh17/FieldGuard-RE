import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:field_guard_re/core/router/app_routes.dart';
import 'package:field_guard_re/core/theme/app_colors.dart';
import 'package:field_guard_re/core/theme/app_responsive.dart';
import 'package:field_guard_re/core/theme/app_text_styles.dart';
import 'package:field_guard_re/features/collections/data/models/collection.dart';
import 'package:field_guard_re/features/collections/data/models/collection_response.dart';
import 'package:field_guard_re/features/collections/data/models/sms_preview.dart';

/// Confirmation screen shown after a successful `POST /collections`.
///
/// Adapts to the collection method:
///   * **CASH** — the backend sends the shop a verification SMS, so we show
///     "SMS Sent to {shop}" and render the verbatim SMS body.
///   * **CHEQUE** — the cheque is stored PENDING until it clears; there is no
///     "payment received" SMS to show, so we show "Cheque Recorded" with the
///     cheque details and a pending-clearance status instead of the SMS UI.
class SmsSentScreen extends StatelessWidget {
  final CollectionResponse response;

  const SmsSentScreen({super.key, required this.response});

  static final _money = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹ ',
    decimalDigits: 2,
  );

  @override
  Widget build(BuildContext context) {
    final hPad = AppResponsive.horizontalPad(context);
    final iconSize = AppResponsive.r(context, 120);

    final c = response.collection;
    final isCheque = c.method.toUpperCase() == 'CHEQUE';
    final shopName = c.shop?.name ?? 'Shop';
    final SmsPreview? preview = response.shopReceipt;
    final hasSms =
        !isCheque && preview != null && preview.body.trim().isNotEmpty;

    // The receipt SMS is best-effort — it can be silently dropped if the
    // company is over its monthly SMS limit (any plan). So we never claim it
    // was "sent"; the wording stays future/best-effort.
    final headline = isCheque ? 'Cheque Recorded' : 'Collection Recorded';
    final subtitle = shopName;

    return Scaffold(
      backgroundColor: AppColors.backgroundBeige,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 24),
                child: Column(
                  children: [
                    SizedBox(height: AppResponsive.r(context, 12)),
                    Container(
                      width: iconSize,
                      height: iconSize,
                      decoration: BoxDecoration(
                        color:
                            AppColors.lightGreenCircle.withValues(alpha: 0.4),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isCheque
                            ? Icons.receipt_long_rounded
                            : Icons.check_circle_outline_rounded,
                        size: AppResponsive.r(context, 52),
                        color: AppColors.primaryGreen,
                      ),
                    ),
                    SizedBox(height: AppResponsive.r(context, 28)),
                    Text(
                      headline,
                      style: AppTextStyles.heading1R(context).copyWith(
                        fontSize: AppResponsive.sp(context, 24),
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: AppResponsive.r(context, 6)),
                    Text(
                      subtitle,
                      style: AppTextStyles.subtitleR(context).copyWith(
                        color: AppColors.textLight,
                        fontSize: AppResponsive.sp(context, 14),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: AppResponsive.r(context, 28)),
                    if (isCheque)
                      _ChequeCard(collection: c, money: _money)
                    else if (hasSms)
                      _MessageCard(body: preview.body, shopName: shopName)
                    else
                      _AmountCard(amount: c.amount, money: _money),
                    SizedBox(height: AppResponsive.r(context, 16)),
                    const _RecordedChip(),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(hPad, 8, hPad, 24),
              child: SizedBox(
                width: double.infinity,
                height: AppResponsive.r(context, 54),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => context.go(AppRoutes.home),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Continue',
                        style: AppTextStyles.buttonTextR(context).copyWith(
                          fontSize: AppResponsive.sp(context, 16),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.arrow_forward,
                        size: AppResponsive.r(context, 20),
                      ),
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

// ── Cheque details card (CHEQUE) ──────────────────────────────────────────────

class _ChequeCard extends StatelessWidget {
  final Collection collection;
  final NumberFormat money;

  const _ChequeCard({required this.collection, required this.money});

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('d MMM yyyy');
    final chequeDate = collection.chequeDate;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: EdgeInsets.all(AppResponsive.r(context, 20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            money.format(collection.amount),
            style: TextStyle(
              color: AppColors.primaryGreen,
              fontWeight: FontWeight.bold,
              fontSize: AppResponsive.sp(context, 28),
            ),
          ),
          SizedBox(height: AppResponsive.r(context, 14)),
          _Row(label: 'Cheque No.', value: collection.chequeNumber),
          _Row(label: 'Bank', value: collection.chequeBank),
          _Row(
            label: 'Cheque date',
            value: chequeDate == null ? null : dateFmt.format(chequeDate),
          ),
          SizedBox(height: AppResponsive.r(context, 14)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.schedule_rounded,
                    size: 16, color: Color(0xFFB45309)),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'Pending bank clearance',
                    style: AppTextStyles.subtitleR(context).copyWith(
                      color: const Color(0xFFB45309),
                      fontWeight: FontWeight.w600,
                      fontSize: AppResponsive.sp(context, 13),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: AppResponsive.r(context, 10)),
          Text(
            'Shop will be notified when the cheque clears.',
            style: AppTextStyles.subtitleR(context).copyWith(
              color: AppColors.textLight,
              fontSize: AppResponsive.sp(context, 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String? value;
  const _Row({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    if (value == null || value!.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: AppResponsive.r(context, 100),
            child: Text(
              label,
              style: AppTextStyles.subtitleR(context).copyWith(
                color: AppColors.textLight,
                fontSize: AppResponsive.sp(context, 13),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value!,
              style: AppTextStyles.subtitleR(context).copyWith(
                color: Colors.black87,
                fontWeight: FontWeight.w600,
                fontSize: AppResponsive.sp(context, 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Amount-only card (cash without an SMS — edge case) ────────────────────────

class _AmountCard extends StatelessWidget {
  final double amount;
  final NumberFormat money;
  const _AmountCard({required this.amount, required this.money});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: EdgeInsets.all(AppResponsive.r(context, 20)),
      child: Column(
        children: [
          Text(
            'AMOUNT COLLECTED',
            style: AppTextStyles.labelR(context).copyWith(
              color: AppColors.textGray,
              fontSize: AppResponsive.sp(context, 11),
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            money.format(amount),
            style: TextStyle(
              color: AppColors.primaryGreen,
              fontWeight: FontWeight.bold,
              fontSize: AppResponsive.sp(context, 30),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Message card (CASH) ───────────────────────────────────────────────────────

class _MessageCard extends StatelessWidget {
  final String? body;
  final String shopName;
  const _MessageCard({required this.body, required this.shopName});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: EdgeInsets.all(AppResponsive.r(context, 20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Best-effort wording — the SMS can be dropped silently if the
          // company is over its monthly SMS limit, so never claim it was sent.
          Row(
            children: [
              Icon(
                Icons.mail_outline,
                size: AppResponsive.r(context, 17),
                color: AppColors.textGray,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Receipt will be sent to $shopName',
                  style: AppTextStyles.labelR(context).copyWith(
                    color: AppColors.textGray,
                    fontSize: AppResponsive.sp(context, 12),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: AppResponsive.r(context, 16)),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFD1FADF),
              borderRadius: BorderRadius.circular(12),
            ),
            padding: EdgeInsets.all(AppResponsive.r(context, 16)),
            child: Text(
              (body == null || body!.trim().isEmpty)
                  ? 'SMS preview unavailable'
                  : body!,
              style: AppTextStyles.subtitleR(context).copyWith(
                color: AppColors.primaryGreen,
                fontSize: AppResponsive.sp(context, 13),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Trust chip ──────────────────────────────────────────────────────────────

class _RecordedChip extends StatelessWidget {
  const _RecordedChip();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.lock_outline,
          size: AppResponsive.r(context, 14),
          color: AppColors.textLight,
        ),
        const SizedBox(width: 6),
        Text(
          'Recorded permanently',
          style: AppTextStyles.subtitleR(context).copyWith(
            color: AppColors.textLight,
            fontSize: AppResponsive.sp(context, 12),
          ),
        ),
      ],
    );
  }
}
