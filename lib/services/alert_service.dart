import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';

import '../constants/api_config.dart';
import '../data/notification_data.dart';
import '../data/vehicle_data.dart';
import '../models/notification_model.dart';
import '../models/vehicle_model.dart';
import '../utils/coordinate_parser.dart';
import 'api_client.dart';
import 'auth_service.dart';
import 'live_notification_controller.dart';
import '../utils/live_overspeed_guard.dart';
import 'reverse_geocoding_service.dart';

class AlertService {
  AlertService._();

  static bool _hasBaseline = false;
  static final Set<String> _knownEventKeys = <String>{};
  static bool _isFetching = false;

  /// Resets baseline tracker (call on logout or account switch).
  static void resetBaseline() {
    _hasBaseline = false;
    _knownEventKeys.clear();
  }

  /// Fetches event / alert logs from `{baseUrl}/api/get_events`.
  /// Falls back to local/cached data if remote server is not configured or in case of error.
  static Future<List<AppNotification>> getEvents({
    int? deviceId,
    int? page,
    int? limit,
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

    if (_isFetching && !forceRefresh) {
      return NotificationData.alerts;
    }

    _isFetching = true;

    try {
      final Uri uri = ApiConfig.getEventsUri(
        server,
        token: token,
        deviceId: deviceId,
        page: page,
        limit: limit ?? (page == null ? 100 : null),
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

      List<AppNotification> parsed = _parseEvents(response, deviceNamesById);
      parsed = _enrichWithLiveDevices(parsed);

      if (kDebugMode) {
        print('AlertService: Parsed ${parsed.length} events');
      }

      if (parsed.isNotEmpty) {
        if (!_hasBaseline) {
          _hasBaseline = true;
          for (final AppNotification n in parsed) {
            _knownEventKeys.add(_notifKey(n));
          }
          _enqueueRecentAlertsForBanner(parsed);
        } else if (page == null || page == 1) {
          // On polling, push all new events
          _diffAndPushNew(parsed);
        }

        if (page == null || page == 1) {
          final List<AppNotification> merged =
              _mergeAlertLists(parsed, NotificationData.alerts);
          NotificationData.assignAlerts(merged);
          parsed = merged;
        }

        _resolveMissingAddresses(parsed, server: server, token: token);
        return _filterForDevice(parsed, deviceId: deviceId);
      }

      final List<AppNotification> cached =
          _mergeAlertLists(NotificationData.alerts, <AppNotification>[]);
      return _filterForDevice(cached, deviceId: deviceId);
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
    } finally {
      _isFetching = false;
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

  static List<AppNotification> _enrichWithLiveDevices(
    List<AppNotification> events,
  ) {
    if (events.isEmpty || VehicleData.vehicles.isEmpty) {
      return events;
    }

    return events.map((AppNotification event) {
      double? lat = event.latitude;
      double? lng = event.longitude;
      String location = event.location;

      VehicleModel? matched;
      for (final VehicleModel vehicle in VehicleData.vehicles) {
        if (vehicle.name.trim().toLowerCase() ==
            event.vehicleId.trim().toLowerCase()) {
          matched = vehicle;
          break;
        }
      }

      matched ??= () {
        for (final VehicleModel vehicle in VehicleData.vehicles) {
          final String a = event.vehicleId.toLowerCase();
          final String b = vehicle.name.toLowerCase();
          if (a.contains(b) || b.contains(a)) {
            return vehicle;
          }
        }
        return null;
      }();

      if (matched != null) {
        lat ??= matched.latitude;
        lng ??= matched.longitude;
        if (location == 'Location not available' ||
            CoordinateParser.looksLikeCoordinatePair(location)) {
          location = matched.location;
        }
      }

      if (lat == event.latitude &&
          lng == event.longitude &&
          location == event.location) {
        return event;
      }

      return AppNotification(
        id: event.id,
        vehicleId: event.vehicleId,
        eventTitle: event.eventTitle,
        location: location,
        timestamp: event.timestamp,
        category: event.category,
        eventType: event.eventType,
        latitude: lat,
        longitude: lng,
        speed: event.speed,
      );
    }).toList();
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
        if ((notif.location == 'Location not available' ||
                CoordinateParser.looksLikeCoordinatePair(notif.location)) &&
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
        NotificationData.assignAlerts(events);
      }
    });
  }

  /// Loads alerts for UI: API + cached live alerts, with optional device filter.
  static Future<List<AppNotification>> getDisplayAlerts({
    int? deviceId,
    String? vehicleName,
    bool forceRefresh = true,
  }) async {
    List<AppNotification> remote = await getEvents(
      forceRefresh: forceRefresh,
      limit: 100,
    );

    if ((remote.isEmpty || !_hasOperationalAlerts(remote)) &&
        deviceId != null) {
      final List<AppNotification> allDevices = await getEvents(
        deviceId: null,
        forceRefresh: true,
        limit: 100,
      );
      remote = _mergeAlertLists(remote, allDevices);
    }

    List<AppNotification> merged =
        _mergeAlertLists(remote, NotificationData.alerts);
    merged = _enrichWithLiveDevices(merged);
    merged.sort(
      (AppNotification a, AppNotification b) =>
          b.timestamp.compareTo(a.timestamp),
    );

    merged = _filterForDevice(
      merged,
      deviceId: deviceId,
      vehicleName: vehicleName,
    );

    if (pageSafeOperationalFilter(merged)) {
      merged = merged
          .where((AppNotification n) => _isOperationalAlert(n))
          .toList();
      if (merged.isEmpty) {
        merged = _filterForDevice(
          _mergeAlertLists(remote, NotificationData.alerts),
          deviceId: deviceId,
          vehicleName: vehicleName,
        );
      }
    }

    return merged;
  }

  static bool pageSafeOperationalFilter(List<AppNotification> items) {
    return items.any(_isOperationalAlert);
  }

  static bool _hasOperationalAlerts(List<AppNotification> items) {
    return items.any(_isOperationalAlert);
  }

  static bool _isOperationalAlert(AppNotification n) {
    return n.category == NotificationCategory.alerts &&
        (n.eventType == NotificationEventType.ignitionOn ||
            n.eventType == NotificationEventType.ignitionOff ||
            n.eventType == NotificationEventType.overSpeed ||
            n.eventType == NotificationEventType.geofenceIn ||
            n.eventType == NotificationEventType.geofenceOut ||
            n.eventType == NotificationEventType.movement ||
            n.eventType == NotificationEventType.offline);
  }

  static List<AppNotification> _filterForDevice(
    List<AppNotification> items, {
    int? deviceId,
    String? vehicleName,
  }) {
    Iterable<AppNotification> result = items;

    if (vehicleName != null && vehicleName.trim().isNotEmpty) {
      final String filter = vehicleName.trim().toLowerCase();
      final List<AppNotification> byName = result
          .where(
            (AppNotification n) =>
                n.vehicleId.toLowerCase().contains(filter) ||
                filter.contains(n.vehicleId.toLowerCase()),
          )
          .toList();
      if (byName.isNotEmpty) {
        result = byName;
      }
    }

    if (deviceId != null) {
      final List<AppNotification> byDevice = result.where((AppNotification n) {
        for (final VehicleModel v in VehicleData.vehicles) {
          if (v.id == deviceId &&
              v.name.trim().toLowerCase() ==
                  n.vehicleId.trim().toLowerCase()) {
            return true;
          }
        }
        return false;
      }).toList();
      if (byDevice.isNotEmpty) {
        return byDevice;
      }
    }

    return result.toList();
  }

  static List<AppNotification> _mergeAlertLists(
    List<AppNotification> primary,
    List<AppNotification> secondary,
  ) {
    final Map<String, AppNotification> unique = <String, AppNotification>{};
    for (final AppNotification item in <AppNotification>[
      ...primary,
      ...secondary,
    ]) {
      unique[_notifKey(item)] = item;
    }
    final List<AppNotification> merged = unique.values.toList();
    merged.sort(
      (AppNotification a, AppNotification b) =>
          b.timestamp.compareTo(a.timestamp),
    );
    return merged;
  }

  // ─── Live banner diff ─────────────────────────────────────────────────────

  static void _enqueueRecentAlertsForBanner(
    List<AppNotification> parsed, {
    int maxBanner = 100,
  }) {
    final Iterable<AppNotification> operational = parsed.where(
      _isOperationalAlert,
    );
    LiveNotificationController.instance.enqueueBatch(
      operational,
      maxCount: maxBanner,
    );
  }

  /// Compares [fresh] against [_knownEventKeys]. Any new notification is pushed.
  static void _diffAndPushNew(List<AppNotification> fresh) {
    if (fresh.isEmpty) return;

    for (final AppNotification n in fresh) {
      final String key = _notifKey(n);
      if (!_knownEventKeys.contains(key)) {
        _knownEventKeys.add(key);
        if (n.eventType == NotificationEventType.overSpeed &&
            !LiveOverspeedGuard.shouldPushApiOverSpeed(
              n,
              liveVehicle: LiveOverspeedGuard.matchVehicle(
                n,
                VehicleData.vehicles,
              ),
            )) {
          continue;
        }
        LiveNotificationController.instance.push(n);
      }
    }
  }

  /// Unique key for an [AppNotification] used for diffing.
  static String _notifKey(AppNotification n) {
    if (n.id != null) return 'id_${n.id}';
    final int secBucket = n.timestamp.millisecondsSinceEpoch ~/ 1000;
    return '${n.vehicleId}_${n.eventType.name}_$secBucket';
  }
}
