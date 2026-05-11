import 'package:flutter/material.dart';
import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/theme/app_responsive.dart';
import '../../../../../core/theme/app_text_styles.dart';
import 'illustration_card.dart';

class OnboardingPage extends StatelessWidget {
  const OnboardingPage({super.key, required this.pageIndex});

  final int pageIndex;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        IllustrationCard(pageIndex: pageIndex),
        SizedBox(height: AppResponsive.r(context, 36)),
        Text(
          AppStrings.onboardingTitles[pageIndex],
          textAlign: TextAlign.center,
          style: AppTextStyles.heading1R(context).copyWith(
            fontSize: AppResponsive.sp(context, 26),
            fontWeight: FontWeight.w800,
            height: 1.25,
          ),
        ),
        SizedBox(height: AppResponsive.r(context, 14)),
        Text(
          AppStrings.onboardingSubtitles[pageIndex],
          textAlign: TextAlign.center,
          style: AppTextStyles.subtitleR(context).copyWith(
            fontSize: AppResponsive.sp(context, 14),
            height: 1.6,
          ),
        ),
      ],
    );
  }
}
