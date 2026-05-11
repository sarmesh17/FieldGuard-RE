import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:field_guard_re/core/constants/app_constants.dart';
import 'package:field_guard_re/core/constants/app_strings.dart';
import 'package:field_guard_re/core/router/app_routes.dart';
import 'package:field_guard_re/core/theme/app_responsive.dart';
import 'package:field_guard_re/core/theme/app_text_styles.dart';
import 'package:field_guard_re/features/auth/presentation/providers/auth_provider.dart';
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

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onSignIn() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final phone = _phoneController.text.trim();
    final password = _passwordController.text.trim();
    unawaited(ref.read(authNotifierProvider.notifier).login(phone, password));
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authNotifierProvider, (_, state) {
      if (state is AuthSuccess) {
        ref.read(authNotifierProvider.notifier).reset();
        context.go(AppRoutes.home);
      } else if (state is AuthError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(state.message),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });

    final isLoading = ref.watch(authNotifierProvider) is AuthLoading;
    final hPad = AppResponsive.horizontalPad(context);

    return Scaffold(
      backgroundColor: const Color(0xFFFAF8F3),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: hPad),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: AppResponsive.r(context, 56)),
                const ShieldIconBadge(),
                SizedBox(height: AppResponsive.r(context, 28)),
                Text(
                  AppStrings.welcomeBack,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.heading1R(context).copyWith(
                    fontSize: AppResponsive.sp(context, 30),
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                SizedBox(height: AppResponsive.r(context, 8)),
                Text(
                  AppStrings.signInToAccount,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.subtitleR(context),
                ),
                SizedBox(height: AppResponsive.r(context, 32)),
                FormCard(
                  phoneController: _phoneController,
                  passwordController: _passwordController,
                  obscurePassword: _obscurePassword,
                  isLoading: isLoading,
                  onTogglePassword: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                  onSignIn: _onSignIn,
                ),
                SizedBox(height: AppResponsive.r(context, 24)),
                Text(
                  AppConstants.appVersion,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.versionR(context),
                ),
                SizedBox(height: AppResponsive.r(context, 32)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
