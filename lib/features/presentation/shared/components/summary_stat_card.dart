import 'package:flutter/material.dart';
import 'package:field_guard_re/core/theme/app_colors.dart';
import 'package:field_guard_re/core/theme/app_responsive.dart';
import 'package:field_guard_re/core/theme/app_text_styles.dart';

/// A reusable stat card used on Daily Summary and Profile screens.
///
/// Optionally shows an [icon] above the value (Profile variant).
/// When no icon is provided the value is rendered larger (Daily Summary variant).
class SummaryStatCard extends StatelessWidget {
  final String value;
  final String label;

  /// Optional icon shown above the value (Profile screen style).
  final IconData? icon;

  const SummaryStatCard({
    super.key,
    required this.value,
    required this.label,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final hasIcon = icon != null;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: EdgeInsets.symmetric(
        vertical: AppResponsive.r(context, 16),
        horizontal: AppResponsive.r(context, 12),
      ),
      child: Column(
        children: [
          if (hasIcon) ...[
            Icon(
              icon,
              size: AppResponsive.r(context, 24),
              color: AppColors.primaryGreen,
            ),
            SizedBox(height: AppResponsive.r(context, 8)),
          ],
          Text(
            value,
            style: hasIcon
                ? AppTextStyles.label.copyWith(
                    fontSize: AppResponsive.sp(context, 18),
                    fontWeight: FontWeight.bold,
                  )
                : AppTextStyles.heading1.copyWith(
                    fontSize: AppResponsive.sp(context, 28),
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                  ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: hasIcon ? 2 : 4),
          Text(
            label,
            style: hasIcon
                ? AppTextStyles.subtitle.copyWith(
                    fontSize: AppResponsive.sp(context, 12),
                    color: AppColors.textGray,
                  )
                : AppTextStyles.label.copyWith(
                    fontSize: AppResponsive.sp(context, 10),
                    color: AppColors.textGray,
                    letterSpacing: 0.5,
                    height: 1.3,
                  ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
