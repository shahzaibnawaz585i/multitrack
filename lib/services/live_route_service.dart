import 'dart:math' as math;

import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../models/vehicle_model.dart';
import 'history_service.dart';

/// Builds live road paths from GPS server data (`get_devices` tail + `get_history`).
class LiveRouteService {
  LiveRouteService._();

  /// Recent route points for smooth arrow movement when detail screen opens.
  static Future<List<LatLng>> bootstrapRoute({
    required int deviceId,
    List<VehicleTrackPoint> tail = const <VehicleTrackPoint>[],
    Duration historyWindow = const Duration(minutes: 3),
  }) async {
    List<LatLng> points = tail
        .map((VehicleTrackPoint p) => LatLng(p.latitude, p.longitude))
        .toList();

    if (points.length < 4) {
      final HistoryRoute route = await HistoryService.getRoute(
        deviceId: deviceId,
        from: DateTime.now().subtract(historyWindow),
        to: DateTime.now(),
      );
      if (route.points.isNotEmpty) {
        points = <LatLng>[
          ...points,
          ...route.points.map((HistoryPoint p) => p.position),
        ];
      }
    }

    return dedupe(points);
  }

  /// Points ahead of [current] on [path] — arrow starts moving immediately.
  static List<LatLng> queueAhead({
    required List<LatLng> path,
    required LatLng current,
  }) {
    if (path.isEmpty) {
      return <LatLng>[];
    }

    int nearestIdx = 0;
    double nearestDist = double.infinity;
    for (int i = 0; i < path.length; i++) {
      final double d = haversineMeters(current, path[i]);
      if (d < nearestDist) {
        nearestDist = d;
        nearestIdx = i;
      }
    }

    final List<LatLng> ahead = <LatLng>[];
    for (int i = nearestIdx + 1; i < path.length; i++) {
      if (haversineMeters(current, path[i]) > 0.4) {
        ahead.add(path[i]);
      }
    }

    if (ahead.isEmpty && nearestIdx < path.length - 1) {
      ahead.add(path.last);
    }
    return ahead;
  }

  static List<LatLng> dedupe(List<LatLng> raw) {
    final List<LatLng> out = <LatLng>[];
    for (final LatLng point in raw) {
      if (out.isEmpty || haversineMeters(out.last, point) > 0.4) {
        out.add(point);
      }
    }
    return out;
  }

  static double haversineMeters(LatLng a, LatLng b) {
    const double r = 6371000;
    final double lat1 = a.latitude * math.pi / 180;
    final double lat2 = b.latitude * math.pi / 180;
    final double dLat = (b.latitude - a.latitude) * math.pi / 180;
    final double dLng = (b.longitude - a.longitude) * math.pi / 180;
    final double s = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1) *
            math.cos(lat2) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    return r * 2 * math.atan2(math.sqrt(s), math.sqrt(1 - s));
  }
}
