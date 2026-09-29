import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/api_config.dart';
import '../data/vehicle_data.dart';
import '../models/notification_model.dart';
import '../models/vehicle_model.dart';
import '../utils/coordinate_parser.dart';
import 'api_client.dart';
import 'auth_service.dart';
import 'live_notification_controller.dart';
import 'reverse_geocoding_service.dart';

class _VehicleStateSnapshot {
  final String status;
  final double speed;

  const _VehicleStateSnapshot({
    required this.status,
    required this.speed,
  });
}

class VehicleService {
  VehicleService._();

  static Future<List<VehicleModel>>? _inFlight;
  static DateTime? _lastSuccessfulFetch;
  static const Duration _cacheTtl = Duration(seconds: 30);
  static const String _diskCacheKey = 'vehicle_service_get_devices_v1';
  static const String _diskCacheTimeKey = 'vehicle_service_get_devices_time_v1';
  static bool _geocodingInFlight = false;
  static const int _maxGeocodePerFetch = 24;
  static final Map<String, _VehicleStateSnapshot> _previousStates =
      <String, _VehicleStateSnapshot>{};

  /// Resets vehicle baseline tracker (call on logout).
  static void resetBaseline() {
    _previousStates.clear();
  }

  /// Clears in-memory + on-disk fleet (logout).
  static void clearFleetCache() {
    _inFlight = null;
    _lastSuccessfulFetch = null;
    VehicleData.assignVehicles(<VehicleModel>[]);
    unawaited(_clearPersistedFleet());
  }

