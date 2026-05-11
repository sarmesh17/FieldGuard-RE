/// Application route paths
/// 
/// This class contains all the route path constants used throughout the app.
/// Use these constants instead of hardcoded strings for type-safe navigation.
/// 
/// Example:
/// ```dart
/// context.go(AppRoutes.home);
/// context.push(AppRoutes.profile);
/// ```
class AppRoutes {
  // Prevent instantiation
  AppRoutes._();

  /// Splash screen route - Initial route
  static const String splash = '/';

  /// Onboarding screen route
  static const String onboarding = '/onboarding';

  /// Login screen route
  static const String login = '/login';

  /// Home screen route - Main dashboard
  static const String home = '/home';

  /// Route planning screen
  static const String route = '/route';

  /// Shop details screen
  static const String shopDetails = '/shop-details';

  /// Active visit tracking screen
  static const String activeVisit = '/active-visit';

  /// New order creation screen
  static const String newOrder = '/new-order';

  /// Payment collection screen
  static const String collectPayment = '/collect-payment';

  /// SMS sent confirmation screen
  static const String smsSent = '/sms-sent';

  /// Daily summary report screen
  static const String dailySummary = '/daily-summary';

  /// Visit history list screen
  static const String visitHistory = '/visit-history';

  /// Notifications center screen
  static const String notifications = '/notifications';

  /// User profile screen
  static const String profile = '/profile';
}
