import '../models/driver_model.dart';
import '../models/vehicle_model.dart';
import 'driver_service.dart';
import 'vehicle_service.dart';

class VehicleDriverPhoneService {
  VehicleDriverPhoneService._();

  static Future<String> phoneForDevice(int deviceId) async {
    String? phone = _phoneFromFleet(deviceId);
    if (_isValid(phone)) {
      return phone!;
    }

    await VehicleService.getDevices(forceRefresh: false);
    phone = _phoneFromFleet(deviceId);
    if (_isValid(phone)) {
      return phone!;
    }

    final VehicleModel? device = VehicleService.findCachedDevice(deviceId);
    final int? driverId = device?.driverId;
    if (driverId != null) {
      final List<DriverModel> drivers = await DriverService.getDrivers();
      for (final DriverModel driver in drivers) {
        if (driver.id == driverId && _isValid(driver.phone)) {
          return driver.phone.trim();
        }
      }
    }

    await VehicleService.getDevices(forceRefresh: true);
    phone = _phoneFromFleet(deviceId);
    if (_isValid(phone)) {
      return phone!;
    }

    return '';
  }

  static String? _phoneFromFleet(int deviceId) {
    final VehicleModel? device = VehicleService.findCachedDevice(deviceId);
    if (device == null) {
      return null;
    }
    return device.driverPhone.trim();
  }

  static bool _isValid(String? value) {
    if (value == null) {
      return false;
    }
    final String digits = value.replaceAll(RegExp(r'\D'), '');
    return digits.length >= 7;
  }
}
