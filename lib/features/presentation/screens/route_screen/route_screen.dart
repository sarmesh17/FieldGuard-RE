import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:go_router/go_router.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' hide Size;
import 'package:permission_handler/permission_handler.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/services/mapbox_directions_service.dart';
import '../../../../core/theme/app_responsive.dart';
import '../../../geofence/presentation/providers/geofence_provider.dart';
import '../../../tasks/data/models/task_model.dart';
import '../../../tasks/presentation/providers/tasks_provider.dart';
import '../../../tracking/presentation/providers/tracking_provider.dart';
import 'components/schedule_list.dart';
import 'components/task_nav_overlay_controller.dart';

class RouteScreen extends ConsumerStatefulWidget {
  const RouteScreen({super.key});

  @override
  ConsumerState<RouteScreen> createState() => _RouteScreenState();
}

class _RouteScreenState extends ConsumerState<RouteScreen> {
  MapboxMap? _mapboxMap;
  bool _isLocating = false;
  geo.Position? _lastPosition; // cached so fullscreen reuses it

  // Position stream — feeds the task navigation overlay's re-route trigger.
  StreamSubscription<geo.Position>? _positionStream;

  // ── Task navigation overlay ──────────────────────────────────────────────
  // Owned by `TaskNavOverlayController`; we just hold a reference so the
  // active task transitions and position updates can be forwarded to it.
  // Same controller is used by `MapFullscreenScreen` so behaviour stays
  // identical between the embedded and fullscreen maps.
  TaskNavOverlayController? _navOverlay;
  RouteInfo? _activeRoute;
  bool _activeRouteFetching = false;

  @override
  void dispose() {
    _positionStream?.cancel();
    _navOverlay?.dispose();
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

    // Spin up the shared overlay controller and let it pre-create the
    // annotation managers + pin image so a later task transition has zero
    // first-paint latency.
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

    // Auto-fly to real location on map load.
    await _autoGoToLocation();

    // Always-on position stream: drives both the geofence inside/outside
    // check AND the task navigation re-route trigger so the green polyline
    // tracks the user as they move (fixing the "line stuck on first
    // origin" bug).
    _startPositionStream();

    // If we entered the screen while a task is already IN_PROGRESS, draw
    // its route now instead of waiting for the next status change.
    final activeAtMount = ref.read(activeInProgressTaskProvider);
    if (activeAtMount != null) {
      await overlay.setTask(activeAtMount, currentPos: _lastPosition);
    }
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

  /// Always-on stream while the screen is mounted — feeds the task navigation
  /// overlay's re-route trigger so the green polyline tracks the user.
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
    // Forward to the navigation overlay — it decides internally whether
    // the user has moved far enough to warrant a fresh route fetch.
    _navOverlay?.onPositionUpdate(current);
  }

  // ── UI ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final hPad = AppResponsive.horizontalPad(context);
    final mapHeight = AppResponsive.hp(context, 30).clamp(180.0, 280.0);

    // React to changes in which task is active (or none). The overlay
    // controller handles its own no-op short-circuit when the same task is
    // set twice; we just forward the transition.
    ref.listen<TaskModel?>(activeInProgressTaskProvider, (prev, next) {
      if (prev?.id == next?.id) return;
      _navOverlay?.setTask(next, currentPos: _lastPosition);
    });

    final activeTask = ref.watch(activeInProgressTaskProvider);
    final todayCount = ref.watch(todayTasksProvider).length;
    final reachedTaskId = ref.watch(reachedDestinationTaskIdProvider);
    final hasReached =
        activeTask != null && reachedTaskId == activeTask.id;

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
              child: Text(
                  todayCount == 1 ? '1 Task' : '$todayCount Tasks',
                  style: TextStyle(
                    color: const Color(0xFF157347),
                    fontWeight: FontWeight.bold,
                    fontSize: AppResponsive.sp(context, 14),
                  )),
            ),
          ),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(66),
          child: _TrackingToggleBar(),
        ),
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

            // ── Active task / Next stop card ──────────────────────────────
            Padding(
              padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 16),
              child: _ActiveNavCard(
                task: activeTask,
                route: _activeRoute,
                routeFetching: _activeRouteFetching,
                reached: hasReached,
                onOpenTask: activeTask == null
                    ? null
                    : () => context
                        .push(AppRoutes.taskDetailPath(activeTask.id)),
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

  const _MapIconButton({required this.icon, required this.onTap});

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
        child: Icon(icon, color: const Color(0xFF157347), size: 20),
      ),
    );
  }
}

class _TrackingToggleBar extends ConsumerWidget {
  const _TrackingToggleBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tracking = ref.watch(trackingNotifierProvider);
    final isActive = tracking.isActive;
    final accent = const Color(0xFF157347);

    Future<void> onToggle() async {
      final messenger = ScaffoldMessenger.of(context);
      final notifier = ref.read(trackingNotifierProvider.notifier);
      final message = await notifier.toggle();
      if (!context.mounted) return;
      final error = ref.read(trackingNotifierProvider).error;
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(message ?? error ?? 'Something went wrong'),
            backgroundColor: message != null ? accent : Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
    }

