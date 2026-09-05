import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

import '../constants/api_config.dart';
import '../models/driver_model.dart';
import 'api_client.dart';
import 'auth_service.dart';

class DriverService {
  DriverService._();

  static Future<List<DriverModel>> getDrivers() async {
    final String server = await AuthService.server();
    final String? token = await AuthService.token();

    if (!ApiConfig.usesRemoteApi(server) || token == null || token.isEmpty) {
      return <DriverModel>[];
    }

    try {
      final Uri uri = ApiConfig.getUserDriversUri(server, token: token);
      final dynamic response = await ApiClient.get(uri, token: token);
      return _parseList(response);
    } catch (e, stack) {
      if (kDebugMode) {
        print('DriverService.getDrivers error: $e');
      }
      developer.log(
        'Failed to fetch drivers: $e',
        error: e,
        stackTrace: stack,
        name: 'DriverService',
      );
      return <DriverModel>[];
    }
  }

  static Future<bool> addDriver({
    required String name,
    required String phone,
    required String uniqueId,
  }) async {
    final String server = await AuthService.server();
    final String? token = await AuthService.token();

    if (!ApiConfig.usesRemoteApi(server) || token == null || token.isEmpty) {
      return false;
    }

    try {
      final Map<String, dynamic> response = await ApiClient.postJson(
        ApiConfig.addUserDriverUri(server),
        body: <String, dynamic>{
          'user_api_hash': token,
          'name': name,
          'phone': phone,
          'unique_id': uniqueId,
        },
        token: token,
      );
      return _isSuccess(response);
    } catch (e, stack) {
      developer.log(
        'Failed to add driver: $e',
        error: e,
        stackTrace: stack,
        name: 'DriverService',
      );
      return false;
    }
  }

  static List<DriverModel> _parseList(dynamic response) {
    final List<DriverModel> list = <DriverModel>[];
    _collectMaps(response, list);
    return list;
  }

  static void _collectMaps(dynamic node, List<DriverModel> target) {
    if (node is List) {
      for (final dynamic item in node) {
        _collectMaps(item, target);
      }
      return;
    }

    if (node is! Map) {
      return;
    }

    final Map<String, dynamic> map = node.map(
      (Object? k, Object? v) => MapEntry(k.toString(), v),
    );

    if (_looksLikeDriver(map)) {
      final DriverModel? model = DriverModel.fromJson(map);
      if (model != null) {
        target.add(model);
      }
      return;
    }

    for (final dynamic value in map.values) {
      if (value is List || value is Map) {
        _collectMaps(value, target);
      }
    }
  }

  static bool _looksLikeDriver(Map<String, dynamic> map) {
    return map.containsKey('name') ||
        map.containsKey('driver_name') ||
        (map.containsKey('phone') && map.containsKey('unique_id'));
  }

  static bool _isSuccess(Map<String, dynamic> response) {
    if (response['success'] == true) {
      return true;
    }
    final dynamic status = response['status'];
    if (status == 1 || status == '1' || status == true) {
      return true;
    }
    return response.isEmpty;
  }
}
