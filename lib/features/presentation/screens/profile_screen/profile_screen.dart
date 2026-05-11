import 'package:flutter/material.dart';
import 'package:field_guard_re/core/theme/app_colors.dart';
import 'package:field_guard_re/core/theme/app_responsive.dart';
import 'package:field_guard_re/core/theme/app_text_styles.dart';
import 'components/section_header.dart';
import 'components/menu_item.dart';
import 'components/bottom_nav_bar.dart';
import '../../shared/components/summary_stat_card.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final hPad = AppResponsive.horizontalPad(context);
    final avatarRadius = AppResponsive.r(context, 42);

    return Scaffold(
      backgroundColor: AppColors.backgroundBeige,
      appBar: AppBar(
        backgroundColor: AppColors.cardWhite,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: AppColors.textDark),
          onPressed: () {},
        ),
        title: Text(
          'FieldSales Pro',
          style: AppTextStyles.labelR(context).copyWith(
            fontSize: AppResponsive.sp(context, 16),
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
        centerTitle: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: CircleAvatar(
              radius: AppResponsive.r(context, 18),
              backgroundColor: AppColors.lightGreenCircle,
              child: Text(
                'RK',
                style: AppTextStyles.labelR(context).copyWith(
                  fontSize: AppResponsive.sp(context, 13),
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryGreen,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile Header
            Container(
              color: AppColors.cardWhite,
              padding: EdgeInsets.symmetric(vertical: AppResponsive.r(context, 24)),
              child: Column(
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: avatarRadius,
                        backgroundColor: AppColors.primaryGreen,
                        child: Text(
                          'RK',
                          style: AppTextStyles.heading1R(context).copyWith(
                            fontSize: AppResponsive.sp(context, 30),
                            fontWeight: FontWeight.bold,
                            color: AppColors.cardWhite,
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: AppResponsive.r(context, 28),
                          height: AppResponsive.r(context, 28),
                          decoration: BoxDecoration(
                            color: AppColors.cardWhite,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.backgroundBeige,
                              width: 2,
                            ),
                          ),
                          child: Icon(
                            Icons.camera_alt,
                            size: AppResponsive.r(context, 14),
                            color: AppColors.textDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: AppResponsive.r(context, 12)),
                  Text(
                    'Raj Kumar',
                    style: AppTextStyles.heading1R(context).copyWith(
                      fontSize: AppResponsive.sp(context, 20),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Sales Representative',
                    style: AppTextStyles.subtitleR(context).copyWith(
                      fontSize: AppResponsive.sp(context, 13),
                      color: AppColors.textGray,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: AppResponsive.r(context, 16),
                        color: AppColors.textGray,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Kathmandu Zone',
                        style: AppTextStyles.subtitleR(context).copyWith(
                          fontSize: AppResponsive.sp(context, 13),
                          color: AppColors.textGray,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Stats Cards
            Padding(
              padding: EdgeInsets.symmetric(horizontal: hPad),
              child: Row(
                children: const [
                  Expanded(
                    child: SummaryStatCard(
                      icon: Icons.store_outlined,
                      value: '142',
                      label: 'Visits',
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: SummaryStatCard(
                      icon: Icons.account_balance_wallet_outlined,
                      value: '₹ 3.2L',
                      label: 'Collected',
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: SummaryStatCard(
                      icon: Icons.check_circle_outline,
                      value: '96%',
                      label: 'Confirmation',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const SectionHeader(title: 'ACCOUNT'),
            MenuItem(icon: Icons.person_outline, title: 'Personal Details', onTap: () {}),
            MenuItem(icon: Icons.account_balance_outlined, title: 'Bank Information', onTap: () {}),
            const SizedBox(height: 16),
            const SectionHeader(title: 'WORK'),
            MenuItem(icon: Icons.map_outlined, title: 'Territory Map', onTap: () {}),
            MenuItem(icon: Icons.history, title: 'Visit History', onTap: () {}),
            const SizedBox(height: 16),
            const SectionHeader(title: 'APP SETTINGS'),
            MenuItem(icon: Icons.notifications_outlined, title: 'Notifications', onTap: () {}),
            MenuItem(icon: Icons.lock_outline, title: 'Security & Pin', onTap: () {}),
            const SizedBox(height: 16),
            const SectionHeader(title: 'SUPPORT'),
            MenuItem(icon: Icons.help_outline, title: 'Help Center', onTap: () {}),
            MenuItem(icon: Icons.warning_amber_outlined, title: 'Report an Issue', onTap: () {}),
            const SizedBox(height: 24),
            TextButton.icon(
              onPressed: () {},
              icon: Icon(
                Icons.logout,
                color: const Color(0xFFDC2626),
                size: AppResponsive.r(context, 20),
              ),
              label: Text(
                'Sign Out',
                style: AppTextStyles.labelR(context).copyWith(
                  fontSize: AppResponsive.sp(context, 15),
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFFDC2626),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'FieldGuard Agent v2.4.1',
              style: AppTextStyles.versionR(context),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
      bottomNavigationBar: const BottomNavBar(selectedIndex: 3),
    );
  }
}
