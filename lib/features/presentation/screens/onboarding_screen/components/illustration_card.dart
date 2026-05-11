import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';

class IllustrationCard extends StatelessWidget {
  const IllustrationCard({super.key, required this.pageIndex});

  final int pageIndex;

  static const List<String> _images = [
    'assets/images/stay_ahead_in_the_field.png',
    'assets/images/know_every_visit_img.png',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.onboardingImageBg,
        borderRadius: BorderRadius.circular(24),
      ),
      clipBehavior: Clip.antiAlias,
      child: AspectRatio(
        aspectRatio: 1.25,
        child: Image.asset(
          _images[pageIndex],
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
        ),
      ),
    );
  }
}
