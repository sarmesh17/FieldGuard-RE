import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:field_guard_re/core/router/app_router.dart';
import 'package:field_guard_re/core/router/app_routes.dart';
import 'package:field_guard_re/core/services/background_location_service.dart';
import 'package:field_guard_re/core/services/debug_log_service.dart';
import 'package:field_guard_re/core/services/geofence_visit_service.dart';
import 'package:field_guard_re/core/services/notification_service.dart';
import 'package:field_guard_re/core/services/token_refresh_service.dart';
import 'package:field_guard_re/core/theme/app_theme.dart';
import 'package:go_router/go_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  MapboxOptions.setAccessToken(dotenv.env['MAPBOX_PUBLIC_TOKEN']!);

  // On-device debug log (geofence traces survive without a laptop attached).
  await DebugLogService.instance.init();

  // Register the notification channel + request permission up-front so the
  // geofence enter/exit alerts can fire later without a first-time delay.
  // (Also creates the foreground-service channel the background service uses.)
  await NotificationService.instance.init();

  // Register the background location service isolate (does not start it —
  // start/stop is driven by whether a task is IN_PROGRESS).
  await BackgroundLocationService.initialize();

  // Close any visit left open by a previous app-kill (flagged exitEstimated)
  // and flush the persisted upload queue. Fire-and-forget — must not delay
  // first paint.
  GeofenceVisitService.instance.recover();

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _onAppResumed();
    }
  }

  Future<void> _onAppResumed() async {
    // Retry any geofence visits that couldn't be uploaded while backgrounded.
    GeofenceVisitService.instance.flushQueue();

    final isValid = await TokenRefreshService.refreshIfNeeded();
    if (!isValid) {
      AppRouter.navigatorKey.currentContext?.go(AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'FieldGuard Agent',
      theme: AppTheme.lightTheme,
      routerConfig: AppRouter.router,
    );
  }
}
