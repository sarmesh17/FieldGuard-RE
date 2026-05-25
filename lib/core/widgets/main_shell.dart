import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:field_guard_re/core/router/app_routes.dart';
import 'package:field_guard_re/features/geofence/presentation/providers/geofence_provider.dart';
import 'package:field_guard_re/features/tasks/presentation/providers/tasks_provider.dart';
import 'bottom_nav_bar.dart';

class MainShell extends ConsumerWidget {
  final Widget child;

  const MainShell({super.key, required this.child});

  static int _selectedIndex(String path) {
    switch (path) {
      case AppRoutes.home:
        return 0;
      case AppRoutes.shops:
        return 1;
      case AppRoutes.route:
        return 2;
      case AppRoutes.tasks:
        return 3;
      case AppRoutes.profile:
        return 4;
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Mount task-based live tracking sync once for the whole shell so the
    // socket auto-starts/stops based on active (IN_PROGRESS) tasks regardless
    // of which tab the user is currently on.
    ref.watch(taskTrackingSyncProvider);

    // Keeps the shop-visit geofence armed to the active IN_PROGRESS task's
    // shop (enter/stay/exit tracking) for the whole shell lifetime.
    ref.watch(geofenceVisitSyncProvider);

    final location = GoRouterState.of(context).uri.path;
    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavBar(selectedIndex: _selectedIndex(location)),
    );
  }
}
