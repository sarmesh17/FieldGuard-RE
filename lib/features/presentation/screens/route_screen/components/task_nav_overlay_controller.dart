import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' hide Size;

import '../../../../../core/services/mapbox_directions_service.dart';
import '../../../../tasks/data/models/task_model.dart';

/// Re-route only when the user has drifted at least this many metres from
/// the origin used for the previous Mapbox Directions request. Stops us
/// from spamming the API every metre.
const _reRouteDistanceMeters = 75.0;

/// Or, regardless of distance, after this much wall-clock time. Catches the
/// "user is stuck in traffic, polyline still reflects the old plan" case.
const _reRouteMaxAge = Duration(seconds: 20);

/// Encapsulates the destination pin + driving polyline + camera-fit logic
/// for "navigating to a task". Lives outside the widget tree so the same
/// behaviour can be shared between the embedded route screen map and the
/// fullscreen map without copy-pasting hundreds of lines.
///
/// Lifecycle:
/// 1. Construct after the [MapboxMap] is ready in `onMapCreated`.
/// 2. Call [init] once — bootstraps annotation managers + caches the pin PNG.
/// 3. Call [setTask] when the active task changes (incl. on first frame).
/// 4. Pipe every [geo.Position] from your stream into [onPositionUpdate];
///    the controller decides whether the move warrants a re-route.
/// 5. Call [dispose] in your widget's `dispose`.
class TaskNavOverlayController {
  final MapboxMap map;

  /// Fired whenever the route or fetching state changes so the host widget
  /// can refresh the ETA pill / "calculating…" indicator.
  final void Function(RouteInfo? route, bool fetching) onChanged;

  PolylineAnnotationManager? _polyManager;
  PointAnnotationManager? _pointManager;
  Uint8List? _pinImage;

  PolylineAnnotation? _routeLine;
  PointAnnotation? _shopPin;

  /// Full geometry of the last fetched route in `[lng, lat]` order. Kept so
  /// the polyline can be re-anchored to the user's live position on every
  /// GPS fix (realtime feel) without hitting the Directions API each time.
  List<List<double>>? _routeCoordinates;

  TaskModel? _currentTask;
  geo.Position? _lastRoutedFrom;
  DateTime _lastRouteAt = DateTime.fromMillisecondsSinceEpoch(0);
  bool _fetching = false;
  bool _disposed = false;

  TaskNavOverlayController({required this.map, required this.onChanged});

  /// One-time setup. Safe to call on a fresh controller; idempotent.
  Future<void> init() async {
    if (_disposed) return;
    _polyManager ??= await map.annotations.createPolylineAnnotationManager();
    _pointManager ??= await map.annotations.createPointAnnotationManager();
    _pinImage ??= await _buildPinImage();
  }

  /// Switch the active task. Pass `null` to clear. If [currentPos] is
  /// supplied (e.g. the host already has a recent fix) we kick off the
  /// initial route fetch + camera fit immediately; otherwise the controller
  /// waits for [onPositionUpdate].
  Future<void> setTask(
    TaskModel? task, {
    geo.Position? currentPos,
    bool fitCamera = true,
  }) async {
    if (_disposed) return;
    if (task == null) {
      await clear();
      return;
    }
    if (_currentTask?.id == task.id) return; // already showing this one
    await clear();
    _currentTask = task;
    await _drawPin(task);
    if (currentPos != null) {
      await _fetchAndDrawRoute(task, currentPos, fitCamera: fitCamera);
    }
  }

  /// Forward every position fix here. The controller throttles re-routes
  /// using [_reRouteDistanceMeters] / [_reRouteMaxAge] so callers don't
  /// have to. No-op when there's no active task.
  Future<void> onPositionUpdate(geo.Position pos) async {
    if (_disposed) return;
    final task = _currentTask;
    if (task == null) return;

    // Realtime: re-anchor the drawn polyline to the user's live position on
    // every fix — instant, no network. The throttled re-route below still
    // corrects the actual path once the user drifts far enough.
    await _trimRouteToPosition(pos);

    if (_fetching) return;

    final last = _lastRoutedFrom;
    final now = DateTime.now();
    if (last == null) {
      // First fix after setTask() without a starting position — draw fresh
      // and fit the camera.
      await _fetchAndDrawRoute(task, pos, fitCamera: true);
      return;
    }
    final dist = geo.Geolocator.distanceBetween(
      last.latitude,
      last.longitude,
      pos.latitude,
      pos.longitude,
    );
    final aged = now.difference(_lastRouteAt) >= _reRouteMaxAge;
    if (dist < _reRouteDistanceMeters && !aged) return;

    await _fetchAndDrawRoute(task, pos, fitCamera: false);
  }

