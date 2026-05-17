import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:go_router/go_router.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_responsive.dart';
import 'components/create_geofence_form.dart';
import 'components/schedule_list.dart';

const _geofenceRadius = 50.0; // metres

class RouteScreen extends StatefulWidget {
  const RouteScreen({super.key});

  @override
  State<RouteScreen> createState() => _RouteScreenState();
}

class _RouteScreenState extends State<RouteScreen> {
  MapboxMap? _mapboxMap;
  bool _isLocating = false;
  geo.Position? _lastPosition; // cached so fullscreen reuses it

  // Geofence state
  Position? _geofenceCenter;
  bool _geofenceActive = false;
  bool _isInsideGeofence = false;
  StreamSubscription<geo.Position>? _positionStream;
  PolygonAnnotationManager? _polygonManager;
  PolygonAnnotation? _geofencePolygon;

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }

  // ── Map setup ─────────────────────────────────────────────────────────────

  void _onMapCreated(MapboxMap mapboxMap) {
    _mapboxMap = mapboxMap;
    _initMap();
  }

  Future<void> _initMap() async {
    final status = await Permission.locationWhenInUse.request();
    if (!status.isGranted) return;

    await _mapboxMap?.location.updateSettings(
      LocationComponentSettings(enabled: true, pulsingEnabled: true),
    );

    // Fix 1: auto-fly to real location on map load
    await _autoGoToLocation();
  }

  /// Fix 2: fetches GPS and flies the camera, showing a loading bar while waiting
  Future<void> _autoGoToLocation() async {
    if (!mounted) return;
    setState(() => _isLocating = true);

    try {
      final pos = await geo.Geolocator.getCurrentPosition(
        locationSettings: const geo.LocationSettings(
          accuracy: geo.LocationAccuracy.high,
        ),
      );
      _lastPosition = pos; // cache for fullscreen reuse
      if (mounted) {
        await _mapboxMap?.flyTo(
          CameraOptions(
            center: Point(coordinates: Position(pos.longitude, pos.latitude)),
            zoom: 15.0,
          ),
          MapAnimationOptions(duration: 1200),
        );
      }
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  Future<void> _goToMyLocation() async {
    final status = await Permission.locationWhenInUse.status;
    if (!status.isGranted) {
      final newStatus = await Permission.locationWhenInUse.request();
      if (!newStatus.isGranted) return;
      await _mapboxMap?.location.updateSettings(
        LocationComponentSettings(enabled: true, pulsingEnabled: true),
      );
    }
    await _autoGoToLocation();
  }

  // ── Geofence ──────────────────────────────────────────────────────────────

  Future<void> _setGeofence() async {
    final status = await Permission.locationWhenInUse.status;
    if (!status.isGranted) return;

    // Fetch GPS first so the form can show it auto-filled
    final pos = await geo.Geolocator.getCurrentPosition(
      locationSettings: const geo.LocationSettings(
        accuracy: geo.LocationAccuracy.high,
      ),
    );
    _lastPosition = pos;

    if (!mounted) return;

    // Show the form — returns true only when API call succeeds
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CreateGeofenceForm(
        latitude: pos.latitude,
        longitude: pos.longitude,
      ),
    );

    if (confirmed != true) return;

    // Form submitted successfully — now create the geofence on the map
    final center = Position(pos.longitude, pos.latitude);
    await _drawGeofenceCircle(center);
    await _mapboxMap?.flyTo(
      CameraOptions(
        center: Point(coordinates: center),
        zoom: 17.0,
      ),
      MapAnimationOptions(duration: 1000),
    );

    setState(() {
      _geofenceCenter = center;
      _geofenceActive = true;
      _isInsideGeofence = true;
    });

    _startPositionStream();
  }

  Future<void> _clearGeofence() async {
    _positionStream?.cancel();
    _positionStream = null;

    if (_polygonManager != null && _geofencePolygon != null) {
      await _polygonManager!.delete(_geofencePolygon!);
      _geofencePolygon = null;
    }

    setState(() {
      _geofenceCenter = null;
      _geofenceActive = false;
      _isInsideGeofence = false;
    });
  }

  Future<void> _drawGeofenceCircle(Position center) async {
    if (_polygonManager != null && _geofencePolygon != null) {
      await _polygonManager!.delete(_geofencePolygon!);
    }
    _polygonManager ??=
        await _mapboxMap!.annotations.createPolygonAnnotationManager();

    _geofencePolygon = await _polygonManager!.create(
      PolygonAnnotationOptions(
        geometry: Polygon(coordinates: [_circlePoints(center, _geofenceRadius)]),
        fillColor: const Color(0xFF157347).toARGB32(),
        fillOpacity: 0.15,
        fillOutlineColor: const Color(0xFF157347).toARGB32(),
      ),
    );
  }

  void _startPositionStream() {
    _positionStream = geo.Geolocator.getPositionStream(
      locationSettings: const geo.LocationSettings(
        accuracy: geo.LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen(_onPositionUpdate);
  }

  void _onPositionUpdate(geo.Position current) {
    if (_geofenceCenter == null) return;

    final distance = geo.Geolocator.distanceBetween(
      current.latitude,
      current.longitude,
      _geofenceCenter!.lat.toDouble(),
      _geofenceCenter!.lng.toDouble(),
    );

    final nowInside = distance <= _geofenceRadius;

    if (nowInside && !_isInsideGeofence) {
      setState(() => _isInsideGeofence = true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(children: [
              Icon(Icons.location_on, color: Colors.white),
              SizedBox(width: 8),
              Text('You entered the geofence area!',
                  style: TextStyle(fontWeight: FontWeight.w600)),
            ]),
            backgroundColor: Color(0xFF157347),
            duration: Duration(seconds: 4),
          ),
        );
      }
    } else if (!nowInside && _isInsideGeofence) {
      setState(() => _isInsideGeofence = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(children: [
              Icon(Icons.location_off, color: Colors.white),
              SizedBox(width: 8),
              Text('You left the geofence area.',
                  style: TextStyle(fontWeight: FontWeight.w600)),
            ]),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 4),
          ),
        );
      }
    }
  }

  List<Position> _circlePoints(Position center, double radiusMeters) {
    const earthRadius = 6371000.0;
    final lat = center.lat.toDouble() * math.pi / 180;
    final lng = center.lng.toDouble() * math.pi / 180;
    final d = radiusMeters / earthRadius;
    const n = 64;
    return List.generate(n + 1, (i) {
      final bearing = (2 * math.pi * i) / n;
      final pLat = math.asin(math.sin(lat) * math.cos(d) +
          math.cos(lat) * math.sin(d) * math.cos(bearing));
      final pLng = lng +
          math.atan2(math.sin(bearing) * math.sin(d) * math.cos(lat),
              math.cos(d) - math.sin(lat) * math.sin(pLat));
      return Position(pLng * 180 / math.pi, pLat * 180 / math.pi);
    });
  }

  // ── UI ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final hPad = AppResponsive.horizontalPad(context);
    final mapHeight = AppResponsive.hp(context, 30).clamp(180.0, 280.0);

    return Scaffold(
      backgroundColor: const Color(0xFFFAF8F3),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          "Today's Route",
          style: TextStyle(
            color: const Color(0xFF157347),
            fontWeight: FontWeight.bold,
            fontSize: AppResponsive.sp(context, 20),
          ),
        ),
        centerTitle: true,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16, top: 10, bottom: 10),
            padding: EdgeInsets.symmetric(
                horizontal: AppResponsive.r(context, 14), vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFD1FADF),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Text('8 Shops',
                  style: TextStyle(
                    color: const Color(0xFF157347),
                    fontWeight: FontWeight.bold,
                    fontSize: AppResponsive.sp(context, 14),
                  )),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ── Map area ──────────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: mapHeight + 24,
              child: Stack(
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(hPad, 24, hPad, 0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: SizedBox(
                        width: double.infinity,
                        height: mapHeight,
                        child: Stack(
                          children: [
                            MapWidget(
                              key: const ValueKey('routeMap'),
                              styleUri: MapboxStyles.STANDARD,
                              onMapCreated: _onMapCreated,
                            ),
                            // Fix 2: thin loading bar at top of map (Google Maps style)
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
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Geofence status chip — top left
                  if (_geofenceActive)
                    Positioned(
                      top: 32,
                      left: hPad + 8,
                      child: _StatusChip(inside: _isInsideGeofence),
                    ),

                  // Fullscreen button — top right
                  Positioned(
                    top: 32,
                    right: hPad + 8,
                    child: _MapIconButton(
                      icon: Icons.fullscreen,
                      onTap: () => context.push(
                        AppRoutes.mapFullscreen,
                        extra: {
                          'lat': _lastPosition?.latitude,
                          'lng': _lastPosition?.longitude,
                        },
                      ),
                    ),
                  ),

                  // Geofence toggle — bottom left
                  Positioned(
                    bottom: 8,
                    left: hPad + 8,
                    child: _MapIconButton(
                      icon: _geofenceActive
                          ? Icons.fence
                          : Icons.fence_outlined,
                      color: _geofenceActive
                          ? const Color(0xFF157347)
                          : const Color(0xFF6B7280),
                      onTap: _geofenceActive ? _clearGeofence : _setGeofence,
                    ),
                  ),

                  // My location — bottom right
                  Positioned(
                    bottom: 8,
                    right: hPad + 8,
                    child: _MapIconButton(
                      icon: Icons.my_location,
                      onTap: _goToMyLocation,
                    ),
                  ),
                ],
              ),
            ),

            // ── Next Stop Card ────────────────────────────────────────────
            Container(
              margin: EdgeInsets.symmetric(horizontal: hPad, vertical: 16),
              padding: EdgeInsets.all(AppResponsive.r(context, 20)),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Center(
                    child: SizedBox(
                      width: 40,
                      child: Divider(thickness: 3, color: Color(0xFFE5E7EB)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text('NEXT STOP',
                      style: TextStyle(
                        color: const Color(0xFF6B7280),
                        fontWeight: FontWeight.w600,
                        fontSize: AppResponsive.sp(context, 12),
                      )),
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Starlight Convenience',
                                style: TextStyle(
                                  fontSize: AppResponsive.sp(context, 20),
                                  fontWeight: FontWeight.bold,
                                )),
                            const SizedBox(height: 4),
                            Text('4200 Broadway St, New York',
                                style: TextStyle(
                                  fontSize: AppResponsive.sp(context, 14),
                                  color: const Color(0xFF6B7280),
                                )),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: AppResponsive.r(context, 10),
                          vertical: AppResponsive.r(context, 6),
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD1FADF),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.directions_car,
                                size: AppResponsive.r(context, 16),
                                color: const Color(0xFF157347)),
                            const SizedBox(width: 4),
                            Text('2.3 km · ~8 min',
                                style: TextStyle(
                                  color: const Color(0xFF157347),
                                  fontWeight: FontWeight.w600,
                                  fontSize: AppResponsive.sp(context, 12),
                                )),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: AppResponsive.r(context, 18)),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF157347),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                            padding: EdgeInsets.symmetric(
                                vertical: AppResponsive.r(context, 14)),
                          ),
                          onPressed: () {},
                          icon: const Icon(Icons.navigation, color: Colors.white),
                          label: Text('Navigate',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: AppResponsive.sp(context, 15),
                              )),
                        ),
                      ),
                      SizedBox(width: AppResponsive.r(context, 16)),
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFF157347)),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                            padding: EdgeInsets.symmetric(
                                vertical: AppResponsive.r(context, 14)),
                          ),
                          onPressed: () {},
                          icon: const Icon(Icons.phone,
                              color: Color(0xFF157347)),
                          label: Text('Call Shop',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: AppResponsive.sp(context, 15),
                                color: const Color(0xFF157347),
                              )),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            Padding(
              padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text("Today's Schedule",
                    style: TextStyle(
                      fontSize: AppResponsive.sp(context, 18),
                      fontWeight: FontWeight.w600,
                    )),
              ),
            ),
            const ScheduleList(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// ── Shared widgets ────────────────────────────────────────────────────────────

class _MapIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color color;

  const _MapIconButton({
    required this.icon,
    required this.onTap,
    this.color = const Color(0xFF157347),
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final bool inside;
  const _StatusChip({required this.inside});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: inside ? const Color(0xFF157347) : Colors.orange,
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
          const Icon(Icons.circle, size: 8, color: Colors.white),
          const SizedBox(width: 5),
          Text(
            inside ? 'Inside' : 'Outside',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
