import 'dart:collection';
import 'dart:math' as math;

import 'package:flutter/animation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../services/live_route_service.dart';

/// Animates a vehicle marker along road coordinate paths (never straight GPS jumps).
class VehicleTrackAnimator {
  VehicleTrackAnimator({required TickerProvider vsync})
    : _segmentCtrl = AnimationController(vsync: vsync) {
    _segmentCtrl.addListener(_onSegmentTick);
    _segmentCtrl.addStatusListener(_onSegmentStatus);
  }

  final AnimationController _segmentCtrl;
  final Queue<_PathJob> _pathQueue = Queue<_PathJob>();
  final List<LatLng> trailPoints = <LatLng>[];

  List<LatLng> _activePath = <LatLng>[];
  LatLng _displayPosition = const LatLng(0, 0);
  double _displayBearing = 0.0;
  double _frozenBearing = 0.0;
  bool _bearingFrozen = false;
  bool _initialized = false;
  bool _disposed = false;

  void Function(LatLng position, double bearing)? onSegmentFrame;

  LatLng get displayPosition => _displayPosition;
  double get displayBearing => _displayBearing;
  bool get isAnimating => !_disposed && _segmentCtrl.isAnimating;
  bool get isDisposed => _disposed;

  void seed(LatLng start, {double bearing = 0.0}) {
    if (_disposed) return;
    _displayPosition = start;
    _displayBearing = bearing;
    _frozenBearing = bearing;
    trailPoints
      ..clear()
      ..add(start);
    _initialized = true;
  }

  void seedRoadPath(List<LatLng> path, {required double speedKmh}) {
    if (_disposed || path.length < 2) {
      if (path.isNotEmpty) seed(path.first);
      return;
    }

    _segmentCtrl.stop();
    _pathQueue.clear();
    _activePath = <LatLng>[];

    _displayPosition = path.first;
    _displayBearing = _bearing(path.first, path[1]);
    _frozenBearing = _displayBearing;
    // Trail starts at current position only — animation appends points to avoid
    // drawing the full bootstrap path twice (static + animated overlap).
    trailPoints
      ..clear()
      ..add(path.first);
    _initialized = true;

    _enqueuePath(path, _durationForPath(path, speedKmh), speedKmh > 1.0);
  }

  /// Clears the rendered trail polyline for this vehicle.
  void clearTrail() {
    if (_disposed) return;
    trailPoints.clear();
    if (_displayPosition.latitude != 0 || _displayPosition.longitude != 0) {
      trailPoints.add(_displayPosition);
    }
  }

  /// Instantly draws the green trail from server tail — no animation jump.
  void seedTrailFromPoints(List<LatLng> points) {
    if (_disposed || points.isEmpty) return;
    final List<LatLng> deduped = LiveRouteService.dedupe(points);
    trailPoints
      ..clear()
      ..addAll(deduped);
    _displayPosition = deduped.last;
    if (deduped.length >= 2) {
      _displayBearing = _bearing(deduped[deduped.length - 2], deduped.last);
      _frozenBearing = _displayBearing;
    }
    _initialized = true;
  }

  void enqueueRoadPath(
    List<LatLng> path, {
    required Duration duration,
    required bool moving,
    double speedKmh = 0.0,
  }) {
    if (_disposed || path.length < 2) return;
    if (!_initialized) {
      seed(path.first, bearing: _bearing(path.first, path.last));
    }

    _bearingFrozen = !moving;
    if (!moving) {
      _displayPosition = path.last;
      _commitTrailPoint(path.last);
      onSegmentFrame?.call(_displayPosition, _frozenBearing);
      return;
    }

    final List<LatLng> cleaned = <LatLng>[_displayPosition];
    for (int i = 0; i < path.length; i++) {
      if (LiveRouteService.haversineMeters(cleaned.last, path[i]) > 0.4) {
        cleaned.add(path[i]);
      }
    }
    if (cleaned.length < 2) {
      cleaned.add(path.last);
    }

    _segmentCtrl.stop();
    _pathQueue.clear();
    _enqueuePath(cleaned, duration, true);
  }

  void snapTo(LatLng fix, {double? bearing, bool freezeBearing = false}) {
    if (_disposed) return;
    _segmentCtrl.stop();
    _pathQueue.clear();
    _activePath = <LatLng>[];
    _displayPosition = fix;
    if (bearing != null) {
      _displayBearing = bearing;
      _frozenBearing = bearing;
    }
    _bearingFrozen = freezeBearing;
    _commitTrailPoint(fix);
    onSegmentFrame?.call(_displayPosition, _displayBearing);
  }

