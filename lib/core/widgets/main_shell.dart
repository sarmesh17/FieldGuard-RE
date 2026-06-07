import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:field_guard_re/core/router/app_routes.dart';
import 'package:field_guard_re/core/services/live_tracking_service.dart';
import 'package:field_guard_re/core/services/push_notification_service.dart';
import 'package:field_guard_re/features/geofence/presentation/providers/geofence_provider.dart';
import 'package:field_guard_re/features/notifications/presentation/providers/notifications_provider.dart';
import 'package:field_guard_re/features/tasks/presentation/providers/tasks_provider.dart';
import 'package:field_guard_re/features/tracking/presentation/providers/tracking_provider.dart';
import 'bottom_nav_bar.dart';

class MainShell extends ConsumerStatefulWidget {
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
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  @override
  void initState() {
    super.initState();
    // Restore the user's last Live Tracking choice across process restarts.
    // Deferred to the next frame so the providers we touch (and the
    // platform channels they go through) are fully mounted. Best-effort —
    // it silently no-ops if permissions are now missing.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(trackingNotifierProvider.notifier).restore();
    });

    // A foreground push means the backend just added an inbox item — refresh
    // the list + unread badge live. Cleared in dispose.
    PushNotificationService.instance.onInboxChanged = () {
      if (mounted) ref.read(notificationsNotifierProvider.notifier).refresh();
    };

    // Real-time notifications over the tracking socket (only while a tracking
    // session is connected — see LiveTrackingService). Prepend live; resync the
    // whole inbox on (re)connect since the socket has no replay queue.
    LiveTrackingService.instance.onNotification = (json) {
      if (mounted) {
        ref.read(notificationsNotifierProvider.notifier).addRealtime(json);
      }
    };
    LiveTrackingService.instance.onSocketConnected = () {
      if (mounted) ref.read(notificationsNotifierProvider.notifier).refresh();
    };
  }

  @override
  void dispose() {
    PushNotificationService.instance.onInboxChanged = null;
    LiveTrackingService.instance.onNotification = null;
    LiveTrackingService.instance.onSocketConnected = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Mount task-based live tracking sync once for the whole shell so the
    // socket auto-starts/stops based on active (IN_PROGRESS) tasks regardless
    // of which tab the user is currently on.
    ref.watch(taskTrackingSyncProvider);

    // Keeps the shop-visit geofence armed to the active IN_PROGRESS task's
    // shop (enter/stay/exit tracking) for the whole shell lifetime.
    ref.watch(geofenceVisitSyncProvider);

    // Bridges geofence enter/exit into notifications + auto-complete-on-exit.
    ref.watch(geofenceEventHandlerProvider);

    final location = GoRouterState.of(context).uri.path;
    return Scaffold(
      body: widget.child,
      bottomNavigationBar:
          BottomNavBar(selectedIndex: MainShell._selectedIndex(location)),
    );
  }
}
