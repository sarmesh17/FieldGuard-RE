import 'package:flutter/material.dart';
import 'package:field_guard_re/core/theme/app_colors.dart';
import 'package:field_guard_re/core/theme/app_responsive.dart';

class ShieldIconBadge extends StatelessWidget {
  const ShieldIconBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final size = AppResponsive.r(context, 84);
    return Center(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.16),
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.35),
            width: 1.5,
          ),
        ),
        child: Center(
          child: Container(
            width: AppResponsive.r(context, 60),
            height: AppResponsive.r(context, 60),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.shield_outlined,
              size: AppResponsive.r(context, 32),
              color: AppColors.primaryGreen,
            ),
          ),
        ),
      ),
    );
  }
}
