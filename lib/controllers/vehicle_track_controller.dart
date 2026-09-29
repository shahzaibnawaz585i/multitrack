import 'dart:math' as math;

import 'package:flutter/scheduler.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../models/gps_fix.dart';
import '../models/vehicle_model.dart';
import '../services/gps_filter_service.dart';
import '../services/live_route_service.dart';
import '../services/road_route_service.dart';
import '../utils/vehicle_track_animator.dart';

enum GpsIngestResult { wrongDevice, rejected, snapped, animated, unchanged }

/// Orchestrates GPS filtering, road routing, marker animation, and camera state.
///
/// Each instance is bound to a single [deviceId] so GPS/trail state never mixes
/// between vehicles.
class VehicleTrackController {
  VehicleTrackController({
    required TickerProvider vsync,
    required this.deviceId,
  }) {
    _filter = GpsFilterService();
    _animator = VehicleTrackAnimator(vsync: vsync);
    navCamera = NavigationCamera(
      followLerp: 0.18,
      lookAheadMeters: 55.0,
      zoom: 18.0,
      tilt: 0.0,
    );
  }

  final int? deviceId;

  late final GpsFilterService _filter;
  late final VehicleTrackAnimator _animator;
  late final NavigationCamera navCamera;

  bool _disposed = false;
  VehicleMotionState _motion = VehicleMotionState.stopped;
  int _fixSequence = 0;
  DateTime? _lastIngestWallClock;
  static const Duration _defaultPollSpan = Duration(milliseconds: 2000);

  VehicleTrackAnimator get animator => _animator;
  VehicleMotionState get motionState => _motion;
  GpsFix? get lastValidFix => _filter.lastAccepted;

  set onFrame(void Function(LatLng position, double bearing)? callback) {
    _animator.onSegmentFrame = callback;
  }

  GpsFix _nextFix({required LatLng position, required double speedKmh}) {
    _fixSequence += 1;
    return GpsFix(
      position: position,
      timestamp: DateTime.now(),
      speedKmh: speedKmh,
      sequence: _fixSequence,
    );
  }

  void seed(LatLng start, {double bearing = 0.0}) {
    _animator.seed(start, bearing: bearing);
    _filter.reset(seed: _nextFix(position: start, speedKmh: 0));
  }

  Future<void> seedRoadPath(
    List<LatLng> path, {
    required double speedKmh,
  }) async {
    if (_disposed || path.isEmpty) return;
    final List<LatLng> deduped = LiveRouteService.dedupe(path);
    _animator.seedRoadPath(deduped, speedKmh: speedKmh);
    // Filter must match animator start — not the path end — or the first live
    // polls reject fixes as backward/stale while the marker is still animating.
    _filter.reset(
      seed: _nextFix(position: deduped.first, speedKmh: speedKmh),
    );
  }

  /// Primary entry point for live GPS updates from any transport layer.
  Future<GpsIngestResult> ingestFix({
    required GpsFix fix,
    List<LatLng> tailHint = const <LatLng>[],
  }) async {
    if (_disposed) return GpsIngestResult.unchanged;

    _motion = _resolveMotion(fix.speedKmh);

    final GpsFix? previousFix = _filter.lastAccepted;

    final GpsFilterResult result = _filter.evaluate(fix);
    if (result.rejected || result.fix == null) {
      return GpsIngestResult.rejected;
    }

    final GpsFix accepted = result.fix!;
    final LatLng from = _animator.displayPosition;
    final LatLng to = accepted.position;
    final double dist = LiveRouteService.haversineMeters(from, to);

    if (dist < 0.3) {
      return GpsIngestResult.unchanged;
    }

    _motion = dist > 0.8 ? VehicleMotionState.moving : VehicleMotionState.idle;

    try {
      final List<LatLng> roadPath = await RoadRouteService.routeBetween(
        from: from,
        to: to,
        tailHint: tailHint,
      );

      if (_disposed) return GpsIngestResult.unchanged;

      final Duration duration = _animationDuration(
        roadPath,
        accepted,
        previousFix,
      );

      final double effectiveSpeedKmh = accepted.speedKmh > 0
          ? accepted.speedKmh
          : math.max(4.0, (dist / (duration.inMilliseconds / 1000.0)) * 3.6);

      _animator.enqueueRoadPath(
        roadPath,
        duration: duration,
        moving: true,
        speedKmh: effectiveSpeedKmh,
      );
      return GpsIngestResult.animated;
    } catch (_) {
      _animator.snapTo(
        to,
        bearing: _resolveBearing(from, to, tailHint, _animator.displayBearing),
      );
      return GpsIngestResult.snapped;
    }
  }