  List<LatLng>? _samplingPath;
  List<double>? _segmentLengths;
  double _pathTotalLength = 0.0;

  void _invalidateSamplingCache() {
    _samplingPath = null;
    _segmentLengths = null;
    _pathTotalLength = 0.0;
  }

  void _ensureSamplingCache(List<LatLng> path) {
    if (identical(_samplingPath, path) && _segmentLengths != null) {
      return;
    }
    _samplingPath = path;
    _segmentLengths = <double>[];
    _pathTotalLength = 0.0;
    for (int i = 0; i < path.length - 1; i++) {
      final double len = LiveRouteService.haversineMeters(path[i], path[i + 1]);
      _segmentLengths!.add(len);
      _pathTotalLength += len;
    }
  }

  List<LatLng> trailSnapshot() {
    if (trailPoints.length < 2) return <LatLng>[];
    return List<LatLng>.unmodifiable(trailPoints);
  }

  /// Trail for display — ends slightly behind the vehicle so the green line
  /// stays behind the fixed center arrow (Google Maps nav style).
  List<LatLng> trailDisplaySnapshot() {
    if (trailPoints.length < 2) return <LatLng>[];
    final List<LatLng> out = List<LatLng>.from(trailPoints);
    final LatLng behind = _offsetMeters(
      _displayPosition,
      (_displayBearing + 180) % 360,
      10.0,
    );
    out[out.length - 1] = behind;
    return List<LatLng>.unmodifiable(out);
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _segmentCtrl.removeListener(_onSegmentTick);
    _segmentCtrl.removeStatusListener(_onSegmentStatus);
    _segmentCtrl.stop();
    _segmentCtrl.dispose();
    _pathQueue.clear();
    onSegmentFrame = null;
  }

  void _enqueuePath(List<LatLng> path, Duration duration, bool moving) {
    _pathQueue.add(_PathJob(points: path, duration: duration, moving: moving));
    if (!_segmentCtrl.isAnimating) {
      _startNextPath();
    }
  }

  void _startNextPath() {
    if (_disposed || _pathQueue.isEmpty) return;
    final _PathJob job = _pathQueue.removeFirst();
    _invalidateSamplingCache();
    _activePath = job.points;
    _bearingFrozen = !job.moving;
    _segmentCtrl
      ..duration = job.duration
      ..forward(from: 0);
  }

  void _onSegmentTick() {
    if (_disposed || _activePath.length < 2) return;

    final double t = Curves.linear.transform(_segmentCtrl.value);
    final _PathSample sample = _samplePath(_activePath, t);
    _displayPosition = sample.position;

    if (_bearingFrozen) {
      _displayBearing = _frozenBearing;
    } else {
      _displayBearing = lerpAngleShortest(
        _displayBearing,
        sample.bearing,
        0.35,
      );
      _frozenBearing = _displayBearing;
    }

    _updateTrailTip(_displayPosition);
    onSegmentFrame?.call(_displayPosition, _displayBearing);
  }

  void _onSegmentStatus(AnimationStatus status) {
    if (_disposed || status != AnimationStatus.completed) return;
    if (_activePath.isNotEmpty) {
      _commitTrailPoint(_activePath.last);
    }
    if (_pathQueue.isNotEmpty) {
      _startNextPath();
    }
  }

  Duration _durationForPath(List<LatLng> path, double speedKmh) {
    double meters = 0;
    for (int i = 0; i < path.length - 1; i++) {
      meters += LiveRouteService.haversineMeters(path[i], path[i + 1]);
    }
    final double mps = math.max(speedKmh, 4.0) / 3.6;
    return Duration(
      milliseconds: (meters / mps * 1000).round().clamp(400, 12000),
    );
  }

