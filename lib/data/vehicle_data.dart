import 'package:flutter/foundation.dart';

import '../models/vehicle_model.dart';

class VehicleData {
  VehicleData._();

  /// Bumps when [vehicles] is replaced (e.g. after geocoding live addresses).
  static final ValueNotifier<int> revision = ValueNotifier<int>(0);

  static void assignVehicles(List<VehicleModel> next) {
    vehicles = next;
    revision.value++;
  }

  /// Populated from [VehicleService.getDevices] after login — no demo vehicles.
  static List<VehicleModel> vehicles = <VehicleModel>[];

  static List<VehicleModel> get vehicleList => vehicles;
}