  Future<GpsIngestResult> ingestVehicleModel(VehicleModel vehicle) async {
    if (_disposed || vehicle.latitude == null || vehicle.longitude == null) {
      return GpsIngestResult.unchanged;
    }

    if (deviceId != null && vehicle.id != deviceId) {
      return GpsIngestResult.wrongDevice;
    }

    final List<LatLng> tail = vehicle.tail
        .map((VehicleTrackPoint p) => LatLng(p.latitude, p.longitude))
        .toList();

    final double speedKmh = double.tryParse(vehicle.speed) ?? 0.0;

    return ingestFix(
      fix: _nextFix(
        position: LatLng(vehicle.latitude!, vehicle.longitude!),
        speedKmh: speedKmh,
      ),
      tailHint: tail,
    );
  }

  /// Applies a server position when filtering rejected but the marker drifted.
  void forceSnapTo(LatLng position, {required double bearing}) {
    if (_disposed) return;
    _animator.snapTo(
      position,
      bearing: bearing,
      freezeBearing: _motion != VehicleMotionState.moving,
    );
    _filter.reset(seed: _nextFix(position: position, speedKmh: 0));
  }

  static double _resolveBearing(
    LatLng from,
    LatLng to,
    List<LatLng> tailHint,
    double fallback,
  ) {
    if (LiveRouteService.haversineMeters(from, to) >= 1.0) {
      return _bearing(from, to);
    }
    if (tailHint.length >= 2) {
      return _bearing(tailHint[tailHint.length - 2], tailHint.last);
    }
    return fallback;
  }

  static double _bearing(LatLng from, LatLng to) {
    final double lat1 = from.latitude * math.pi / 180;
    final double lat2 = to.latitude * math.pi / 180;
    final double dLng = (to.longitude - from.longitude) * math.pi / 180;
    final double y = math.sin(dLng) * math.cos(lat2);
    final double x =
        math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLng);
    return (math.atan2(y, x) * 180 / math.pi + 360) % 360;
  }

  Duration _animationDuration(
    List<LatLng> path,
    GpsFix fix,
    GpsFix? previousFix,
  ) {
    double meters = 0;
    for (int i = 0; i < path.length - 1; i++) {
      meters += LiveRouteService.haversineMeters(path[i], path[i + 1]);
    }

    final DateTime now = DateTime.now();
    if (_lastIngestWallClock != null) {
      final double wallMs = now
          .difference(_lastIngestWallClock!)
          .inMilliseconds
          .toDouble();
      _lastIngestWallClock = now;
      if (wallMs >= 400) {
        return Duration(
          milliseconds: (wallMs * 1.05).round().clamp(1200, 5000),
        );
      }
    } else {
      _lastIngestWallClock = now;
    }

    if (previousFix != null) {
      final double dtMs = fix.timestamp
          .difference(previousFix.timestamp)
          .inMilliseconds
          .toDouble();
      if (dtMs >= 400) {
        return Duration(milliseconds: (dtMs * 1.05).round().clamp(1200, 5000));
      }
    }

    final double mps = (fix.speedKmh <= 0 ? 8.0 : fix.speedKmh) / 3.6;
    return Duration(
      milliseconds: (meters / mps * 1000).round().clamp(
        1200,
        _defaultPollSpan.inMilliseconds + 500,
      ),
    );
  }

  static VehicleMotionState _resolveMotion(double speedKmh) {
    if (speedKmh <= 0.5) return VehicleMotionState.stopped;
    if (speedKmh <= 3.0) return VehicleMotionState.idle;
    return VehicleMotionState.moving;
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _animator.dispose();
  }
}
