import 'package:flutter/material.dart';
import 'package:field_guard_re/core/theme/app_colors.dart';
import 'package:field_guard_re/core/theme/app_responsive.dart';
import 'package:field_guard_re/core/theme/app_text_styles.dart';
import 'components/visit_card.dart';
import '../profile_screen/components/bottom_nav_bar.dart';

class VisitHistoryScreen extends StatefulWidget {
  const VisitHistoryScreen({super.key});

  @override
  State<VisitHistoryScreen> createState() => _VisitHistoryScreenState();
}

class _VisitHistoryScreenState extends State<VisitHistoryScreen> {
  int selectedFilter = 0;
  final List<String> filters = ['All', 'Today', 'This Week', 'This Month'];

  @override
  Widget build(BuildContext context) {
    final hPad = AppResponsive.horizontalPad(context);

    return Scaffold(
      backgroundColor: AppColors.backgroundBeige,
      appBar: AppBar(
        backgroundColor: AppColors.cardWhite,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          'Visit History',
          style: AppTextStyles.heading1R(context).copyWith(
            fontSize: AppResponsive.sp(context, 20),
            fontWeight: FontWeight.bold,
            color: AppColors.primaryGreen,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Search and Filter Bar
          Container(
            color: AppColors.cardWhite,
            padding: EdgeInsets.fromLTRB(hPad, 8, hPad, 16),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.backgroundBeige,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.inputBorder),
                    ),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search shop name...',
                        hintStyle: AppTextStyles.inputHintR(context).copyWith(
                          fontSize: AppResponsive.sp(context, 14),
                        ),
                        prefixIcon: Icon(
                          Icons.search,
                          color: AppColors.textGray,
                          size: AppResponsive.r(context, 22),
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  width: AppResponsive.r(context, 48),
                  height: AppResponsive.r(context, 48),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundBeige,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.inputBorder),
                  ),
                  child: Icon(
                    Icons.tune,
                    color: AppColors.textDark,
                    size: AppResponsive.r(context, 22),
                  ),
                ),
              ],
            ),
          ),
          // Filter Chips
          Container(
            color: AppColors.cardWhite,
            padding: EdgeInsets.only(left: hPad, bottom: 16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(filters.length, (i) {
                  final selected = i == selectedFilter;
                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: ChoiceChip(
                      label: Text(
                        filters[i],
                        style: AppTextStyles.labelR(context).copyWith(
                          fontWeight: FontWeight.w600,
                          color: selected
                              ? AppColors.buttonTextWhite
                              : AppColors.textGray,
                          fontSize: AppResponsive.sp(context, 13),
                        ),
                      ),
                      selected: selected,
                      selectedColor: AppColors.primaryGreen,
                      backgroundColor: AppColors.cardWhite,
                      side: selected
                          ? BorderSide.none
                          : const BorderSide(color: AppColors.inputBorder),
                      onSelected: (_) => setState(() => selectedFilter = i),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      labelPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 2,
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
          // Visit List
          Expanded(
            child: ListView(
              padding: EdgeInsets.all(hPad),
              children: [
                Text(
                  'Today — 3 May 2026',
                  style: AppTextStyles.labelR(context).copyWith(
                    fontSize: AppResponsive.sp(context, 15),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                const VisitCard(
                  shopName: 'Starlight Convenience',
                  shopType: 'Retail Partner',
                  time: '09:15 AM',
                  duration: '45 mins',
                  verificationMethod: 'NFC',
                  isConfirmed: true,
                  borderColor: AppColors.primaryGreen,
                ),
                const SizedBox(height: 12),
                const VisitCard(
                  shopName: 'Oasis Markets HQ',
                  shopType: 'Distributor',
                  time: '11:30 AM',
                  duration: '1h 15m',
                  verificationMethod: 'NFC',
                  isConfirmed: true,
                  borderColor: AppColors.primaryGreen,
                ),
                const SizedBox(height: 24),
                Text(
                  'Yesterday — 2 May 2026',
                  style: AppTextStyles.labelR(context).copyWith(
                    fontSize: AppResponsive.sp(context, 15),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                const VisitCard(
                  shopName: 'Metro Pharmacy',
                  shopType: 'Pharmacy',
                  time: '02:45 PM',
                  duration: '20 mins',
                  verificationMethod: 'Manual Entry',
                  isConfirmed: true,
                  borderColor: Color(0xFFFB923C),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: const BottomNavBar(selectedIndex: 2),
    );
  }
}
