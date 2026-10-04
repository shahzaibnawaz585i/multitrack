import '../models/notification_model.dart';
import '../models/vehicle_model.dart';

/// Client-side checks so overspeed banners/notifications only fire while moving.
class LiveOverspeedGuard {
  LiveOverspeedGuard._();

  static const double defaultLimitKmph = 80;
  static const double minMovingKmph = 8;
  static const double parkedSpeedKmph = 3;

  static double limitKmphFor(VehicleModel vehicle) {
    final double configured =
        VehicleModel.parseSpeedKmh(vehicle.speedLimitKmph);
    return configured > 0 ? configured : defaultLimitKmph;
  }

  static bool isParked(VehicleModel vehicle) {
    final String status = vehicle.status.trim().toUpperCase();
    if (status == 'STOPPED' ||
        status == 'NOT REPORTING' ||
        status == 'EXPIRED' ||
        status == 'INACTIVE') {
      return true;
    }
    return VehicleModel.parseSpeedKmh(vehicle.speed) <= parkedSpeedKmph;
  }

  /// True when a live poll should trigger an overspeed notification.
  static bool shouldNotifyLiveTransition({
    required VehicleModel vehicle,
    required double previousSpeedKmph,
    required double currentSpeedKmh,
  }) {
    if (currentSpeedKmh <= minMovingKmph) {
      return false;
    }
    if (isParked(vehicle)) {
      return false;
    }
    final String status = vehicle.status.trim().toUpperCase();
    if (status != 'RUNNING' && currentSpeedKmh <= minMovingKmph) {
      return false;
    }
    final double limit = limitKmphFor(vehicle);
    return previousSpeedKmph <= limit && currentSpeedKmh > limit;
  }

  /// Filters server [get_events] overspeed rows when the device is parked now.
  static bool shouldPushApiOverSpeed(
    AppNotification notification, {
    VehicleModel? liveVehicle,
  }) {
    final double eventSpeed = notification.speed ?? 0;
    if (eventSpeed <= minMovingKmph) {
      return false;
    }

    if (liveVehicle == null) {
      return true;
    }

    // Device reads as parked now — ignore stale or spurious server overspeed rows.
    if (isParked(liveVehicle)) {
      return false;
    }

    return eventSpeed > limitKmphFor(liveVehicle);
  }

  static VehicleModel? matchVehicle(
    AppNotification notification,
    Iterable<VehicleModel> fleet,
  ) {
    if (notification.id != null) {
      for (final VehicleModel v in fleet) {
        if (v.id == notification.id) {
          return v;
        }
      }
    }
    final String target = notification.vehicleId.trim().toLowerCase();
    if (target.isEmpty) {
      return null;
    }
    for (final VehicleModel v in fleet) {
      final String name = v.name.trim().toLowerCase();
      if (name == target || name.contains(target) || target.contains(name)) {
        return v;
      }
    }
    return null;
  }
}
