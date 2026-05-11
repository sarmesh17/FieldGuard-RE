import 'package:flutter/material.dart';
import 'package:field_guard_re/core/theme/app_colors.dart';
import 'package:field_guard_re/core/theme/app_responsive.dart';
import 'package:field_guard_re/core/theme/app_text_styles.dart';

class SmsSentScreen extends StatelessWidget {
  final String shopName;
  final String phoneNumber;
  final String amount;
  final String repName;
  final String time;

  const SmsSentScreen({
    super.key,
    required this.shopName,
    required this.phoneNumber,
    required this.amount,
    required this.repName,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    final hPad = AppResponsive.horizontalPad(context);
    final iconSize = AppResponsive.r(context, 120);

    return Scaffold(
      backgroundColor: AppColors.backgroundBeige,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: hPad),
          child: Column(
            children: [
              const Spacer(flex: 2),
              Container(
                width: iconSize,
                height: iconSize,
                decoration: BoxDecoration(
                  color: AppColors.lightGreenCircle.withValues(alpha: 0.4),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.mail_outline_rounded,
                  size: AppResponsive.r(context, 50),
                  color: AppColors.primaryGreen,
                ),
              ),
              SizedBox(height: AppResponsive.r(context, 32)),
              Text(
                'SMS Sent to $shopName',
                style: AppTextStyles.heading1R(context).copyWith(
                  fontSize: AppResponsive.sp(context, 24),
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: AppResponsive.r(context, 8)),
              Text(
                phoneNumber,
                style: AppTextStyles.subtitleR(context).copyWith(
                  color: AppColors.textLight,
                  fontSize: AppResponsive.sp(context, 14),
                ),
              ),
              SizedBox(height: AppResponsive.r(context, 32)),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.cardWhite,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                padding: EdgeInsets.all(AppResponsive.r(context, 20)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: AppResponsive.r(context, 17),
                          color: AppColors.textGray,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'MESSAGE SENT',
                          style: AppTextStyles.labelR(context).copyWith(
                            color: AppColors.textGray,
                            fontSize: AppResponsive.sp(context, 11),
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: AppResponsive.r(context, 16)),
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD1FADF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: EdgeInsets.all(AppResponsive.r(context, 16)),
                      child: Text(
                        'Dear $shopName, Rep $repName collected ₹$amount from your shop at $time. Reply 1 if correct, Reply 2 if wrong.',
                        style: AppTextStyles.subtitleR(context).copyWith(
                          color: AppColors.primaryGreen,
                          fontSize: AppResponsive.sp(context, 13),
                          height: 1.5,
                        ),
                      ),
                    ),
                    SizedBox(height: AppResponsive.r(context, 16)),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.lock_outline,
                          size: AppResponsive.r(context, 14),
                          color: AppColors.textLight,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Tamper-proof · Cannot be edited',
                          style: AppTextStyles.subtitleR(context).copyWith(
                            color: AppColors.textLight,
                            fontSize: AppResponsive.sp(context, 12),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: AppResponsive.r(context, 32)),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: AppResponsive.r(context, 16),
                    height: AppResponsive.r(context, 16),
                    child: const CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(AppColors.textGray),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Waiting for shopkeeper reply...',
                    style: AppTextStyles.subtitleR(context).copyWith(
                      color: AppColors.textGray,
                      fontSize: AppResponsive.sp(context, 13),
                    ),
                  ),
                ],
              ),
              const Spacer(flex: 3),
              SizedBox(
                width: double.infinity,
                height: AppResponsive.r(context, 54),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {},
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Continue to Next Task',
                        style: AppTextStyles.buttonTextR(context).copyWith(
                          fontSize: AppResponsive.sp(context, 16),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.arrow_forward,
                        size: AppResponsive.r(context, 20),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {},
                child: Text(
                  'View Visit Summary',
                  style: AppTextStyles.linkR(context).copyWith(
                    color: AppColors.primaryGreen,
                    fontSize: AppResponsive.sp(context, 15),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
