import 'package:flutter/material.dart';
import '../../../../core/theme/app_responsive.dart';
import 'components/circle_action.dart';
import 'components/visit_status_card.dart';
import 'components/check_in_card.dart';
import 'components/recent_activity_card.dart';

class ShopDetailsScreen extends StatelessWidget {
  const ShopDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final hPad = AppResponsive.horizontalPad(context);

    return Scaffold(
      backgroundColor: const Color(0xFFFAF8F3),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF157347)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Shop Details',
          style: TextStyle(
            color: const Color(0xFF157347),
            fontWeight: FontWeight.bold,
            fontSize: AppResponsive.sp(context, 20),
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Color(0xFF157347)),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: AppResponsive.r(context, 12)),
              Text(
                'Sharma General Store',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: AppResponsive.sp(context, 20),
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: AppResponsive.r(context, 4)),
              Text(
                'Owner: Sharma Ji',
                style: TextStyle(
                  fontSize: AppResponsive.sp(context, 14),
                  color: const Color(0xFF6B7280),
                ),
              ),
              const SizedBox(height: 2),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    color: const Color(0xFF157347),
                    size: AppResponsive.r(context, 17),
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      'Shop 42, Main Bazaar',
                      style: TextStyle(
                        fontSize: AppResponsive.sp(context, 14),
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: AppResponsive.r(context, 18)),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAction(icon: Icons.phone, onTap: () {}),
                  SizedBox(width: AppResponsive.r(context, 28)),
                  CircleAction(icon: Icons.map, onTap: () {}),
                  SizedBox(width: AppResponsive.r(context, 28)),
                  CircleAction(icon: Icons.history, onTap: () {}),
                ],
              ),
              SizedBox(height: AppResponsive.r(context, 18)),
              const VisitStatusCard(),
              SizedBox(height: AppResponsive.r(context, 18)),
              const CheckInCard(),
              SizedBox(height: AppResponsive.r(context, 18)),
              const RecentActivityCard(),
              SizedBox(height: AppResponsive.r(context, 32)),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.all(AppResponsive.r(context, 16)),
        child: SizedBox(
          width: double.infinity,
          height: AppResponsive.r(context, 52),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF157347),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {},
            child: Text(
              'Start Visit',
              style: TextStyle(
                fontSize: AppResponsive.sp(context, 17),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
