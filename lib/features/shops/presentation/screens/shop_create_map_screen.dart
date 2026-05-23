import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:go_router/go_router.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' hide Size;
import 'package:permission_handler/permission_handler.dart';
import 'package:dio/dio.dart';

import '../../../presentation/screens/route_screen/components/create_geofence_form.dart';
import '../providers/shop_provider.dart';

class ShopCreateMapScreen extends ConsumerStatefulWidget {
  const ShopCreateMapScreen({super.key});

  @override
  ConsumerState<ShopCreateMapScreen> createState() =>
      _ShopCreateMapScreenState();
}

class _ShopCreateMapScreenState extends ConsumerState<ShopCreateMapScreen> {
  MapboxMap? _mapboxMap;
  bool _isLocating = false;
  StreamSubscription<geo.Position>? _positionStream;

  // ── Map setup ──────────────────────────────────────────────────────────────

  void _onMapCreated(MapboxMap map) {
    _mapboxMap = map;
    _initMap();
  }

  Future<void> _initMap() async {
    final status = await Permission.locationWhenInUse.request();
    if (!status.isGranted) return;

    await _mapboxMap?.location.updateSettings(
      LocationComponentSettings(enabled: true, pulsingEnabled: true),
    );

    await _flyToCurrentPosition();

    // Keep position stream running so the blue dot stays live.
    _positionStream = geo.Geolocator.getPositionStream(
      locationSettings: const geo.LocationSettings(
        accuracy: geo.LocationAccuracy.high,
        distanceFilter: 5,
      ),
    ).listen((_) {});
  }

  Future<void> _flyToCurrentPosition() async {
    if (!mounted) return;
    setState(() => _isLocating = true);
    try {
      final pos = await geo.Geolocator.getCurrentPosition(
        locationSettings: const geo.LocationSettings(
          accuracy: geo.LocationAccuracy.high,
        ),
      );
      await _mapboxMap?.flyTo(
        CameraOptions(
          center: Point(coordinates: Position(pos.longitude, pos.latitude)),
          zoom: 17.0,
          pitch: 0,
        ),
        MapAnimationOptions(duration: 1200),
      );
    } catch (_) {
      // Silently ignore; user can tap my-location manually.
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  // ── Reverse geocode ────────────────────────────────────────────────────────

  Future<String?> _reverseGeocode(double lat, double lng) async {
    try {
      final token = dotenv.env['MAPBOX_PUBLIC_TOKEN'];
      if (token == null || token.isEmpty) return null;
      final dio = Dio();
      final url =
          'https://api.mapbox.com/geocoding/v5/mapbox.places/$lng,$lat.json';
      final response = await dio.get<Map<String, dynamic>>(
        url,
        queryParameters: {'access_token': token, 'limit': 1},
      );
      final features =
          (response.data?['features'] as List?)?.cast<Map<String, dynamic>>();
      if (features == null || features.isEmpty) return null;
      return features.first['place_name'] as String?;
    } catch (_) {
      return null;
    }
  }

  // ── Create shop flow ───────────────────────────────────────────────────────

  Future<void> _onCreateShopHere() async {
    final status = await Permission.locationWhenInUse.status;
    if (!status.isGranted) return;

    if (!mounted) return;
    setState(() => _isLocating = true);

    late geo.Position pos;
    String? address;
    try {
      pos = await geo.Geolocator.getCurrentPosition(
        locationSettings: const geo.LocationSettings(
          accuracy: geo.LocationAccuracy.high,
        ),
      );
      address = await _reverseGeocode(pos.latitude, pos.longitude);
    } catch (_) {
      if (mounted) setState(() => _isLocating = false);
      return;
    }

    if (!mounted) return;
    setState(() => _isLocating = false);

    // Reset notifier so previous errors are cleared.
    ref.read(shopNotifierProvider.notifier).reset();

    final success = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CreateGeofenceForm(
        latitude: pos.latitude,
        longitude: pos.longitude,
        initialAddress: address,
      ),
    );

    if (success == true && mounted) {
      // Pop back to shops list, which will auto-refresh.
      context.pop();
    }
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }

  // ── UI ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Map
          MapWidget(
            key: const ValueKey('shopCreateMap'),
            styleUri: MapboxStyles.STANDARD,
            onMapCreated: _onMapCreated,
          ),

          // Loading bar
          if (_isLocating)
            const Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: LinearProgressIndicator(
                minHeight: 3,
                color: Color(0xFF157347),
                backgroundColor: Color(0xFFD1FADF),
              ),
            ),

          // Back button — top left
          Positioned(
            top: 48,
            left: 16,
            child: _CircleButton(
              icon: Icons.arrow_back,
              onTap: () => context.pop(),
            ),
          ),

          // Instruction banner — top centre
          Positioned(
            top: 48,
            left: 72,
            right: 16,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Text(
                'Stand at the shop, then tap Create Shop Here',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF111827),
                ),
              ),
            ),
          ),

          // My-location button — bottom right
          Positioned(
            bottom: 110,
            right: 16,
            child: _CircleButton(
              icon: Icons.my_location,
              onTap: _flyToCurrentPosition,
            ),
          ),

          // "Create Shop Here" primary action button — bottom full-width
          Positioned(
            left: 16,
            right: 16,
            bottom: 32,
            child: SizedBox(
              height: 56,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF157347),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 4,
                ),
                onPressed: _isLocating ? null : _onCreateShopHere,
                icon: const Icon(Icons.add_location_alt_outlined, size: 22),
                label: const Text(
                  'Create Shop Here',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shared helpers ─────────────────────────────────────────────────────────────

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CircleButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Icon(icon, color: const Color(0xFF374151), size: 22),
      ),
    );
  }
}
