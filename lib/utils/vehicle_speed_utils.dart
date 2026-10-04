import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../models/vehicle_model.dart';
import '../services/live_route_service.dart';

/// Live speed parsing/formatting shared by detail screen and track controller.
class VehicleSpeed {
  VehicleSpeed._();

  static const double _pollGapSeconds = 4.0;

  static double resolvedKmh(VehicleModel vehicle) {
    final double kmh = VehicleModel.parseSpeedKmh(vehicle.speed);
    return kmh < 0 ? 0 : kmh;
  }

  /// Server speed, or movement inferred from recent tail when API speed is stale/zero.
  static double effectiveKmh(VehicleModel vehicle) {
    double kmh = resolvedKmh(vehicle);
    if (kmh >= 3) {
      return kmh;
    }

    final double fromTail = _kmhFromTail(vehicle);
    if (fromTail > kmh) {
      kmh = fromTail;
    }

    final double fromCoords = _kmhFromCoordsVersusTail(vehicle);
    if (fromCoords > kmh) {
      kmh = fromCoords;
    }

    return kmh < 0 ? 0 : kmh;
  }

  static double _kmhFromTail(VehicleModel vehicle) {
    if (vehicle.tail.length < 2) {
      return 0;
    }
    final VehicleTrackPoint a = vehicle.tail[vehicle.tail.length - 2];
    final VehicleTrackPoint b = vehicle.tail.last;
    final double meters = LiveRouteService.haversineMeters(
      LatLng(a.latitude, a.longitude),
      LatLng(b.latitude, b.longitude),
    );
    if (meters < 2) {
      return 0;
    }
    return (meters / _pollGapSeconds) * 3.6;
  }

  static double _kmhFromCoordsVersusTail(VehicleModel vehicle) {
    if (vehicle.latitude == null ||
        vehicle.longitude == null ||
        vehicle.tail.isEmpty) {
      return 0;
    }
    final VehicleTrackPoint last = vehicle.tail.last;
    final double meters = LiveRouteService.haversineMeters(
      LatLng(last.latitude, last.longitude),
      LatLng(vehicle.latitude!, vehicle.longitude!),
    );
    if (meters < 3) {
      return 0;
    }
    return (meters / _pollGapSeconds) * 3.6;
  }

  static String formatLabel(double kmh) {
    if (kmh <= 0) {
      return '00';
    }
    return kmh.round().toString().padLeft(2, '0');
  }
}
