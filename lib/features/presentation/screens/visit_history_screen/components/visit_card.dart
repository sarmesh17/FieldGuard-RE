import 'package:flutter/material.dart';
import 'package:field_guard_re/core/theme/app_colors.dart';
import 'package:field_guard_re/core/theme/app_text_styles.dart';

class VisitCard extends StatelessWidget {
  final String shopName;
  final String shopType;
  final String time;
  final String duration;
  final String verificationMethod;
  final bool isConfirmed;
  final Color borderColor;

  const VisitCard({
    super.key,
    required this.shopName,
    required this.shopType,
    required this.time,
    required this.duration,
    required this.verificationMethod,
    required this.isConfirmed,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final isManual = verificationMethod == 'Manual Entry';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border(
          left: BorderSide(color: borderColor, width: 4),
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      shopName,
                      style: AppTextStyles.label.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.store_outlined,
                          size: 14,
                          color: AppColors.textGray,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          shopType,
                          style: AppTextStyles.subtitle.copyWith(
                            fontSize: 13,
                            color: AppColors.textGray,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.backgroundBeige,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  time,
                  style: AppTextStyles.label.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textGray,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Duration Row
          Row(
            children: [
              const Icon(Icons.access_time, size: 16, color: AppColors.textGray),
              const SizedBox(width: 6),
              Text(
                'Duration: $duration',
                style: AppTextStyles.subtitle.copyWith(
                  fontSize: 13,
                  color: AppColors.textGray,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Badges Row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isManual
                      ? const Color(0xFFFEF3C7)
                      : const Color(0xFFD1FAE5),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isManual ? Icons.warning_amber : Icons.nfc,
                      size: 14,
                      color: isManual
                          ? const Color(0xFFF59E0B)
                          : const Color(0xFF10B981),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      verificationMethod,
                      style: AppTextStyles.label.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isManual
                            ? const Color(0xFFF59E0B)
                            : const Color(0xFF10B981),
                      ),
                    ),
                    if (!isManual) ...[
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.check,
                        size: 14,
                        color: Color(0xFF10B981),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (isConfirmed)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD1FAE5),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.check_circle_outline,
                        size: 14,
                        color: Color(0xFF10B981),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Confirmed',
                        style: AppTextStyles.label.copyWith(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF10B981),
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.check,
                        size: 14,
                        color: Color(0xFF10B981),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
