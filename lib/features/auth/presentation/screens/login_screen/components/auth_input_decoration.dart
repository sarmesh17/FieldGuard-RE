import 'package:flutter/material.dart';
import 'package:field_guard_re/core/constants/app_constants.dart';
import 'package:field_guard_re/core/theme/app_colors.dart';
import 'package:field_guard_re/core/theme/app_text_styles.dart';

/// Shared input decoration for the auth screen so the phone, password and
/// country-code fields read as one consistent set on the white card —
/// independent of the global theme's default input styling.
InputDecoration authInputDecoration({
  required String hintText,
  Widget? prefixIcon,
  Widget? suffixIcon,
}) {
  OutlineInputBorder border(Color color, double width) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
        borderSide: BorderSide(color: color, width: width),
      );

  return InputDecoration(
    hintText: hintText,
    hintStyle: AppTextStyles.inputHint,
    prefixIcon: prefixIcon,
    suffixIcon: suffixIcon,
    filled: true,
    fillColor: AppColors.inputBackground,
    // Fixed-ish vertical rhythm so the field matches the 56px country-code
    // box next to it. The error text renders below without resizing the box.
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
    enabledBorder: border(AppColors.inputBorder, 1),
    border: border(AppColors.inputBorder, 1),
    focusedBorder: border(AppColors.primaryGreen, 1.6),
    errorBorder: border(Colors.red.shade400, 1),
    focusedErrorBorder: border(Colors.red.shade600, 1.6),
  );
}
