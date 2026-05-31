import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_responsive.dart';
import 'components/onboarding_page.dart';
import 'components/page_indicator.dart';
import 'components/primary_button.dart';
import 'components/already_have_account_row.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  static const int _totalPages = 2;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onNext() {
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      context.go(AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hPad = AppResponsive.horizontalPad(context);

    return Scaffold(
      backgroundColor: const Color(0xFFFAF8F3),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: hPad),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _totalPages,
                  onPageChanged: (i) => setState(() => _currentPage = i),
                  itemBuilder: (context, index) =>
                      OnboardingPage(pageIndex: index),
                ),
              ),
              const SizedBox(height: 24),
              PageIndicator(total: _totalPages, current: _currentPage),
              const SizedBox(height: 28),
              PrimaryButton(
                label: _currentPage == _totalPages - 1
                    ? AppStrings.getStarted
                    : 'Next',
                onPressed: _onNext,
              ),
              const SizedBox(height: 16),
              AlreadyHaveAccountRow(
                onLogIn: () => context.go(AppRoutes.login),
              ),
              const SizedBox(height: 28),
            ],
          ),
        ),
      ),
    );
  }
}
