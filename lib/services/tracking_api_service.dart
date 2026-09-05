import 'dart:developer' as developer;

import '../constants/api_config.dart';
import 'api_client.dart';
import 'auth_service.dart';

/// Covers history, reports, devices, commands, FCM, sensors, tasks, and sharing.
class TrackingApiService {
  TrackingApiService._();

  static Future<dynamic> getHistory({
    required int deviceId,
    required String from,
    required String to,
  }) async {
    final String server = await AuthService.server();
    final String? token = await AuthService.token();
    if (token == null || token.isEmpty) {
      return null;
    }

    try {
      final Uri uri = ApiConfig.getHistoryUri(
        server,
        token: token,
        deviceId: deviceId,
        from: from,
        to: to,
      );
      return await ApiClient.get(uri, token: token);
    } catch (e, stack) {
      developer.log('getHistory failed: $e', error: e, stackTrace: stack, name: 'TrackingApiService');
      return null;
    }
  }

  static Future<Map<String, dynamic>?> generateReport({
    required int reportId,
    required int deviceId,
    required String from,
    required String to,
    Map<String, dynamic>? extra,
  }) async {
    final String server = await AuthService.server();
    final String? token = await AuthService.token();
    if (token == null || token.isEmpty) {
      return null;
    }

    try {
      final Map<String, dynamic> body = <String, dynamic>{
        'user_api_hash': token,
        'report_id': reportId.toString(),
        'device_id': deviceId.toString(),
        'from': from,
        'to': to,
        if (extra != null) ...extra,
      };
      return await ApiClient.postJson(
        ApiConfig.generateReportUri(server),
        body: body,
        token: token,
      );
    } catch (e, stack) {
      developer.log('generateReport failed: $e', error: e, stackTrace: stack, name: 'TrackingApiService');
      return null;
    }
  }

  static Future<Map<String, dynamic>?> getUserData() async {
    final String server = await AuthService.server();
    final String? token = await AuthService.token();
    if (token == null || token.isEmpty) {
      return null;
    }

    try {
      final Uri uri = ApiConfig.getUserDataUri(server, token: token);
      final dynamic response = await ApiClient.get(uri, token: token);
      if (response is Map<String, dynamic>) {
        return response;
      }
      if (response is Map) {
        return response.map((k, v) => MapEntry(k.toString(), v));
      }
      return null;
    } catch (e, stack) {
      developer.log('getUserData failed: $e', error: e, stackTrace: stack, name: 'TrackingApiService');
      return null;
    }
  }

  static Future<bool> registerFcmToken(String fcmToken) async {
    final String server = await AuthService.server();
    final String? token = await AuthService.token();
    if (token == null || token.isEmpty || fcmToken.isEmpty) {
      return false;
    }

    try {
      await ApiClient.get(
        ApiConfig.fcmTokenUri(server, token: token, fcmToken: fcmToken),
        token: token,
      );
      return true;
    } catch (e, stack) {
      developer.log('registerFcmToken failed: $e', error: e, stackTrace: stack, name: 'TrackingApiService');
      return false;
    }
  }

  static Future<bool> deleteFcmToken(String fcmToken) async {
    final String server = await AuthService.server();
    if (fcmToken.isEmpty) {
      return false;
    }

    try {
      await ApiClient.get(
        ApiConfig.deleteFcmTokenUri(server, fcmToken: fcmToken),
      );
      return true;
    } catch (e, stack) {
      developer.log('deleteFcmToken failed: $e', error: e, stackTrace: stack, name: 'TrackingApiService');
      return false;
    }
  }

  static Future<List<Map<String, dynamic>>> getDeviceCommands(int deviceId) async {
    final String server = await AuthService.server();
    final String? token = await AuthService.token();
    if (token == null || token.isEmpty) {
      return <Map<String, dynamic>>[];
    }

    try {
      final Uri uri = ApiConfig.getDeviceCommandsUri(
        server,
        token: token,
        deviceId: deviceId,
      );
      final dynamic response = await ApiClient.get(uri, token: token);
      return _parseMapList(response);
    } catch (e, stack) {
      developer.log('getDeviceCommands failed: $e', error: e, stackTrace: stack, name: 'TrackingApiService');
      return <Map<String, dynamic>>[];
    }
  }

