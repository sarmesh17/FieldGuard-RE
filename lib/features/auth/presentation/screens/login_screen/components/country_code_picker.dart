import 'package:flutter/material.dart';
import 'package:field_guard_re/core/constants/app_constants.dart';
import 'package:field_guard_re/core/theme/app_colors.dart';
import 'package:field_guard_re/core/theme/app_text_styles.dart';

class CountryCodePicker extends StatelessWidget {
  const CountryCodePicker({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.inputBackground,
          borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
          border: Border.all(color: AppColors.inputBorder, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🇳🇵', style: TextStyle(fontSize: 20)),
            const SizedBox(width: 6),
            Text(
              '+977',
              style: AppTextStyles.inputText.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.arrow_drop_down,
              size: 20,
              color: AppColors.textGray,
            ),
          ],
        ),
      ),
    );
  }
}
