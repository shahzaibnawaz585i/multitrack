import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:math' as math;

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import 'tracking_api_service.dart';

class HistoryPoint {
  const HistoryPoint({
    required this.position,
    this.time,
    this.speed,
    this.address,
  });

  final LatLng position;
  final DateTime? time;
  final double? speed;
  final String? address;
}

class HistoryRoute {
  const HistoryRoute({
    required this.points,
    this.distanceKm,
    this.durationLabel,
    this.avgSpeed,
  });

  final List<HistoryPoint> points;
  final double? distanceKm;
  final String? durationLabel;
  final double? avgSpeed;

  bool get isEmpty => points.isEmpty;
}

class HistoryService {
  HistoryService._();

  static final DateFormat _apiFormat = DateFormat('yyyy-MM-dd HH:mm:ss');

  static String formatForApi(DateTime value) => _apiFormat.format(value);

  static Future<HistoryRoute> getRoute({
    required int deviceId,
    required DateTime from,
    required DateTime to,
  }) async {
    try {
      final dynamic response = await TrackingApiService.getHistory(
        deviceId: deviceId,
        from: formatForApi(from),
        to: formatForApi(to),
      );
      final HistoryRoute raw = _parse(response);
      if (raw.points.length < 2) return raw;

      // Snap GPS points onto real roads using OSRM (free, no API key needed)
      final List<HistoryPoint> snapped = await _snapToRoads(raw.points);
      return HistoryRoute(
        points: snapped,
        distanceKm: raw.distanceKm,
        durationLabel: raw.durationLabel,
        avgSpeed: raw.avgSpeed,
      );
    } catch (e, stack) {
      developer.log('HistoryService.getRoute failed: $e', error: e, stackTrace: stack);
      return const HistoryRoute(points: <HistoryPoint>[]);
    }
  }

  /// Snaps a list of GPS points onto real road network using the free OSRM API.
  /// Processes in batches of 100 to stay within URL length limits.
  static Future<List<HistoryPoint>> _snapToRoads(
    List<HistoryPoint> points,
  ) async {
    const int batchSize = 100;
    if (points.length < 2) return points;

    // Thin out points to avoid too many similar coordinates (max 500 total)
    final List<HistoryPoint> thinned = _thinPoints(points, maxCount: 500);

    final List<HistoryPoint> result = <HistoryPoint>[];
    int i = 0;

    while (i < thinned.length) {
      final int end = math.min(i + batchSize, thinned.length);
      final List<HistoryPoint> batch = thinned.sublist(i, end);

      try {
        final List<HistoryPoint> snappedBatch = await _osrmMatch(batch);
        // Avoid duplicate point where batches join
        if (result.isNotEmpty && snappedBatch.isNotEmpty) {
          result.addAll(snappedBatch.sublist(1));
        } else {
          result.addAll(snappedBatch);
        }
      } catch (e) {
        developer.log('OSRM batch $i-$end failed, using raw GPS: $e');
        result.addAll(batch);
      }

      // Overlap by 1 so batches connect seamlessly
      i = end - 1;
      if (i >= thinned.length - 1) break;
    }

    return result.isNotEmpty ? result : thinned;
  }

  /// Calls the OSRM match API for a single batch of GPS points.
  static Future<List<HistoryPoint>> _osrmMatch(
    List<HistoryPoint> points,
  ) async {
    if (points.length < 2) return points;

    // Build coordinate string: lon,lat;lon,lat;...
    final StringBuffer coords = StringBuffer();
    for (int i = 0; i < points.length; i++) {
      if (i > 0) coords.write(';');
      coords.write('${points[i].position.longitude},${points[i].position.latitude}');
    }

    // Use OSRM's route service (more reliable than match for tracking data)
    final Uri uri = Uri.parse(
      'https://router.project-osrm.org/route/v1/driving/$coords'
      '?overview=full&geometries=geojson',
    );

    final http.Response response = await http
        .get(uri, headers: <String, String>{'Accept': 'application/json'})
        .timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      throw Exception('OSRM returned ${response.statusCode}');
    }

    final Map<String, dynamic> data =
        json.decode(response.body) as Map<String, dynamic>;

