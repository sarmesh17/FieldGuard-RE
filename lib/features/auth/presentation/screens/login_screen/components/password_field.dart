import 'package:flutter/material.dart';
import 'package:field_guard_re/core/constants/app_constants.dart';
import 'package:field_guard_re/core/constants/app_strings.dart';
import 'package:field_guard_re/core/theme/app_colors.dart';
import 'package:field_guard_re/core/theme/app_text_styles.dart';

class PasswordField extends StatelessWidget {
  const PasswordField({
    super.key,
    required this.controller,
    required this.obscureText,
    required this.onToggle,
  });

  final TextEditingController controller;
  final bool obscureText;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      style: AppTextStyles.inputText,
      decoration: InputDecoration(
        hintText: AppStrings.enterPassword,
        hintStyle: AppTextStyles.inputHint,
        suffixIcon: IconButton(
          onPressed: onToggle,
          icon: Icon(
            obscureText
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            color: AppColors.textGray,
            size: 22,
          ),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) return AppStrings.passwordRequired;
        if (value.length < AppConstants.minPasswordLength) {
          return AppStrings.passwordTooShort;
        }
        return null;
      },
    );
  }
}
