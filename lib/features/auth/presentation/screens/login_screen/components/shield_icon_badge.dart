import 'package:flutter/material.dart';
import 'package:field_guard_re/core/theme/app_colors.dart';
import 'package:field_guard_re/core/theme/app_responsive.dart';

class ShieldIconBadge extends StatelessWidget {
  const ShieldIconBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final size = AppResponsive.r(context, 72);
    return Center(
      child: Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          color: AppColors.lightGreenCircle,
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.shield_outlined,
          size: AppResponsive.r(context, 36),
          color: AppColors.primaryGreen,
        ),
      ),
    );
  }
}
