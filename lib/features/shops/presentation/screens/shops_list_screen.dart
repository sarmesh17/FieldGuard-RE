import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:field_guard_re/core/router/app_routes.dart';
import 'package:field_guard_re/core/theme/app_responsive.dart';
import 'package:field_guard_re/features/auth/presentation/providers/auth_provider.dart';
import 'package:field_guard_re/features/shops/data/models/shop_model.dart';
import 'package:field_guard_re/features/shops/presentation/providers/shop_provider.dart';

// ── Filter matrix: role → list of (chip label, source query value) ───────────
// Single source of truth — mirrors the backend SHOP_FILTER_MATRIX constant.
const _kFilterMatrix = <String, List<(String, String)>>{
  'ADMIN': [('Manager', 'manager'), ('Employee', 'employee')],
  'MANAGER': [('Admin', 'admin'), ('Employee', 'employee')],
  'EMPLOYEE': [('Admin', 'admin'), ('Manager', 'manager')],
};

const _kGreen = Color(0xFF157347);

class ShopsListScreen extends ConsumerStatefulWidget {
  const ShopsListScreen({super.key});

  @override
  ConsumerState<ShopsListScreen> createState() => _ShopsListScreenState();
}

class _ShopsListScreenState extends ConsumerState<ShopsListScreen> {
  /// null = All (no ?source param), otherwise the source query value.
  String? _selectedSource;
  String _search = '';

  /// Indices whose entrance animation has already played, so a card recycled
  /// by ListView while scrolling doesn't re-animate every time it scrolls back
  /// into view. Lives in the screen state (survives card disposal).
  final Set<int> _animated = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(shopsListNotifierProvider.notifier).fetch();
    });
  }

  void _onChipTap(String? source) {
    if (_selectedSource == source) return;
    setState(() {
      _selectedSource = source;
      _animated.clear(); // new list → let it cascade in again
    });
    ref.read(shopsListNotifierProvider.notifier).fetch(source: source);
  }

  List<ShopModel> _applySearch(List<ShopModel> shops) {
    if (_search.isEmpty) return shops;
    final q = _search.toLowerCase();
    return shops
        .where(
          (s) =>
              s.name.toLowerCase().contains(q) ||
              s.address.toLowerCase().contains(q),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final listState = ref.watch(shopsListNotifierProvider);
    final authState = ref.watch(authNotifierProvider);
    final currentUser = authState is AuthSuccess
        ? authState.response.user
        : null;

    final role = (currentUser?.role ?? '').toUpperCase();
    final chipDefs = _kFilterMatrix[role] ?? [];

    final allShops = listState is ShopsListSuccess
        ? listState.shops
        : <ShopModel>[];
    final filtered = _applySearch(allShops);

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ShopsHeader(
            total: allShops.length,
            loading: listState is ShopsListLoading,
            selectedSource: _selectedSource,
            chipDefs: chipDefs,
            onChip: _onChipTap,
            onSearch: (v) => setState(() => _search = v),
            onRefresh: () => ref
                .read(shopsListNotifierProvider.notifier)
                .fetch(source: _selectedSource),
          ),
          Expanded(
            child: switch (listState) {
              ShopsListLoading() || ShopsListInitial() => const _LoadingView(),
              ShopsListError(:final message) => _ErrorView(
                message: message,
                onRetry: () => ref
                    .read(shopsListNotifierProvider.notifier)
                    .fetch(source: _selectedSource),
              ),
              ShopsListSuccess() =>
                filtered.isEmpty
                    ? const _EmptyView()
                    : _ShopsList(shops: filtered, animated: _animated),
            },
          ),
        ],
      ),

      // ── FAB: Create Shop ──────────────────────────────────────────────────
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.shopCreateMap),
        backgroundColor: _kGreen,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_location_alt_outlined),
        label: const Text(
          'Create Shop',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}

// ── Gradient header ───────────────────────────────────────────────────────────

