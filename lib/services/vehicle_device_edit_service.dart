import '../constants/api_config.dart';
import '../models/vehicle_model.dart';
import 'api_client.dart';
import 'auth_service.dart';
import 'vehicle_service.dart';

class VehicleDeviceEditService {
  VehicleDeviceEditService._();

  static Future<void> updateOdometer({
    required int deviceId,
    required double kilometers,
  }) async {
    final String formatted = '${kilometers.toStringAsFixed(2)} km';
    final VehicleModel? cached = VehicleService.findCachedDevice(deviceId);
    if (cached != null) {
      VehicleService.patchCachedDevice(
        cached.copyWith(odometer: formatted),
      );
    }

    final String? token = await AuthService.token();
    if (token == null || token.isEmpty) {
      throw const ApiException('Not logged in');
    }
    final String server = await AuthService.server();
    if (!ApiConfig.usesRemoteApi(server)) {
      return;
    }

    final Uri uri = ApiConfig.editDeviceUri(server);
    final String deviceName = cached?.name ?? '';
    final String kmRaw = kilometers.toStringAsFixed(2);

    final List<Map<String, dynamic>> bodies = <Map<String, dynamic>>[
      <String, dynamic>{
        'user_api_hash': token,
        'device_id': deviceId.toString(),
        'id': deviceId.toString(),
        'name': deviceName,
        'odometer': kmRaw,
      },
      <String, dynamic>{
        'user_api_hash': token,
        'device_id': deviceId.toString(),
        'odometer_value': kmRaw,
      },
      <String, dynamic>{
        'user_api_hash': token,
        'device_id': deviceId.toString(),
        'current_odometer': kmRaw,
      },
      <String, dynamic>{
        'user_api_hash': token,
        'device_id': deviceId.toString(),
        'total_distance': kmRaw,
      },
    ];

    Object? lastError;
    for (final Map<String, dynamic> body in bodies) {
      try {
        final dynamic response =
            await ApiClient.postFormRaw(uri, body: body, token: token);
        if (_isSuccess(response)) {
          await VehicleService.getDevices(forceRefresh: true);
          return;
        }
        if (response is Map && response['message'] != null) {
          lastError = response['message'];
        }
      } catch (e) {
        lastError = e;
      }
    }

    throw ApiException(
      lastError?.toString() ?? 'Could not update odometer',
    );
  }

  static Future<void> updateEngineNumber({
    required int deviceId,
    required String engineNumber,
  }) async {
    final String trimmed = engineNumber.trim();
    if (trimmed.isEmpty) {
      throw const ApiException('Please enter engine number');
    }

    final VehicleModel? cached = VehicleService.findCachedDevice(deviceId);
    if (cached != null) {
      VehicleService.patchCachedDevice(
        cached.copyWith(engineNumber: trimmed),
      );
    }

    final String? token = await AuthService.token();
    if (token == null || token.isEmpty) {
      throw const ApiException('Not logged in');
    }
    final String server = await AuthService.server();
    if (!ApiConfig.usesRemoteApi(server)) {
      return;
    }

    final Uri uri = ApiConfig.editDeviceUri(server);
    final String deviceName = cached?.name ?? '';

    final List<Map<String, dynamic>> bodies = <Map<String, dynamic>>[
      <String, dynamic>{
        'user_api_hash': token,
        'device_id': deviceId.toString(),
        'id': deviceId.toString(),
        'name': deviceName,
        'engine_number': trimmed,
      },
      <String, dynamic>{
        'user_api_hash': token,
        'device_id': deviceId.toString(),
        'engine_no': trimmed,
      },
      <String, dynamic>{
        'user_api_hash': token,
        'device_id': deviceId.toString(),
        'object_engine': trimmed,
      },
      <String, dynamic>{
        'user_api_hash': token,
        'device_id': deviceId.toString(),
        'engine_num': trimmed,
      },
    ];

    Object? lastError;
    for (final Map<String, dynamic> body in bodies) {
      try {
        final dynamic response =
            await ApiClient.postFormRaw(uri, body: body, token: token);
        if (_isSuccess(response)) {
          await VehicleService.getDevices(forceRefresh: true);
          return;
        }
        if (response is Map && response['message'] != null) {
          lastError = response['message'];
        }
      } catch (e) {
        lastError = e;
      }
    }

    throw ApiException(
      lastError?.toString() ?? 'Could not update engine number',
    );
  }

