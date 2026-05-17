import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'components/create_geofence_form.dart';

const _geofenceRadiusFullscreen = 50.0; // metres

class MapFullscreenScreen extends StatefulWidget {
  final double? initialLat;
  final double? initialLng;

  const MapFullscreenScreen({super.key, this.initialLat, this.initialLng});

  @override
  State<MapFullscreenScreen> createState() => _MapFullscreenScreenState();
}

class _MapFullscreenScreenState extends State<MapFullscreenScreen> {
  MapboxMap? _mapboxMap;
  bool _isLocating = false;

  // Geofence state
  Position? _geofenceCenter;
  bool _geofenceActive = false;
  bool _isInsideGeofence = false;
  StreamSubscription<geo.Position>? _positionStream;
  PolygonAnnotationManager? _polygonManager;
  PolygonAnnotation? _geofencePolygon;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
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

    final lat = widget.initialLat;
    final lng = widget.initialLng;

    if (lat != null && lng != null) {
      // Reuse the position already fetched by the route screen — no GPS call
      await _mapboxMap?.setCamera(
        CameraOptions(
          center: Point(coordinates: Position(lng, lat)),
          zoom: 15.0,
        ),
      );
    } else {
      // Fallback: fetch location only if none was passed in
      await _autoGoToLocation();
    }
  }

  Future<void> _autoGoToLocation() async {
    if (!mounted) return;
    setState(() => _isLocating = true);

    try {
      final pos = await geo.Geolocator.getCurrentPosition(
        locationSettings: const geo.LocationSettings(
          accuracy: geo.LocationAccuracy.high,
        ),
      );
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

    final pos = await geo.Geolocator.getCurrentPosition(
      locationSettings: const geo.LocationSettings(
        accuracy: geo.LocationAccuracy.high,
      ),
    );

    if (!mounted) return;

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
        geometry: Polygon(
          coordinates: [_circlePoints(center, _geofenceRadiusFullscreen)],
        ),
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

    final nowInside = distance <= _geofenceRadiusFullscreen;

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
    return Scaffold(
      body: Stack(
        children: [
          // Full screen map
          MapWidget(
            key: const ValueKey('fullscreenMap'),
            styleUri: MapboxStyles.STANDARD,
            onMapCreated: _onMapCreated,
          ),

          // Fix 2: thin loading bar at very top
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
          const Positioned(top: 48, left: 16, child: _BackButton()),

          // Geofence status chip — top centre
          if (_geofenceActive)
            Positioned(
              top: 52,
              left: 0,
              right: 0,
              child: Center(child: _StatusChip(inside: _isInsideGeofence)),
            ),

          // Geofence toggle — bottom left
          Positioned(
            bottom: 48,
            left: 16,
            child: _MapIconButton(
              icon: _geofenceActive ? Icons.fence : Icons.fence_outlined,
              color: _geofenceActive
                  ? const Color(0xFF157347)
                  : const Color(0xFF6B7280),
              onTap: _geofenceActive ? _clearGeofence : _setGeofence,
            ),
          ),

          // My location — bottom right
          Positioned(
            bottom: 48,
            right: 16,
            child: _MapIconButton(
              icon: Icons.my_location,
              onTap: _goToMyLocation,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shared widgets ────────────────────────────────────────────────────────────

class _BackButton extends StatelessWidget {
  const _BackButton();

  @override
  Widget build(BuildContext context) {
    return _MapIconButton(
      icon: Icons.arrow_back,
      onTap: () => Navigator.of(context).pop(),
    );
  }
}

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
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, color: color, size: 22),
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: inside ? const Color(0xFF157347) : Colors.orange,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.circle, size: 8, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            inside ? 'Inside Geofence' : 'Outside Geofence',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