  /// Re-anchors the drawn polyline so it starts at [pos] and runs to the
  /// destination. Runs on every GPS fix so the green line tracks the user in
  /// realtime — purely local, no Directions API call. The throttled re-route
  /// in [onPositionUpdate] still corrects the actual path on larger drifts.
  Future<void> _trimRouteToPosition(geo.Position pos) async {
    final coords = _routeCoordinates;
    final line = _routeLine;
    if (coords == null || coords.length < 2 || line == null) return;
    if (_polyManager == null) return;

    // Find the route vertex nearest the user — everything before it has
    // already been travelled and should drop off the line.
    var nearestIdx = 0;
    var nearestDist = double.infinity;
    for (var i = 0; i < coords.length; i++) {
      final d = geo.Geolocator.distanceBetween(
        pos.latitude,
        pos.longitude,
        coords[i][1],
        coords[i][0],
      );
      if (d < nearestDist) {
        nearestDist = d;
        nearestIdx = i;
      }
    }

    // Trimmed route = the user's live position + every vertex still ahead.
    final trimmed = <Position>[Position(pos.longitude, pos.latitude)];
    for (var i = nearestIdx + 1; i < coords.length; i++) {
      trimmed.add(Position(coords[i][0], coords[i][1]));
    }
    if (trimmed.length < 2) {
      // User is at the final vertex — keep a valid 2-point line to the end.
      final last = coords.last;
      trimmed.add(Position(last[0], last[1]));
    }

    line.geometry = LineString(coordinates: trimmed);
    try {
      await _polyManager!.update(line);
    } catch (_) {/* line may have been swapped by a concurrent re-route */}
  }

  /// Removes pin + polyline, resets all internal state. Safe to call when
  /// nothing is drawn.
  Future<void> clear() async {
    if (_routeLine != null && _polyManager != null) {
      try {
        await _polyManager!.delete(_routeLine!);
      } catch (_) {/* annotation may already be gone */}
    }
    if (_shopPin != null && _pointManager != null) {
      try {
        await _pointManager!.delete(_shopPin!);
      } catch (_) {/* annotation may already be gone */}
    }
    _routeLine = null;
    _shopPin = null;
    _currentTask = null;
    _routeCoordinates = null;
    _lastRoutedFrom = null;
    _lastRouteAt = DateTime.fromMillisecondsSinceEpoch(0);
    if (!_disposed) onChanged(null, false);
  }

  Future<void> dispose() async {
    _disposed = true;
    await clear();
  }

  // ── Internals ────────────────────────────────────────────────────────────

  Future<void> _drawPin(TaskModel task) async {
    final lat = double.tryParse(task.shopLatitude ?? '');
    final lng = double.tryParse(task.shopLongitude ?? '');
    if (lat == null || lng == null) return;
    if (_pointManager == null || _pinImage == null) return;

    _shopPin = await _pointManager!.create(
      PointAnnotationOptions(
        geometry: Point(coordinates: Position(lng, lat)),
        image: _pinImage,
        iconSize: 1.0,
        iconAnchor: IconAnchor.BOTTOM,
        textField: task.title,
        textOffset: [0, -3.5],
        textSize: 13,
        textColor: const Color(0xFF111827).toARGB32(),
        textHaloColor: Colors.white.toARGB32(),
        textHaloWidth: 2,
      ),
    );
  }

