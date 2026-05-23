import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:field_guard_re/core/services/mapbox_directions_service.dart';

/// Inputs needed to fetch a route. Equality-by-value so Riverpod caches the
/// result correctly and re-fetches only when source/destination actually move.
class RouteRequest {
  final double srcLat;
  final double srcLng;
  final double dstLat;
  final double dstLng;

  const RouteRequest({
    required this.srcLat,
    required this.srcLng,
    required this.dstLat,
    required this.dstLng,
  });

  @override
  bool operator ==(Object other) =>
      other is RouteRequest &&
      other.srcLat == srcLat &&
      other.srcLng == srcLng &&
      other.dstLat == dstLat &&
      other.dstLng == dstLng;

  @override
  int get hashCode => Object.hash(srcLat, srcLng, dstLat, dstLng);
}

/// Resolves the fastest driving route (with live traffic) for the given
/// source → destination pair. Riverpod's `family` cache means identical
/// requests reuse the previous response instead of hammering the API.
final taskRouteProvider =
    FutureProvider.autoDispose.family<RouteInfo, RouteRequest>((ref, req) {
  return MapboxDirectionsService.instance.getRoute(
    srcLat: req.srcLat,
    srcLng: req.srcLng,
    dstLat: req.dstLat,
    dstLng: req.dstLng,
  );
});
