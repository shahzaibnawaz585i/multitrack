import '../data/vehicle_data.dart';
import '../models/notification_model.dart';
import '../models/vehicle_model.dart';
import 'coordinate_parser.dart';

class NotificationLocationText {
  NotificationLocationText._();

  static String resolve(AppNotification notification) {
    String location = notification.location.trim();

    if (_isGoodAddress(location)) {
      return location;
    }

    final VehicleModel? live = _matchVehicle(notification);
    if (live != null && _isGoodAddress(live.location)) {
      return live.location;
    }

    final double? lat = notification.latitude ?? live?.latitude;
    final double? lng = notification.longitude ?? live?.longitude;
    if (lat != null && lng != null && (lat != 0.0 || lng != 0.0)) {
      return 'Lat ${lat.toStringAsFixed(5)}, Lng ${lng.toStringAsFixed(5)}';
    }

    return 'Location not available';
  }

  static bool _isGoodAddress(String value) {
    if (value.isEmpty || value == 'Location not available') {
      return false;
    }
    return !CoordinateParser.looksLikeCoordinatePair(value);
  }

  static VehicleModel? _matchVehicle(AppNotification notification) {
    final String id = notification.vehicleId.trim().toLowerCase();
    if (id.isEmpty) {
      return null;
    }

    for (final VehicleModel vehicle in VehicleData.vehicles) {
      final String name = vehicle.name.trim().toLowerCase();
      if (name == id || name.contains(id) || id.contains(name)) {
        return vehicle;
      }
    }
    return null;
  }
}
