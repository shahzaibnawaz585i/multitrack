import '../models/vehicle_model.dart';
import 'vehicle_detail_api_service.dart';
import 'vehicle_service.dart';

/// Fast, cache-first loaders for [VehicleDetailScreen] (live + statistics prefetch).
class VehicleDetailFastApiService {
  VehicleDetailFastApiService._();

  static const Duration _minNetworkGap = Duration(seconds: 2);
  static final Map<int, DateTime> _lastNetworkByDevice = <int, DateTime>{};

  /// Opens detail: refresh fleet once + prefetch today statistics (non-blocking).
  static Future<void> prefetchForDetail(int deviceId) async {
    await refreshLiveDevice(deviceId, allowNetwork: true);
    final DateTime now = DateTime.now();
    VehicleDetailApiService.warmStatisticsCache(deviceId);
    VehicleDetailApiService.loadStatistics(
      deviceId: deviceId,
      from: DateTime(now.year, now.month, now.day),
      to: DateTime(now.year, now.month, now.day, 23, 59, 59, 999),
    );
  }

  /// Cache-first live row; hits network at most every [_minNetworkGap] per device.
  static Future<VehicleModel?> refreshLiveDevice(
    int deviceId, {
    required bool allowNetwork,
    bool resolveAddress = true,
    bool aggressiveNetwork = false,
  }) async {
    VehicleModel? device = VehicleService.findCachedDevice(deviceId);

    final DateTime now = DateTime.now();
    final DateTime? lastNet = _lastNetworkByDevice[deviceId];
    final bool mayUseNetwork = allowNetwork &&
        (aggressiveNetwork ||
            lastNet == null ||
            now.difference(lastNet) >= _minNetworkGap);

    if (mayUseNetwork) {
      _lastNetworkByDevice[deviceId] = now;
      final List<VehicleModel> fleet =
          await VehicleService.getDevices(forceRefresh: true);
      for (final VehicleModel d in fleet) {
        if (d.id == deviceId) {
          device = d;
          break;
        }
      }
    }

    device ??= VehicleService.findCachedDevice(deviceId);
    if (device == null) {
      return null;
    }

    if (resolveAddress && _needsStreetAddress(device)) {
      final String? address = await VehicleService.resolveAddressFor(device);
      if (address != null && address.isNotEmpty) {
        device = device.copyWith(location: address);
        VehicleService.patchCachedDevice(device);
      }
    }

    return device;
  }

  static bool _needsStreetAddress(VehicleModel device) {
    final String loc = device.location.trim();
    return loc.isEmpty ||
        loc == 'Location not available' ||
        _looksLikeCoords(loc);
  }

  static bool _looksLikeCoords(String value) {
    final RegExp pair = RegExp(r'^-?\d+\.?\d*\s*,\s*-?\d+\.?\d*$');
    return pair.hasMatch(value.trim());
  }
}
