import 'package:flutter/material.dart';
import '../../../../core/theme/app_responsive.dart';
import 'components/visit_tasks_card.dart';
import '../../shared/components/quick_action_card.dart';

class ActiveVisitScreen extends StatelessWidget {
  const ActiveVisitScreen({super.key});

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
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Green Active Visit header
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                horizontal: hPad,
                vertical: AppResponsive.r(context, 24),
              ),
              decoration: const BoxDecoration(
                color: Color(0xFF157347),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: AppResponsive.r(context, 10),
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'ACTIVE VISIT',
                          style: TextStyle(
                            color: Colors.white70,
                            fontWeight: FontWeight.w600,
                            fontSize: AppResponsive.sp(context, 12),
                          ),
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: AppResponsive.r(context, 10),
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD1FADF),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.nfc,
                              color: const Color(0xFF157347),
                              size: AppResponsive.r(context, 18),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'NFC',
                              style: TextStyle(
                                color: const Color(0xFF157347),
                                fontWeight: FontWeight.bold,
                                fontSize: AppResponsive.sp(context, 13),
                              ),
                            ),
                            Icon(
                              Icons.keyboard_arrow_down,
                              color: const Color(0xFF157347),
                              size: AppResponsive.r(context, 18),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: AppResponsive.r(context, 18)),
                  Text(
                    'Sharma General Store',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: AppResponsive.sp(context, 22),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        color: const Color(0xFFD1FADF),
                        size: AppResponsive.r(context, 17),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Sector 42, Main Market',
                        style: TextStyle(
                          color: const Color(0xFFD1FADF),
                          fontSize: AppResponsive.sp(context, 14),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: AppResponsive.r(context, 24)),
                  // Timer card
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(
                      vertical: AppResponsive.r(context, 20),
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '00  :  18  :  42',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: AppResponsive.sp(context, 36),
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                        ),
                        SizedBox(height: AppResponsive.r(context, 10)),
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: AppResponsive.r(context, 18),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Duration',
                                style: TextStyle(
                                  color: const Color(0xFFD1FADF),
                                  fontSize: AppResponsive.sp(context, 12),
                                ),
                              ),
                              Text(
                                'Min. required: 5 min',
                                style: TextStyle(
                                  color: const Color(0xFFD1FADF),
                                  fontSize: AppResponsive.sp(context, 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: AppResponsive.r(context, 8)),
                        Container(
                          height: 6,
                          margin: EdgeInsets.symmetric(
                            horizontal: AppResponsive.r(context, 8),
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD1FADF),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: AppResponsive.r(context, 24)),
            // Quick Actions — Wrap reflows into multiple rows on narrow screens
            Padding(
              padding: EdgeInsets.symmetric(horizontal: hPad),
              child: Wrap(
                spacing: AppResponsive.r(context, 12),
                runSpacing: AppResponsive.r(context, 12),
                children: const [
                  QuickActionCard(
                    icon: Icons.shopping_cart_outlined,
                    label: 'Log Order',
                    variant: QuickActionVariant.horizontal,
                    backgroundColor: Color(0xFFD1FADF),
                  ),
                  QuickActionCard(
                    icon: Icons.payments_outlined,
                    label: 'Collect Payment',
                    variant: QuickActionVariant.horizontal,
                    backgroundColor: Color(0xFFFFF3E0),
                  ),
                  QuickActionCard(
                    icon: Icons.camera_alt_outlined,
                    label: 'Shop Photo',
                    variant: QuickActionVariant.horizontal,
                    backgroundColor: Color(0xFFE5E7EB),
                  ),
                  QuickActionCard(
                    icon: Icons.note_alt_outlined,
                    label: 'Add Note',
                    variant: QuickActionVariant.horizontal,
                    backgroundColor: Color(0xFFE5E7EB),
                  ),
                ],
              ),
            ),
            SizedBox(height: AppResponsive.r(context, 28)),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: hPad),
              child: const VisitTasksCard(),
            ),
            SizedBox(height: AppResponsive.r(context, 32)),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: hPad),
              child: SizedBox(
                width: double.infinity,
                height: AppResponsive.r(context, 48),
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF157347)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () {},
                  icon: const Icon(Icons.exit_to_app, color: Color(0xFF157347)),
                  label: Text(
                    'End Visit',
                    style: TextStyle(
                      color: const Color(0xFF157347),
                      fontWeight: FontWeight.bold,
                      fontSize: AppResponsive.sp(context, 16),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: () {},
              icon: Icon(
                Icons.flag_outlined,
                color: const Color(0xFF6B7280),
                size: AppResponsive.r(context, 20),
              ),
              label: Text(
                'Flag Issue',
                style: TextStyle(
                  color: const Color(0xFF6B7280),
                  fontWeight: FontWeight.w600,
                  fontSize: AppResponsive.sp(context, 14),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
