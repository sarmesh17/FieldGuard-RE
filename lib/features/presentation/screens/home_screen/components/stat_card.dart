import 'package:flutter/material.dart';
import '../../../../../core/theme/app_responsive.dart';

class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final Color? valueColor;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(
          vertical: AppResponsive.r(context, 18),
          horizontal: AppResponsive.r(context, 8),
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: AppResponsive.sp(context, 28),
                fontWeight: FontWeight.bold,
                color: valueColor ?? const Color(0xFF157347),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: AppResponsive.sp(context, 13),
                color: const Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
