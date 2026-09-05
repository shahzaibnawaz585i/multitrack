import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../constants/api_config.dart';
import '../models/geofence_model.dart';
import 'api_client.dart';
import 'auth_service.dart';

class GeofenceService {
  GeofenceService._();

  static Future<List<GeofenceModel>> getGeofences() async {
    final String server = await AuthService.server();
    final String? token = await AuthService.token();

    if (!ApiConfig.usesRemoteApi(server) || token == null || token.isEmpty) {
      return <GeofenceModel>[];
    }

    try {
      final Uri uri = ApiConfig.getGeofencesUri(server, token: token);
      final dynamic response = await ApiClient.get(uri, token: token);
      return _parseList(response);
    } catch (e, stack) {
      if (kDebugMode) {
        print('GeofenceService.getGeofences error: $e');
      }
      developer.log(
        'Failed to fetch geofences: $e',
        error: e,
        stackTrace: stack,
        name: 'GeofenceService',
      );
      return <GeofenceModel>[];
    }
  }

  static Future<bool> addGeofence({
    required String name,
    required LatLng position,
    required double radiusMeters,
    required bool isCircular,
    String? address,
  }) async {
    final String server = await AuthService.server();
    final String? token = await AuthService.token();

    if (!ApiConfig.usesRemoteApi(server) || token == null || token.isEmpty) {
      return false;
    }

    try {
      final Map<String, dynamic> body = <String, dynamic>{
        'user_api_hash': token,
        'name': name,
        'type': isCircular ? 'circle' : 'polygon',
        'radius': radiusMeters.toStringAsFixed(2),
        'lat': position.latitude.toString(),
        'lng': position.longitude.toString(),
        'center[lat]': position.latitude.toString(),
        'center[lng]': position.longitude.toString(),
        'coordinates':
            '${position.latitude} ${position.longitude}',
        if (address != null && address.isNotEmpty) 'address': address,
      };

      final Map<String, dynamic> response = await ApiClient.postJson(
        ApiConfig.addGeofenceUri(server),
        body: body,
        token: token,
      );
      return _isSuccess(response);
    } catch (e, stack) {
      developer.log(
        'Failed to add geofence: $e',
        error: e,
        stackTrace: stack,
        name: 'GeofenceService',
      );
      return false;
    }
  }

  static Future<bool> editGeofence({
    required int id,
    required String name,
    required LatLng position,
    required double radiusMeters,
    required bool isCircular,
    String? address,
  }) async {
    final String server = await AuthService.server();
    final String? token = await AuthService.token();

    if (!ApiConfig.usesRemoteApi(server) || token == null || token.isEmpty) {
      return false;
    }

    try {
      final Map<String, dynamic> body = <String, dynamic>{
        'user_api_hash': token,
        'id': id.toString(),
        'name': name,
        'type': isCircular ? 'circle' : 'polygon',
        'radius': radiusMeters.toStringAsFixed(2),
        'lat': position.latitude.toString(),
        'lng': position.longitude.toString(),
        'center[lat]': position.latitude.toString(),
        'center[lng]': position.longitude.toString(),
        'coordinates':
            '${position.latitude} ${position.longitude}',
        if (address != null && address.isNotEmpty) 'address': address,
      };

      final Map<String, dynamic> response = await ApiClient.postJson(
        ApiConfig.editGeofenceUri(server),
        body: body,
        token: token,
      );
      return _isSuccess(response);
    } catch (e, stack) {
      developer.log(
        'Failed to edit geofence: $e',
        error: e,
        stackTrace: stack,
        name: 'GeofenceService',
      );
      return false;
    }
  }

  static Future<bool> destroyGeofence(int id) async {
    final String server = await AuthService.server();
    final String? token = await AuthService.token();

    if (!ApiConfig.usesRemoteApi(server) || token == null || token.isEmpty) {
      return false;
    }

    try {
      final Map<String, dynamic> response = await ApiClient.postJson(
        ApiConfig.destroyGeofenceUri(server),
        body: <String, dynamic>{
          'user_api_hash': token,
          'id': id.toString(),
        },
        token: token,
      );
      return _isSuccess(response);
    } catch (e, stack) {
      developer.log(
        'Failed to destroy geofence: $e',
        error: e,
        stackTrace: stack,
        name: 'GeofenceService',
      );
      return false;
    }
  }

  static List<GeofenceModel> _parseList(dynamic response) {
    final List<GeofenceModel> list = <GeofenceModel>[];
    _collectMaps(response, list);
    return list;
  }

  static void _collectMaps(dynamic node, List<GeofenceModel> target) {
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

    if (_looksLikeGeofence(map)) {
      final GeofenceModel? model = GeofenceModel.fromJson(map);
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

  static bool _looksLikeGeofence(Map<String, dynamic> map) {
    final bool hasName =
        map.containsKey('name') || map.containsKey('title');
    final bool hasLocation = map.containsKey('coordinates') ||
        map.containsKey('center') ||
        map.containsKey('lat') ||
        map.containsKey('latitude') ||
        map.containsKey('radius');
    return hasName && hasLocation;
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
