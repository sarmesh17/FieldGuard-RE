import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:field_guard_re/core/theme/app_colors.dart';
import 'package:field_guard_re/core/router/app_routes.dart';
import 'nav_item.dart';

class BottomNavBar extends StatelessWidget {
  final int selectedIndex;

  const BottomNavBar({super.key, required this.selectedIndex});

  static const _routes = [
    AppRoutes.home,
    AppRoutes.route,
    AppRoutes.visitHistory,
    AppRoutes.profile,
  ];

  @override
  Widget build(BuildContext context) {
    void go(int index) {
      if (selectedIndex != index) context.go(_routes[index]);
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              NavItem(
                icon: Icons.home_outlined,
                label: 'Home',
                isSelected: selectedIndex == 0,
                onTap: () => go(0),
              ),
              NavItem(
                icon: Icons.map_outlined,
                label: 'Route',
                isSelected: selectedIndex == 1,
                onTap: () => go(1),
              ),
              NavItem(
                icon: Icons.store_outlined,
                label: 'Visits',
                isSelected: selectedIndex == 2,
                onTap: () => go(2),
              ),
              NavItem(
                icon: Icons.person_outline,
                label: 'Profile',
                isSelected: selectedIndex == 3,
                onTap: () => go(3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
