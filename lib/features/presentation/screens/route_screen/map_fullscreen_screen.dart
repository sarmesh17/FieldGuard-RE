import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' hide Size;
import 'package:permission_handler/permission_handler.dart';

import '../../../../core/services/mapbox_directions_service.dart';
import '../../../tasks/data/models/task_model.dart';
import '../../../tasks/presentation/providers/tasks_provider.dart';
import 'components/create_geofence_form.dart';
import 'components/task_nav_overlay_controller.dart';

const _geofenceRadiusFullscreen = 50.0; // metres

class MapFullscreenScreen extends ConsumerStatefulWidget {
  final double? initialLat;
  final double? initialLng;

  const MapFullscreenScreen({super.key, this.initialLat, this.initialLng});

  @override
  ConsumerState<MapFullscreenScreen> createState() =>
      _MapFullscreenScreenState();
}

class _MapFullscreenScreenState extends ConsumerState<MapFullscreenScreen> {
  MapboxMap? _mapboxMap;
  bool _isLocating = false;
  geo.Position? _lastPosition;

  // Geofence state
  Position? _geofenceCenter;
  bool _geofenceActive = false;
  bool _isInsideGeofence = false;
  StreamSubscription<geo.Position>? _positionStream;
  PolygonAnnotationManager? _polygonManager;
  PolygonAnnotation? _geofencePolygon;

  // Task navigation overlay (shared with the embedded route screen).
  TaskNavOverlayController? _navOverlay;
  RouteInfo? _activeRoute;
  bool _activeRouteFetching = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _navOverlay?.dispose();
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
      LocationComponentSettings(
        enabled: true,
        pulsingEnabled: true,
        // Render the directional puck (Google-Maps-style heading cone) so the
        // user can see which way they're facing, not just where they are.
        puckBearingEnabled: true,
        puckBearing: PuckBearing.HEADING,
      ),
    );

    // Bootstrap the shared nav overlay so the destination pin + polyline
    // can be drawn the same way as on the embedded map.
    final overlay = TaskNavOverlayController(
      map: _mapboxMap!,
      onChanged: (route, fetching) {
        if (!mounted) return;
        setState(() {
          _activeRoute = route;
          _activeRouteFetching = fetching;
        });
      },
    );
    await overlay.init();
    if (!mounted) return;
    _navOverlay = overlay;

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
      // Seed `_lastPosition` from the passed-in coords so the nav overlay can
      // fetch the route immediately. Without this, `setTask` gets a null
      // `currentPos` and waits for the position stream — but with a 5m
      // `distanceFilter` a stationary user never emits a fix, leaving the
      // route stuck on "No route yet". Only lat/lng are used downstream
      // (route src), so the other GPS fields are placeholders.
      _lastPosition = geo.Position(
        latitude: lat,
        longitude: lng,
        timestamp: DateTime.now(),
        accuracy: 0,
        altitude: 0,
        altitudeAccuracy: 0,
        heading: 0,
        headingAccuracy: 0,
        speed: 0,
        speedAccuracy: 0,
      );
    } else {
      // Fallback: fetch location only if none was passed in
      await _autoGoToLocation();
    }

    // Always-on stream feeds geofence transitions AND nav overlay re-routes.
    _startPositionStream();

    // If a task is already in progress, draw it now.
    final activeAtMount = ref.read(activeInProgressTaskProvider);
    if (activeAtMount != null) {
      await overlay.setTask(activeAtMount, currentPos: _lastPosition);
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
      _lastPosition = pos;
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
        LocationComponentSettings(
        enabled: true,
        pulsingEnabled: true,
        // Render the directional puck (Google-Maps-style heading cone) so the
        // user can see which way they're facing, not just where they are.
        puckBearingEnabled: true,
        puckBearing: PuckBearing.HEADING,
      ),
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
    // Position stream is already running (started in `_initMap`); the
    // listener picks up the new geofence center automatically.
  }

  Future<void> _clearGeofence() async {
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

  /// Single always-on stream while the screen is mounted. Drives both the
  /// geofence inside/outside check AND the task navigation re-route
  /// trigger so the green polyline tracks the user as they move.
  void _startPositionStream() {
    _positionStream?.cancel();
    _positionStream = geo.Geolocator.getPositionStream(
      locationSettings: const geo.LocationSettings(
        accuracy: geo.LocationAccuracy.high,
        // Tighter filter → more frequent fixes so the route polyline
        // re-anchors to the user in near-realtime as they move.
        distanceFilter: 5,
      ),
    ).listen(_onPositionUpdate);
  }

  void _onPositionUpdate(geo.Position current) {
    _lastPosition = current;
    _navOverlay?.onPositionUpdate(current);

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
    // Mirror the embedded route screen's behaviour: when the active task
    // changes (or clears), forward it to the overlay controller. The
    // controller short-circuits if the same task is set twice.
    ref.listen<TaskModel?>(activeInProgressTaskProvider, (prev, next) {
      if (prev?.id == next?.id) return;
      _navOverlay?.setTask(next, currentPos: _lastPosition);
    });

    final activeTask = ref.watch(activeInProgressTaskProvider);

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

          // Active-task ETA banner — top centre. Only shown while a task
          // is in progress; the geofence chip drops down a row in that
          // case to avoid overlap.
          if (activeTask != null)
            Positioned(
              top: 48,
              left: 72,
              right: 72,
              child: _NavBanner(
                task: activeTask,
                route: _activeRoute,
                fetching: _activeRouteFetching,
              ),
            ),

          // Geofence status chip — top centre (or just below the nav banner
          // when navigating, so both can coexist).
          if (_geofenceActive)
            Positioned(
              top: activeTask != null ? 110 : 52,
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

/// Floating banner shown across the top of the fullscreen map while a task
/// is IN_PROGRESS. Surfaces the same ETA / distance the embedded route
/// screen shows in its bottom card so the user doesn't lose context when
/// switching to fullscreen.
class _NavBanner extends StatelessWidget {
  final TaskModel task;
  final RouteInfo? route;
  final bool fetching;

  const _NavBanner({
    required this.task,
    required this.route,
    required this.fetching,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.directions_car,
              color: Color(0xFF157347), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  route == null
                      ? (fetching ? 'Calculating route…' : 'No route yet')
                      : '${route!.prettyDistance} · ${route!.prettyDuration}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF157347),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          if (fetching)
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFF157347),
              ),
            ),
        ],
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
