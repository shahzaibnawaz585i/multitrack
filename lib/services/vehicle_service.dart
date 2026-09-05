import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';

import '../constants/api_config.dart';
import '../data/vehicle_data.dart';
import '../models/vehicle_model.dart';
import 'api_client.dart';
import 'auth_service.dart';
import 'reverse_geocoding_service.dart';

class VehicleService {
  VehicleService._();

  /// Fetches vehicles/devices from `{baseUrl}/api/get_devices`.
  /// Falls back to local/cached data if remote server is not configured or in case of error.
  static Future<List<VehicleModel>> getDevices({bool forceRefresh = false}) async {
    final String server = await AuthService.server();
    final String? token = await AuthService.token();

    if (!ApiConfig.usesRemoteApi(server)) {
      if (kDebugMode) {
        print('VehicleService: No remote baseUrl configured for $server. Using local VehicleData.');
      }
      return VehicleData.vehicles;
    }

    try {
      final Uri uri = ApiConfig.getDevicesUri(server, token: token);
      if (kDebugMode) {
        print('VehicleService: Fetching devices from $uri with token: $token');
      }

      final dynamic response = await ApiClient.get(uri, token: token);

      if (kDebugMode) {
        print('VehicleService: Response received: $response');
      }

      final List<VehicleModel> parsedDevices = _parseDevices(response);

      if (kDebugMode) {
        print('VehicleService: Parsed ${parsedDevices.length} devices');
      }

      VehicleData.vehicles = parsedDevices;

      if (parsedDevices.isNotEmpty) {
        // Asynchronously resolve text addresses for devices without street names
        _resolveMissingAddresses(parsedDevices, server: server, token: token);
      }

      return parsedDevices;
    } catch (e, stack) {
      if (kDebugMode) {
        print('VehicleService Error: $e');
      }
      developer.log(
        'Failed to fetch devices from get_devices API: $e',
        error: e,
        stackTrace: stack,
        name: 'VehicleService',
      );
      return VehicleData.vehicles;
    }
  }

  static void _resolveMissingAddresses(
    List<VehicleModel> devices, {
    required String server,
    String? token,
  }) {
    // Fire and forget batch reverse geocoding in background
    Future.microtask(() async {
      for (int i = 0; i < devices.length; i++) {
        final VehicleModel dev = devices[i];
        if (dev.location == 'Location not available' &&
            dev.latitude != null &&
            dev.longitude != null &&
            (dev.latitude != 0.0 || dev.longitude != 0.0)) {
          final String resolved = await ReverseGeocodingService.resolveAddress(
            lat: dev.latitude!,
            lng: dev.longitude!,
            server: server,
            token: token,
          );
          if (resolved.isNotEmpty && resolved != 'Location not available') {
            devices[i] = dev.copyWith(location: resolved);
          }
        }
      }
      VehicleData.vehicles = devices;
    });
  }

  static List<VehicleModel> _parseDevices(dynamic response) {
    final List<VehicleModel> devices = <VehicleModel>[];

    if (response is List) {
      for (final dynamic item in response) {
        if (item is Map<String, dynamic>) {
          _extractFromMap(item, devices);
        } else if (item is Map) {
          final Map<String, dynamic> converted = item.map(
            (Object? k, Object? v) => MapEntry(k.toString(), v),
          );
          _extractFromMap(converted, devices);
        }
      }
    } else if (response is Map<String, dynamic>) {
      _extractFromMap(response, devices);
    } else if (response is Map) {
      final Map<String, dynamic> converted = response.map(
        (Object? k, Object? v) => MapEntry(k.toString(), v),
      );
      _extractFromMap(converted, devices);
    }

    if (devices.isEmpty) {
      return devices;
    }

    // Deduplicate in case groups overlap
    final Set<String> seen = <String>{};
    final List<VehicleModel> unique = <VehicleModel>[];
    for (int i = 0; i < devices.length; i++) {
      final VehicleModel v = devices[i];
      final String key = v.id != null
          ? 'id_${v.id}'
          : (v.name.isNotEmpty ? 'name_${v.name}' : 'idx_$i');
      if (!seen.contains(key)) {
        seen.add(key);
        unique.add(v);
      }
    }

    return unique;
  }

  static void _extractFromMap(
    Map<String, dynamic> map,
    List<VehicleModel> targetList,
  ) {
    // 1. If it is a group containing an 'items' list or map
    if (map.containsKey('items')) {
      final dynamic items = map['items'];
      if (items is List) {
        for (final dynamic subItem in items) {
          if (subItem is Map) {
            final Map<String, dynamic> subMap = subItem.map(
              (Object? k, Object? v) => MapEntry(k.toString(), v),
            );
            _extractFromMap(subMap, targetList);
          }
        }
        return;
      } else if (items is Map) {
        for (final dynamic subItem in items.values) {
          if (subItem is Map) {
            final Map<String, dynamic> subMap = subItem.map(
              (Object? k, Object? v) => MapEntry(k.toString(), v),
            );
            _extractFromMap(subMap, targetList);
          }
        }
        return;
      }
    }

    // 2. If it contains a 'devices' list or map
    if (map.containsKey('devices')) {
      final dynamic devices = map['devices'];
      if (devices is List) {
        for (final dynamic subItem in devices) {
          if (subItem is Map) {
            final Map<String, dynamic> subMap = subItem.map(
              (Object? k, Object? v) => MapEntry(k.toString(), v),
            );
            _extractFromMap(subMap, targetList);
          }
        }
        return;
      } else if (devices is Map) {
        for (final dynamic subItem in devices.values) {
          if (subItem is Map) {
            final Map<String, dynamic> subMap = subItem.map(
              (Object? k, Object? v) => MapEntry(k.toString(), v),
            );
            _extractFromMap(subMap, targetList);
          }
        }
        return;
      }
    }

    // 3. If it contains a 'data' list or map
    if (map.containsKey('data')) {
      final dynamic data = map['data'];
      if (data is List) {
        for (final dynamic subItem in data) {
          if (subItem is Map) {
            final Map<String, dynamic> subMap = subItem.map(
              (Object? k, Object? v) => MapEntry(k.toString(), v),
            );
            _extractFromMap(subMap, targetList);
          }
        }
        return;
      } else if (data is Map) {
        for (final dynamic subItem in data.values) {
          if (subItem is Map) {
            final Map<String, dynamic> subMap = subItem.map(
              (Object? k, Object? v) => MapEntry(k.toString(), v),
            );
            _extractFromMap(subMap, targetList);
          }
        }
        return;
      }
    }

    // 4. Check if this map represents a single device
    if (map.containsKey('device_data') ||
        map.containsKey('lat') ||
        map.containsKey('latitude') ||
        map.containsKey('imei') ||
        map.containsKey('device_name') ||
        map.containsKey('plate_number') ||
        (map.containsKey('name') && !map.containsKey('items'))) {
      targetList.add(VehicleModel.fromJson(map));
      return;
    }

    // 5. If map contains nested maps or lists (e.g. numeric keys {"0": {...}, "1": {...}})
    for (final dynamic val in map.values) {
      if (val is Map) {
        final Map<String, dynamic> subMap = val.map(
          (Object? k, Object? v) => MapEntry(k.toString(), v),
        );
        _extractFromMap(subMap, targetList);
      } else if (val is List) {
        for (final dynamic subVal in val) {
          if (subVal is Map) {
            final Map<String, dynamic> subMap = subVal.map(
              (Object? k, Object? v) => MapEntry(k.toString(), v),
            );
            _extractFromMap(subMap, targetList);
          }
        }
      }
    }
  }
}
