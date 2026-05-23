import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Single decoded route from the Mapbox Directions API.
class RouteInfo {
  /// Polyline points in `[lng, lat]` order, ready to feed straight into a
  /// Mapbox `LineString`.
  final List<List<double>> coordinates;

  /// Total route distance in meters.
  final double distanceMeters;

  /// Total route duration in seconds (with live traffic when the
  /// `driving-traffic` profile is used).
  final double durationSeconds;

  const RouteInfo({
    required this.coordinates,
    required this.distanceMeters,
    required this.durationSeconds,
  });

  String get prettyDistance {
    if (distanceMeters >= 1000) {
      return '${(distanceMeters / 1000).toStringAsFixed(1)} km';
    }
    return '${distanceMeters.round()} m';
  }

  String get prettyDuration {
    final mins = (durationSeconds / 60).round();
    if (mins < 60) return '$mins min';
    final h = mins ~/ 60;
    final m = mins % 60;
    return m == 0 ? '${h}h' : '${h}h ${m}m';
  }
}

/// Thin wrapper over the Mapbox Directions REST API. Uses its own `Dio` so the
/// app's auth interceptor (which targets the FieldGuard backend) is not
/// applied to external calls.
class MapboxDirectionsService {
  MapboxDirectionsService._() : _dio = Dio();
  static final MapboxDirectionsService instance = MapboxDirectionsService._();

  static const _baseUrl = 'https://api.mapbox.com/directions/v5/mapbox';

  final Dio _dio;

  /// Resolves the fastest route between two points. Defaults to the
  /// `driving-traffic` profile so the ETA reflects current traffic, matching
  /// Zomato/Uber-style behaviour.
  Future<RouteInfo> getRoute({
    required double srcLat,
    required double srcLng,
    required double dstLat,
    required double dstLng,
    String profile = 'driving-traffic',
  }) async {
    final token = dotenv.env['MAPBOX_PUBLIC_TOKEN'];
    if (token == null || token.isEmpty) {
      throw StateError('MAPBOX_PUBLIC_TOKEN missing from .env');
    }

    // Mapbox expects coordinates as `lng,lat;lng,lat` (note the order).
    final coords = '$srcLng,$srcLat;$dstLng,$dstLat';
    final url = '$_baseUrl/$profile/$coords';

    final response = await _dio.get<Map<String, dynamic>>(
      url,
      queryParameters: {
        'geometries': 'geojson',
        'overview': 'full',
        'access_token': token,
      },
    );

    final body = response.data;
    final routes = body?['routes'] as List?;
    if (routes == null || routes.isEmpty) {
      throw StateError('No route found between the given points.');
    }

    final route = routes.first as Map<String, dynamic>;
    final geometry = route['geometry'] as Map<String, dynamic>;
    final rawCoords = geometry['coordinates'] as List;

    return RouteInfo(
      coordinates: rawCoords
          .map((p) => (p as List).map((n) => (n as num).toDouble()).toList())
          .toList(),
      distanceMeters: (route['distance'] as num).toDouble(),
      durationSeconds: (route['duration'] as num).toDouble(),
    );
  }
}