  static Future<Map<String, dynamic>?> sendGprsCommand({
    required int deviceId,
    required String command,
  }) async {
    return _post(
      ApiConfig.sendGprsCommandUri(await AuthService.server()),
      <String, dynamic>{
        'device_id': deviceId.toString(),
        'command': command,
      },
    );
  }

  static Future<Map<String, dynamic>?> sendCommandData(
    Map<String, dynamic> payload,
  ) async {
    return _post(
      ApiConfig.sendCommandDataUri(await AuthService.server()),
      payload,
    );
  }

  static Future<Map<String, dynamic>?> addDevice(Map<String, dynamic> payload) async {
    return _post(ApiConfig.addDeviceUri(await AuthService.server()), payload);
  }

  static Future<Map<String, dynamic>?> editDevice(Map<String, dynamic> payload) async {
    return _post(ApiConfig.editDeviceUri(await AuthService.server()), payload);
  }

  static Future<List<Map<String, dynamic>>> getTasks() async {
    final String server = await AuthService.server();
    final String? token = await AuthService.token();
    if (token == null || token.isEmpty) {
      return <Map<String, dynamic>>[];
    }

    try {
      final dynamic response = await ApiClient.get(
        ApiConfig.getTasksUri(server, token: token),
        token: token,
      );
      return _parseMapList(response);
    } catch (e, stack) {
      developer.log('getTasks failed: $e', error: e, stackTrace: stack, name: 'TrackingApiService');
      return <Map<String, dynamic>>[];
    }
  }

  static Future<Map<String, dynamic>?> addTask(Map<String, dynamic> payload) async {
    return _post(ApiConfig.addTaskUri(await AuthService.server()), payload);
  }

  static Future<Map<String, dynamic>?> sharing(Map<String, dynamic> payload) async {
    return _post(ApiConfig.sharingUri(await AuthService.server()), payload);
  }

  static Future<Map<String, dynamic>?> addSensor(Map<String, dynamic> payload) async {
    return _post(ApiConfig.addSensorUri(await AuthService.server()), payload);
  }

  static Future<Map<String, dynamic>?> editSensor(Map<String, dynamic> payload) async {
    return _post(ApiConfig.editSensorUri(await AuthService.server()), payload);
  }

  static Future<Map<String, dynamic>?> editSensorData(Map<String, dynamic> payload) async {
    return _post(ApiConfig.editSensorDataUri(await AuthService.server()), payload);
  }

  static Future<Map<String, dynamic>?> destroySensor(int sensorId) async {
    return _post(
      ApiConfig.destroySensorUri(await AuthService.server()),
      <String, dynamic>{'id': sensorId.toString()},
    );
  }

  static Future<Map<String, dynamic>?> _post(
    Uri uri,
    Map<String, dynamic> payload,
  ) async {
    final String? token = await AuthService.token();
    if (token == null || token.isEmpty) {
      return null;
    }

    try {
      final Map<String, dynamic> body = <String, dynamic>{
        'user_api_hash': token,
        ...payload,
      };
      return await ApiClient.postJson(uri, body: body, token: token);
    } catch (e, stack) {
      developer.log('POST ${uri.path} failed: $e', error: e, stackTrace: stack, name: 'TrackingApiService');
      return null;
    }
  }

  static List<Map<String, dynamic>> _parseMapList(dynamic response) {
    final List<Map<String, dynamic>> result = <Map<String, dynamic>>[];
    if (response is List) {
      for (final dynamic item in response) {
        if (item is Map) {
          result.add(item.map((k, v) => MapEntry(k.toString(), v)));
        }
      }
    } else if (response is Map) {
      for (final dynamic value in response.values) {
        if (value is List) {
          result.addAll(_parseMapList(value));
        }
      }
    }
    return result;
  }
}