  _PathSample _samplePath(List<LatLng> path, double t) {
    if (path.length < 2) {
      return _PathSample(path.first, _displayBearing);
    }

    _ensureSamplingCache(path);
    final List<double> segLens = _segmentLengths!;
    final double total = _pathTotalLength;
    if (total <= 0.01) {
      return _PathSample(path.last, _displayBearing);
    }

    double remaining = t * total;
    for (int i = 0; i < segLens.length; i++) {
      if (remaining <= segLens[i] || i == segLens.length - 1) {
        final double frac = segLens[i] <= 0 ? 0 : remaining / segLens[i];
        final LatLng a = path[i];
        final LatLng b = path[i + 1];
        return _PathSample(
          LatLng(
            a.latitude + (b.latitude - a.latitude) * frac,
            a.longitude + (b.longitude - a.longitude) * frac,
          ),
          _bearing(a, b),
        );
      }
      remaining -= segLens[i];
    }
    return _PathSample(path.last, _bearing(path[path.length - 2], path.last));
  }

  void _commitTrailPoint(LatLng point) {
    if (trailPoints.isEmpty ||
        LiveRouteService.haversineMeters(trailPoints.last, point) >= 0.5) {
      trailPoints.add(point);
    } else {
      trailPoints[trailPoints.length - 1] = point;
    }
    _trimTrail(maxPoints: 200);
  }

  void _updateTrailTip(LatLng tip) {
    if (trailPoints.isEmpty) {
      trailPoints.add(tip);
      return;
    }
    if (LiveRouteService.haversineMeters(trailPoints.last, tip) > 0.35) {
      trailPoints.add(tip);
    } else {
      trailPoints[trailPoints.length - 1] = tip;
    }
  }

  void _trimTrail({required int maxPoints}) {
    if (trailPoints.length <= maxPoints) return;
    trailPoints.removeRange(0, trailPoints.length - maxPoints);
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

  static double lerpAngleShortest(double from, double to, double t) {
    final double diff = (to - from + 540) % 360 - 180;
    return (from + diff * t + 360) % 360;
  }

  static LatLng _offsetMeters(LatLng origin, double bearingDeg, double meters) {
    const double mPerDegLat = 111319.5;
    final double mPerDegLng =
        mPerDegLat * math.cos(origin.latitude * math.pi / 180);
    final double rad = bearingDeg * math.pi / 180.0;
    return LatLng(
      origin.latitude + meters * math.cos(rad) / mPerDegLat,
      origin.longitude + meters * math.sin(rad) / mPerDegLng,
    );
  }
}

class _PathJob {
  const _PathJob({
    required this.points,
    required this.duration,
    required this.moving,
  });

  final List<LatLng> points;
  final Duration duration;
  final bool moving;
}

class _PathSample {
  const _PathSample(this.position, this.bearing);

  final LatLng position;
  final double bearing;
}

/// Smooth navigation camera — keeps vehicle near bottom-center of visible map.
class NavigationCamera {
  NavigationCamera({
    this.followLerp = 0.12,
    this.lookAheadMeters = 75.0,
    this.zoom = 18.0,
    this.tilt = 0.0,
  });

  final double followLerp;
  final double lookAheadMeters;
  final double zoom;
  final double tilt;

  LatLng _target = const LatLng(0, 0);
  double _bearing = 0.0;
  bool _initialized = false;

  CameraPosition cameraFor(LatLng car, double bearing) {
    if (!_initialized) {
      _target = _offsetTarget(car, bearing);
      _bearing = bearing;
      _initialized = true;
    } else {
      final LatLng desired = _offsetTarget(car, bearing);
      _target = LatLng(
        _target.latitude + (desired.latitude - _target.latitude) * followLerp,
        _target.longitude +
            (desired.longitude - _target.longitude) * followLerp,
      );
      _bearing = VehicleTrackAnimator.lerpAngleShortest(
        _bearing,
        bearing,
        followLerp,
      );
    }

    return CameraPosition(
      target: _target,
      zoom: zoom,
      bearing: _bearing,
      tilt: tilt,
    );
  }

  void reset(LatLng car, double bearing) {
    _target = _offsetTarget(car, bearing);
    _bearing = bearing;
    _initialized = true;
  }

  LatLng _offsetTarget(LatLng car, double bearing) {
    const double mPerDegLat = 111319.5;
    final double mPerDegLng =
        mPerDegLat * math.cos(car.latitude * math.pi / 180);
    final double backBearing = (bearing + 180) % 360;
    final double rad = backBearing * math.pi / 180.0;
    return LatLng(
      car.latitude + lookAheadMeters * math.cos(rad) / mPerDegLat,
      car.longitude + lookAheadMeters * math.sin(rad) / mPerDegLng,
    );
  }
}
