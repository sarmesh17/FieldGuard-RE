import 'package:flutter/material.dart';
import '../../../../core/theme/app_responsive.dart';
import 'components/map_marker.dart';
import 'components/schedule_list.dart';
import '../profile_screen/components/bottom_nav_bar.dart';

class RouteScreen extends StatelessWidget {
  const RouteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final hPad = AppResponsive.horizontalPad(context);
    // Map area height: 30% of screen height, capped at 280 on tablets
    final mapHeight = AppResponsive.hp(context, 30).clamp(180.0, 280.0);

    return Scaffold(
      backgroundColor: const Color(0xFFFAF8F3),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          "Today's Route",
          style: TextStyle(
            color: const Color(0xFF157347),
            fontWeight: FontWeight.bold,
            fontSize: AppResponsive.sp(context, 20),
          ),
        ),
        centerTitle: true,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16, top: 10, bottom: 10),
            padding: EdgeInsets.symmetric(
              horizontal: AppResponsive.r(context, 14),
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFD1FADF),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Text(
                '8 Shops',
                style: TextStyle(
                  color: const Color(0xFF157347),
                  fontWeight: FontWeight.bold,
                  fontSize: AppResponsive.sp(context, 14),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Map placeholder — fills width, height is proportional
            SizedBox(
              width: double.infinity,
              height: mapHeight + 24,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(hPad, 24, hPad, 0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: SizedBox(
                        width: double.infinity,
                        height: mapHeight,
                        child: Image.asset(
                          'assets/images/map_placeholder.png',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                  const Positioned(
                    left: 80,
                    top: 60,
                    child: MapMarker(number: 1),
                  ),
                  const Positioned(
                    left: 160,
                    top: 100,
                    child: MapMarker(number: 2, isCurrent: true),
                  ),
                  const Positioned(
                    right: 80,
                    bottom: 40,
                    child: MapMarker(number: 3),
                  ),
                  Positioned(
                    right: 24,
                    bottom: 16,
                    child: CircleAvatar(
                      backgroundColor: Colors.white,
                      child: const Icon(
                        Icons.my_location,
                        color: Color(0xFF157347),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Next Stop Card
            Container(
              margin: EdgeInsets.symmetric(horizontal: hPad, vertical: 16),
              padding: EdgeInsets.all(AppResponsive.r(context, 20)),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Center(
                    child: SizedBox(
                      width: 40,
                      child: Divider(thickness: 3, color: Color(0xFFE5E7EB)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'NEXT STOP',
                    style: TextStyle(
                      color: const Color(0xFF6B7280),
                      fontWeight: FontWeight.w600,
                      fontSize: AppResponsive.sp(context, 12),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Starlight Convenience',
                              style: TextStyle(
                                fontSize: AppResponsive.sp(context, 20),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '4200 Broadway St, New York',
                              style: TextStyle(
                                fontSize: AppResponsive.sp(context, 14),
                                color: const Color(0xFF6B7280),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: AppResponsive.r(context, 10),
                          vertical: AppResponsive.r(context, 6),
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD1FADF),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.directions_car,
                              size: AppResponsive.r(context, 16),
                              color: const Color(0xFF157347),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '2.3 km · ~8 min',
                              style: TextStyle(
                                color: const Color(0xFF157347),
                                fontWeight: FontWeight.w600,
                                fontSize: AppResponsive.sp(context, 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: AppResponsive.r(context, 18)),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF157347),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            padding: EdgeInsets.symmetric(
                              vertical: AppResponsive.r(context, 14),
                            ),
                          ),
                          onPressed: () {},
                          icon: const Icon(Icons.navigation, color: Colors.white),
                          label: Text(
                            'Navigate',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: AppResponsive.sp(context, 15),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: AppResponsive.r(context, 16)),
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFF157347)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            padding: EdgeInsets.symmetric(
                              vertical: AppResponsive.r(context, 14),
                            ),
                          ),
                          onPressed: () {},
                          icon: const Icon(
                            Icons.phone,
                            color: Color(0xFF157347),
                          ),
                          label: Text(
                            'Call Shop',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: AppResponsive.sp(context, 15),
                              color: const Color(0xFF157347),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Today's Schedule",
                  style: TextStyle(
                    fontSize: AppResponsive.sp(context, 18),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const ScheduleList(),
            const SizedBox(height: 24),
          ],
        ),
      ),
      bottomNavigationBar: const BottomNavBar(selectedIndex: 1),
    );
  }
}
