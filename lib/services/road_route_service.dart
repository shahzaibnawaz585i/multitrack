import 'dart:convert';

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

import '../constants/app_config.dart';
import '../utils/polyline_utils.dart';
import 'live_route_service.dart';

/// Resolves road-following coordinate paths between GPS fixes.
///
/// Priority:
/// 1. Device tail points from GPS server (already road-snapped on backend)
/// 2. Google Directions API (when configured, rate-limited)
/// 3. Last resort: direct segment (only if routing unavailable)
class RoadRouteService {
  RoadRouteService._();

  static final Map<String, List<LatLng>> _routeCache = <String, List<LatLng>>{};
  static DateTime? _lastDirectionsCall;
  static const Duration _directionsCooldown = Duration(seconds: 4);
  static const int _maxCacheEntries = 64;

  static Future<List<LatLng>> routeBetween({
    required LatLng from,
    required LatLng to,
    List<LatLng> tailHint = const <LatLng>[],
  }) async {
    final String cacheKey = _cacheKey(from, to);
    final List<LatLng>? cached = _routeCache[cacheKey];
    if (cached != null && cached.length >= 2) {
      return cached;
    }

    final List<LatLng> fromTail = _extractTailSegment(from, to, tailHint);
    if (fromTail.length >= 2) {
      final List<LatLng> result = LiveRouteService.dedupe(fromTail);
      _storeCache(cacheKey, result);
      return result;
    }

    final double directDist = LiveRouteService.haversineMeters(from, to);
    if (directDist < 60.0) {
      final List<LatLng> fallback = LiveRouteService.dedupe(<LatLng>[from, to]);
      _storeCache(cacheKey, fallback);
      return fallback;
    }

    final List<LatLng>? directions = await _fetchGoogleDirections(from, to);
    if (directions != null && directions.length >= 2) {
      final List<LatLng> result = LiveRouteService.dedupe(directions);
      _storeCache(cacheKey, result);
      return result;
    }

    final List<LatLng> fallback =
        LiveRouteService.dedupe(<LatLng>[from, to]);
    _storeCache(cacheKey, fallback);
    return fallback;
  }

  static void _storeCache(String key, List<LatLng> route) {
    if (_routeCache.length >= _maxCacheEntries) {
      _routeCache.remove(_routeCache.keys.first);
    }
    _routeCache[key] = route;
  }

  static String _cacheKey(LatLng from, LatLng to) {
    return '${from.latitude.toStringAsFixed(4)},${from.longitude.toStringAsFixed(4)}'
        '->${to.latitude.toStringAsFixed(4)},${to.longitude.toStringAsFixed(4)}';
  }

  static List<LatLng> _extractTailSegment(
    LatLng from,
    LatLng to,
    List<LatLng> tail,
  ) {
    if (tail.length < 2) return <LatLng>[];

    final int startIdx = _nearestIndex(from, tail);
    final List<LatLng> sub = <LatLng>[from];
    for (int i = startIdx + 1; i < tail.length; i++) {
      if (LiveRouteService.haversineMeters(sub.last, tail[i]) > 0.5 &&
          LiveRouteService.haversineMeters(to, tail[i]) > 0.5) {
        sub.add(tail[i]);
      }
    }
    if (LiveRouteService.haversineMeters(sub.last, to) > 0.2) {
      sub.add(to);
    }
    return sub;
  }

  static int _nearestIndex(LatLng point, List<LatLng> path) {
    int best = 0;
    double bestDist = double.infinity;
    for (int i = 0; i < path.length; i++) {
      final double d = LiveRouteService.haversineMeters(point, path[i]);
      if (d < bestDist) {
        bestDist = d;
        best = i;
      }
    }
    return best;
  }

  static Future<List<LatLng>?> _fetchGoogleDirections(
    LatLng from,
    LatLng to,
  ) async {
    final String key = AppConfig.googleMapsApiKey.trim();
    if (key.isEmpty) return null;

    final DateTime now = DateTime.now();
    if (_lastDirectionsCall != null &&
        now.difference(_lastDirectionsCall!) < _directionsCooldown) {
      return null;
    }
    _lastDirectionsCall = now;

    final Uri uri = Uri.https(
      'maps.googleapis.com',
      '/maps/api/directions/json',
      <String, String>{
        'origin': '${from.latitude},${from.longitude}',
        'destination': '${to.latitude},${to.longitude}',
        'mode': 'driving',
        'key': key,
      },
    );

    try {
      final http.Response response =
          await http.get(uri).timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) return null;

      final dynamic decoded = jsonDecode(response.body);
      if (decoded is! Map) return null;
      if (decoded['status']?.toString() != 'OK') return null;

      final dynamic routes = decoded['routes'];
      if (routes is! List || routes.isEmpty) return null;

      final dynamic overview = routes.first['overview_polyline'];
      if (overview is! Map) return null;
      final String? encoded = overview['points']?.toString();
      if (encoded == null || encoded.isEmpty) return null;

      return PolylineUtils.decode(encoded);
    } catch (_) {
      return null;
    }
  }
}
