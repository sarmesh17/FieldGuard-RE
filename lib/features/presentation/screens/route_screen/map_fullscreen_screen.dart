import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' hide Size;
import 'package:permission_handler/permission_handler.dart';

import '../../../../core/services/mapbox_directions_service.dart';
import '../../../tasks/data/models/task_model.dart';
import '../../../tasks/presentation/providers/tasks_provider.dart';
import '../../../tracking/presentation/providers/tracking_provider.dart';
import 'components/task_nav_overlay_controller.dart';

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

  // Position stream — feeds the task navigation overlay's re-route trigger.
  StreamSubscription<geo.Position>? _positionStream;

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

    // Enable the puck AFTER the overlay's managers exist, anchoring it above
    // the route polyline's layer so the green line renders beneath the dot.
    await _mapboxMap?.location.updateSettings(
      LocationComponentSettings(
        enabled: true,
        pulsingEnabled: true,
        // Render the directional puck (Google-Maps-style heading cone) so the
        // user can see which way they're facing, not just where they are.
        puckBearingEnabled: true,
        puckBearing: PuckBearing.HEADING,
        layerAbove: overlay.routeLayerId,
      ),
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

  /// Always-on stream while the screen is mounted — drives the task
  /// navigation re-route trigger so the green polyline tracks the user.
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

    // If Live Tracking is turned off while the fullscreen map is open, this
    // screen has nothing meaningful to show (no puck, no route). Pop back to
    // the route screen, where the tracking-off overlay greets the user.
    ref.listen<bool>(
      trackingNotifierProvider.select((s) => s.isActive),
      (prev, next) {
        if (prev == true && next == false && context.mounted) {
          context.pop();
        }
      },
    );

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
          // is in progress.
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
      onTap: () => context.pop(),
    );
  }
}

class _MapIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _MapIconButton({required this.icon, required this.onTap});

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
        child: Icon(icon, color: const Color(0xFF157347), size: 22),
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
