import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/presentation/screens/splash_screen/splash_screen.dart';
import '../../features/presentation/screens/onboarding_screen/onboarding_screen.dart';
import '../../features/auth/presentation/screens/login_screen/login_screen.dart';
import '../../features/presentation/screens/home_screen/home_screen.dart';
import '../../features/presentation/screens/route_screen/route_screen.dart';
import '../../features/presentation/screens/collect_payment_screen/collect_payment_screen.dart';
import '../../features/collections/data/models/collection_response.dart';
import '../../features/presentation/screens/sms_sent_screen/sms_sent_screen.dart';
import '../../features/tasks/presentation/screens/task_detail_screen.dart';
import '../../features/tasks/presentation/screens/task_history_screen.dart';
import '../../features/tasks/presentation/screens/tasks_screen.dart';
import '../../features/presentation/screens/notifications_screen/notifications_screen.dart';
import '../../features/profile/presentation/screens/profile_screen/profile_screen.dart';
import '../../features/profile/presentation/screens/personal_details_screen/personal_details_screen.dart';
import '../../features/presentation/screens/route_screen/map_fullscreen_screen.dart';
import '../../features/shops/presentation/screens/shops_list_screen.dart';
import '../../features/shops/presentation/screens/shop_create_map_screen.dart';
import '../../features/shops/presentation/screens/shop_detail_screen.dart';
import '../../features/legal/presentation/screens/terms_screen.dart';
import '../../features/legal/presentation/screens/privacy_screen.dart';
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
            path: AppRoutes.tasks,
            builder: (context, state) => const TasksScreen(),
          ),
          GoRoute(
            path: AppRoutes.shops,
            builder: (context, state) => const ShopsListScreen(),
          ),
          GoRoute(
            path: AppRoutes.profile,
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),

      // Collect Payment Screen. Requires `extra` with shopId/shopName, plus
      // an optional taskId so we can invalidate the task on a successful
      // collection. Falls back to a friendly error screen if anything was
      // pushed without the required keys (shouldn't happen, but safer than
      // crashing on a stale deep link).
      GoRoute(
        path: AppRoutes.collectPayment,
        builder: (context, state) {
          final extra = state.extra;
          if (extra is Map &&
              extra['shopId'] is int &&
              extra['shopName'] is String) {
            return CollectPaymentScreen(
              shopId: extra['shopId'] as int,
              shopName: extra['shopName'] as String,
              taskId: extra['taskId'] is int ? extra['taskId'] as int : null,
            );
          }
          return const Scaffold(
            body: Center(
              child: Text('Missing shop context for collection'),
            ),
          );
        },
      ),

      // SMS Sent Screen. Takes the full CollectionResponse via `extra` so
      // it can render the backend-authored SMS body verbatim. Falls back
      // to a friendly error screen if anything other than that shape is
      // pushed (shouldn't happen from in-app flow, but safer than crashing
      // on a stale deep link).
      GoRoute(
        path: AppRoutes.smsSent,
        builder: (context, state) {
          final extra = state.extra;
          if (extra is Map && extra['response'] is CollectionResponse) {
            return SmsSentScreen(
              response: extra['response'] as CollectionResponse,
            );
          }
          return const Scaffold(
            body: Center(
              child: Text('Missing collection context'),
            ),
          );
        },
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

      // Shop Create Map Screen (stand-at-shop flow, no bottom nav)
      GoRoute(
        path: AppRoutes.shopCreateMap,
        builder: (context, state) => const ShopCreateMapScreen(),
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

      // Shop Detail Screen (API-backed full details)
      GoRoute(
        path: AppRoutes.shopDetail,
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return ShopDetailScreen(shopId: id);
        },
      ),

      // Task Detail Screen
      GoRoute(
        path: AppRoutes.taskDetail,
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return TaskDetailScreen(taskId: id);
        },
      ),

      // Task History Screen
      GoRoute(
        path: AppRoutes.taskHistory,
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          final title = state.uri.queryParameters['title'] ?? 'Task';
          return TaskHistoryScreen(taskId: id, taskTitle: title);
        },
      ),

      // Legal screens — public, no auth required
      GoRoute(
        path: AppRoutes.termsAndConditions,
        builder: (context, state) => const TermsAndConditionsScreen(),
      ),
      GoRoute(
        path: AppRoutes.privacyPolicy,
        builder: (context, state) => const PrivacyPolicyScreen(),
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
