import 'package:flutter/material.dart';
import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/theme/app_responsive.dart';
import '../../../../../core/theme/app_text_styles.dart';

class AlreadyHaveAccountRow extends StatelessWidget {
  const AlreadyHaveAccountRow({super.key, required this.onLogIn});

  final VoidCallback onLogIn;

  @override
  Widget build(BuildContext context) {
    final fontSize = AppResponsive.sp(context, 14);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '${AppStrings.alreadyHaveAccount} ',
          style: AppTextStyles.subtitle.copyWith(fontSize: fontSize),
        ),
        GestureDetector(
          onTap: onLogIn,
          child: Text(
            AppStrings.logIn,
            style: AppTextStyles.link.copyWith(
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
