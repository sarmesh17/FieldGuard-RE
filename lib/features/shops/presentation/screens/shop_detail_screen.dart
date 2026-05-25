import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:field_guard_re/features/shops/data/models/shop_detail.dart';
import 'package:field_guard_re/features/shops/presentation/providers/shop_provider.dart';

/// Full shop details from `GET /api/v1/shops/{id}` — image, contact, PAN,
/// coordinates, creator and the people the shop is visible to.
class ShopDetailScreen extends ConsumerWidget {
  final int shopId;

  const ShopDetailScreen({super.key, required this.shopId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(shopDetailProvider(shopId));

    return Scaffold(
      backgroundColor: const Color(0xFFF5F3EF),
      appBar: AppBar(
        backgroundColor: const Color(0xFF157347),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Shop Detail',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(shopDetailProvider(shopId)),
          ),
        ],
      ),
      body: state.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFF157347)),
        ),
        error: (e, _) => _ErrorView(
          message: e.toString(),
          onRetry: () => ref.invalidate(shopDetailProvider(shopId)),
        ),
        data: (shop) => _DetailBody(shop: shop),
      ),
    );
  }
}

// ── Body ────────────────────────────────────────────────────────────────────

class _DetailBody extends StatelessWidget {
  final ShopDetail shop;

  const _DetailBody({required this.shop});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Hero card ────────────────────────────────────────────────────
          _Card(
            padding: EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (shop.shopImage != null && shop.shopImage!.isNotEmpty)
                  ClipRRect(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(16)),
                    child: Image.network(
                      shop.shopImage!,
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => _imageFallback(),
                      loadingBuilder: (_, child, progress) {
                        if (progress == null) return child;
                        return Container(
                          height: 180,
                          color: const Color(0xFFF3F4F6),
                          child: const Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFF157347),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              shop.name,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF111827),
                              ),
                            ),
                          ),
                          _Badge(
                            label: shop.isActive ? 'Active' : 'Inactive',
                            color: shop.isActive
                                ? const Color(0xFFDCFCE7)
                                : const Color(0xFFFEF2F2),
                            textColor: shop.isActive
                                ? const Color(0xFF157347)
                                : const Color(0xFFDC2626),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.location_on_outlined,
                              size: 16, color: Color(0xFF6B7280)),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              shop.address,
                              style: const TextStyle(
                                fontSize: 13.5,
                                color: Color(0xFF6B7280),
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

          const SizedBox(height: 12),

          // ── Contact ──────────────────────────────────────────────────────
          _SectionHeader(label: 'Contact', icon: Icons.person_outline),
          _Card(
            child: Column(
              children: [
                _InfoRow(
                  icon: Icons.badge_outlined,
                  label: 'Name',
                  value: shop.contactName.isEmpty ? '—' : shop.contactName,
                ),
                const _Divider(),
                _InfoRow(
                  icon: Icons.phone_outlined,
                  label: 'Phone',
                  value: shop.contactPhone.isEmpty ? '—' : shop.contactPhone,
                ),
                const _Divider(),
                _InfoRow(
                  icon: Icons.credit_card_outlined,
                  label: 'PAN Number',
                  value: (shop.panNumber == null || shop.panNumber!.isEmpty)
                      ? '—'
                      : shop.panNumber!,
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // ── Location ─────────────────────────────────────────────────────
          _SectionHeader(label: 'Location', icon: Icons.map_outlined),
          _Card(
            child: _InfoRow(
              icon: Icons.my_location,
              label: 'Coordinates',
              value:
                  '${shop.latitude.toStringAsFixed(6)}, ${shop.longitude.toStringAsFixed(6)}',
            ),
          ),

          const SizedBox(height: 12),

          // ── Timeline ─────────────────────────────────────────────────────
          _SectionHeader(label: 'Timeline', icon: Icons.schedule_outlined),
          _Card(
            child: Column(
              children: [
                _InfoRow(
                  icon: Icons.access_time_outlined,
                  label: 'Created',
                  value: shop.createdAt != null
                      ? DateFormat('d MMM yyyy, hh:mm a')
                          .format(shop.createdAt!.toLocal())
                      : '—',
                ),
                if (shop.updatedAt != null) ...[
                  const _Divider(),
                  _InfoRow(
                    icon: Icons.update_outlined,
                    label: 'Updated',
                    value: DateFormat('d MMM yyyy, hh:mm a')
                        .format(shop.updatedAt!.toLocal()),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 12),

          // ── Creator ──────────────────────────────────────────────────────
          if (shop.creator != null) ...[
            _SectionHeader(
                label: 'Created By', icon: Icons.verified_user_outlined),
            _Card(child: _PersonTile(person: shop.creator!)),
            const SizedBox(height: 12),
          ],

          // ── Visible to ───────────────────────────────────────────────────
          _SectionHeader(
            label: 'Visible To (${shop.visibleTo.length})',
            icon: Icons.people_outline,
          ),
          _Card(
            child: shop.visibleTo.isEmpty
                ? const Text(
                    'Not shared with anyone',
                    style: TextStyle(fontSize: 14, color: Color(0xFF9CA3AF)),
                  )
                : Column(
                    children: [
                      for (var i = 0; i < shop.visibleTo.length; i++) ...[
                        if (i > 0) const _Divider(),
                        _PersonTile(person: shop.visibleTo[i]),
                      ],
                    ],
                  ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  static Widget _imageFallback() => Container(
        height: 180,
        color: const Color(0xFFECFDF5),
        child: const Center(
          child: Icon(Icons.storefront_outlined,
              size: 40, color: Color(0xFF157347)),
        ),
      );
}

// ── Reusable widgets ──────────────────────────────────────────────────────────

class _PersonTile extends StatelessWidget {
  final ShopPerson person;

  const _PersonTile({required this.person});

  @override
  Widget build(BuildContext context) {
    final img = person.profileImage;
    final hasImg = img != null && img.isNotEmpty;
    return Row(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: const Color(0xFFDCFCE7),
          backgroundImage: hasImg ? NetworkImage(img) : null,
          child: hasImg
              ? null
              : Text(
                  _initials(person.fullName),
                  style: const TextStyle(
                    color: Color(0xFF157347),
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                person.fullName.isEmpty ? '—' : person.fullName,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                [person.role, person.employeeCode]
                    .where((e) => e != null && e.isNotEmpty)
                    .join(' · '),
                style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static String _initials(String name) {
    final parts = name.trim().split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;

  const _Card({required this.child, this.padding = const EdgeInsets.all(16)});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  final IconData icon;

  const _SectionHeader({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: const Color(0xFF157347)),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF157347),
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF9CA3AF)),
        const SizedBox(width: 10),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  value,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111827),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.symmetric(vertical: 10),
        child: Divider(height: 1, color: Color(0xFFF3F4F6)),
      );
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  final Color textColor;

  const _Badge({
    required this.label,
    required this.color,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFFFEF2F2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.error_outline,
                  size: 40, color: Color(0xFFDC2626)),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF157347),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
