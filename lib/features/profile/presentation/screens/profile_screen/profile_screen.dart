import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:field_guard_re/core/router/app_routes.dart';
import 'package:field_guard_re/core/services/token_storage.dart';
import 'package:field_guard_re/core/theme/app_colors.dart';
import 'package:field_guard_re/core/theme/app_responsive.dart';
import 'package:field_guard_re/core/theme/app_text_styles.dart';
import 'package:field_guard_re/features/profile/data/models/profile_response.dart';
import 'package:field_guard_re/features/profile/presentation/providers/profile_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  late final Animation<double> _avatarScale;
  late final Animation<double> _headerFade;
  late final Animation<double> _statsFade;
  late final Animation<Offset> _statsSlide;
  late final Animation<double> _statsCount;
  late final Animation<double> _menu1Fade;
  late final Animation<Offset> _menu1Slide;
  late final Animation<double> _menu2Fade;
  late final Animation<Offset> _menu2Slide;
  late final Animation<double> _menu3Fade;
  late final Animation<Offset> _menu3Slide;
  late final Animation<double> _menu4Fade;
  late final Animation<Offset> _menu4Slide;
  late final Animation<double> _footerFade;
  late final Animation<Offset> _footerSlide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _avatarScale = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.0, 0.45, curve: Curves.elasticOut),
    );
    _headerFade = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.05, 0.45, curve: Curves.easeOut),
    );

    _statsFade = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.25, 0.55, curve: Curves.easeOut),
    );
    _statsSlide = _slide(0.25, 0.55);
    _statsCount = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.28, 0.90, curve: Curves.easeOut),
    );

    _menu1Fade = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.38, 0.65, curve: Curves.easeOut),
    );
    _menu1Slide = _slide(0.38, 0.65);

    _menu2Fade = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.48, 0.73, curve: Curves.easeOut),
    );
    _menu2Slide = _slide(0.48, 0.73);

    _menu3Fade = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.57, 0.80, curve: Curves.easeOut),
    );
    _menu3Slide = _slide(0.57, 0.80);

    _menu4Fade = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.65, 0.87, curve: Curves.easeOut),
    );
    _menu4Slide = _slide(0.65, 0.87);

    _footerFade = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.78, 1.0, curve: Curves.easeOut),
    );
    _footerSlide = _slide(0.78, 1.0);

    // Animation is triggered by ref.listen in build() once ProfileSuccess
    // arrives, so we don't forward here. If the data is already cached when
    // the widget mounts, initState checks and starts it immediately.
    if (ref.read(profileNotifierProvider) is ProfileSuccess) {
      _ctrl.forward();
    }
  }

  Animation<Offset> _slide(double begin, double end) =>
      Tween<Offset>(begin: const Offset(0, 0.35), end: Offset.zero).animate(
        CurvedAnimation(
          parent: _ctrl,
          curve: Interval(begin, end, curve: Curves.easeOutCubic),
        ),
      );

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  String _initials(String fullName) {
    final parts =
        fullName.trim().split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    // Start the animation the moment the API responds with success.
    ref.listen<ProfileState>(profileNotifierProvider, (_, next) {
      if (next is ProfileSuccess) _ctrl.forward(from: 0);
    });

    final profileState = ref.watch(profileNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundBeige,
      body: switch (profileState) {
        ProfileInitial() || ProfileLoading() => const _ProfileSkeleton(),
        ProfileError(:final message) => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(message, style: const TextStyle(color: Colors.red)),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => ref
                      .read(profileNotifierProvider.notifier)
                      .fetchProfile(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ProfileSuccess(:final response) => CustomScrollView(
            slivers: [
              _buildSliverHeader(context, response),
              SliverToBoxAdapter(
                child: _buildBody(context, response),
              ),
            ],
          ),
      },
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────

  Widget _buildSliverHeader(BuildContext context, ProfileResponse response) {
    return SliverAppBar(
      expandedHeight: AppResponsive.r(context, 240),
      pinned: true,
      floating: false,
      automaticallyImplyLeading: false,
      backgroundColor: AppColors.primaryGreen,
      elevation: 0,
      centerTitle: true,
      title: Text(
        'Profile',
        style: AppTextStyles.labelR(context).copyWith(
          fontSize: AppResponsive.sp(context, 16),
          fontWeight: FontWeight.w600,
          color: AppColors.cardWhite,
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: _buildHeaderBackground(context, response),
      ),
    );
  }

  Widget _buildHeaderBackground(
      BuildContext context, ProfileResponse response) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1B5E4F), Color(0xFF2D9B83)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Decorative circles
          Positioned(
            top: -40,
            right: -40,
            child: _decorCircle(160, 0.06),
          ),
          Positioned(
            bottom: 10,
            left: -50,
            child: _decorCircle(140, 0.04),
          ),
          Positioned(
            top: 60,
            right: 30,
            child: _decorCircle(60, 0.07),
          ),
          // Profile content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 40, 16, 16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 8),
                  // Avatar with glowing ring
                  ScaleTransition(
                    scale: _avatarScale,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.5),
                          width: 2.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 16,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: AppResponsive.r(context, 40),
                        backgroundColor:
                            Colors.white.withValues(alpha: 0.18),
                        child: Text(
                          _initials(response.fullName),
                          style: AppTextStyles.heading1R(context).copyWith(
                            fontSize: AppResponsive.sp(context, 28),
                            fontWeight: FontWeight.bold,
                            color: AppColors.cardWhite,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: AppResponsive.r(context, 10)),
                  // Name
                  FadeTransition(
                    opacity: _headerFade,
                    child: Text(
                      response.fullName,
                      style: AppTextStyles.heading1R(context).copyWith(
                        fontSize: AppResponsive.sp(context, 20),
                        fontWeight: FontWeight.bold,
                        color: AppColors.cardWhite,
                      ),
                    ),
                  ),
                  SizedBox(height: AppResponsive.r(context, 6)),
                  // Role pill
                  FadeTransition(
                    opacity: _headerFade,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Text(
                        response.role.toUpperCase(),
                        style: AppTextStyles.labelR(context).copyWith(
                          fontSize: AppResponsive.sp(context, 11),
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.92),
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _decorCircle(double size, double opacity) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: opacity),
        ),
      );

  // ── Body ──────────────────────────────────────────────────────────────────

  Widget _buildBody(BuildContext context, ProfileResponse response) {
    final hPad = AppResponsive.horizontalPad(context);

    return Column(
      children: [
        // Stats
        FadeTransition(
          opacity: _statsFade,
          child: SlideTransition(
            position: _statsSlide,
            child: Padding(
              padding: EdgeInsets.fromLTRB(hPad, 20, hPad, 0),
              child: Row(
                children: [
                  _buildStatTile(
                    context,
                    icon: Icons.store_outlined,
                    label: 'Visits',
                    target: 142,
                    format: (v) => v.toInt().toString(),
                  ),
                  const SizedBox(width: 10),
                  _buildStatTile(
                    context,
                    icon: Icons.account_balance_wallet_outlined,
                    label: 'Collected',
                    target: 3.2,
                    format: (v) => '₹ ${v.toStringAsFixed(1)}L',
                  ),
                  const SizedBox(width: 10),
                  _buildStatTile(
                    context,
                    icon: Icons.check_circle_outline,
                    label: 'Confirmation',
                    target: 96,
                    format: (v) => '${v.toInt()}%',
                  ),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(height: 24),

        // ACCOUNT
        _animatedSection(
          fade: _menu1Fade,
          slide: _menu1Slide,
          child: _buildSection(
            context,
            hPad: hPad,
            title: 'ACCOUNT',
            items: [
              _Item(
                icon: Icons.person_outline,
                label: 'Personal Details',
                iconColor: AppColors.primaryGreen,
                iconBg: const Color(0xFFE4F4EE),
                onTap: () => context.push(AppRoutes.personalDetails),
              ),
              _Item(
                icon: Icons.account_balance_outlined,
                label: 'Bank Information',
                iconColor: AppColors.primaryGreen,
                iconBg: const Color(0xFFE4F4EE),
                onTap: () {},
              ),
            ],
          ),
        ),

        // WORK
        _animatedSection(
          fade: _menu2Fade,
          slide: _menu2Slide,
          child: _buildSection(
            context,
            hPad: hPad,
            title: 'WORK',
            items: [
              _Item(
                icon: Icons.store_outlined,
                label: 'Show Shops',
                iconColor: const Color(0xFF2563EB),
                iconBg: const Color(0xFFEFF6FF),
                onTap: () => context.push(AppRoutes.showShops),
              ),
              _Item(
                icon: Icons.history,
                label: 'Visit History',
                iconColor: const Color(0xFF2563EB),
                iconBg: const Color(0xFFEFF6FF),
                onTap: () {},
              ),
            ],
          ),
        ),

        // APP SETTINGS
        _animatedSection(
          fade: _menu3Fade,
          slide: _menu3Slide,
          child: _buildSection(
            context,
            hPad: hPad,
            title: 'APP SETTINGS',
            items: [
              _Item(
                icon: Icons.notifications_outlined,
                label: 'Notifications',
                iconColor: const Color(0xFF7C3AED),
                iconBg: const Color(0xFFF5F3FF),
                onTap: () {},
              ),
              _Item(
                icon: Icons.lock_outline,
                label: 'Security & Pin',
                iconColor: const Color(0xFF7C3AED),
                iconBg: const Color(0xFFF5F3FF),
                onTap: () {},
              ),
            ],
          ),
        ),

        // SUPPORT
        _animatedSection(
          fade: _menu4Fade,
          slide: _menu4Slide,
          child: _buildSection(
            context,
            hPad: hPad,
            title: 'SUPPORT',
            items: [
              _Item(
                icon: Icons.help_outline,
                label: 'Help Center',
                iconColor: const Color(0xFFEA580C),
                iconBg: const Color(0xFFFFF7ED),
                onTap: () {},
              ),
              _Item(
                icon: Icons.warning_amber_outlined,
                label: 'Report an Issue',
                iconColor: const Color(0xFFEA580C),
                iconBg: const Color(0xFFFFF7ED),
                onTap: () {},
              ),
            ],
          ),
        ),

        const SizedBox(height: 8),

        // Sign out + version
        FadeTransition(
          opacity: _footerFade,
          child: SlideTransition(
            position: _footerSlide,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: hPad),
              child: Column(
                children: [
                  OutlinedButton.icon(
                    onPressed: () async {
                      await TokenStorage.clearTokens();
                      if (context.mounted) context.go(AppRoutes.login);
                    },
                    icon: const Icon(
                      Icons.logout_rounded,
                      color: Color(0xFFDC2626),
                      size: 18,
                    ),
                    label: Text(
                      'Sign Out',
                      style: AppTextStyles.labelR(context).copyWith(
                        fontSize: AppResponsive.sp(context, 15),
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFDC2626),
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(
                          color: Color(0xFFDC2626), width: 1.5),
                      minimumSize: const Size(double.infinity, 52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      backgroundColor:
                          const Color(0xFFDC2626).withValues(alpha: 0.04),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'FieldGuard Agent v2.4.1',
                    style: AppTextStyles.versionR(context),
                  ),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(height: 88),
      ],
    );
  }

  Widget _animatedSection({
    required Animation<double> fade,
    required Animation<Offset> slide,
    required Widget child,
  }) =>
      FadeTransition(
        opacity: fade,
        child: SlideTransition(position: slide, child: child),
      );

  // ── Stat tile ─────────────────────────────────────────────────────────────

  Widget _buildStatTile(
    BuildContext context, {
    required IconData icon,
    required String label,
    required double target,
    required String Function(double) format,
  }) {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardWhite,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: EdgeInsets.symmetric(
          vertical: AppResponsive.r(context, 14),
          horizontal: AppResponsive.r(context, 6),
        ),
        child: Column(
          children: [
            Container(
              width: AppResponsive.r(context, 36),
              height: AppResponsive.r(context, 36),
              decoration: BoxDecoration(
                color: AppColors.lightGreenCircle,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                size: AppResponsive.r(context, 18),
                color: AppColors.primaryGreen,
              ),
            ),
            SizedBox(height: AppResponsive.r(context, 8)),
            AnimatedBuilder(
              animation: _statsCount,
              builder: (context, _) => Text(
                format(_statsCount.value * target),
                style: AppTextStyles.label.copyWith(
                  fontSize: AppResponsive.sp(context, 15),
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: AppTextStyles.subtitle.copyWith(
                fontSize: AppResponsive.sp(context, 10),
                color: AppColors.textGray,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ── Menu section ──────────────────────────────────────────────────────────

  Widget _buildSection(
    BuildContext context, {
    required double hPad,
    required String title,
    required List<_Item> items,
  }) {
    return Padding(
      padding: EdgeInsets.fromLTRB(hPad, 0, hPad, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              title,
              style: AppTextStyles.label.copyWith(
                fontSize: AppResponsive.sp(context, 11),
                fontWeight: FontWeight.w700,
                color: AppColors.textGray,
                letterSpacing: 0.8,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: AppColors.cardWhite,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Column(
                children: [
                  for (int i = 0; i < items.length; i++) ...[
                    _buildTile(context, items[i]),
                    if (i < items.length - 1)
                      Divider(
                        height: 1,
                        thickness: 1,
                        indent: AppResponsive.r(context, 60),
                        color: AppColors.inputBorder,
                      ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTile(BuildContext context, _Item item) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: item.onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AppResponsive.r(context, 16),
            vertical: AppResponsive.r(context, 13),
          ),
          child: Row(
            children: [
              Container(
                width: AppResponsive.r(context, 36),
                height: AppResponsive.r(context, 36),
                decoration: BoxDecoration(
                  color: item.iconBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  item.icon,
                  size: AppResponsive.r(context, 18),
                  color: item.iconColor,
                ),
              ),
              SizedBox(width: AppResponsive.r(context, 14)),
              Expanded(
                child: Text(
                  item.label,
                  style: AppTextStyles.label.copyWith(
                    fontSize: AppResponsive.sp(context, 14),
                    fontWeight: FontWeight.w500,
                    color: AppColors.textDark,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: AppResponsive.r(context, 20),
                color: AppColors.textLight,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Item {
  final IconData icon;
  final String label;
  final Color iconColor;
  final Color iconBg;
  final VoidCallback onTap;

  const _Item({
    required this.icon,
    required this.label,
    required this.iconColor,
    required this.iconBg,
    required this.onTap,
  });
}

// ── Skeleton loader ────────────────────────────────────────────────────────

class _ProfileSkeleton extends StatefulWidget {
  const _ProfileSkeleton();

  @override
  State<_ProfileSkeleton> createState() => _ProfileSkeletonState();
}

class _ProfileSkeletonState extends State<_ProfileSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) => _buildSkeleton(context, _ctrl.value),
    );
  }

  // A bone: rounded rect with a shimmer highlight sweeping left → right.
  Widget _bone(
    double t, {
    double? width,
    required double height,
    double radius = 8,
    bool onHeader = false,
  }) {
    final base = onHeader
        ? Colors.white.withValues(alpha: 0.18)
        : const Color(0xFFE4E6EA);
    final shine = onHeader
        ? Colors.white.withValues(alpha: 0.42)
        : const Color(0xFFF4F5F7);

    // Shine alignment sweeps from x = -3 → +3 over one cycle.
    final shineX = lerpDouble(-3.0, 3.0, t)!;

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(
        width: width,
        height: height,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(color: base),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment(shineX - 1.2, 0),
                  end: Alignment(shineX + 1.2, 0),
                  colors: [
                    Colors.white.withValues(alpha: 0),
                    shine,
                    Colors.white.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeleton(BuildContext context, double t) {
    final hPad = AppResponsive.horizontalPad(context);
    final r = AppResponsive.r;

    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Header ────────────────────────────────────────────────────
          Container(
            height: r(context, 240),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1B5E4F), Color(0xFF2D9B83)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Avatar circle
                _bone(t,
                    width: r(context, 88),
                    height: r(context, 88),
                    radius: 44,
                    onHeader: true),
                SizedBox(height: r(context, 14)),
                // Name bar
                _bone(t,
                    width: r(context, 128),
                    height: r(context, 15),
                    radius: 8,
                    onHeader: true),
                SizedBox(height: r(context, 10)),
                // Role pill
                _bone(t,
                    width: r(context, 78),
                    height: r(context, 26),
                    radius: 13,
                    onHeader: true),
              ],
            ),
          ),

          // ── Stats ──────────────────────────────────────────────────────
          Padding(
            padding: EdgeInsets.fromLTRB(hPad, 20, hPad, 0),
            child: Row(
              children: List.generate(3, (i) {
                return Expanded(
                  child: Container(
                    margin: EdgeInsets.only(left: i == 0 ? 0 : 10),
                    padding: EdgeInsets.symmetric(vertical: r(context, 14)),
                    decoration: BoxDecoration(
                      color: AppColors.cardWhite,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _bone(t,
                            width: r(context, 34),
                            height: r(context, 34),
                            radius: 10),
                        SizedBox(height: r(context, 8)),
                        _bone(t,
                            width: r(context, 36),
                            height: r(context, 12),
                            radius: 6),
                        SizedBox(height: r(context, 5)),
                        _bone(t,
                            width: r(context, 26),
                            height: r(context, 10),
                            radius: 5),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),

          const SizedBox(height: 24),

          // ── Menu groups ────────────────────────────────────────────────
          ...List.generate(4, (groupIdx) {
            return Padding(
              padding: EdgeInsets.fromLTRB(hPad, 0, hPad, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 10),
                    child: _bone(t,
                        width: r(context, 70),
                        height: r(context, 10),
                        radius: 5),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.cardWhite,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Column(
                        children: [
                          _skeletonTile(context, t),
                          Divider(
                            height: 1,
                            thickness: 1,
                            indent: r(context, 60),
                            color: AppColors.inputBorder,
                          ),
                          _skeletonTile(context, t),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),

          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _skeletonTile(BuildContext context, double t) {
    final r = AppResponsive.r;
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: r(context, 16),
        vertical: r(context, 13),
      ),
      child: Row(
        children: [
          _bone(t,
              width: r(context, 36),
              height: r(context, 36),
              radius: 10),
          SizedBox(width: r(context, 14)),
          Expanded(
            child: _bone(t, height: r(context, 13), radius: 7),
          ),
          SizedBox(width: r(context, 48)),
          _bone(t,
              width: r(context, 14),
              height: r(context, 14),
              radius: 4),
        ],
      ),
    );
  }
}
