import '../models/vehicle_model.dart';

/// Helpers to avoid unnecessary list/map rebuilds when vehicle data is unchanged.
class VehicleRefreshUtils {
  VehicleRefreshUtils._();

  static bool listDisplayChanged(
    List<VehicleModel> previous,
    List<VehicleModel> next,
  ) {
    if (previous.length != next.length) return true;

    for (int i = 0; i < previous.length; i++) {
      if (vehicleDisplayChanged(previous[i], next[i])) {
        return true;
      }
    }
    return false;
  }

  static bool vehicleDisplayChanged(VehicleModel a, VehicleModel b) {
    return a.id != b.id ||
        a.name != b.name ||
        a.status != b.status ||
        a.speed != b.speed ||
        a.location != b.location ||
        a.time != b.time ||
        a.liveTime != b.liveTime ||
        a.distance != b.distance ||
        a.odometer != b.odometer ||
        a.latitude != b.latitude ||
        a.longitude != b.longitude;
  }

  static Map<String, int> computeStatusCounts(List<VehicleModel> vehicles) {
    int running = 0;
    int idle = 0;
    int stopped = 0;
    int expired = 0;
    int inactive = 0;

    for (final VehicleModel vehicle in vehicles) {
      final String value = vehicle.status.trim().toLowerCase();
      if (value == 'running') {
        running++;
      } else if (value == 'idle') {
        idle++;
      } else if (value == 'stopped') {
        stopped++;
      } else if (value == 'expired') {
        expired++;
      } else if (value == 'inactive' || value == 'not reporting') {
        inactive++;
      }
    }

    return <String, int>{
      'all': vehicles.length,
      'running': running,
      'idle': idle,
      'stopped': stopped,
      'expired': expired,
      'inactive': inactive,
    };
  }

  static List<VehicleModel> filterVehicles({
    required List<VehicleModel> vehicles,
    required String selectedFilter,
    required String searchQuery,
  }) {
    final String query = searchQuery.trim().toLowerCase();

    return vehicles.where((VehicleModel vehicle) {
      if (!_matchesFilter(vehicle, selectedFilter)) {
        return false;
      }
      if (query.isEmpty) {
        return true;
      }
      return vehicle.name.toLowerCase().contains(query) ||
          vehicle.location.toLowerCase().contains(query) ||
          vehicle.status.toLowerCase().contains(query);
    }).toList(growable: false);
  }

  static bool _matchesFilter(VehicleModel vehicle, String selectedFilter) {
    final String status = vehicle.status.trim().toLowerCase();
    if (selectedFilter == 'all') return true;
    if (selectedFilter == 'inactive') {
      return status == 'inactive' || status == 'not reporting';
    }
    if (selectedFilter == 'expired') return status == 'expired';
    return status == selectedFilter;
  }
}