    return Container(
      color: Colors.white,
      padding: EdgeInsets.fromLTRB(
        AppResponsive.horizontalPad(context),
        0,
        AppResponsive.horizontalPad(context),
        12,
      ),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: AppResponsive.r(context, 14),
          vertical: AppResponsive.r(context, 8),
        ),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFD1FADF) : const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isActive ? accent : const Color(0xFFE5E7EB),
          ),
        ),
        child: Row(
          children: [
            Icon(
              isActive ? Icons.location_on : Icons.location_off,
              color: isActive ? accent : const Color(0xFF6B7280),
              size: AppResponsive.r(context, 20),
            ),
            SizedBox(width: AppResponsive.r(context, 10)),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Live Tracking',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: AppResponsive.sp(context, 14),
                      color: const Color(0xFF111827),
                    ),
                  ),
                  Text(
                    isActive ? 'Tracking your location' : 'Tracking is off',
                    style: TextStyle(
                      fontSize: AppResponsive.sp(context, 12),
                      color: const Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
            if (tracking.isLoading)
              SizedBox(
                width: AppResponsive.r(context, 22),
                height: AppResponsive.r(context, 22),
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  color: accent,
                ),
              )
            else
              Switch(
                value: isActive,
                activeThumbColor: accent,
                onChanged: (_) => onToggle(),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Active task card ──────────────────────────────────────────────────────────

/// Shown directly under the map. When [task] is non-null we surface a
/// "navigating to" view with live ETA / distance pulled from the Mapbox
/// Directions response; otherwise we fall back to a friendly empty state
/// that points the user to the tasks list.
class _ActiveNavCard extends StatelessWidget {
  final TaskModel? task;
  final RouteInfo? route;
  final bool routeFetching;
  final bool reached;
  final VoidCallback? onOpenTask;

  const _ActiveNavCard({
    required this.task,
    required this.route,
    required this.routeFetching,
    required this.reached,
    required this.onOpenTask,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
          if (task == null)
            _emptyContent(context)
          else
            _activeContent(context, task!),
        ],
      ),
    );
  }

  // ── Active state ────────────────────────────────────────────────────────

  Widget _activeContent(BuildContext context, TaskModel task) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              reached ? Icons.check_circle : Icons.circle,
              size: reached ? 14 : 8,
              color: const Color(0xFF157347),
            ),
            const SizedBox(width: 6),
            Text(
              reached ? 'ARRIVED' : 'NAVIGATING TO',
              style: TextStyle(
                color: const Color(0xFF157347),
                fontWeight: FontWeight.w700,
                fontSize: AppResponsive.sp(context, 11),
                letterSpacing: 0.6,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: AppResponsive.sp(context, 20),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    reached
                        ? 'You reached your destination'
                        : (task.description.isNotEmpty
                            ? task.description
                            : ''),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: AppResponsive.sp(context, 14),
                      color: reached
                          ? const Color(0xFF157347)
                          : const Color(0xFF6B7280),
                      fontWeight:
                          reached ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (!reached) _EtaPill(route: route, fetching: routeFetching),
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
                onPressed: onOpenTask,
                icon: const Icon(Icons.assignment_outlined,
                    color: Colors.white),
                label: Text(
                  'Open Task',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: AppResponsive.sp(context, 15),
                  ),
                ),
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
                onPressed: () {
                  // Phone field isn't on the task model yet — placeholder.
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Shop phone number not available yet.'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                icon: const Icon(Icons.phone, color: Color(0xFF157347)),
                label: Text(
                  'Call Shop',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: AppResponsive.sp(context, 15),
                    color: const Color(0xFF157347),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Empty state ─────────────────────────────────────────────────────────

  Widget _emptyContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'NO ACTIVE TASK',
          style: TextStyle(
            color: const Color(0xFF6B7280),
            fontWeight: FontWeight.w700,
            fontSize: AppResponsive.sp(context, 11),
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Showing your current location',
          style: TextStyle(
            fontSize: AppResponsive.sp(context, 18),
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Mark a task as IN_PROGRESS to see the route to its shop here.',
          style: TextStyle(
            fontSize: AppResponsive.sp(context, 13),
            color: const Color(0xFF6B7280),
          ),
        ),
        SizedBox(height: AppResponsive.r(context, 16)),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFF157347)),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              padding: EdgeInsets.symmetric(
                  vertical: AppResponsive.r(context, 12)),
            ),
            onPressed: () => context.go(AppRoutes.tasks),
            icon: const Icon(Icons.list_alt, color: Color(0xFF157347)),
            label: Text(
              'View Tasks',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: AppResponsive.sp(context, 14),
                color: const Color(0xFF157347),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _EtaPill extends StatelessWidget {
  final RouteInfo? route;
  final bool fetching;

  const _EtaPill({required this.route, required this.fetching});

  @override
  Widget build(BuildContext context) {
    return Container(
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
          if (fetching)
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFF157347),
              ),
            )
          else
            Icon(
              Icons.directions_car,
              size: AppResponsive.r(context, 16),
              color: const Color(0xFF157347),
            ),
          const SizedBox(width: 6),
          Text(
            route == null
                ? (fetching ? 'Calculating…' : '— · —')
                : '${route!.prettyDistance} · ${route!.prettyDuration}',
            style: TextStyle(
              color: const Color(0xFF157347),
              fontWeight: FontWeight.w600,
              fontSize: AppResponsive.sp(context, 12),
            ),
          ),
        ],
      ),
    );
  }
}
