import 'package:flutter/material.dart';
import 'package:field_guard_re/core/theme/app_colors.dart';
import 'package:field_guard_re/core/theme/app_responsive.dart';

/// A reusable quick-action tile used across multiple screens.
///
/// [variant] controls the layout:
/// - [QuickActionVariant.vertical] — icon above label (used on Home screen).
/// - [QuickActionVariant.horizontal] — icon in a coloured circle beside label
///   (used on Active Visit screen). Requires [backgroundColor].
enum QuickActionVariant { vertical, horizontal }

class QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final QuickActionVariant variant;

  /// Background colour for the icon circle — only used in [QuickActionVariant.horizontal].
  final Color? backgroundColor;

  const QuickActionCard({
    super.key,
    required this.icon,
    required this.label,
    this.variant = QuickActionVariant.vertical,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return variant == QuickActionVariant.vertical
        ? _VerticalLayout(icon: icon, label: label)
        : _HorizontalLayout(
            icon: icon,
            label: label,
            backgroundColor: backgroundColor ?? AppColors.lightGreenCircle,
          );
  }
}

// ── Vertical layout (Home screen) ─────────────────────────────────────────────

class _VerticalLayout extends StatelessWidget {
  final IconData icon;
  final String label;

  const _VerticalLayout({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final boxSize = AppResponsive.r(context, 56);
    final iconSize = AppResponsive.r(context, 28);
    final fontSize = AppResponsive.sp(context, 12);

    return Column(
      children: [
        Container(
          width: boxSize,
          height: boxSize,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(icon, color: AppColors.primaryGreen, size: iconSize),
        ),
        SizedBox(height: AppResponsive.r(context, 6)),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: fontSize,
            color: AppColors.primaryGreen,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// ── Horizontal layout (Active Visit screen) ───────────────────────────────────
// Uses intrinsic sizing so it works in both Wrap and Row contexts without
// a hard-coded width. Wrap handles multi-row reflowing on small screens.

class _HorizontalLayout extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color backgroundColor;

  const _HorizontalLayout({
    required this.icon,
    required this.label,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final minH = AppResponsive.r(context, 72);
    final fontSize = AppResponsive.sp(context, 14);

    return ConstrainedBox(
      constraints: BoxConstraints(
        minWidth: AppResponsive.wp(context, 40),
        maxWidth: AppResponsive.wp(context, 48),
        minHeight: minH,
      ),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: AppResponsive.r(context, 12),
          vertical: AppResponsive.r(context, 12),
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: AppResponsive.r(context, 20),
              backgroundColor: backgroundColor,
              child: Icon(
                icon,
                color: AppColors.primaryGreen,
                size: AppResponsive.r(context, 20),
              ),
            ),
            SizedBox(width: AppResponsive.r(context, 10)),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
