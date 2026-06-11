import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:field_guard_re/core/constants/app_strings.dart';
import 'package:field_guard_re/core/router/app_routes.dart';
import 'package:field_guard_re/core/services/live_tracking_service.dart';
import 'package:field_guard_re/core/services/push_notification_service.dart';
import 'package:field_guard_re/core/theme/app_colors.dart';
import 'package:field_guard_re/core/theme/app_responsive.dart';
import 'package:field_guard_re/core/theme/app_text_styles.dart';
import 'package:field_guard_re/features/auth/presentation/providers/auth_provider.dart';
import 'package:field_guard_re/features/legal/presentation/providers/legal_provider.dart';
import 'components/shield_icon_badge.dart';
import 'components/form_card.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _termsAccepted = false;

  @override
  void initState() {
    super.initState();
    _phoneController.addListener(_clearAuthError);
    _passwordController.addListener(_clearAuthError);
    // Pre-fetch legal version so it's ready by the time the user taps Sign In.
    Future.microtask(() => ref.read(legalVersionProvider.future));
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _clearAuthError() {
    if (!mounted) return;
    final state = ref.read(authNotifierProvider);
    if (state is AuthError) {
      ref.read(authNotifierProvider.notifier).reset();
    }
  }

  void _onSignIn() {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final phone = _phoneController.text.trim();
    final password = _passwordController.text.trim();
    // legalVersionProvider resolves instantly after pre-fetch; falls back to
    // today's date if the network call hasn't completed yet.
    final termsVersion = ref.read(legalVersionProvider).valueOrNull ??
        DateTime.now().toIso8601String().substring(0, 10);
    unawaited(
      ref.read(authNotifierProvider.notifier).login(
        phone,
        password,
        termsAccepted: _termsAccepted,
        termsVersion: termsVersion,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authNotifierProvider, (_, state) {
      if (state is AuthSuccess) {
        ref.read(authNotifierProvider.notifier).reset();
        // Session is live (tokens already saved) — register this device's FCM
        // token with the backend so it can push to it. Fire-and-forget.
        unawaited(PushNotificationService.instance.registerToken());
        // Open the realtime socket for live in-app notifications (independent
        // of live tracking — so notifications arrive even with tracking off).
        unawaited(LiveTrackingService.instance.connect());
        context.go(AppRoutes.home);
      }
      // AuthError no longer triggers a SnackBar — it's rendered inline inside
      // the FormCard (see errorMessage below) so the keyboard can't hide it.
    });

    final authState = ref.watch(authNotifierProvider);
    final isLoading = authState is AuthLoading;
    final errorMessage = authState is AuthError ? authState.message : null;

    return Scaffold(
      backgroundColor: AppColors.primaryGreen,
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Center the content when there's room, scroll when there isn't.
          // ConstrainedBox(minHeight) + IntrinsicHeight + a Spacer-free
          // Column with mainAxisAlignment.center is what makes short and
          // landscape screens degrade gracefully instead of overflowing.
          return SingleChildScrollView(
            // Let the gradient bleed under the status bar; SafeArea handles
            // the actual content insets below.
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: _LoginContent(
                  formKey: _formKey,
                  phoneController: _phoneController,
                  passwordController: _passwordController,
                  obscurePassword: _obscurePassword,
                  isLoading: isLoading,
                  errorMessage: errorMessage,
                  termsAccepted: _termsAccepted,
                  onTermsChanged: (v) => setState(() => _termsAccepted = v),
                  onTogglePassword: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                  onSignIn: _onSignIn,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Gradient backdrop that lays out the brand hero + form card.
///
/// * Portrait: a single centred column (hero stacked above the card).
/// * Landscape: a two-pane row — brand hero on the left (top-aligned, NOT
///   vertically centred, so it reads like a header rather than floating in
///   the middle), form card on the right. This keeps the form fully visible
///   on short landscape heights instead of being squeezed.
///
/// All sizes flow through [AppResponsive] (MediaQuery-driven), so text and
/// components scale with the viewport rather than relying on fixed pixels.
class _LoginContent extends StatelessWidget {
  const _LoginContent({
    required this.formKey,
    required this.phoneController,
    required this.passwordController,
    required this.obscurePassword,
    required this.isLoading,
    required this.onTogglePassword,
    required this.onSignIn,
    required this.termsAccepted,
    required this.onTermsChanged,
    this.errorMessage,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController phoneController;
  final TextEditingController passwordController;
  final bool obscurePassword;
  final bool isLoading;
  final VoidCallback onTogglePassword;
  final VoidCallback onSignIn;
  final bool termsAccepted;
  final ValueChanged<bool> onTermsChanged;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    final landscape = AppResponsive.isLandscape(context);

    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF134E40), Color(0xFF1B5E4F), Color(0xFF0D9488)],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AppResponsive.horizontalPad(context),
            vertical: AppResponsive.vGap(context, 16),
          ),
          child: landscape ? _buildLandscape(context) : _buildPortrait(context),
        ),
      ),
    );
  }

  // ── Portrait: centred single column ──────────────────────────────────────
  Widget _buildPortrait(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: AppResponsive.vGap(context, 32)),
            _BrandHero(centered: true),
            SizedBox(height: AppResponsive.vGap(context, 32)),
            _card(),
            SizedBox(height: AppResponsive.vGap(context, 16)),
          ],
        ),
      ),
    );
  }

  // ── Landscape: two panes, hero left (top-aligned), form right ────────────
  Widget _buildLandscape(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Brand pane — flexes a bit wider so the heading has room to breathe.
        Expanded(
          flex: 5,
          child: Padding(
            padding: EdgeInsets.only(
              top: AppResponsive.vGap(context, 24),
              right: AppResponsive.r(context, 24),
            ),
            child: _BrandHero(centered: false),
          ),
        ),
        // Form pane — scrolls on its own if a short landscape height can't fit
        // the whole card, so the gradient pane never pushes it off-screen.
        Expanded(
          flex: 6,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: AppResponsive.vGap(context, 8)),
                _card(),
                SizedBox(height: AppResponsive.vGap(context, 8)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _card() => FormCard(
    formKey: formKey,
    phoneController: phoneController,
    passwordController: passwordController,
    obscurePassword: obscurePassword,
    isLoading: isLoading,
    onTogglePassword: onTogglePassword,
    onSignIn: onSignIn,
    termsAccepted: termsAccepted,
    onTermsChanged: onTermsChanged,
    errorMessage: errorMessage,
  );

}

/// Shield badge + welcome heading + subtitle. [centered] true centres it
/// (portrait); false left-aligns it (landscape brand pane).
class _BrandHero extends StatelessWidget {
  const _BrandHero({required this.centered});

  final bool centered;

  @override
  Widget build(BuildContext context) {
    final align = centered ? TextAlign.center : TextAlign.start;
    return Column(
      crossAxisAlignment: centered
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const ShieldIconBadge(),
        SizedBox(height: AppResponsive.vGap(context, 20)),
        Text(
          AppStrings.welcomeBack,
          textAlign: align,
          style: AppTextStyles.heading1R(context).copyWith(
            color: Colors.white,
            fontSize: AppResponsive.sp(context, centered ? 30 : 34),
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
            height: 1.1,
          ),
        ),
        SizedBox(height: AppResponsive.vGap(context, 8)),
        Text(
          AppStrings.signInToAccount,
          textAlign: align,
          style: AppTextStyles.subtitleR(
            context,
          ).copyWith(color: Colors.white.withValues(alpha: 0.85)),
        ),
      ],
    );
  }
}
