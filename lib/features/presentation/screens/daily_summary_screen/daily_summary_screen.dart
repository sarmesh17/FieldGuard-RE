import 'package:flutter/material.dart';
import 'package:field_guard_re/core/theme/app_colors.dart';
import 'package:field_guard_re/core/theme/app_responsive.dart';
import 'package:field_guard_re/core/theme/app_text_styles.dart';
import 'components/verification_row.dart';
import 'components/payment_item.dart';
import '../../shared/components/summary_stat_card.dart';

class DailySummaryScreen extends StatelessWidget {
  const DailySummaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final hPad = AppResponsive.horizontalPad(context);

    return Scaffold(
      backgroundColor: AppColors.backgroundBeige,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Today's Summary",
              style: AppTextStyles.heading1R(context).copyWith(
                fontSize: AppResponsive.sp(context, 20),
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Sunday, 3 May 2026',
              style: AppTextStyles.subtitleR(context).copyWith(
                fontSize: AppResponsive.sp(context, 12),
                color: AppColors.textGray,
              ),
            ),
          ],
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined, color: Colors.black),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Expanded(
                    child: SummaryStatCard(value: '8/8', label: 'SHOPS\nVISITED'),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: SummaryStatCard(value: '₹\n45k', label: 'COLLECTED'),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: SummaryStatCard(
                        value: '4h\n32m', label: 'TIME IN\nFIELD'),
                  ),
                ],
              ),
              SizedBox(height: AppResponsive.r(context, 20)),
              // Visit Details Card
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
                          Icons.store_outlined,
                          size: AppResponsive.r(context, 20),
                          color: AppColors.primaryGreen,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Visit Details',
                          style: AppTextStyles.labelR(context).copyWith(
                            fontSize: AppResponsive.sp(context, 16),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: AppResponsive.r(context, 20)),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Completion',
                          style: AppTextStyles.subtitleR(context).copyWith(
                            fontSize: AppResponsive.sp(context, 14),
                            color: AppColors.textDark,
                          ),
                        ),
                        Text(
                          '100%',
                          style: AppTextStyles.labelR(context).copyWith(
                            fontSize: AppResponsive.sp(context, 14),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: const LinearProgressIndicator(
                        value: 1.0,
                        minHeight: 8,
                        backgroundColor: AppColors.inputBorder,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.primaryGreen,
                        ),
                      ),
                    ),
                    SizedBox(height: AppResponsive.r(context, 20)),
                    const VerificationRow(
                      icon: Icons.nfc,
                      iconColor: Color(0xFF10B981),
                      iconBgColor: Color(0xFFD1FAE5),
                      label: 'NFC Verified',
                      count: '6 visits',
                    ),
                    const SizedBox(height: 12),
                    VerificationRow(
                      icon: Icons.qr_code_2,
                      iconColor: AppColors.textGray,
                      iconBgColor: const Color(0xFFF3F4F6),
                      label: 'QR Verified',
                      count: '1 visit',
                    ),
                    const SizedBox(height: 12),
                    VerificationRow(
                      icon: Icons.dialpad,
                      iconColor: AppColors.textGray,
                      iconBgColor: const Color(0xFFF3F4F6),
                      label: 'OTP Verified',
                      count: '1 visit',
                    ),
                  ],
                ),
              ),
              SizedBox(height: AppResponsive.r(context, 20)),
              // Score Card
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
                  border: const Border(
                    left: BorderSide(color: AppColors.primaryGreen, width: 5),
                  ),
                ),
                padding: EdgeInsets.all(AppResponsive.r(context, 24)),
                child: Column(
                  children: [
                    Text(
                      "TODAY'S SCORE",
                      style: AppTextStyles.labelR(context).copyWith(
                        fontSize: AppResponsive.sp(context, 12),
                        color: AppColors.textGray,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '94',
                          style: AppTextStyles.heading1R(context).copyWith(
                            fontSize: AppResponsive.sp(context, 48),
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryGreen,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Text(
                            '/100',
                            style: AppTextStyles.subtitleR(context).copyWith(
                              fontSize: AppResponsive.sp(context, 20),
                              color: AppColors.textGray,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        5,
                        (_) => Icon(
                          Icons.star,
                          color: const Color(0xFFFBBF24),
                          size: AppResponsive.r(context, 24),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Great work today, Raj!',
                      style: AppTextStyles.subtitleR(context).copyWith(
                        fontSize: AppResponsive.sp(context, 14),
                        color: AppColors.textGray,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: AppResponsive.r(context, 20)),
              // Payments Collected Card
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
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.account_balance_wallet_outlined,
                              size: AppResponsive.r(context, 20),
                              color: AppColors.primaryGreen,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Payments Collected',
                              style: AppTextStyles.labelR(context).copyWith(
                                fontSize: AppResponsive.sp(context, 15),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '3 Transactions',
                          style: AppTextStyles.subtitleR(context).copyWith(
                            fontSize: AppResponsive.sp(context, 12),
                            color: AppColors.textGray,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: AppResponsive.r(context, 16)),
                    const PaymentItem(
                      shopName: 'Sharma Electronics',
                      invoiceNumber: 'Inv #INV-2026-081',
                      amount: '₹ 25,000',
                      paymentMethod: 'CHEQUE',
                      methodColor: Color(0xFFDCFCE7),
                      methodTextColor: Color(0xFF166534),
                    ),
                    const Divider(height: 24),
                    const PaymentItem(
                      shopName: 'Gupta General Store',
                      invoiceNumber: 'Inv #INV-2026-082',
                      amount: '₹ 15,000',
                      paymentMethod: 'CASH',
                      methodColor: Color(0xFFFEF3C7),
                      methodTextColor: Color(0xFF92400E),
                    ),
                    const Divider(height: 24),
                    const PaymentItem(
                      shopName: 'Verma Enterprises',
                      invoiceNumber: 'Inv #INV-2026-083',
                      amount: '₹ 5,000',
                      paymentMethod: 'UPI',
                      methodColor: Color(0xFFE0E7FF),
                      methodTextColor: Color(0xFF3730A3),
                    ),
                  ],
                ),
              ),
              SizedBox(height: AppResponsive.r(context, 20)),
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
                      Icon(Icons.play_arrow, size: AppResponsive.r(context, 20)),
                      const SizedBox(width: 8),
                      Text(
                        'Submit Daily Report',
                        style: AppTextStyles.buttonTextR(context).copyWith(
                          fontSize: AppResponsive.sp(context, 16),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: TextButton(
                  onPressed: () {},
                  child: Text(
                    'View Full History',
                    style: AppTextStyles.linkR(context).copyWith(
                      color: AppColors.primaryGreen,
                      fontSize: AppResponsive.sp(context, 15),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
