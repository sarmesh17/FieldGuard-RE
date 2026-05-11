import 'package:flutter/material.dart';
import '../../../../core/theme/app_responsive.dart';
import 'components/active_visit_card.dart';
import 'components/route_card.dart';
import 'components/stat_card.dart';
import '../../shared/components/quick_action_card.dart';
import '../profile_screen/components/bottom_nav_bar.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final hPad = AppResponsive.horizontalPad(context);
    final isTablet = AppResponsive.isTablet(context);

    return Scaffold(
      backgroundColor: const Color(0xFFFAF8F3),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: AppResponsive.r(context, 80),
        automaticallyImplyLeading: false,
        titleSpacing: hPad,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Good Morning, 👋',
                  style: TextStyle(
                    fontSize: AppResponsive.sp(context, 15),
                    color: const Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Raj Kumar',
                  style: TextStyle(
                    fontSize: AppResponsive.sp(context, 22),
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Icon(
                  Icons.notifications_none,
                  color: Colors.black,
                  size: AppResponsive.r(context, 28),
                ),
                SizedBox(width: AppResponsive.r(context, 16)),
                CircleAvatar(
                  radius: AppResponsive.r(context, 20),
                  backgroundColor: const Color(0xFFD1FADF),
                  child: Text(
                    'RK',
                    style: TextStyle(
                      color: const Color(0xFF157347),
                      fontWeight: FontWeight.bold,
                      fontSize: AppResponsive.sp(context, 13),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: hPad),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            // Stat cards — flex row, each card is Expanded
            Row(
              children: const [
                StatCard(title: 'Shops Today', value: '8'),
                SizedBox(width: 10),
                StatCard(title: 'Visited', value: '5'),
                SizedBox(width: 10),
                StatCard(
                  title: 'Remaining',
                  value: '3',
                  valueColor: Color(0xFFFFA500),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const ActiveVisitCard(),
            const SizedBox(height: 24),
            Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: AppResponsive.sp(context, 18),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            // On tablet use 4-per-row; on phone the Row naturally distributes
            isTablet
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Expanded(
                        child: QuickActionCard(
                          icon: Icons.add_box_outlined,
                          label: 'New Order',
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: QuickActionCard(
                          icon: Icons.payments_outlined,
                          label: 'Collect Pmt',
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: QuickActionCard(
                          icon: Icons.camera_alt_outlined,
                          label: 'Take Photo',
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: QuickActionCard(
                          icon: Icons.assignment_outlined,
                          label: 'Daily Report',
                        ),
                      ),
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      QuickActionCard(
                        icon: Icons.add_box_outlined,
                        label: 'New Order',
                      ),
                      QuickActionCard(
                        icon: Icons.payments_outlined,
                        label: 'Collect Pmt',
                      ),
                      QuickActionCard(
                        icon: Icons.camera_alt_outlined,
                        label: 'Take Photo',
                      ),
                      QuickActionCard(
                        icon: Icons.assignment_outlined,
                        label: 'Daily Report',
                      ),
                    ],
                  ),
            const SizedBox(height: 28),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Today's Route",
                  style: TextStyle(
                    fontSize: AppResponsive.sp(context, 18),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextButton(
                  onPressed: () {},
                  child: Row(
                    children: [
                      Text(
                        'View Map',
                        style: TextStyle(
                          color: const Color(0xFF157347),
                          fontSize: AppResponsive.sp(context, 14),
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward,
                        size: AppResponsive.r(context, 16),
                        color: const Color(0xFF157347),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            RouteCard(
              index: 1,
              shopName: 'Mittal Traders',
              address: '14, Gandhi Market, Sector 4',
              status: 'Done',
              statusColor: const Color(0xFF157347),
              statusBg: const Color(0xFFD1FADF),
              distance: '0.5 km away',
              isActive: false,
            ),
            RouteCard(
              index: 2,
              shopName: 'Sharma General Store',
              address: 'Shop 42, Main Bazaar',
              status: 'Active',
              statusColor: const Color(0xFFFFA500),
              statusBg: const Color(0xFFFFF3E0),
              distance: 'Currently Here',
              isActive: true,
            ),
            RouteCard(
              index: 3,
              shopName: 'Verma Supermart',
              address: 'Plot 8, Industrial Area Ph-1',
              status: 'Pending',
              statusColor: const Color(0xFF6B7280),
              statusBg: const Color(0xFFE5E7EB),
              distance: '1.2 km away',
              isActive: false,
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
      bottomNavigationBar: const BottomNavBar(selectedIndex: 0),
    );
  }
}
