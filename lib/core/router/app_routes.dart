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

  /// Payment collection screen. Requires `extra` of shape:
  ///   `{ 'shopId': int, 'shopName': String, 'taskId': int? }`
  /// Use [collectPaymentExtra] to build the map safely.
  static const String collectPayment = '/collect-payment';
  static Map<String, dynamic> collectPaymentExtra({
    required int shopId,
    required String shopName,
    int? taskId,
  }) =>
      {
        'shopId': shopId,
        'shopName': shopName,
        'taskId': ?taskId,
      };

  /// SMS sent confirmation screen
  static const String smsSent = '/sms-sent';

  /// Daily summary report screen
  static const String dailySummary = '/daily-summary';

  /// Visit history list screen
  static const String visitHistory = '/visit-history';

  /// Tasks list screen
  static const String tasks = '/tasks';

  /// Task detail screen
  static const String taskDetail = '/task-detail/:id';
  static String taskDetailPath(int id) => '/task-detail/$id';

  /// Task history screen
  static const String taskHistory = '/task-history/:id';
  static String taskHistoryPath(int id) => '/task-history/$id';

  /// Notifications center screen
  static const String notifications = '/notifications';

  /// User profile screen
  static const String profile = '/profile';

  /// Personal details edit screen
  static const String personalDetails = '/personal-details';

  /// Full screen map view
  static const String mapFullscreen = '/map-fullscreen';

  /// Shops list screen
  static const String showShops = '/show-shops';

  /// Shops tab screen (bottom-nav tab)
  static const String shops = '/shops';

  /// Shop creation map screen (stand-at-shop flow)
  static const String shopCreateMap = '/shop-create-map';

  /// Shop detail screen (API-backed full details)
  static const String shopDetail = '/shop-detail/:id';
  static String shopDetailPath(int id) => '/shop-detail/$id';
}
