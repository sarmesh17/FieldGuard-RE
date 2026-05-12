import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:field_guard_re/core/router/app_routes.dart';
import 'bottom_nav_bar.dart';

class MainShell extends StatelessWidget {
  final Widget child;

  const MainShell({super.key, required this.child});

  static int _selectedIndex(String path) {
    switch (path) {
      case AppRoutes.home:
        return 0;
      case AppRoutes.route:
        return 1;
      case AppRoutes.visitHistory:
        return 2;
      case AppRoutes.profile:
        return 3;
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavBar(selectedIndex: _selectedIndex(location)),
    );
  }
}
