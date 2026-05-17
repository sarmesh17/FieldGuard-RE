import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/presentation/screens/splash_screen/splash_screen.dart';
import '../../features/presentation/screens/onboarding_screen/onboarding_screen.dart';
import '../../features/auth/presentation/screens/login_screen/login_screen.dart';
import '../../features/presentation/screens/home_screen/home_screen.dart';
import '../../features/presentation/screens/route_screen/route_screen.dart';
import '../../features/presentation/screens/shop_details_screen/shop_details_screen.dart';
import '../../features/presentation/screens/active_visit_screen/active_visit_screen.dart';
import '../../features/presentation/screens/new_order_screen/new_order_screen.dart';
import '../../features/presentation/screens/collect_payment_screen/collect_payment_screen.dart';
import '../../features/presentation/screens/sms_sent_screen/sms_sent_screen.dart';
import '../../features/presentation/screens/daily_summary_screen/daily_summary_screen.dart';
import '../../features/presentation/screens/visit_history_screen/visit_history_screen.dart';
import '../../features/presentation/screens/notifications_screen/notifications_screen.dart';
import '../../features/profile/presentation/screens/profile_screen/profile_screen.dart';
import '../../features/profile/presentation/screens/personal_details_screen/personal_details_screen.dart';
import '../../features/presentation/screens/route_screen/map_fullscreen_screen.dart';
import '../../features/shops/presentation/screens/shops_list_screen.dart';
import '../widgets/main_shell.dart';
import 'app_routes.dart';

/// App Router Configuration using GoRouter
class AppRouter {
  static final navigatorKey = GlobalKey<NavigatorState>();

  static final GoRouter router = GoRouter(
    navigatorKey: navigatorKey,
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: true,
    routes: [
      // Splash Screen
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),

      // Onboarding Screen
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),

      // Login Screen
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),

      // Tab screens wrapped in a shell that provides the global bottom nav bar
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.home,
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: AppRoutes.route,
            builder: (context, state) => const RouteScreen(),
          ),
          GoRoute(
            path: AppRoutes.visitHistory,
            builder: (context, state) => const VisitHistoryScreen(),
          ),
          GoRoute(
            path: AppRoutes.profile,
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),

      // Shop Details Screen
      GoRoute(
        path: AppRoutes.shopDetails,
        builder: (context, state) => const ShopDetailsScreen(),
      ),

      // Active Visit Screen
      GoRoute(
        path: AppRoutes.activeVisit,
        builder: (context, state) => const ActiveVisitScreen(),
      ),

      // New Order Screen
      GoRoute(
        path: AppRoutes.newOrder,
        builder: (context, state) => const NewOrderScreen(),
      ),

      // Collect Payment Screen
      GoRoute(
        path: AppRoutes.collectPayment,
        builder: (context, state) => const CollectPaymentScreen(),
      ),

      // SMS Sent Screen
      GoRoute(
        path: AppRoutes.smsSent,
        builder: (context, state) {
          final extra = state.extra as Map<String, String>?;
          return SmsSentScreen(
            shopName: extra?['shopName'] ?? 'Shop',
            phoneNumber: extra?['phoneNumber'] ?? '+000 0000 0000',
            amount: extra?['amount'] ?? '0',
            repName: extra?['repName'] ?? 'Rep',
            time: extra?['time'] ?? '00:00',
          );
        },
      ),

      // Daily Summary Screen
      GoRoute(
        path: AppRoutes.dailySummary,
        builder: (context, state) => const DailySummaryScreen(),
      ),

      // Notifications Screen
      GoRoute(
        path: AppRoutes.notifications,
        builder: (context, state) => const NotificationsScreen(),
      ),

      // Personal Details Screen
      GoRoute(
        path: AppRoutes.personalDetails,
        builder: (context, state) => const PersonalDetailsScreen(),
      ),

      // Map Fullscreen Screen
      GoRoute(
        path: AppRoutes.mapFullscreen,
        builder: (context, state) {
          final extra = state.extra as Map<String, double?>?;
          return MapFullscreenScreen(
            initialLat: extra?['lat'],
            initialLng: extra?['lng'],
          );
        },
      ),

      // Shops List Screen
      GoRoute(
        path: AppRoutes.showShops,
        builder: (context, state) => const ShopsListScreen(),
      ),

    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Page not found',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(state.uri.toString()),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go(AppRoutes.home),
              child: const Text('Go to Home'),
            ),
          ],
        ),
      ),
    ),
  );
}
