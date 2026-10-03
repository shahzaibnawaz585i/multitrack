import '../models/vehicle_model.dart';
import 'vehicle_detail_fast_api_service.dart';
import 'vehicle_service.dart';

/// Live telemetry for vehicle detail sheet (`GET /api/get_devices`).
class VehicleDetailTelemetryService {
  VehicleDetailTelemetryService._();

  /// Network refresh with cache-first fallback.
  static Future<VehicleModel?> loadLive(int deviceId) {
    return VehicleDetailFastApiService.refreshLiveDevice(
      deviceId,
      allowNetwork: true,
    );
  }

  static VehicleModel? cached(int deviceId) {
    return VehicleService.findCachedDevice(deviceId);
  }
}
