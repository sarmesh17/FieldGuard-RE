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

  /// Live straight-line distance (metres) from the user to the active task's
  /// shop, recomputed on every GPS fix. Drives the nav-card distance label so
  /// it updates in real time as the user walks in — unlike the driving-route
  /// ETA, which only refreshes on a throttled re-route and can look "stuck".
  double? _straightLineToShop;

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
    // Spin up the shared overlay controller and let it pre-create the
    // annotation managers + pin image so a later task transition has zero
    // first-paint latency. Safe to do without tracking — these are just
    // empty Mapbox layers; no GPS is requested.
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

    // Only request permission and start GPS / puck / streams if the user has
    // turned Live Tracking on. Otherwise we leave the map idle and wait for
    // them to flip the toggle — `_resumeForTracking` runs then.
    if (ref.read(trackingNotifierProvider).isActive) {
      await _resumeForTracking();
    }
  }

  /// Brings up the GPS-dependent parts of the map: location permission, the
  /// puck, an initial camera fly-to, the live position stream, and the active
  /// task's route. Called on map load (if tracking is already on) and again
  /// whenever the user flips Live Tracking on.
  Future<void> _resumeForTracking() async {
    if (!mounted) return;
    final map = _mapboxMap;
    final overlay = _navOverlay;
    if (map == null || overlay == null) return;

    final status = await Permission.locationWhenInUse.request();
    if (!status.isGranted || !mounted) return;

    // Enable the puck above the route polyline's layer so the green line
    // renders beneath the dot.
    await map.location.updateSettings(
      LocationComponentSettings(
        enabled: true,
        pulsingEnabled: true,
        puckBearingEnabled: true,
        puckBearing: PuckBearing.HEADING,
        layerAbove: overlay.routeLayerId,
      ),
    );

    await _autoGoToLocation();
    _startPositionStream();

    // If a task is already IN_PROGRESS when tracking comes on, draw its
    // route immediately instead of waiting for the next status change.
    final activeAtMount = ref.read(activeInProgressTaskProvider);
    if (activeAtMount != null) {
      await overlay.setTask(activeAtMount, currentPos: _lastPosition);
    }
  }

  /// Tears the GPS-dependent parts down when the user turns Live Tracking
  /// off. The map widget itself stays mounted (a grey overlay covers it in
  /// the UI); we just stop draining battery / asking for fixes.
  Future<void> _suspendForTracking() async {
    await _positionStream?.cancel();
    _positionStream = null;
    await _navOverlay?.clear();
    await _mapboxMap?.location.updateSettings(
      LocationComponentSettings(enabled: false),
    );
    _lastPosition = null;
    if (mounted) {
      setState(() {
        _activeRoute = null;
        _activeRouteFetching = false;
        _straightLineToShop = null;
      });
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
    // No-op when Live Tracking is off — UI's "my location" button is hidden
    // in that state, but guard anyway in case of a race.
    if (!ref.read(trackingNotifierProvider).isActive) return;
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

    // Live straight-line distance to the active shop for the nav-card label.
    final task = ref.read(activeInProgressTaskProvider);
    final shopLat = double.tryParse(task?.shopLatitude ?? '');
    final shopLng = double.tryParse(task?.shopLongitude ?? '');
    final dist = (shopLat != null && shopLng != null)
        ? geo.Geolocator.distanceBetween(
            current.latitude,
            current.longitude,
            shopLat,
            shopLng,
          )
        : null;
    if (dist != _straightLineToShop && mounted) {
      setState(() => _straightLineToShop = dist);
    }
  }

  // ── UI ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final hPad = AppResponsive.horizontalPad(context);
    // Portrait: ~30% of height (180–280). Landscape: the viewport is short, so
    // a 180px floor would dominate the screen and bury the active-task card and
    // schedule below the fold. Use a smaller share + lower clamp there so the
    // map stays a glanceable strip and the list is reachable without scrolling
    // past a full-screen map.
    final mapHeight = AppResponsive.isLandscape(context)
        ? AppResponsive.hp(context, 55).clamp(150.0, 210.0)
        : AppResponsive.hp(context, 30).clamp(180.0, 280.0);

    // React to changes in which task is active (or none). The overlay
    // controller handles its own no-op short-circuit when the same task is
    // set twice; we just forward the transition.
    ref.listen<TaskModel?>(activeInProgressTaskProvider, (prev, next) {
      if (prev?.id == next?.id) return;
      _navOverlay?.setTask(next, currentPos: _lastPosition);
    });

    // Arrival is owned by the geofence ENTER event (background isolate),
    // surfaced via reachedDestinationTaskIdProvider — NOT a local distance
    // check. Relay ONLY the arrive (→true) transition: once arrived, the route
    // stays gone until the active task changes (handled by setTask). We must
    // NOT setReached(false) when the marker clears on exit — the exit clears
    // the marker before the auto-complete PATCH lands, so the task is briefly
    // still IN_PROGRESS, and redrawing the route there put the green line back
    // on the way out.
    ref.listen<int?>(reachedDestinationTaskIdProvider, (prev, next) {
      final activeId = ref.read(activeInProgressTaskProvider)?.id;
      if (next != null && next == activeId) {
        _navOverlay?.setReached(true);
      }
    });

    // React to the Live Tracking master switch. ON→OFF tears down all
    // GPS-driven UI (stream, puck, nav overlay). OFF→ON resumes setup.
    ref.listen<bool>(trackingNotifierProvider.select((s) => s.isActive), (
      prev,
      next,
    ) {
      if (prev == next) return;
      if (next) {
        _resumeForTracking();
      } else {
        _suspendForTracking();
      }
    });

    final trackingActive = ref.watch(
      trackingNotifierProvider.select((s) => s.isActive),
    );
    final activeTask = ref.watch(activeInProgressTaskProvider);
    final todayCount = ref.watch(todayTasksProvider).length;
    final reachedTaskId = ref.watch(reachedDestinationTaskIdProvider);
    final hasReached = activeTask != null && reachedTaskId == activeTask.id;

    return Scaffold(
      backgroundColor: const Color(0xFFFAF8F3),
      body: Column(
        children: [
          _RouteHeader(taskCount: todayCount),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // ── Map area ──────────────────────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    height: mapHeight + AppResponsive.r(context, 24),
                    child: Stack(
                      children: [
                        Padding(
                          padding: EdgeInsets.fromLTRB(
                            hPad,
                            AppResponsive.r(context, 24),
                            hPad,
                            0,
                          ),
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
                                  // Tracking-off curtain: greys the map and tells
                                  // the user to enable Live Tracking. AbsorbPointer
                                  // also blocks pan/zoom — the map is effectively
                                  // inert while tracking is off.
                                  if (!trackingActive)
                                    const Positioned.fill(
                                      child: _TrackingOffOverlay(),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        // Fullscreen button — top right (hidden when tracking off)
                        if (trackingActive)
                          Positioned(
                            top: AppResponsive.r(context, 32),
                            right: hPad + AppResponsive.r(context, 8),
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

                        // My location — bottom right (hidden when tracking off)
                        if (trackingActive)
                          Positioned(
                            bottom: AppResponsive.r(context, 8),
                            right: hPad + AppResponsive.r(context, 8),
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
                    padding: EdgeInsets.symmetric(
                      horizontal: hPad,
                      vertical: 16,
                    ),
                    child: _ActiveNavCard(
                      task: activeTask,
                      route: _activeRoute,
                      routeFetching: _activeRouteFetching,
                      reached: hasReached,
                      straightLineMeters: _straightLineToShop,
                      onOpenTask: activeTask == null
                          ? null
                          : () => context.push(
                              AppRoutes.taskDetailPath(activeTask.id),
                            ),
                    ),
                  ),

                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: hPad,
                      vertical: 8,
                    ),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Today's Schedule",
                        style: TextStyle(
                          fontSize: AppResponsive.sp(context, 18),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const ScheduleList(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Gradient header ─────────────────────────────────────────────────────────

/// Brand green→teal header band — title + today's task count, with the Live
/// Tracking toggle tucked underneath. Matches the tasks/profile/login headers
/// so the app reads as one family. Rounded bottom so the map below tucks in.
class _RouteHeader extends StatelessWidget {
  final int taskCount;

  const _RouteHeader({required this.taskCount});

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
            children: [
              Row(
                children: [
                  Text(
                    "Today's Route",
                    style: TextStyle(
                      fontSize: AppResponsive.sp(context, 22),
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
                      taskCount == 1 ? '1 Task' : '$taskCount Tasks',
                      style: TextStyle(
                        fontSize: AppResponsive.sp(context, 12),
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.95),
                      ),
                    ),
                  ),
                  const Spacer(),
                ],
              ),
              SizedBox(height: AppResponsive.vGap(context, 12)),
              const _TrackingToggleBar(),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Shared widgets ────────────────────────────────────────────────────────────

/// Curtain shown over the embedded map while Live Tracking is off — greys
/// out the tiles, blocks pan/zoom, and prompts the user to flip the toggle.
/// All GPS-driven UI (puck, route, my-location/fullscreen buttons) is also
/// torn down separately; this is the visible cue.
class _TrackingOffOverlay extends StatelessWidget {
  const _TrackingOffOverlay();

  @override
  Widget build(BuildContext context) {
    return AbsorbPointer(
      child: Container(
        color: Colors.white.withValues(alpha: 0.78),
        alignment: Alignment.center,
        padding: EdgeInsets.symmetric(horizontal: AppResponsive.r(context, 24)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.location_off_outlined,
              color: const Color(0xFF6B7280),
              size: AppResponsive.r(context, 34),
            ),
            const SizedBox(height: 8),
            Text(
              'Live Tracking is off',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: AppResponsive.sp(context, 14),
                color: const Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Enable it above to see your route.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: AppResponsive.sp(context, 12),
                color: const Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      ),
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
        width: AppResponsive.r(context, 40),
        height: AppResponsive.r(context, 40),
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
        child: Icon(
          icon,
          color: const Color(0xFF157347),
          size: AppResponsive.r(context, 20),
        ),
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

    // Rendered on the gradient header, so colours are white/translucent.
    // AnimatedContainer smoothly fades the fill/border as tracking toggles.
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      padding: EdgeInsets.symmetric(
        horizontal: AppResponsive.r(context, 14),
        vertical: AppResponsive.r(context, 10),
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: isActive ? 0.22 : 0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: isActive ? 0.5 : 0.25),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isActive ? Icons.location_on : Icons.location_off,
            color: Colors.white,
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
                    color: Colors.white,
                  ),
                ),
                Text(
                  isActive ? 'Tracking your location' : 'Tracking is off',
                  style: TextStyle(
                    fontSize: AppResponsive.sp(context, 12),
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
          if (tracking.isLoading)
            SizedBox(
              width: AppResponsive.r(context, 22),
              height: AppResponsive.r(context, 22),
              child: const CircularProgressIndicator(
                strokeWidth: 2.4,
                color: Colors.white,
              ),
            )
          else
            Switch(
              value: isActive,
              activeThumbColor: const Color(0xFF1B5E4F),
              activeTrackColor: Colors.white,
              inactiveThumbColor: Colors.white,
              inactiveTrackColor: Colors.white.withValues(alpha: 0.3),
              onChanged: (_) => onToggle(),
            ),
        ],
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
  final double? straightLineMeters;
  final VoidCallback? onOpenTask;

  const _ActiveNavCard({
    required this.task,
    required this.route,
    required this.routeFetching,
    required this.reached,
    required this.straightLineMeters,
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
          // Smooth cross-fade when switching between the empty and active
          // states (a task becoming IN_PROGRESS, or finishing).
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 320),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            transitionBuilder: (child, anim) => FadeTransition(
              opacity: anim,
              child: SizeTransition(
                sizeFactor: anim,
                axisAlignment: -1,
                child: child,
              ),
            ),
            child: KeyedSubtree(
              key: ValueKey(task?.id ?? 'empty'),
              child: task == null
                  ? _emptyContent(context)
                  : _activeContent(context, task!),
            ),
          ),
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
            if (reached)
              const Icon(Icons.check_circle, size: 14, color: Color(0xFF157347))
            else
              const _PulsingDot(color: Color(0xFF157347)),
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
                        : (task.description.isNotEmpty ? task.description : ''),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: AppResponsive.sp(context, 14),
                      color: reached
                          ? const Color(0xFF157347)
                          : const Color(0xFF6B7280),
                      fontWeight: reached ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, anim) => ScaleTransition(
                scale: Tween<double>(begin: 0.85, end: 1).animate(anim),
                child: FadeTransition(opacity: anim, child: child),
              ),
              child: reached
                  ? const _ArrivedPill(key: ValueKey('arrived'))
                  : _EtaPill(
                      key: const ValueKey('eta'),
                      route: route,
                      fetching: routeFetching,
                      straightLineMeters: straightLineMeters,
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
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: EdgeInsets.symmetric(
                    vertical: AppResponsive.r(context, 14),
                  ),
                ),
                onPressed: onOpenTask,
                icon: const Icon(
                  Icons.assignment_outlined,
                  color: Colors.white,
                ),
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
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: EdgeInsets.symmetric(
                    vertical: AppResponsive.r(context, 14),
                  ),
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
                borderRadius: BorderRadius.circular(14),
              ),
              padding: EdgeInsets.symmetric(
                vertical: AppResponsive.r(context, 12),
              ),
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

/// Replaces the ETA pill once the agent has arrived — a clear green
/// "Arrived" chip so the card reads as a completed leg, not a stalled ETA.
class _ArrivedPill extends StatelessWidget {
  const _ArrivedPill({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppResponsive.r(context, 10),
        vertical: AppResponsive.r(context, 6),
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF157347),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.check_circle,
            size: AppResponsive.r(context, 16),
            color: Colors.white,
          ),
          const SizedBox(width: 6),
          Text(
            'Arrived',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: AppResponsive.sp(context, 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _EtaPill extends StatelessWidget {
  final RouteInfo? route;
  final bool fetching;

  /// Live straight-line distance to the shop (metres). Preferred over the
  /// driving distance because it updates on every GPS fix — the driving route
  /// only re-fetches on a throttled trigger, so near the destination it looks
  /// frozen (e.g. stuck on "30 m").
  final double? straightLineMeters;

  const _EtaPill({
    super.key,
    required this.route,
    required this.fetching,
    required this.straightLineMeters,
  });

  String _label() {
    final m = straightLineMeters;
    if (m != null) {
      final dist = m < 1000
          ? '${m.round()} m'
          : '${(m / 1000).toStringAsFixed(1)} km';
      // Append the driving ETA when it's available and the user isn't already
      // basically on top of the shop.
      if (route != null && m > 50) return '$dist · ${route!.prettyDuration}';
      return '$dist away';
    }
    // No live fix yet — fall back to the driving route, or a placeholder.
    if (route != null) {
      return '${route!.prettyDistance} · ${route!.prettyDuration}';
    }
    return fetching ? 'Calculating…' : '— · —';
  }

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
          if (fetching && straightLineMeters == null)
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
            _label(),
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

/// A live "you're navigating" indicator — a solid dot with a soft ring that
/// expands and fades out on a loop, like a radar ping. Signals that tracking
/// is actively running.
class _PulsingDot extends StatefulWidget {
  final Color color;

  const _PulsingDot({required this.color});

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 16,
      height: 16,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, _) {
          final t = _ctrl.value;
          return Stack(
            alignment: Alignment.center,
            children: [
              // Expanding, fading ring.
              Container(
                width: 8 + 8 * t,
                height: 8 + 8 * t,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.color.withValues(alpha: (1 - t) * 0.35),
                ),
              ),
              // Solid core.
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.color,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
