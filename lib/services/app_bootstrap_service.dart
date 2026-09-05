import '../data/vehicle_data.dart';
import '../models/vehicle_model.dart';
import 'alert_service.dart';
import 'auth_service.dart';
import 'vehicle_service.dart';

/// Prefetches shared app data after login or on dashboard load.
class AppBootstrapService {
  AppBootstrapService._();

  static Future<List<VehicleModel>> refreshVehicles({
    bool forceRefresh = true,
  }) async {
    return VehicleService.getDevices(forceRefresh: forceRefresh);
  }

  static Future<void> prefetchAfterLogin() async {
    if (!await AuthService.isLoggedIn()) {
      return;
    }
    await refreshVehicles(forceRefresh: true);
    await AlertService.getEvents(forceRefresh: true);
  }
}
