import 'dart:math' as math;

import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../models/gps_fix.dart';
import 'live_route_service.dart';

/// Validates and filters raw GPS fixes before they enter the animation pipeline.
class GpsFilterService {
  GpsFilterService({
    this.stationaryJitterMeters = 5.0,
    this.minMoveMeters = 1.0,
    this.maxJumpMeters = 250.0,
    this.maxSpeedKmh = 220.0,
  });

  final double stationaryJitterMeters;
  final double minMoveMeters;
  final double maxJumpMeters;
  final double maxSpeedKmh;

  GpsFix? _lastAccepted;
  int _sequence = 0;

  GpsFix? get lastAccepted => _lastAccepted;

  void reset({GpsFix? seed}) {
    _lastAccepted = seed;
    _sequence = seed?.sequence ?? 0;
  }

  GpsFilterResult evaluate(GpsFix incoming) {
    if (!_isValidCoordinate(incoming.position)) {
      return const GpsFilterResult.rejected(GpsRejectReason.invalidCoordinates);
    }

    final GpsFix? prev = _lastAccepted;
    if (prev == null) {
      return _accept(incoming);
    }

    final double dist =
        LiveRouteService.haversineMeters(prev.position, incoming.position);

    if (dist < 0.2) {
      return const GpsFilterResult.rejected(GpsRejectReason.duplicate);
    }

    final double dtSec = math.max(
      (incoming.timestamp.difference(prev.timestamp).inMilliseconds).abs() / 1000.0,
      0.2,
    );

    final double impliedSpeedKmh = (dist / dtSec) * 3.6;
    if (impliedSpeedKmh > maxSpeedKmh && dist > maxJumpMeters) {
      return const GpsFilterResult.rejected(GpsRejectReason.unrealisticJump);
    }

    final bool stationary =
        incoming.speedKmh <= 0.5 && prev.speedKmh <= 0.5;
    if (stationary && dist < 1.0) {
      return const GpsFilterResult.rejected(GpsRejectReason.stationaryJitter);
    }

    return _accept(incoming);
  }

  GpsFilterResult _accept(GpsFix fix) {
    _sequence += 1;
    final GpsFix accepted = fix.copyWith(sequence: _sequence);
    _lastAccepted = accepted;
    return GpsFilterResult.accepted(accepted);
  }

  static bool _isValidCoordinate(LatLng p) {
    if (p.latitude.isNaN ||
        p.longitude.isNaN ||
        p.latitude.isInfinite ||
        p.longitude.isInfinite) {
      return false;
    }
    if (p.latitude.abs() > 90 || p.longitude.abs() > 180) {
      return false;
    }
    if (p.latitude == 0.0 && p.longitude == 0.0) {
      return false;
    }
    return true;
  }
}
