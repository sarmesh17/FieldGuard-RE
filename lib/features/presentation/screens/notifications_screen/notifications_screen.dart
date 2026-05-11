import 'package:flutter/material.dart';
import 'package:field_guard_re/core/theme/app_colors.dart';
import 'package:field_guard_re/core/theme/app_responsive.dart';
import 'package:field_guard_re/core/theme/app_text_styles.dart';
import 'components/notification_card.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  int selectedFilter = 0;
  final List<String> filters = ['All', 'Alerts', 'Payments', 'Visits'];

  @override
  Widget build(BuildContext context) {
    final hPad = AppResponsive.horizontalPad(context);

    return Scaffold(
      backgroundColor: AppColors.backgroundBeige,
      appBar: AppBar(
        backgroundColor: AppColors.cardWhite,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primaryGreen),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Notifications',
          style: AppTextStyles.heading1R(context).copyWith(
            fontSize: AppResponsive.sp(context, 20),
            fontWeight: FontWeight.bold,
            color: AppColors.primaryGreen,
          ),
        ),
        centerTitle: false,
        actions: [
          TextButton(
            onPressed: () {},
            child: Text(
              'Mark all read',
              style: AppTextStyles.linkR(context).copyWith(
                color: AppColors.primaryGreen,
                fontSize: AppResponsive.sp(context, 13),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Chips — scrollable to handle all screen widths
          Container(
            color: AppColors.cardWhite,
            padding: EdgeInsets.fromLTRB(hPad, 8, hPad, 16),
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
                      backgroundColor: AppColors.backgroundBeige,
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
          Expanded(
            child: ListView(
              padding: EdgeInsets.all(hPad),
              children: [
                const NotificationCard(
                  icon: Icons.warning_amber_rounded,
                  iconColor: Color(0xFFDC2626),
                  iconBgColor: Color(0xFFFEE2E2),
                  borderColor: Color(0xFFDC2626),
                  title: 'Payment Disputed!',
                  description:
                      'Client #8902 has filed a dispute for the transaction on route 4B.',
                  time: 'Just now',
                ),
                const SizedBox(height: 12),
                const NotificationCard(
                  icon: Icons.access_time_rounded,
                  iconColor: Color(0xFFF59E0B),
                  iconBgColor: Color(0xFFFEF3C7),
                  borderColor: Color(0xFFF59E0B),
                  title: 'Short Visit Flagged',
                  description:
                      'Visit duration at Patel Electronics was below the 5-minute minimum threshold.',
                  time: '10m ago',
                ),
                const SizedBox(height: 12),
                const NotificationCard(
                  icon: Icons.check_circle_outline_rounded,
                  iconColor: Color(0xFF10B981),
                  iconBgColor: Color(0xFFD1FAE5),
                  borderColor: Color(0xFF10B981),
                  title: 'Payment Confirmed — Sharma General Store',
                  description:
                      'Cash payment of ₹4,500 successfully logged and verified.',
                  time: '1h ago',
                ),
                const SizedBox(height: 12),
                NotificationCard(
                  icon: Icons.map_outlined,
                  iconColor: AppColors.textGray,
                  iconBgColor: const Color(0xFFF3F4F6),
                  borderColor: AppColors.textGray,
                  title: 'Route Updated by Manager',
                  description:
                      '2 new priority stops added to your afternoon schedule.',
                  time: '2h ago',
                ),
                const SizedBox(height: 32),
                Center(
                  child: Text(
                    "You've caught up on all notifications.",
                    style: AppTextStyles.subtitleR(context).copyWith(
                      fontSize: AppResponsive.sp(context, 13),
                      color: AppColors.textLight,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