/// Brand green→teal header: title + total-count pill + refresh, a search field,
/// and the role-matrix filter pills — all on the gradient, matching the
/// tasks/route/profile headers so the app reads as one family.
class _ShopsHeader extends StatelessWidget {
  final int total;
  final bool loading;
  final String? selectedSource;
  final List<(String, String)> chipDefs;
  final ValueChanged<String?> onChip;
  final ValueChanged<String> onSearch;
  final VoidCallback onRefresh;

  const _ShopsHeader({
    required this.total,
    required this.loading,
    required this.selectedSource,
    required this.chipDefs,
    required this.onChip,
    required this.onSearch,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final hPad = AppResponsive.horizontalPad(context);

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF134E40), Color(0xFF1B5E4F), Color(0xFF0D9488)],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            hPad,
            AppResponsive.vGap(context, 8),
            hPad,
            AppResponsive.vGap(context, 14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title row
              Row(
                children: [
                  Text(
                    'Shops',
                    style: TextStyle(
                      fontSize: AppResponsive.sp(context, 24),
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(width: AppResponsive.r(context, 10)),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppResponsive.r(context, 10),
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      '$total Total',
                      style: TextStyle(
                        fontSize: AppResponsive.sp(context, 12),
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.95),
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (loading)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  else
                    GestureDetector(
                      onTap: onRefresh,
                      child: const Icon(Icons.refresh, color: Colors.white),
                    ),
                ],
              ),
              SizedBox(height: AppResponsive.vGap(context, 12)),
              // Search field
              TextField(
                onChanged: onSearch,
                style: TextStyle(fontSize: AppResponsive.sp(context, 14)),
                decoration: InputDecoration(
                  hintText: 'Search shops...',
                  hintStyle: TextStyle(
                    color: const Color(0xFF9CA3AF),
                    fontSize: AppResponsive.sp(context, 14),
                  ),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: Color(0xFF9CA3AF),
                    size: 20,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              if (chipDefs.isNotEmpty) ...[
                SizedBox(height: AppResponsive.vGap(context, 10)),
                Wrap(
                  spacing: AppResponsive.r(context, 8),
                  runSpacing: AppResponsive.r(context, 8),
                  children: [
                    _FilterPill(
                      label: 'All',
                      selected: selectedSource == null,
                      onTap: () => onChip(null),
                    ),
                    ...chipDefs.map(
                      (entry) => _FilterPill(
                        label: entry.$1,
                        selected: selectedSource == entry.$2,
                        onTap: () => onChip(entry.$2),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Filter pill on the gradient header — explicit white/translucent colours so
/// it reads clearly on the gradient. AnimatedContainer gives a smooth select.
class _FilterPill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        padding: EdgeInsets.symmetric(
          horizontal: AppResponsive.r(context, 16),
          vertical: AppResponsive.r(context, 8),
        ),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.white.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: selected
                ? Colors.transparent
                : Colors.white.withValues(alpha: 0.4),
          ),
        ),
        child: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 220),
          style: TextStyle(
            fontSize: AppResponsive.sp(context, 13),
            fontWeight: FontWeight.w600,
            color: selected ? _kGreen : Colors.white,
          ),
          child: Text(label),
        ),
      ),
    );
  }
}

// ── Shops list ────────────────────────────────────────────────────────────────

class _ShopsList extends StatelessWidget {
  final List<ShopModel> shops;
  final Set<int> animated;

  const _ShopsList({required this.shops, required this.animated});

  @override
  Widget build(BuildContext context) {
    final hPad = AppResponsive.horizontalPad(context);
    return ListView.separated(
      padding: EdgeInsets.fromLTRB(
        hPad,
        AppResponsive.r(context, 16),
        hPad,
        AppResponsive.r(context, 100),
      ),
      itemCount: shops.length,
      separatorBuilder: (_, _) =>
          SizedBox(height: AppResponsive.r(context, 12)),
      itemBuilder: (_, i) => _ShopCard(
        shop: shops[i],
        index: i,
        alreadyAnimated: animated.contains(i),
        markAnimated: () => animated.add(i),
      ),
    );
  }
}

// ── Shop card ─────────────────────────────────────────────────────────────────

class _ShopCard extends StatefulWidget {
  final ShopModel shop;
  final int index;
  final bool alreadyAnimated;
  final VoidCallback markAnimated;

  const _ShopCard({
    required this.shop,
    required this.index,
    required this.alreadyAnimated,
    required this.markAnimated,
  });

  @override
  State<_ShopCard> createState() => _ShopCardState();
}

class _ShopCardState extends State<_ShopCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entry;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _entry = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _fade = CurvedAnimation(parent: _entry, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _entry, curve: Curves.easeOutCubic));

    if (widget.alreadyAnimated) {
      // Recycled card that already played its entrance — show it settled.
      _entry.value = 1.0;
    } else {
      final steps = widget.index.clamp(0, 12);
      Future.delayed(Duration(milliseconds: steps * 55), () {
        if (mounted) {
          _entry.forward();
          widget.markAnimated();
        }
      });
    }
  }

