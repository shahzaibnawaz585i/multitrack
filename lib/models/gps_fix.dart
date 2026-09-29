import 'package:google_maps_flutter/google_maps_flutter.dart';

/// A single GPS observation from any source (REST, WebSocket, MQTT, etc.).
class GpsFix {
  const GpsFix({
    required this.position,
    required this.timestamp,
    this.speedKmh = 0.0,
    this.accuracyMeters,
    this.sequence = 0,
  });

  final LatLng position;
  final DateTime timestamp;
  final double speedKmh;
  final double? accuracyMeters;
  final int sequence;

  GpsFix copyWith({
    LatLng? position,
    DateTime? timestamp,
    double? speedKmh,
    double? accuracyMeters,
    int? sequence,
  }) {
    return GpsFix(
      position: position ?? this.position,
      timestamp: timestamp ?? this.timestamp,
      speedKmh: speedKmh ?? this.speedKmh,
      accuracyMeters: accuracyMeters ?? this.accuracyMeters,
      sequence: sequence ?? this.sequence,
    );
  }
}

enum VehicleMotionState { moving, idle, stopped, offline }

enum GpsRejectReason {
  invalidCoordinates,
  staleTimestamp,
  duplicate,
  backwardMovement,
  unrealisticJump,
  stationaryJitter,
}

class GpsFilterResult {
  const GpsFilterResult.accepted(this.fix)
      : rejected = false,
        reason = null;

  const GpsFilterResult.rejected(this.reason)
      : rejected = true,
        fix = null;

  final bool rejected;
  final GpsFix? fix;
  final GpsRejectReason? reason;
}
