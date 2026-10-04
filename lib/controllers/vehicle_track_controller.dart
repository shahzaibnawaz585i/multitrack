import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/scheduler.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../models/gps_fix.dart';
import '../models/vehicle_model.dart';
import '../services/gps_filter_service.dart';
import '../services/live_route_service.dart';
import '../services/road_route_service.dart';
import '../utils/vehicle_track_animator.dart';
import '../utils/vehicle_speed_utils.dart';

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
      centerOnMarker: true,
      followLerp: 0.35,
      lookAheadMeters: 0,
      zoom: 16.0,
      tilt: 0.0,
      rotateWithVehicle: true,
    );
  }

  final int? deviceId;

  late final GpsFilterService _filter;
  late final VehicleTrackAnimator _animator;
  late final NavigationCamera navCamera;

  bool _disposed = false;
  VehicleMotionState _motion = VehicleMotionState.stopped;
  int _fixSequence = 0;
  int _routeRequestId = 0;
  DateTime? _lastIngestWallClock;
  Future<GpsIngestResult>? _ingestChain;
  static const Duration _defaultPollSpan = Duration(milliseconds: 2500);

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

  /// Queues [fix] for smooth interpolation (FIFO) — see [VehicleTrackAnimator].
  Future<GpsIngestResult> ingestFix({
    required GpsFix fix,
    List<LatLng> tailHint = const <LatLng>[],
  }) async {
    if (_disposed) {
      return GpsIngestResult.unchanged;
    }
    final Future<GpsIngestResult> chained = (_ingestChain ??
            Future<GpsIngestResult>.value(GpsIngestResult.unchanged))
        .then((_) => _ingestFixNow(fix: fix, tailHint: tailHint));
    _ingestChain = chained;
    return chained;
  }

  Future<GpsIngestResult> _ingestFixNow({
    required GpsFix fix,
    required List<LatLng> tailHint,
  }) async {
    if (_disposed) {
      return GpsIngestResult.unchanged;
    }

    _motion = _resolveMotion(fix.speedKmh);

    final GpsFix? previousFix = _filter.lastAccepted;

    final GpsFilterResult result = _filter.evaluate(fix);
    final LatLng from = _animator.displayPosition;
    GpsFix accepted;
    if (result.rejected || result.fix == null) {
      final double visualToFix =
          LiveRouteService.haversineMeters(from, fix.position);
      final bool coastCatchUp = visualToFix >= 45.0 ||
          (visualToFix >= 1.5 &&
              (fix.speedKmh > 0.5 || _motion == VehicleMotionState.moving));
      if (!coastCatchUp) {
        return GpsIngestResult.rejected;
      }
      accepted = fix;
      _filter.syncAcceptedPosition(fix.position, speedKmh: fix.speedKmh);
    } else {
      accepted = result.fix!;
    }

    final LatLng to = accepted.position;
    final double dist = LiveRouteService.haversineMeters(from, to);

    if (dist >= 350) {
      final double bearing = _resolveBearing(
        from,
        to,
        tailHint,
        _animator.displayBearing,
      );
      _animator.snapTo(
        to,
        bearing: bearing,
        freezeBearing: accepted.speedKmh <= 0.5,
      );
      _filter.syncAcceptedPosition(to, speedKmh: accepted.speedKmh);
      _motion = _resolveMotion(accepted.speedKmh);
      return GpsIngestResult.snapped;
    }

    if ((dist >= 18 && accepted.speedKmh > 2.0 && _animator.queuedSegments > 0) ||
        dist >= 120) {
      catchUpToServer(
        to,
        speedKmh: accepted.speedKmh,
        tailHint: tailHint,
      );
      return GpsIngestResult.animated;
    }

    if (dist < 0.15) {
      _motion = _resolveMotion(accepted.speedKmh);
      return GpsIngestResult.unchanged;
    }

    _motion = dist > 0.8 ? VehicleMotionState.moving : VehicleMotionState.idle;

    // Sync path only — no network wait on the live poll path (prevents long freezes).
    List<LatLng> roadPath = RoadRouteService.pathAlongDeviceTail(
      from: from,
      to: to,
      tail: tailHint,
    );
    if (roadPath.length < 2) {
      final List<LatLng>? cached = RoadRouteService.cachedRouteBetween(from, to);
      if (cached != null && cached.length >= 2) {
        roadPath = cached;
      } else {
        roadPath = LiveRouteService.dedupe(<LatLng>[from, to]);
      }
    }
    roadPath = _clipPathTowardTarget(roadPath, to);

    if (_disposed) {
      return GpsIngestResult.unchanged;
    }

    final Duration duration = _animationDuration(
      roadPath,
      accepted,
      previousFix,
    );

    final bool moving = accepted.speedKmh > 0.5 || dist > 2.0;
    if (!moving) {
      _animator.enqueueCoordinate(
        to,
        duration: const Duration(milliseconds: 400),
        moving: false,
      );
      return GpsIngestResult.animated;
    }

    if (roadPath.length <= 2) {
      _animator.enqueueCoordinate(
        to,
        duration: duration,
        moving: true,
        maxStepMeters: 6,
      );
      if (dist >= 12.0) {
        _fetchRoadPathAndEnqueue(
          from: from,
          to: to,
          tailHint: tailHint,
          duration: duration,
          speedKmh: accepted.speedKmh,
        );
      }
    } else {
      _animator.enqueueRoadPath(
        roadPath,
        duration: duration,
        moving: true,
        speedKmh: accepted.speedKmh,
      );
    }
    return GpsIngestResult.animated;
  }

  void _fetchRoadPathAndEnqueue({
    required LatLng from,
    required LatLng to,
    required List<LatLng> tailHint,
    required Duration duration,
    required double speedKmh,
  }) {
    final int requestId = ++_routeRequestId;
    unawaited(() async {
      final List<LatLng> routed = await RoadRouteService.routeBetween(
        from: from,
        to: to,
        tailHint: tailHint,
      );
      if (_disposed || requestId != _routeRequestId) {
        return;
      }
      if (routed.length < 3) {
        return;
      }
      final List<LatLng> clipped = _clipPathTowardTarget(routed, to);
      if (clipped.length < 3) {
        return;
      }
      final double driftMeters = LiveRouteService.haversineMeters(
        _animator.displayPosition,
        to,
      );
      if (driftMeters < 2.0) {
        return;
      }
      _animator.enqueueRoadPath(
        clipped,
        duration: duration,
        moving: true,
        speedKmh: speedKmh,
      );
    }());
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

    final double speedKmh = VehicleSpeed.effectiveKmh(vehicle);

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
    double pollMs = _defaultPollSpan.inMilliseconds.toDouble();
    if (_lastIngestWallClock != null) {
      pollMs = now
          .difference(_lastIngestWallClock!)
          .inMilliseconds
          .toDouble()
          .clamp(2500, 12000);
    }
    _lastIngestWallClock = now;

    if (fix.speedKmh <= 0.5 && meters < 4) {
      return const Duration(milliseconds: 400);
    }

    final double speedKmh = fix.speedKmh > 1.0
        ? fix.speedKmh
        : (_motion == VehicleMotionState.moving ? 28.0 : 12.0);
    final double mps = math.max(speedKmh / 3.6, 1.4);
    int physicsMs = (meters / mps * 1000).round().clamp(320, 18000);

    final int windowMs = (pollMs * 0.5).round().clamp(800, 2200);
    int durationMs = math.max(physicsMs, windowMs);
    if (durationMs > 2200) {
      durationMs = 2200;
    }
    if (durationMs < 320) {
      durationMs = 320;
    }

    final int backlog = _animator.queuedSegments;
    if (backlog > 0) {
      durationMs = (durationMs / (backlog + 1)).round().clamp(280, durationMs);
    }
    return Duration(milliseconds: durationMs);
  }

  /// When the marker lags the server fix (common on mobile), fast-forward visually.
  void catchUpToServer(
    LatLng serverPosition, {
    required double speedKmh,
    List<LatLng> tailHint = const <LatLng>[],
  }) {
    if (_disposed) return;
    final LatLng from = _animator.displayPosition;
    final double lagMeters =
        LiveRouteService.haversineMeters(from, serverPosition);
    if (lagMeters < 25) {
      return;
    }

    if (lagMeters >= 800) {
      final double bearing = _resolveBearing(
        from,
        serverPosition,
        tailHint,
        _animator.displayBearing,
      );
      _animator.snapTo(
        serverPosition,
        bearing: bearing,
        freezeBearing: speedKmh <= 0.5,
      );
      _filter.syncAcceptedPosition(serverPosition, speedKmh: speedKmh);
      return;
    }

    List<LatLng> path = RoadRouteService.pathAlongDeviceTail(
      from: from,
      to: serverPosition,
      tail: tailHint,
    );
    if (path.length < 2) {
      path = LiveRouteService.dedupe(<LatLng>[from, serverPosition]);
    }
    path = _clipPathTowardTarget(path, serverPosition);

    double pathMeters = 0;
    for (int i = 0; i < path.length - 1; i++) {
      pathMeters += LiveRouteService.haversineMeters(path[i], path[i + 1]);
    }

    final double mps = math.max(speedKmh / 3.6, 2.0);
    int ms = (pathMeters / mps * 1000).round().clamp(350, 1600);
    if (lagMeters > 40) {
      ms = (ms * 0.65).round().clamp(300, 1200);
    }

    _filter.syncAcceptedPosition(serverPosition, speedKmh: speedKmh);
    _animator.catchUpToward(
      serverPosition,
      duration: Duration(milliseconds: ms),
      moving: speedKmh > 0.5,
    );
  }

  static List<LatLng> _clipPathTowardTarget(List<LatLng> path, LatLng to) {
    if (path.length < 2) {
      return path;
    }
    int endIdx = path.length - 1;
    double endDist = LiveRouteService.haversineMeters(path[endIdx], to);
    for (int i = 0; i < path.length; i++) {
      final double d = LiveRouteService.haversineMeters(path[i], to);
      if (d < endDist) {
        endDist = d;
        endIdx = i;
      }
    }
    final List<LatLng> out = path.sublist(0, endIdx + 1);
    if (LiveRouteService.haversineMeters(out.last, to) > 0.35) {
      out.add(to);
    }
    return LiveRouteService.dedupe(out);
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
