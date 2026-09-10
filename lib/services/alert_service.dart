import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';

import '../constants/api_config.dart';
import '../data/notification_data.dart';
import '../data/vehicle_data.dart';
import '../models/notification_model.dart';
import '../models/vehicle_model.dart';
import 'api_client.dart';
import 'auth_service.dart';
import 'reverse_geocoding_service.dart';

class AlertService {
  AlertService._();

  /// Fetches event / alert logs from `{baseUrl}/api/get_events`.
  /// Falls back to local/cached data if remote server is not configured or in case of error.
  static Future<List<AppNotification>> getEvents({
    int? deviceId,
    int? page,
    bool forceRefresh = false,
  }) async {
    final String server = await AuthService.server();
    final String? token = await AuthService.token();

    if (!ApiConfig.usesRemoteApi(server) || token == null || token.isEmpty) {
      if (kDebugMode) {
        print('AlertService: No remote server or token available for $server. Using local NotificationData.');
      }
      return NotificationData.alerts;
    }

    try {
      final Uri uri = ApiConfig.getEventsUri(
        server,
        token: token,
        deviceId: deviceId,
        page: page,
      );

      if (kDebugMode) {
        print('AlertService: Fetching events from $uri');
      }

      final dynamic response = await ApiClient.get(uri, token: token);

      if (kDebugMode) {
        print('AlertService: Response received: $response');
      }

      final Map<int, String> deviceNamesById = <int, String>{};
      for (final VehicleModel v in VehicleData.vehicles) {
        if (v.id != null) {
          deviceNamesById[v.id!] = v.name;
        }
      }

      final List<AppNotification> parsed = _parseEvents(response, deviceNamesById);

      if (kDebugMode) {
        print('AlertService: Parsed ${parsed.length} events');
      }

      if (parsed.isNotEmpty) {
        NotificationData.alerts = parsed;
        _resolveMissingAddresses(parsed, server: server, token: token);
        return parsed;
      }

      return NotificationData.alerts;
    } catch (e, stack) {
      if (kDebugMode) {
        print('AlertService Error: $e');
      }
      developer.log(
        'Failed to fetch events from get_events API: $e',
        error: e,
        stackTrace: stack,
        name: 'AlertService',
      );
      return NotificationData.alerts;
    }
  }

  /// Fetches configured alert definitions from `{baseUrl}/api/alerts`.
  static Future<List<Map<String, dynamic>>> getAlerts() async {
    final String server = await AuthService.server();
    final String? token = await AuthService.token();

    if (!ApiConfig.usesRemoteApi(server) || token == null || token.isEmpty) {
      return <Map<String, dynamic>>[];
    }

    try {
      final dynamic response = await ApiClient.getOptional(
        ApiConfig.alertsUri(server, token: token),
        token: token,
      );
      if (response == null) {
        return <Map<String, dynamic>>[];
      }
      return _parseMapList(response);
    } catch (_) {
      return <Map<String, dynamic>>[];
    }
  }

  /// Fetches alert type labels from `{baseUrl}/api/alert-types`.
  static Future<List<String>> getAlertTypes() async {
    final String server = await AuthService.server();
    final String? token = await AuthService.token();

    if (!ApiConfig.usesRemoteApi(server) || token == null || token.isEmpty) {
      return <String>[];
    }

    try {
      final dynamic response = await ApiClient.getOptional(
        ApiConfig.alertTypesUri(server, token: token),
        token: token,
      );
      if (response == null) {
        return <String>[];
      }
      return _parseAlertTypeLabels(response);
    } catch (_) {
      return <String>[];
    }
  }

  static List<String> _parseAlertTypeLabels(dynamic response) {
    final List<String> labels = <String>[];
    void addLabel(dynamic value) {
      if (value == null) return;
      final String label = value.toString().trim();
      if (label.isNotEmpty && !labels.contains(label)) {
        labels.add(label);
      }
    }

    if (response is List) {
      for (final dynamic item in response) {
        if (item is Map) {
          addLabel(item['name'] ?? item['title'] ?? item['type'] ?? item['label']);
        } else {
          addLabel(item);
        }
      }
    } else if (response is Map) {
      if (response['items'] is List) {
        return _parseAlertTypeLabels(response['items']);
      }
      if (response['data'] is List) {
        return _parseAlertTypeLabels(response['data']);
      }
      if (response['types'] is List) {
        return _parseAlertTypeLabels(response['types']);
      }
      for (final dynamic value in response.values) {
        if (value is List) {
          labels.addAll(_parseAlertTypeLabels(value));
        }
      }
    }
    return labels;
  }

