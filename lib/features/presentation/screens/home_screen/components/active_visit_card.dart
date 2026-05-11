import 'package:flutter/material.dart';
import '../../../../../core/theme/app_responsive.dart';

class ActiveVisitCard extends StatelessWidget {
  const ActiveVisitCard({super.key});

  @override
  Widget build(BuildContext context) {
    final pad = AppResponsive.r(context, 20);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(pad),
      decoration: BoxDecoration(
        color: const Color(0xFF157347),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'ACTIVE VISIT',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: AppResponsive.sp(context, 13),
                  fontWeight: FontWeight.w600,
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                  padding: EdgeInsets.symmetric(
                    horizontal: AppResponsive.r(context, 18),
                    vertical: AppResponsive.r(context, 8),
                  ),
                ),
                onPressed: () {},
                child: Row(
                  children: [
                    const Icon(Icons.circle, color: Colors.red, size: 10),
                    const SizedBox(width: 6),
                    Text(
                      'End Visit',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: AppResponsive.sp(context, 14),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: AppResponsive.r(context, 10)),
          Text(
            'Sharma General Store',
            style: TextStyle(
              color: Colors.white,
              fontSize: AppResponsive.sp(context, 22),
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: AppResponsive.r(context, 10)),
          Row(
            children: [
              Text(
                '00:12:34',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: AppResponsive.sp(context, 28),
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              SizedBox(width: AppResponsive.r(context, 16)),
              Row(
                children: [
                  Icon(
                    Icons.verified,
                    color: const Color(0xFFD1FADF),
                    size: AppResponsive.r(context, 18),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'NFC Verified',
                    style: TextStyle(
                      color: const Color(0xFFD1FADF),
                      fontWeight: FontWeight.w600,
                      fontSize: AppResponsive.sp(context, 13),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
