import 'dart:async';
import 'dart:developer' as developer;

import '../constants/api_config.dart';
import '../utils/report_response_parser.dart';
import 'api_client.dart';
import 'auth_service.dart';

class GetHistoryResult {
  const GetHistoryResult({required this.statusCode, this.body});
  final int statusCode;
  final dynamic body;
}

class TrackingApiService {
  TrackingApiService._();

  static Future<GetHistoryResult?> getHistory({
    required int deviceId,
    required DateTime from,
    required DateTime to,
    int? page,
    int? limit,
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
        page: page,
        limit: limit,
      );
      developer.log(
        'getHistory device_id=$deviceId '
        '${uri.queryParameters['from_date']} ${uri.queryParameters['from_time']} -> '
        '${uri.queryParameters['to_date']} ${uri.queryParameters['to_time']}',
        name: 'TrackingApiService',
      );
      HttpJsonResponse response = await ApiClient.getWithStatus(uri, token: token);
      developer.log(
        'getHistory status=${response.statusCode} device_id=$deviceId',
        name: 'TrackingApiService',
      );
      return GetHistoryResult(
        statusCode: response.statusCode,
        body: response.body,
      );
    } on ApiException {
      rethrow;
    } on TimeoutException {
      developer.log(
        'getHistory timeout device_id=$deviceId, retrying once',
        name: 'TrackingApiService',
      );
      try {
        final Uri uri = ApiConfig.getHistoryUri(
          server,
          token: token,
          deviceId: deviceId,
          from: from,
          to: to,
          page: page,
          limit: limit,
        );
        final HttpJsonResponse response = await ApiClient.getWithStatus(
          uri,
          token: token,
          timeout: const Duration(seconds: 90),
        );
        return GetHistoryResult(
          statusCode: response.statusCode,
          body: response.body,
        );
      } catch (e, stack) {
        developer.log('getHistory retry failed: $e', error: e, stackTrace: stack);
        rethrow;
      }
    } catch (e, stack) {
      developer.log('getHistory failed: $e', error: e, stackTrace: stack);
      rethrow;
    }
  }

  static Future<dynamic> generateReport({
    required int reportId,
    required int deviceId,
    required String from,
    required String to,
    Map<String, dynamic>? extra,
  }) async {
    final String server = await AuthService.server();
    final String? token = await AuthService.token();
    if (token == null || token.isEmpty) return null;
    try {
      return await ApiClient.postFormRaw(
        ApiConfig.generateReportUri(server),
        body: <String, dynamic>{
          'user_api_hash': token,
          'report_id': reportId.toString(),
          'device_id': deviceId.toString(),
          'from': from,
          'to': to,
          if (extra != null) ...extra,
        },
        token: token,
      );
    } catch (e, stack) {
      developer.log('generateReport failed: $e', error: e, stackTrace: stack);
      return null;
    }
  }

  static Future<Map<String, dynamic>?> getUserData() async {
    final String server = await AuthService.server();
    final String? token = await AuthService.token();
    if (token == null || token.isEmpty) return null;
    try {
      final dynamic response =
          await ApiClient.get(ApiConfig.getUserDataUri(server, token: token), token: token);
      if (response is Map<String, dynamic>) return response;
      if (response is Map) {
        return response.map((Object? k, Object? v) => MapEntry(k.toString(), v));
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<List<Map<String, dynamic>>> getDeviceCommands(int deviceId) async {
    final String server = await AuthService.server();
    final String? token = await AuthService.token();
    if (token == null || token.isEmpty) return <Map<String, dynamic>>[];
    try {
      final dynamic response = await ApiClient.get(
        ApiConfig.getDeviceCommandsUri(server, token: token, deviceId: deviceId),
        token: token,
      );
      if (response is List) {
        return response.whereType<Map>().map((Map e) => Map<String, dynamic>.from(e)).toList();
      }
      return <Map<String, dynamic>>[];
    } catch (_) {
      return <Map<String, dynamic>>[];
    }
  }

  static Future<Map<String, dynamic>?> sendCommandData(Map<String, dynamic> body) async {
    final String server = await AuthService.server();
    final String? token = await AuthService.token();
    if (token == null || token.isEmpty) return null;
    try {
      return await ApiClient.postForm(
        ApiConfig.sendCommandDataUri(server),
        body: <String, dynamic>{'user_api_hash': token, ...body},
        token: token,
      );
    } catch (_) {
      return null;
    }
  }

  static Future<Map<String, dynamic>?> sharing(Map<String, dynamic> body) async {
    final String server = await AuthService.server();
    final String? token = await AuthService.token();
    if (token == null || token.isEmpty) return null;
    try {
      return await ApiClient.postForm(
        ApiConfig.sharingUri(server),
        body: <String, dynamic>{'user_api_hash': token, ...body},
        token: token,
      );
    } catch (_) {
      return null;
    }
  }

  static Future<void> registerFcmToken(String fcmToken) async {
    final String server = await AuthService.server();
    final String? token = await AuthService.token();
    if (token == null || token.isEmpty || fcmToken.trim().isEmpty) return;
    try {
      await ApiClient.get(
        ApiConfig.fcmTokenUri(server, token: token, fcmToken: fcmToken.trim()),
        token: token,
      );
    } catch (_) {}
  }

  static Future<void> deleteFcmToken(String fcmToken) async {
    final String server = await AuthService.server();
    if (fcmToken.trim().isEmpty) return;
    try {
      await ApiClient.get(
        ApiConfig.deleteFcmTokenUri(server, fcmToken: fcmToken.trim()),
      );
    } catch (_) {}
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
      return ReportResponseParser.listFromDynamic(response);
    } catch (_) {
      return <Map<String, dynamic>>[];
    }
  }
}
