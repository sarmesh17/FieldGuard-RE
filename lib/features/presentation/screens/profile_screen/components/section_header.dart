import 'package:flutter/material.dart';
import 'package:field_guard_re/core/theme/app_colors.dart';
import 'package:field_guard_re/core/theme/app_text_styles.dart';

class SectionHeader extends StatelessWidget {
  final String title;

  const SectionHeader({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        title,
        style: AppTextStyles.label.copyWith(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.textGray,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
