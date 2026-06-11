import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:field_guard_re/core/router/app_routes.dart';
import 'package:field_guard_re/core/services/live_tracking_service.dart';
import 'package:field_guard_re/core/services/push_notification_service.dart';
import 'package:field_guard_re/core/theme/app_responsive.dart';
import 'package:field_guard_re/features/auth/presentation/providers/auth_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );

    _animationController.forward();
    _navigateAfterSplash();
  }

  Future<void> _navigateAfterSplash() async {
    await Future.delayed(const Duration(milliseconds: 2500));
    if (!mounted) return;

    // Rebuild AuthSuccess from the saved JWT so currentUser.role is
    // available across the app (filter chips, role gating, etc.).
    final restored =
        await ref.read(authNotifierProvider.notifier).restoreSession();
    if (!mounted) return;

    // Authenticated → home, first-time / logged-out → onboarding
    context.go(restored ? AppRoutes.home : AppRoutes.onboarding);

    if (restored) {
      // Re-register the FCM token on every authenticated launch — it may have
      // rotated, or registration may have failed (offline) last session.
      unawaited(PushNotificationService.instance.registerToken());
      // Open the realtime socket for live in-app notifications (independent of
      // live tracking).
      unawaited(LiveTrackingService.instance.connect());
      // If the app was cold-started by tapping a push, jump to that screen now
      // that we're on home.
      PushNotificationService.instance.consumePendingDeepLink();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final iconSize = AppResponsive.r(context, 88);
    final shieldSize = AppResponsive.r(context, 46);
    final titleSize = AppResponsive.sp(context, 36);
    final agentSize = AppResponsive.sp(context, 13);

    return Scaffold(
      backgroundColor: const Color(0xFF1B6B45),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            children: [
              Expanded(
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: iconSize,
                        height: iconSize,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(iconSize * 0.25),
                        ),
                        child: Icon(
                          Icons.shield_outlined,
                          size: shieldSize,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: AppResponsive.r(context, 28)),
                      Text(
                        'FieldGuard',
                        style: TextStyle(
                          fontSize: titleSize,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'AGENT',
                        style: TextStyle(
                          fontSize: agentSize,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.7),
                          letterSpacing: 4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 40),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(3, (i) {
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(
                              alpha: i == 0 ? 1.0 : 0.4,
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'v1.0.0',
                      style: TextStyle(
                        fontSize: AppResponsive.sp(context, 12),
                        color: Colors.white.withValues(alpha: 0.5),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