    final String code = (data['code'] as String?) ?? '';
    if (code != 'Ok') {
      throw Exception('OSRM code: $code');
    }

    final List<dynamic> routes = data['routes'] as List<dynamic>;
    if (routes.isEmpty) throw Exception('OSRM: no routes');

    final Map<String, dynamic> routeMap =
        routes.first as Map<String, dynamic>;
    final Map<String, dynamic> geometry =
        routeMap['geometry'] as Map<String, dynamic>;
    final List<dynamic> coordinates =
        geometry['coordinates'] as List<dynamic>;

    // Convert [lon, lat] pairs back to HistoryPoints
    final List<HistoryPoint> snapped = <HistoryPoint>[];
    for (final dynamic coord in coordinates) {
      final List<dynamic> pair = coord as List<dynamic>;
      final double lon = (pair[0] as num).toDouble();
      final double lat = (pair[1] as num).toDouble();
      snapped.add(HistoryPoint(position: LatLng(lat, lon)));
    }

    return snapped;
  }

  /// Reduces point count while preserving the overall shape (Douglas-Peucker-like thinning).
  static List<HistoryPoint> _thinPoints(
    List<HistoryPoint> points, {
    required int maxCount,
  }) {
    if (points.length <= maxCount) return points;
    final int step = (points.length / maxCount).ceil();
    final List<HistoryPoint> thinned = <HistoryPoint>[];
    for (int i = 0; i < points.length; i++) {
      if (i % step == 0 || i == points.length - 1) {
        thinned.add(points[i]);
      }
    }
    return thinned;
  }

  static HistoryRoute _parse(dynamic response) {
    final List<HistoryPoint> points = <HistoryPoint>[];
    _collectPoints(response, points);

    double? distanceKm;
    String? durationLabel;
    double? avgSpeed;

    if (response is Map) {
      final Map<String, dynamic> map = response.map(
        (Object? k, Object? v) => MapEntry(k.toString(), v),
      );
      distanceKm = _parseDouble(map['distance'] ?? map['total_distance']);
      durationLabel = (map['duration'] ?? map['drive_duration'] ?? map['engine_hours'])
          ?.toString();
      avgSpeed = _parseDouble(map['avg_speed'] ?? map['average_speed'] ?? map['speed_avg']);
    }

    return HistoryRoute(
      points: points,
      distanceKm: distanceKm,
      durationLabel: durationLabel,
      avgSpeed: avgSpeed,
    );
  }

  static void _collectPoints(dynamic node, List<HistoryPoint> target) {
    if (node is List) {
      for (final dynamic item in node) {
        _collectPoints(item, target);
      }
      return;
    }

    if (node is! Map) {
      return;
    }

    final Map<String, dynamic> map = node.map(
      (Object? k, Object? v) => MapEntry(k.toString(), v),
    );

    final double? lat = _parseDouble(
      map['lat'] ?? map['latitude'] ?? map['y'],
    );
    final double? lng = _parseDouble(
      map['lng'] ?? map['longitude'] ?? map['lon'] ?? map['x'],
    );

    if (lat != null && lng != null && (lat != 0.0 || lng != 0.0)) {
      target.add(
        HistoryPoint(
          position: LatLng(lat, lng),
          time: _parseTime(map['time'] ?? map['timestamp'] ?? map['server_time']),
          speed: _parseDouble(map['speed']),
          address: (map['address'] ?? map['location'])?.toString(),
        ),
      );
      return;
    }

    for (final String key in <String>['items', 'data', 'history', 'points', 'route']) {
      if (map.containsKey(key)) {
        _collectPoints(map[key], target);
      }
    }
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(
      value.toString().replaceAll(RegExp(r'[^0-9.\-]'), ''),
    );
  }

  static DateTime? _parseTime(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is int) {
      if (value > 9999999999) {
        return DateTime.fromMillisecondsSinceEpoch(value);
      }
      return DateTime.fromMillisecondsSinceEpoch(value * 1000);
    }
    final String raw = value.toString().trim();
    if (raw.isEmpty) {
      return null;
    }
    try {
      return DateTime.parse(raw);
    } catch (_) {
      return null;
    }
  }
}
