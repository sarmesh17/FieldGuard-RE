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
  bool _isConfirming = false;

  // Pin state — updated when camera settles after panning
  double? _pinLat;
  double? _pinLng;
  String? _pinAddress;
  bool _cameraMoving = false;
  Timer? _geocodeDebounce;

  // ── Map setup ──────────────────────────────────────────────────────────────

  void _onMapCreated(MapboxMap map) {
    _mapboxMap = map;
    _initMap();
  }

  Future<void> _initMap() async {
    final status = await Permission.locationWhenInUse.request();
    if (!status.isGranted || !mounted) return;

    await _mapboxMap?.location.updateSettings(
      LocationComponentSettings(enabled: true, pulsingEnabled: true),
    );

    await _flyToCurrentPosition();
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
      // User can pan manually.
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  // Called ~600 ms after the camera stops moving — reads center + geocodes.
  Future<void> _onCameraSettled() async {
    if (!mounted || _mapboxMap == null) return;
    try {
      final camera = await _mapboxMap!.getCameraState();
      final lat = camera.center.coordinates.lat.toDouble();
      final lng = camera.center.coordinates.lng.toDouble();
      final address = await _reverseGeocode(lat, lng);
      if (!mounted) return;
      setState(() {
        _pinLat = lat;
        _pinLng = lng;
        _pinAddress = address;
        _cameraMoving = false;
      });
    } catch (_) {
      if (mounted) setState(() => _cameraMoving = false);
    }
  }

  // ── Reverse geocode ────────────────────────────────────────────────────────

  Future<String?> _reverseGeocode(double lat, double lng) async {
    try {
      final token = dotenv.env['MAPBOX_PUBLIC_TOKEN'];
      if (token == null || token.isEmpty) return null;
      final url =
          'https://api.mapbox.com/geocoding/v5/mapbox.places/$lng,$lat.json';
      final response = await Dio().get<Map<String, dynamic>>(
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

  // ── Confirm pin and open form ──────────────────────────────────────────────

  Future<void> _onConfirmPin() async {
    if (_mapboxMap == null) return;
    setState(() => _isConfirming = true);

    double lat;
    double lng;
    String? address;

    try {
      // Always read fresh camera centre in case geocode debounce hasn't fired.
      final camera = await _mapboxMap!.getCameraState();
      lat = camera.center.coordinates.lat.toDouble();
      lng = camera.center.coordinates.lng.toDouble();
      // Reuse cached address if pin hasn't moved since last settle.
      address = (_cameraMoving || _pinLat != lat || _pinLng != lng)
          ? await _reverseGeocode(lat, lng)
          : _pinAddress;
    } catch (_) {
      if (mounted) setState(() => _isConfirming = false);
      return;
    }

    if (!mounted) return;
    setState(() => _isConfirming = false);

    ref.read(shopNotifierProvider.notifier).reset();

    final success = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CreateGeofenceForm(
        latitude: lat,
        longitude: lng,
        initialAddress: address,
      ),
    );

    if (success == true && mounted) context.pop();
  }

  @override
  void dispose() {
    _geocodeDebounce?.cancel();
    super.dispose();
  }

  // ── UI ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final busy = _isLocating || _isConfirming;

    return Scaffold(
      body: Stack(
        children: [
          // ── Map ────────────────────────────────────────────────────────────
          MapWidget(
            key: const ValueKey('shopCreateMap'),
            styleUri: MapboxStyles.STANDARD,
            onMapCreated: _onMapCreated,
          ),

          // ── Loading bar ────────────────────────────────────────────────────
          if (busy)
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

          // ── Touch observer ────────────────────────────────────────────────
          // Fires only on finger-down / finger-up (NOT on every pan frame),
          // so setState is called at most twice per gesture instead of
          // hundreds of times. HitTestBehavior.translucent means it never
          // consumes events — the map underneath still handles all panning.
          Positioned.fill(
            child: Listener(
              behavior: HitTestBehavior.translucent,
              onPointerDown: (_) {
                if (!mounted) return;
                _geocodeDebounce?.cancel();
                if (!_cameraMoving) setState(() => _cameraMoving = true);
              },
              onPointerUp: (_) {
                _geocodeDebounce?.cancel();
                _geocodeDebounce = Timer(
                  const Duration(milliseconds: 400),
                  _onCameraSettled,
                );
              },
              onPointerCancel: (_) {
                _geocodeDebounce?.cancel();
                _geocodeDebounce = Timer(
                  const Duration(milliseconds: 400),
                  _onCameraSettled,
                );
              },
            ),
          ),

          // ── Pin + chip overlay ─────────────────────────────────────────────
          // Positioned.fill so this layer never participates in the outer
          // Stack's layout — no reflow, no map jitter when state changes.
          Positioned.fill(
            child: IgnorePointer(
              child: Stack(
                children: [
                  // Shadow dot — stays at exact map centre
                  Align(
                    alignment: Alignment.center,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOut,
                      width: _cameraMoving ? 14 : 8,
                      height: _cameraMoving ? 6 : 3,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(
                          alpha: _cameraMoving ? 0.15 : 0.4,
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  // Pin icon — transform (not margin) so layout is never
                  // affected. Translate -24 puts the icon tip at map centre
                  // (tip = icon bottom = centre + 24px for a 48px icon).
                  // Lifts an extra 10px while moving.
                  Align(
                    alignment: Alignment.center,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOut,
                      transform: Matrix4.translationValues(
                        0,
                        _cameraMoving ? -34 : -24,
                        0,
                      ),
                      child: Icon(
                        Icons.location_pin,
                        size: 48,
                        color: const Color(0xFF157347),
                        shadows: [
                          Shadow(
                            color: Colors.black.withValues(
                              alpha: _cameraMoving ? 0.3 : 0.15,
                            ),
                            blurRadius: _cameraMoving ? 14 : 4,
                            offset: Offset(0, _cameraMoving ? 8 : 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Coord chip — fades in/out via opacity, never added or
                  // removed from the tree, so no layout shift occurs.
                  Align(
                    alignment: Alignment.center,
                    child: Transform.translate(
                      offset: const Offset(0, 36),
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 200),
                        opacity:
                            (_pinLat != null && !_cameraMoving) ? 1.0 : 0.0,
                        child: _CoordChip(
                          lat: _pinLat ?? 0,
                          lng: _pinLng ?? 0,
                          address: _pinAddress,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Back button ────────────────────────────────────────────────────
          Positioned(
            top: 48,
            left: 16,
            child: _CircleButton(
              icon: Icons.arrow_back,
              onTap: () => context.pop(),
            ),
          ),

          // ── Instruction banner ─────────────────────────────────────────────
          Positioned(
            top: 48,
            left: 72,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
              child: const Row(
                children: [
                  Icon(Icons.touch_app_outlined,
                      size: 16, color: Color(0xFF157347)),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Pan the map to the shop, then tap Pin Shop Here',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF111827),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── My-location button ─────────────────────────────────────────────
          Positioned(
            bottom: 110,
            right: 16,
            child: _CircleButton(
              icon: Icons.my_location,
              onTap: busy ? () {} : _flyToCurrentPosition,
            ),
          ),

          // ── "Pin Shop Here" button ─────────────────────────────────────────
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
                  disabledBackgroundColor:
                      const Color(0xFF157347).withValues(alpha: 0.6),
                  disabledForegroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 4,
                ),
                onPressed: busy ? null : _onConfirmPin,
                icon: busy
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.push_pin_outlined, size: 22),
                label: Text(
                  busy ? 'Locating…' : 'Pin Shop Here',
                  style: const TextStyle(
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

// ── Coordinate chip ────────────────────────────────────────────────────────────

class _CoordChip extends StatelessWidget {
  final double lat;
  final double lng;
  final String? address;

  const _CoordChip({
    required this.lat,
    required this.lng,
    this.address,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 280),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.place, size: 13, color: Color(0xFF157347)),
              const SizedBox(width: 5),
              Text(
                '${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF157347),
                ),
              ),
            ],
          ),
          if (address != null && address!.isNotEmpty) ...[
            const SizedBox(height: 3),
            Text(
              address!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF6B7280),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Circle icon button ─────────────────────────────────────────────────────────

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