  /// Saves alert configuration for a device via `POST /api/alerts`.
  static Future<bool> saveAlerts({
    required int deviceId,
    required List<String> enabledTypes,
  }) async {
    final String server = await AuthService.server();
    final String? token = await AuthService.token();

    if (!ApiConfig.usesRemoteApi(server) || token == null || token.isEmpty) {
      return false;
    }

    try {
      final Map<String, dynamic> body = <String, dynamic>{
        'user_api_hash': token,
        'device_id': deviceId.toString(),
        'alerts': enabledTypes.join(','),
      };

      for (int i = 0; i < enabledTypes.length; i++) {
        body['alerts[$i]'] = enabledTypes[i];
      }

      final Map<String, dynamic> response = await ApiClient.postJson(
        ApiConfig.alertsUri(server),
        body: body,
        token: token,
      );

      if (response['success'] == true) {
        return true;
      }
      final dynamic status = response['status'];
      return status == 1 || status == '1' || status == true;
    } catch (e, stack) {
      developer.log(
        'Failed to save alerts: $e',
        error: e,
        stackTrace: stack,
        name: 'AlertService',
      );
      return false;
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
      if (response['items'] is List) {
        return _parseMapList(response['items']);
      }
      if (response['data'] is List) {
        return _parseMapList(response['data']);
      }
      for (final dynamic value in response.values) {
        if (value is List) {
          result.addAll(_parseMapList(value));
        }
      }
    }
    return result;
  }

  static List<AppNotification> _parseEvents(
    dynamic response,
    Map<int, String> deviceNamesById,
  ) {
    final List<AppNotification> list = <AppNotification>[];

    if (response is List) {
      for (final dynamic item in response) {
        if (item is Map) {
          final Map<String, dynamic> converted = item.map((k, v) => MapEntry(k.toString(), v));
          list.add(AppNotification.fromJson(converted, deviceNamesById: deviceNamesById));
        }
      }
    } else if (response is Map) {
      final Map<String, dynamic> map = response.map((k, v) => MapEntry(k.toString(), v));
      if (map.containsKey('items')) {
        final dynamic items = map['items'];
        if (items is List) {
          for (final dynamic item in items) {
            if (item is Map) {
              list.add(AppNotification.fromJson(item.map((k, v) => MapEntry(k.toString(), v)), deviceNamesById: deviceNamesById));
            }
          }
        } else if (items is Map && items['data'] is List) {
          for (final dynamic item in items['data']) {
            if (item is Map) {
              list.add(AppNotification.fromJson(item.map((k, v) => MapEntry(k.toString(), v)), deviceNamesById: deviceNamesById));
            }
          }
        }
      } else if (map.containsKey('events') && map['events'] is List) {
        for (final dynamic item in map['events']) {
          if (item is Map) {
            list.add(AppNotification.fromJson(item.map((k, v) => MapEntry(k.toString(), v)), deviceNamesById: deviceNamesById));
          }
        }
      } else if (map.containsKey('data') && map['data'] is List) {
        for (final dynamic item in map['data']) {
          if (item is Map) {
            list.add(AppNotification.fromJson(item.map((k, v) => MapEntry(k.toString(), v)), deviceNamesById: deviceNamesById));
          }
        }
      }
    }

    return list;
  }

  static void _resolveMissingAddresses(
    List<AppNotification> events, {
    required String server,
    String? token,
  }) {
    Future.microtask(() async {
      bool updated = false;
      for (int i = 0; i < events.length; i++) {
        final AppNotification notif = events[i];
        if ((notif.location == 'Location not available' || notif.location.contains(',')) &&
            notif.latitude != null &&
            notif.longitude != null &&
            (notif.latitude != 0.0 || notif.longitude != 0.0)) {
          final String resolved = await ReverseGeocodingService.resolveAddress(
            lat: notif.latitude!,
            lng: notif.longitude!,
            server: server,
            token: token,
          );
          if (resolved.isNotEmpty && resolved != 'Location not available') {
            events[i] = AppNotification(
              id: notif.id,
              vehicleId: notif.vehicleId,
              eventTitle: notif.eventTitle,
              location: resolved,
              timestamp: notif.timestamp,
              category: notif.category,
              eventType: notif.eventType,
              latitude: notif.latitude,
              longitude: notif.longitude,
              speed: notif.speed,
            );
            updated = true;
          }
        }
      }
      if (updated) {
        NotificationData.alerts = events;
      }
    });
  }
}