  @override
  void dispose() {
    _entry.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shop = widget.shop;
    final radius = BorderRadius.circular(18);

    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: GestureDetector(
          onTapDown: (_) => setState(() => _pressed = true),
          onTapUp: (_) {
            setState(() => _pressed = false);
            context.push(AppRoutes.shopDetailPath(shop.id));
          },
          onTapCancel: () => setState(() => _pressed = false),
          child: AnimatedScale(
            scale: _pressed ? 0.97 : 1.0,
            duration: const Duration(milliseconds: 120),
            curve: Curves.easeOut,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: radius,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: radius,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _CardBanner(shop: shop),
                    Padding(
                      padding: EdgeInsets.all(AppResponsive.r(context, 16)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  shop.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: AppResponsive.sp(context, 16),
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF111827),
                                  ),
                                ),
                              ),
                              SizedBox(width: AppResponsive.r(context, 8)),
                              GestureDetector(
                                onTap: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Edit shop — coming soon'),
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                },
                                child: Icon(
                                  Icons.edit_outlined,
                                  size: AppResponsive.r(context, 18),
                                  color: const Color(0xFF6B7280),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: AppResponsive.r(context, 8)),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.location_on_outlined,
                                size: AppResponsive.r(context, 15),
                                color: const Color(0xFF6B7280),
                              ),
                              const SizedBox(width: 5),
                              Expanded(
                                child: Text(
                                  shop.address,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: AppResponsive.sp(context, 12.5),
                                    color: const Color(0xFF6B7280),
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The top of a shop card: the shop photo when available, otherwise a branded
/// green banner with a storefront glyph — so every card has a consistent
/// header. The Active / Inactive badge floats top-right over either.
class _CardBanner extends StatelessWidget {
  final ShopModel shop;

  const _CardBanner({required this.shop});

  @override
  Widget build(BuildContext context) {
    final imageHeight = AppResponsive.r(context, 150);
    final bannerHeight = AppResponsive.r(context, 96);
    final hasImage = shop.shopImage != null && shop.shopImage!.isNotEmpty;

    return Stack(
      children: [
        if (hasImage)
          Image.network(
            shop.shopImage!,
            height: imageHeight,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => _placeholder(bannerHeight),
            loadingBuilder: (_, child, progress) {
              if (progress == null) return child;
              return Container(
                height: imageHeight,
                color: const Color(0xFFF3F4F6),
                child: const Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: _kGreen,
                  ),
                ),
              );
            },
          )
        else
          _placeholder(bannerHeight),

        // Active / Inactive badge — floats over the banner, top-right.
        Positioned(
          top: AppResponsive.r(context, 10),
          right: AppResponsive.r(context, 10),
          child: _StatusBadge(active: shop.isActive),
        ),
      ],
    );
  }

  Widget _placeholder(double height) {
    return Container(
      height: height,
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1B5E4F), Color(0xFF2D9B83)],
        ),
      ),
      child: const Center(
        child: Icon(Icons.storefront_outlined, color: Colors.white, size: 36),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final bool active;

  const _StatusBadge({required this.active});

  @override
  Widget build(BuildContext context) {
    final color = active ? _kGreen : const Color(0xFFDC2626);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppResponsive.r(context, 10),
        vertical: AppResponsive.r(context, 5),
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: AppResponsive.r(context, 7),
            height: AppResponsive.r(context, 7),
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          SizedBox(width: AppResponsive.r(context, 6)),
          Text(
            active ? 'Active' : 'Inactive',
            style: TextStyle(
              fontSize: AppResponsive.sp(context, 11),
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Loading ───────────────────────────────────────────────────────────────────

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    final hPad = AppResponsive.horizontalPad(context);
    return ListView.separated(
      padding: EdgeInsets.fromLTRB(
        hPad,
        AppResponsive.r(context, 16),
        hPad,
        AppResponsive.r(context, 16),
      ),
      itemCount: 6,
      separatorBuilder: (_, _) =>
          SizedBox(height: AppResponsive.r(context, 12)),
      itemBuilder: (_, _) => const _ShopSkeleton(),
    );
  }
}

class _ShopSkeleton extends StatefulWidget {
  const _ShopSkeleton();

  @override
  State<_ShopSkeleton> createState() => _ShopSkeletonState();
}

class _ShopSkeletonState extends State<_ShopSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
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
      builder: (_, _) {
        final shimmerColor = Color.lerp(
          const Color(0xFFE5E7EB),
          const Color(0xFFF3F4F6),
          _ctrl.value,
        )!;
        return Container(
          padding: EdgeInsets.all(AppResponsive.r(context, 16)),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: AppResponsive.r(context, 40),
                    height: AppResponsive.r(context, 40),
                    decoration: BoxDecoration(
                      color: shimmerColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  SizedBox(width: AppResponsive.r(context, 12)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: AppResponsive.r(context, 14),
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: shimmerColor,
                            borderRadius: BorderRadius.circular(7),
                          ),
                        ),
                        SizedBox(height: AppResponsive.r(context, 8)),
                        Container(
                          height: AppResponsive.r(context, 11),
                          width: AppResponsive.r(context, 140),
                          decoration: BoxDecoration(
                            color: shimmerColor,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: AppResponsive.r(context, 12)),
              Container(
                height: AppResponsive.r(context, 11),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: shimmerColor,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Error ─────────────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(AppResponsive.r(context, 32)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(AppResponsive.r(context, 20)),
              decoration: const BoxDecoration(
                color: Color(0xFFFEF2F2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline,
                size: AppResponsive.r(context, 40),
                color: const Color(0xFFDC2626),
              ),
            ),
            SizedBox(height: AppResponsive.r(context, 16)),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: AppResponsive.sp(context, 14),
                color: const Color(0xFF6B7280),
              ),
            ),
            SizedBox(height: AppResponsive.r(context, 20)),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _kGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Empty ─────────────────────────────────────────────────────────────────────

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(AppResponsive.r(context, 32)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(AppResponsive.r(context, 24)),
              decoration: const BoxDecoration(
                color: Color(0xFFF0FDF4),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.store_outlined,
                size: AppResponsive.r(context, 48),
                color: _kGreen,
              ),
            ),
            SizedBox(height: AppResponsive.r(context, 20)),
            Text(
              'No shops yet',
              style: TextStyle(
                fontSize: AppResponsive.sp(context, 18),
                fontWeight: FontWeight.bold,
                color: const Color(0xFF111827),
              ),
            ),
            SizedBox(height: AppResponsive.r(context, 8)),
            Text(
              'Shops you create via geofencing\nwill appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: AppResponsive.sp(context, 14),
                color: const Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