  static Future<void> assignDeviceGroup({
    required int deviceId,
    required int groupId,
    String? groupName,
  }) async {
    final VehicleModel? cached = VehicleService.findCachedDevice(deviceId);
    if (cached != null) {
      VehicleService.patchCachedDevice(
        cached.copyWith(
          groupId: groupId,
          groupName: groupName ?? cached.groupName,
        ),
      );
    }

    final String? token = await AuthService.token();
    if (token == null || token.isEmpty) {
      throw const ApiException('Not logged in');
    }
    final String server = await AuthService.server();
    if (!ApiConfig.usesRemoteApi(server)) {
      return;
    }

    final Uri uri = ApiConfig.editDeviceUri(server);
    final String deviceName = cached?.name ?? '';

    final List<Map<String, dynamic>> bodies = <Map<String, dynamic>>[
      <String, dynamic>{
        'user_api_hash': token,
        'device_id': deviceId.toString(),
        'id': deviceId.toString(),
        'name': deviceName,
        'group_id': groupId.toString(),
      },
      <String, dynamic>{
        'user_api_hash': token,
        'device_id': deviceId.toString(),
        'p_group_id': groupId.toString(),
      },
      <String, dynamic>{
        'user_api_hash': token,
        'device_id': deviceId.toString(),
        'device_group_id': groupId.toString(),
      },
      <String, dynamic>{
        'user_api_hash': token,
        'device_id': deviceId.toString(),
        'groups[]': groupId.toString(),
      },
    ];

    Object? lastError;
    for (final Map<String, dynamic> body in bodies) {
      try {
        final dynamic response =
            await ApiClient.postFormRaw(uri, body: body, token: token);
        if (_isSuccess(response)) {
          await VehicleService.getDevices(forceRefresh: true);
          return;
        }
        if (response is Map && response['message'] != null) {
          lastError = response['message'];
        }
      } catch (e) {
        lastError = e;
      }
    }

    throw ApiException(
      lastError?.toString() ?? 'Could not update device group',
    );
  }

  static Future<void> updateSpeedLimit({
    required int deviceId,
    required double limitKmph,
  }) async {
    if (limitKmph <= 0) {
      throw const ApiException('Please enter a valid speed limit');
    }
    final String raw = limitKmph.toStringAsFixed(
      limitKmph.truncateToDouble() == limitKmph ? 0 : 1,
    );
    await _updateNumericDeviceFields(
      deviceId: deviceId,
      patch: (VehicleModel d) => d.copyWith(speedLimitKmph: raw),
      bodies: (String token, String deviceName) => <Map<String, dynamic>>[
        <String, dynamic>{
          'user_api_hash': token,
          'device_id': deviceId.toString(),
          'id': deviceId.toString(),
          'name': deviceName,
          'speed_limit': raw,
        },
        <String, dynamic>{
          'user_api_hash': token,
          'device_id': deviceId.toString(),
          'overspeed': raw,
        },
        <String, dynamic>{
          'user_api_hash': token,
          'device_id': deviceId.toString(),
          'overspeed_limit': raw,
        },
        <String, dynamic>{
          'user_api_hash': token,
          'device_id': deviceId.toString(),
          'max_speed_limit': raw,
        },
      ],
      failureMessage: 'Could not update speed limit',
    );
  }

  static Future<void> updateFuelPricePerLiter({
    required int deviceId,
    required double price,
  }) async {
    if (price < 0) {
      throw const ApiException('Please enter a valid fuel cost');
    }
    final String raw = price.toStringAsFixed(2);
    await _updateNumericDeviceFields(
      deviceId: deviceId,
      patch: (VehicleModel d) => d.copyWith(fuelPricePerLiter: raw),
      bodies: (String token, String deviceName) => <Map<String, dynamic>>[
        <String, dynamic>{
          'user_api_hash': token,
          'device_id': deviceId.toString(),
          'id': deviceId.toString(),
          'name': deviceName,
          'fuel_price': raw,
        },
        <String, dynamic>{
          'user_api_hash': token,
          'device_id': deviceId.toString(),
          'fuel_cost_per_liter': raw,
        },
        <String, dynamic>{
          'user_api_hash': token,
          'device_id': deviceId.toString(),
          'cost_per_liter': raw,
        },
      ],
      failureMessage: 'Could not update fuel cost',
    );
  }

