import 'package:flutter/material.dart';
import 'package:field_guard_re/core/constants/app_constants.dart';
import 'package:field_guard_re/core/constants/app_strings.dart';
import 'package:field_guard_re/core/theme/app_colors.dart';
import 'package:field_guard_re/core/theme/app_responsive.dart';
import 'package:field_guard_re/core/theme/app_text_styles.dart';
import 'phone_input_row.dart';
import 'password_field.dart';
import 'sign_in_button.dart';

class FormCard extends StatelessWidget {
  const FormCard({
    super.key,
    required this.phoneController,
    required this.passwordController,
    required this.obscurePassword,
    required this.isLoading,
    required this.onTogglePassword,
    required this.onSignIn,
  });

  final TextEditingController phoneController;
  final TextEditingController passwordController;
  final bool obscurePassword;
  final bool isLoading;
  final VoidCallback onTogglePassword;
  final VoidCallback onSignIn;

  @override
  Widget build(BuildContext context) {
    final vPad = AppResponsive.r(context, 24);
    final hPad = AppResponsive.r(context, 20);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius + 4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 24,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(hPad, vPad, hPad, vPad + 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(AppStrings.mobileNumber, style: AppTextStyles.labelR(context)),
          SizedBox(height: AppResponsive.r(context, 10)),
          PhoneInputRow(controller: phoneController),
          SizedBox(height: AppResponsive.r(context, 20)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(AppStrings.password, style: AppTextStyles.labelR(context)),
              GestureDetector(
                onTap: () {},
                child: Text(
                  AppStrings.forgotPassword,
                  style: AppTextStyles.linkR(context),
                ),
              ),
            ],
          ),
          SizedBox(height: AppResponsive.r(context, 10)),
          PasswordField(
            controller: passwordController,
            obscureText: obscurePassword,
            onToggle: onTogglePassword,
          ),
          SizedBox(height: AppResponsive.r(context, 28)),
          SignInButton(isLoading: isLoading, onPressed: onSignIn),
          SizedBox(height: AppResponsive.r(context, 16)),
          GestureDetector(
            onTap: () {},
            child: Text(
              AppStrings.requestAccess,
              textAlign: TextAlign.center,
              style: AppTextStyles.linkR(context).copyWith(
                fontSize: AppResponsive.sp(context, 16),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
