import 'dart:developer' as developer;

import 'package:google_maps_flutter/google_maps_flutter.dart';
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
      return _parse(response);
    } catch (e, stack) {
      developer.log('HistoryService.getRoute failed: $e', error: e, stackTrace: stack);
      return const HistoryRoute(points: <HistoryPoint>[]);
    }
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
