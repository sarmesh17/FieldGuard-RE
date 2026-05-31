import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:field_guard_re/core/constants/app_constants.dart';
import 'package:field_guard_re/core/constants/app_strings.dart';
import 'package:field_guard_re/core/router/app_routes.dart';
import 'package:field_guard_re/core/theme/app_colors.dart';
import 'package:field_guard_re/core/theme/app_responsive.dart';
import 'package:field_guard_re/core/theme/app_text_styles.dart';
import 'package:go_router/go_router.dart';
import 'phone_input_row.dart';
import 'password_field.dart';
import 'sign_in_button.dart';

class FormCard extends StatefulWidget {
  const FormCard({
    super.key,
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

  /// Backend / auth-flow error rendered as an inline banner above the Sign In
  /// button. Kept in the card (not a SnackBar) so the keyboard never covers
  /// it; per-field validation errors still render below each TextField.
  final String? errorMessage;

  @override
  State<FormCard> createState() => _FormCardState();
}

class _FormCardState extends State<FormCard> {
  // Validation only kicks in after the first submit attempt so errors don't
  // flash on every keystroke while the user is still typing.
  AutovalidateMode _autovalidateMode = AutovalidateMode.disabled;
  bool _showTermsError = false;

  void _handleSignIn() {
    setState(() => _autovalidateMode = AutovalidateMode.onUserInteraction);
    if (!widget.termsAccepted) {
      setState(() => _showTermsError = true);
      return;
    }
    widget.onSignIn();
  }

  @override
  Widget build(BuildContext context) {
    final vPad = AppResponsive.r(context, 24);
    final hPad = AppResponsive.r(context, 20);
    const accent = Color(0xFF157347);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius + 8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 32,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(hPad, vPad, hPad, vPad + 4),
      child: Form(
        key: widget.formKey,
        autovalidateMode: _autovalidateMode,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(AppStrings.mobileNumber, style: AppTextStyles.labelR(context)),
            SizedBox(height: AppResponsive.r(context, 10)),
            PhoneInputRow(controller: widget.phoneController),
            SizedBox(height: AppResponsive.r(context, 18)),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(AppStrings.password, style: AppTextStyles.labelR(context)),
                GestureDetector(
                  onTap: () {},
                  child: Text(
                    AppStrings.forgotPassword,
                    style: AppTextStyles.linkR(context),
                  ),
                ),
              ],
            ),
            SizedBox(height: AppResponsive.r(context, 10)),
            PasswordField(
              controller: widget.passwordController,
              obscureText: widget.obscurePassword,
              onToggle: widget.onTogglePassword,
            ),

            // ── Consent checkbox ───────────────────────────────────────────
            SizedBox(height: AppResponsive.r(context, 20)),
            _ConsentRow(
              accepted: widget.termsAccepted,
              onChanged: (v) {
                widget.onTermsChanged(v);
                if (v && _showTermsError) {
                  setState(() => _showTermsError = false);
                }
              },
              accent: accent,
              onTapTerms: () => context.push(AppRoutes.termsAndConditions),
              onTapPrivacy: () => context.push(AppRoutes.privacyPolicy),
            ),
            if (_showTermsError) ...[
              SizedBox(height: AppResponsive.r(context, 6)),
              Text(
                'Please accept the Terms & Conditions to continue.',
                style: TextStyle(
                  fontSize: AppResponsive.sp(context, 12),
                  color: const Color(0xFFB91C1C),
                ),
              ),
            ],

            if (widget.errorMessage != null) ...[
              SizedBox(height: AppResponsive.r(context, 16)),
              _ErrorBanner(message: widget.errorMessage!),
            ],
            SizedBox(height: AppResponsive.r(context, 22)),
            SignInButton(isLoading: widget.isLoading, onPressed: _handleSignIn),
          ],
        ),
      ),
    );
  }
}

// ── Consent checkbox row ──────────────────────────────────────────────────────

class _ConsentRow extends StatelessWidget {
  final bool accepted;
  final ValueChanged<bool> onChanged;
  final Color accent;
  final VoidCallback onTapTerms;
  final VoidCallback onTapPrivacy;

  const _ConsentRow({
    required this.accepted,
    required this.onChanged,
    required this.accent,
    required this.onTapTerms,
    required this.onTapPrivacy,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 22,
          height: 22,
          child: Checkbox(
            value: accepted,
            onChanged: (v) => onChanged(v ?? false),
            activeColor: accent,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text.rich(
            TextSpan(
              style: TextStyle(
                fontSize: AppResponsive.sp(context, 12.5),
                color: const Color(0xFF374151),
                height: 1.4,
              ),
              children: [
                const TextSpan(text: 'I have read and agree to the '),
                TextSpan(
                  text: 'Terms & Conditions',
                  style: TextStyle(
                    color: accent,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                    decorationColor: accent,
                  ),
                  recognizer: TapGestureRecognizer()..onTap = onTapTerms,
                ),
                const TextSpan(text: ' and '),
                TextSpan(
                  text: 'Privacy Policy',
                  style: TextStyle(
                    color: accent,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                    decorationColor: accent,
                  ),
                  recognizer: TapGestureRecognizer()..onTap = onTapPrivacy,
                ),
                const TextSpan(text: '.'),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Error banner ──────────────────────────────────────────────────────────────

class _ErrorBanner extends StatelessWidget {
  final String message;

  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppResponsive.r(context, 12),
        vertical: AppResponsive.r(context, 10),
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.error_outline,
            color: const Color(0xFFB91C1C),
            size: AppResponsive.r(context, 18),
          ),
          SizedBox(width: AppResponsive.r(context, 8)),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: AppResponsive.sp(context, 13),
                color: const Color(0xFF7F1D1D),
                fontWeight: FontWeight.w600,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