  Future<void> _fetchAndDrawRoute(
    TaskModel task,
    geo.Position from, {
    required bool fitCamera,
  }) async {
    final lat = double.tryParse(task.shopLatitude ?? '');
    final lng = double.tryParse(task.shopLongitude ?? '');
    if (lat == null || lng == null) return;
    if (_polyManager == null) return;

    _fetching = true;
    onChanged(null, true);
    // Mark the origin/time *before* awaiting the network call so any
    // position updates that arrive while the fetch is in-flight don't
    // queue a duplicate re-route.
    _lastRoutedFrom = from;
    _lastRouteAt = DateTime.now();

    try {
      final route = await MapboxDirectionsService.instance.getRoute(
        srcLat: from.latitude,
        srcLng: from.longitude,
        dstLat: lat,
        dstLng: lng,
      );
      if (_disposed) return;
      // Bail out if the task changed while we were fetching — the new
      // setTask() call will draw the correct route.
      if (_currentTask?.id != task.id) return;

      // delete-then-create is the simplest reliable way to swap the
      // polyline geometry; Mapbox doesn't expose an in-place geometry
      // update on PolylineAnnotation.
      if (_routeLine != null) {
        try {
          await _polyManager!.delete(_routeLine!);
        } catch (_) {/* may already be gone */}
      }
      final positions = route.coordinates
          .map((c) => Position(c[0], c[1]))
          .toList(growable: false);
      _routeLine = await _polyManager!.create(
        PolylineAnnotationOptions(
          geometry: LineString(coordinates: positions),
          lineColor: const Color(0xFF1B5E4F).toARGB32(),
          lineWidth: 6.0,
          lineOpacity: 0.9,
        ),
      );
      // Cache the full geometry so subsequent GPS fixes can trim it locally.
      _routeCoordinates = route.coordinates;

      onChanged(route, false);

      if (fitCamera) {
        await _fitToRoute(from, lat, lng);
      }
    } catch (_) {
      if (!_disposed) onChanged(null, false);
    } finally {
      _fetching = false;
    }
  }

  Future<void> _fitToRoute(
    geo.Position from,
    double dstLat,
    double dstLng,
  ) async {
    final cam = await map.cameraForCoordinatesPadding(
      [
        Point(coordinates: Position(from.longitude, from.latitude)),
        Point(coordinates: Position(dstLng, dstLat)),
      ],
      CameraOptions(),
      MbxEdgeInsets(top: 80, left: 40, bottom: 80, right: 40),
      null,
      null,
    );
    final clamped = CameraOptions(
      center: cam.center,
      zoom: (cam.zoom ?? 14).clamp(10.0, 16.0),
      bearing: cam.bearing,
      pitch: cam.pitch,
      anchor: cam.anchor,
      padding: cam.padding,
    );
    await map.flyTo(clamped, MapAnimationOptions(duration: 1000));
  }

  /// Renders a Google-Maps-style teardrop pin to a PNG via Flutter Canvas
  /// so we don't need a bundled asset. Result is cached in `_pinImage`.
  static Future<Uint8List> _buildPinImage() async {
    const double w = 84;
    const double h = 116;
    const double cx = w / 2;
    const double headCy = 34;
    const double headR = 26;
    const double tipY = h - 14;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, w, h));

    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.30)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawOval(
      Rect.fromCenter(
        center: const Offset(cx, h - 8),
        width: 30,
        height: 8,
      ),
      shadowPaint,
    );

    final path = Path();
    const tangentDx = headR * 0.86;
    const tangentDy = headR * 0.50;
    path.moveTo(cx - tangentDx, headCy + tangentDy);
    path.lineTo(cx, tipY);
    path.lineTo(cx + tangentDx, headCy + tangentDy);
    path.arcToPoint(
      Offset(cx - tangentDx, headCy + tangentDy),
      radius: const Radius.circular(headR),
      largeArc: true,
      clockwise: false,
    );
    path.close();

    final strokePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, strokePaint);

    final fillPaint = Paint()
      ..color = const Color(0xFFDC2626)
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, fillPaint);

    canvas.drawCircle(
      const Offset(cx, headCy),
      8.5,
      Paint()..color = Colors.white,
    );

    final picture = recorder.endRecording();
    final image = await picture.toImage(w.toInt(), h.toInt());
    final byteData =
        await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }
}
