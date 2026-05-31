import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:field_guard_re/core/router/app_routes.dart';
import 'package:field_guard_re/core/theme/app_colors.dart';
import 'package:field_guard_re/core/theme/app_responsive.dart';
import 'package:field_guard_re/core/theme/app_text_styles.dart';
import 'package:field_guard_re/features/collections/data/models/collection_response.dart';
import 'package:field_guard_re/features/collections/data/models/sms_preview.dart';

/// Confirmation screen shown after a successful `POST /collections`.
///
/// Renders the **verbatim SMS body** the backend generated (and dispatched
/// to the shop owner) — no client templating, no reply prompt, no
/// waiting-for-reply state. The backend is the single source of truth for
/// what the shop owner actually received (NPR amounts, employee name,
/// outstanding, helpline — all already in the body).
///
/// Pulled from `extra.response` (a [CollectionResponse]) so we have:
///   * `shop.name` — for the headline ("SMS Sent to {shop}")
///   * `shopReceipt.body` / `.recipient` — for the message card
///   * `collector.fullName` — surfaced as the rep who collected
class SmsSentScreen extends StatelessWidget {
  final CollectionResponse response;

  const SmsSentScreen({super.key, required this.response});

  @override
  Widget build(BuildContext context) {
    final hPad = AppResponsive.horizontalPad(context);
    final iconSize = AppResponsive.r(context, 120);

    final shopName = response.collection.shop?.name ?? 'Shop';
    final repName = response.collection.collector?.fullName ?? '—';
    final SmsPreview? preview = response.shopReceipt;

    return Scaffold(
      backgroundColor: AppColors.backgroundBeige,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: hPad),
          child: Column(
            children: [
              const Spacer(flex: 2),
              Container(
                width: iconSize,
                height: iconSize,
                decoration: BoxDecoration(
                  color: AppColors.lightGreenCircle.withValues(alpha: 0.4),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.mail_outline_rounded,
                  size: AppResponsive.r(context, 50),
                  color: AppColors.primaryGreen,
                ),
              ),
              SizedBox(height: AppResponsive.r(context, 32)),
              Text(
                'SMS Sent to $shopName',
                style: AppTextStyles.heading1R(context).copyWith(
                  fontSize: AppResponsive.sp(context, 24),
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: AppResponsive.r(context, 6)),
              Text(
                preview?.recipient.isNotEmpty == true
                    ? preview!.recipient
                    : 'By: $repName',
                style: AppTextStyles.subtitleR(context).copyWith(
                  color: AppColors.textLight,
                  fontSize: AppResponsive.sp(context, 14),
                ),
              ),
              SizedBox(height: AppResponsive.r(context, 28)),
              _MessageCard(body: preview?.body),
              SizedBox(height: AppResponsive.r(context, 16)),
              const _RecordedChip(),
              const Spacer(flex: 3),
              SizedBox(
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
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Message card ────────────────────────────────────────────────────────────

class _MessageCard extends StatelessWidget {
  final String? body;
  const _MessageCard({required this.body});

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
          Row(
            children: [
              Icon(
                Icons.chat_bubble_outline,
                size: AppResponsive.r(context, 17),
                color: AppColors.textGray,
              ),
              const SizedBox(width: 8),
              Text(
                'MESSAGE SENT',
                style: AppTextStyles.labelR(context).copyWith(
                  color: AppColors.textGray,
                  fontSize: AppResponsive.sp(context, 11),
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
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
              // Render the body **verbatim** — backend already writes NPR,
              // employee name, outstanding and helpline into this text. If
              // the body is somehow missing, say so honestly rather than
              // showing a fake fallback.
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

/// Honest replacement for the previous "Tamper-proof · Cannot be edited"
/// chip. The collection row is immutable in the DB — the *content* of the
/// SMS is not cryptographically signed, so we don't claim that.
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
