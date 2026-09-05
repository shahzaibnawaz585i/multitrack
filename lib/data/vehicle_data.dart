import '../models/vehicle_model.dart';

class VehicleData {
  VehicleData._();

  static List<VehicleModel> vehicles = <VehicleModel>[];

  static List<VehicleModel> get vehicleList => vehicles;
}