  /// Last successful [get_devices] payload — show list instantly after app restart.
  static Future<void> restorePersistedFleet() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? raw = prefs.getString(_diskCacheKey);
      if (raw == null || raw.isEmpty) {
        return;
      }
      final dynamic decoded = jsonDecode(raw);
      final List<VehicleModel> parsed = _parseDevices(decoded);
      if (parsed.isEmpty) {
        return;
      }
      VehicleData.assignVehicles(parsed);
      final int? savedMs = prefs.getInt(_diskCacheTimeKey);
      if (savedMs != null) {
        _lastSuccessfulFetch = DateTime.fromMillisecondsSinceEpoch(savedMs);
      }
    } catch (e, stack) {
      developer.log(
        'restorePersistedFleet failed: $e',
        error: e,
        stackTrace: stack,
        name: 'VehicleService',
      );
    }
  }

  static Future<void> _persistFleetResponse(dynamic response) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString(_diskCacheKey, jsonEncode(response));
      await prefs.setInt(
        _diskCacheTimeKey,
        DateTime.now().millisecondsSinceEpoch,
      );
    } catch (_) {}
  }

  static Future<void> _clearPersistedFleet() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(_diskCacheKey);
    await prefs.remove(_diskCacheTimeKey);
  }

  /// Fetches vehicles/devices from `{baseUrl}/api/get_devices`.
  /// Falls back to local/cached data if remote server is not configured or in case of error.
  static Future<List<VehicleModel>> getDevices({bool forceRefresh = false}) async {
    if (!forceRefresh &&
        _lastSuccessfulFetch != null &&
        DateTime.now().difference(_lastSuccessfulFetch!) < _cacheTtl &&
        VehicleData.vehicles.isNotEmpty) {
      return VehicleData.vehicles;
    }

    if (_inFlight != null) {
      return _inFlight!;
    }

    final Future<List<VehicleModel>> request = _fetchDevices();
    _inFlight = request;
    try {
      return await request;
    } finally {
      if (identical(_inFlight, request)) {
        _inFlight = null;
      }
    }
  }

  static Future<List<VehicleModel>> _fetchDevices() async {
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

      await _persistFleetResponse(response);

      final List<VehicleModel> parsedDevices = _parseDevices(response);

      if (kDebugMode) {
        print('VehicleService: Parsed ${parsedDevices.length} devices');
      }

      VehicleData.assignVehicles(parsedDevices);

      if (parsedDevices.isNotEmpty) {
        // Detect live Ignition ON/OFF & OverSpeed transitions
        _detectVehicleStateChanges(parsedDevices);

        // Asynchronously resolve text addresses for devices without street names
        _resolveMissingAddresses(parsedDevices, server: server, token: token);
      }

      _lastSuccessfulFetch = DateTime.now();
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

  static void _detectVehicleStateChanges(List<VehicleModel> vehicles) {
    if (_previousStates.isEmpty) {
      // Baseline initialization: store initial status so no false alarms on startup
      for (final VehicleModel v in vehicles) {
        final String key = v.id != null ? 'id_${v.id}' : v.name;
        final double spd = _parseSpeedKmph(v.speed);
        _previousStates[key] = _VehicleStateSnapshot(
          status: v.status.toUpperCase(),
          speed: spd,
        );
      }
      return;
    }

    final DateTime now = DateTime.now();
    for (final VehicleModel v in vehicles) {
      final String key = v.id != null ? 'id_${v.id}' : v.name;
      final String currentStatus = v.status.toUpperCase();
      final double currentSpeed = _parseSpeedKmph(v.speed);

      final _VehicleStateSnapshot? prev = _previousStates[key];
      if (prev != null) {
        final String prevStatus = prev.status;
        final double prevSpeed = prev.speed;

        // 1. Ignition ON: Changed from STOPPED / NOT REPORTING to RUNNING or IDLE
        final bool wasOff = prevStatus == 'STOPPED' ||
            prevStatus == 'NOT REPORTING' ||
            prevStatus == 'INACTIVE' ||
            prevStatus == 'OFFLINE';
        final bool isNowOn = currentStatus == 'RUNNING' || currentStatus == 'IDLE';

        if (wasOff && isNowOn) {
          final AppNotification notif = AppNotification(
            id: v.id,
            vehicleId: v.name,
            eventTitle: 'Ignition On',
            location: v.location,
            timestamp: now,
            category: NotificationCategory.alerts,
            eventType: NotificationEventType.ignitionOn,
            latitude: v.latitude,
            longitude: v.longitude,
            speed: currentSpeed,
          );
          LiveNotificationController.instance.push(notif);
        }

        // 2. Ignition OFF: Changed from RUNNING or IDLE to STOPPED
        final bool wasOn = prevStatus == 'RUNNING' || prevStatus == 'IDLE';
        final bool isNowOff = currentStatus == 'STOPPED';

        if (wasOn && isNowOff) {
          final AppNotification notif = AppNotification(
            id: v.id,
            vehicleId: v.name,
            eventTitle: 'Ignition Off',
            location: v.location,
            timestamp: now,
            category: NotificationCategory.alerts,
            eventType: NotificationEventType.ignitionOff,
            latitude: v.latitude,
            longitude: v.longitude,
            speed: currentSpeed,
          );
          LiveNotificationController.instance.push(notif);
        }

        // 3. OverSpeed: Speed exceeds 80 km/h
        if (prevSpeed <= 80 && currentSpeed > 80) {
          final AppNotification notif = AppNotification(
            id: v.id,
            vehicleId: v.name,
            eventTitle: 'Device OverSpeed',
            location: v.location,
            timestamp: now,
            category: NotificationCategory.alerts,
            eventType: NotificationEventType.overSpeed,
            latitude: v.latitude,
            longitude: v.longitude,
            speed: currentSpeed,
          );
          LiveNotificationController.instance.push(notif);
        }
      }

      _previousStates[key] = _VehicleStateSnapshot(
        status: currentStatus,
        speed: currentSpeed,
      );
    }
  }

  static double _parseSpeedKmph(String speed) {
    return double.tryParse(speed.replaceAll(RegExp(r'[^\d.]'), '')) ?? 0.0;
  }

  static void _resolveMissingAddresses(
    List<VehicleModel> devices, {
    required String server,
    String? token,
  }) {
    if (_geocodingInFlight) return;
    _geocodingInFlight = true;

    Future.microtask(() async {
      try {
        int resolved = 0;
        for (int i = 0; i < devices.length; i++) {
          if (resolved >= _maxGeocodePerFetch) break;

          final VehicleModel dev = devices[i];
          final bool needsAddress = dev.location == 'Location not available' ||
              CoordinateParser.looksLikeCoordinatePair(dev.location);
          if (needsAddress &&
              dev.latitude != null &&
              dev.longitude != null &&
              (dev.latitude != 0.0 || dev.longitude != 0.0)) {
            final String address = await ReverseGeocodingService.resolveAddress(
              lat: dev.latitude!,
              lng: dev.longitude!,
              server: server,
              token: token,
            );
            resolved++;
            if (address.isNotEmpty && address != 'Location not available') {
              devices[i] = dev.copyWith(location: address);
            }
          }
        }
        VehicleData.assignVehicles(devices);
      } finally {
        _geocodingInFlight = false;
      }
    });
  }

  /// Resolves street address for [vehicle] when API only sent coordinates.
  static Future<String?> resolveAddressFor(VehicleModel vehicle) async {
    if (vehicle.latitude == null ||
        vehicle.longitude == null ||
        (vehicle.latitude == 0.0 && vehicle.longitude == 0.0)) {
      return null;
    }
    final String server = await AuthService.server();
    final String? token = await AuthService.token();
    final String address = await ReverseGeocodingService.resolveAddress(
      lat: vehicle.latitude!,
      lng: vehicle.longitude!,
      server: server,
      token: token,
    );
    if (address.isEmpty || address == 'Location not available') {
      return null;
    }
    return address;
  }

  /// Updates one vehicle in [VehicleData.vehicles] after geocode / fast refresh.
  static void patchCachedDevice(VehicleModel updated) {
    if (updated.id == null) {
      return;
    }
    final List<VehicleModel> list = List<VehicleModel>.from(VehicleData.vehicles);
    for (int i = 0; i < list.length; i++) {
      if (list[i].id == updated.id) {
        list[i] = updated;
        VehicleData.assignVehicles(list);
        return;
      }
    }
  }

  /// Returns a device from the in-memory cache without triggering a network call.
  static VehicleModel? findCachedDevice(int deviceId) {
    for (final VehicleModel vehicle in VehicleData.vehicles) {
      if (vehicle.id == deviceId) {
        return vehicle;
      }
    }
    return null;
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
