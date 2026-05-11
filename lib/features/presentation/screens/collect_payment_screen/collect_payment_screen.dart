import 'package:flutter/material.dart';
import 'package:field_guard_re/core/theme/app_colors.dart';
import 'package:field_guard_re/core/theme/app_responsive.dart';
import 'package:field_guard_re/core/theme/app_text_styles.dart';

class CollectPaymentScreen extends StatefulWidget {
  const CollectPaymentScreen({super.key});

  @override
  State<CollectPaymentScreen> createState() => _CollectPaymentScreenState();
}

class _CollectPaymentScreenState extends State<CollectPaymentScreen> {
  int amount = 0;
  int outstanding = 20000;
  int selectedMethod = 0;
  final List<String> methods = ['Cash', 'Cheque', 'UPI'];

  @override
  Widget build(BuildContext context) {
    final hPad = AppResponsive.horizontalPad(context);

    return Scaffold(
      backgroundColor: AppColors.backgroundBeige,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Collect Payment',
              style: AppTextStyles.heading1R(context).copyWith(
                fontSize: AppResponsive.sp(context, 20),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Sharma General Store',
              style: AppTextStyles.subtitleR(context).copyWith(
                fontSize: AppResponsive.sp(context, 13),
              ),
            ),
          ],
        ),
        centerTitle: false,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 8),
              child: Column(
                children: [
                  // Outstanding Balance Card
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.cardWhite,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                      border: const Border(
                        left: BorderSide(color: AppColors.primaryGreen, width: 5),
                      ),
                    ),
                    padding: EdgeInsets.symmetric(
                      horizontal: AppResponsive.r(context, 20),
                      vertical: AppResponsive.r(context, 18),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'OUTSTANDING BALANCE',
                          style: AppTextStyles.labelR(context).copyWith(
                            color: AppColors.textGray,
                            fontWeight: FontWeight.w600,
                            fontSize: AppResponsive.sp(context, 12),
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '₹ ${outstanding.toStringAsFixed(0)}',
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                            fontSize: AppResponsive.sp(context, 32),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'As of today',
                          style: AppTextStyles.subtitleR(context).copyWith(
                            color: AppColors.textLight,
                            fontSize: AppResponsive.sp(context, 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: AppResponsive.r(context, 16)),
                  // Info Box
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD1FADF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: EdgeInsets.symmetric(
                      horizontal: AppResponsive.r(context, 16),
                      vertical: AppResponsive.r(context, 14),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: AppColors.primaryGreen,
                          size: AppResponsive.r(context, 20),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Hand the phone to the shopkeeper. They will enter the amount they are paying.',
                            style: AppTextStyles.subtitleR(context).copyWith(
                              color: AppColors.primaryGreen,
                              fontSize: AppResponsive.sp(context, 13),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: AppResponsive.r(context, 16)),
                  // Amount & Method Card
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.cardWhite,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    padding: EdgeInsets.symmetric(
                      horizontal: AppResponsive.r(context, 20),
                      vertical: AppResponsive.r(context, 18),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ENTER AMOUNT',
                          style: AppTextStyles.labelR(context).copyWith(
                            color: AppColors.textGray,
                            fontWeight: FontWeight.w600,
                            fontSize: AppResponsive.sp(context, 12),
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          keyboardType: TextInputType.number,
                          style: AppTextStyles.inputTextR(context).copyWith(
                            fontSize: AppResponsive.sp(context, 28),
                            fontWeight: FontWeight.bold,
                          ),
                          decoration: InputDecoration(
                            prefixText: '₹ ',
                            prefixStyle: AppTextStyles.inputTextR(context).copyWith(
                              fontSize: AppResponsive.sp(context, 28),
                              fontWeight: FontWeight.bold,
                              color: AppColors.textLight,
                            ),
                            hintText: '0',
                            hintStyle: AppTextStyles.inputHintR(context).copyWith(
                              fontSize: AppResponsive.sp(context, 28),
                              fontWeight: FontWeight.bold,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  const BorderSide(color: AppColors.inputBorder),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  const BorderSide(color: AppColors.inputBorder),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: AppColors.primaryGreen,
                                width: 1.5,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 8,
                              horizontal: 16,
                            ),
                          ),
                          onChanged: (v) =>
                              setState(() => amount = int.tryParse(v) ?? 0),
                        ),
                        SizedBox(height: AppResponsive.r(context, 18)),
                        Text(
                          'PAYMENT METHOD',
                          style: AppTextStyles.labelR(context).copyWith(
                            color: AppColors.textGray,
                            fontWeight: FontWeight.w600,
                            fontSize: AppResponsive.sp(context, 12),
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: AppResponsive.r(context, 10),
                          runSpacing: 8,
                          children: List.generate(methods.length, (i) {
                            final selected = i == selectedMethod;
                            return ChoiceChip(
                              label: Text(
                                methods[i],
                                style: AppTextStyles.labelR(context).copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: selected
                                      ? AppColors.buttonTextWhite
                                      : AppColors.textGray,
                                  fontSize: AppResponsive.sp(context, 14),
                                ),
                              ),
                              selected: selected,
                              selectedColor: AppColors.primaryGreen,
                              backgroundColor: AppColors.cardWhite,
                              side: selected
                                  ? BorderSide.none
                                  : const BorderSide(color: AppColors.inputBorder),
                              onSelected: (_) =>
                                  setState(() => selectedMethod = i),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(22),
                              ),
                              labelPadding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 2,
                              ),
                            );
                          }),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Confirm Button — pinned to bottom
          Padding(
            padding: EdgeInsets.all(AppResponsive.r(context, 16)),
            child: SizedBox(
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
                child: Text(
                  'Confirm & Send SMS',
                  style: AppTextStyles.buttonTextR(context).copyWith(
                    fontSize: AppResponsive.sp(context, 16),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