  static Future<void> updateEngineWorkCost({
    required int deviceId,
    required double cost,
  }) async {
    if (cost < 0) {
      throw const ApiException('Please enter a valid engine cost');
    }
    final String raw = cost.toStringAsFixed(2);
    await _updateNumericDeviceFields(
      deviceId: deviceId,
      patch: (VehicleModel d) => d.copyWith(engineWorkCost: raw),
      bodies: (String token, String deviceName) => <Map<String, dynamic>>[
        <String, dynamic>{
          'user_api_hash': token,
          'device_id': deviceId.toString(),
          'id': deviceId.toString(),
          'name': deviceName,
          'engine_work_cost': raw,
        },
        <String, dynamic>{
          'user_api_hash': token,
          'device_id': deviceId.toString(),
          'engine_work': raw,
        },
        <String, dynamic>{
          'user_api_hash': token,
          'device_id': deviceId.toString(),
          'engine_cost': raw,
        },
      ],
      failureMessage: 'Could not update engine cost',
    );
  }

  static Future<void> updateFuelMileage({
    required int deviceId,
    required double kmPerLiter,
  }) async {
    if (kmPerLiter <= 0) {
      throw const ApiException('Please enter a valid mileage');
    }
    final String raw = kmPerLiter.toStringAsFixed(
      kmPerLiter.truncateToDouble() == kmPerLiter ? 0 : 2,
    );
    final String label =
        raw.contains('km') ? raw : '$raw km/ltr';
    await _updateNumericDeviceFields(
      deviceId: deviceId,
      patch: (VehicleModel d) => d.copyWith(fuelMileage: label),
      bodies: (String token, String deviceName) => <Map<String, dynamic>>[
        <String, dynamic>{
          'user_api_hash': token,
          'device_id': deviceId.toString(),
          'id': deviceId.toString(),
          'name': deviceName,
          'fuel_mileage': raw,
        },
        <String, dynamic>{
          'user_api_hash': token,
          'device_id': deviceId.toString(),
          'mileage': raw,
        },
        <String, dynamic>{
          'user_api_hash': token,
          'device_id': deviceId.toString(),
          'fuel_economy': raw,
        },
      ],
      failureMessage: 'Could not update mileage',
    );
  }

  static Future<void> _updateNumericDeviceFields({
    required int deviceId,
    required VehicleModel Function(VehicleModel) patch,
    required List<Map<String, dynamic>> Function(
      String token,
      String deviceName,
    )
        bodies,
    required String failureMessage,
  }) async {
    final VehicleModel? cached = VehicleService.findCachedDevice(deviceId);
    if (cached != null) {
      VehicleService.patchCachedDevice(patch(cached));
    }

    final String? token = await AuthService.token();
    if (token == null || token.isEmpty) {
      throw const ApiException('Not logged in');
    }
    final String server = await AuthService.server();
    if (!ApiConfig.usesRemoteApi(server)) {
      return;
    }

    final Uri uri = ApiConfig.editDeviceUri(server);
    final String deviceName = cached?.name ?? '';
    final List<Map<String, dynamic>> attempts =
        bodies(token, deviceName);

    Object? lastError;
    for (final Map<String, dynamic> body in attempts) {
      try {
        final dynamic response =
            await ApiClient.postFormRaw(uri, body: body, token: token);
        if (_isSuccess(response)) {
          await VehicleService.getDevices(forceRefresh: true);
          return;
        }
        if (response is Map && response['message'] != null) {
          lastError = response['message'];
        }
      } catch (e) {
        lastError = e;
      }
    }

    throw ApiException(lastError?.toString() ?? failureMessage);
  }

  static bool _isSuccess(dynamic response) {
    if (response == null) {
      return false;
    }
    if (response is Map) {
      final dynamic status = response['status'];
      if (status == 1 || status == true || status == '1') {
        return true;
      }
      if (response['success'] == true) {
        return true;
      }
      if (response.containsKey('items')) {
        return true;
      }
      final String message = response['message']?.toString().toLowerCase() ?? '';
      if (message.contains('success') || message.contains('updated')) {
        return true;
      }
    }
    return false;
  }
}
