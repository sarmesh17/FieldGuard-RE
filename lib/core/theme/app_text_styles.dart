import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_responsive.dart';

/// Static text style constants (theme defaults).
///
/// Use the static getters when a BuildContext is not available (e.g. inside
/// ThemeData). Use the responsive factory methods ([heading1R], [subtitleR],
/// etc.) whenever a BuildContext is accessible — they scale font sizes to the
/// current screen width automatically.
class AppTextStyles {
  AppTextStyles._();

  // ── Static (context-free) ────────────────────────────────────────────────

  static const TextStyle heading1 = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: AppColors.textDark,
    letterSpacing: -0.5,
  );

  static const TextStyle subtitle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.textGray,
    height: 1.5,
  );

  static const TextStyle label = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.textDark,
  );

  static const TextStyle inputText = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.textDark,
  );

  static const TextStyle inputHint = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.textLight,
  );

  static const TextStyle buttonText = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.buttonTextWhite,
    letterSpacing: 0.2,
  );

  static const TextStyle link = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.tealAccent,
  );

  static const TextStyle linkDark = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: AppColors.textDark,
  );

  static const TextStyle version = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textLight,
  );

  // ── Responsive (requires BuildContext) ──────────────────────────────────

  static TextStyle heading1R(BuildContext context) => heading1.copyWith(
        fontSize: AppResponsive.sp(context, 28),
      );

  static TextStyle subtitleR(BuildContext context) => subtitle.copyWith(
        fontSize: AppResponsive.sp(context, 16),
      );

  static TextStyle labelR(BuildContext context) => label.copyWith(
        fontSize: AppResponsive.sp(context, 14),
      );

  static TextStyle inputTextR(BuildContext context) => inputText.copyWith(
        fontSize: AppResponsive.sp(context, 16),
      );

  static TextStyle inputHintR(BuildContext context) => inputHint.copyWith(
        fontSize: AppResponsive.sp(context, 16),
      );

  static TextStyle buttonTextR(BuildContext context) => buttonText.copyWith(
        fontSize: AppResponsive.sp(context, 16),
      );

  static TextStyle linkR(BuildContext context) => link.copyWith(
        fontSize: AppResponsive.sp(context, 14),
      );

  static TextStyle versionR(BuildContext context) => version.copyWith(
        fontSize: AppResponsive.sp(context, 12),
      );
}
