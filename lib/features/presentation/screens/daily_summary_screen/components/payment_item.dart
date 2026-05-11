import 'package:flutter/material.dart';
import 'package:field_guard_re/core/theme/app_colors.dart';
import 'package:field_guard_re/core/theme/app_text_styles.dart';

class PaymentItem extends StatelessWidget {
  final String shopName;
  final String invoiceNumber;
  final String amount;
  final String paymentMethod;
  final Color methodColor;
  final Color methodTextColor;

  const PaymentItem({
    super.key,
    required this.shopName,
    required this.invoiceNumber,
    required this.amount,
    required this.paymentMethod,
    required this.methodColor,
    required this.methodTextColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                shopName,
                style: AppTextStyles.label.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                invoiceNumber,
                style: AppTextStyles.subtitle.copyWith(
                  fontSize: 13,
                  color: AppColors.textGray,
                ),
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              amount,
              style: AppTextStyles.label.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: methodColor,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                paymentMethod,
                style: AppTextStyles.label.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: methodTextColor,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
