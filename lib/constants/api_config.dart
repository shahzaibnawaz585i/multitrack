class ApiConfig {
  ApiConfig._();

  static const Duration timeout = Duration(seconds: 45);
  static const String defaultBaseUrl = 'https://gps.m-track.net.pk';

  // Auth & devices
  static const String loginPath = '/api/login';
  static const String getDevicesPath = '/api/get_devices';
  static const String addDevicePath = '/api/add_device';
  static const String editDevicePath = '/api/edit_device';

  // Events & alerts
  static const String getEventsPath = '/api/get_events';
  static const String alertsPath = '/api/alerts';

  // Geofences
  static const String getGeofencesPath = '/api/get_geofences';
  static const String addGeofencePath = '/api/add_geofence';
  static const String editGeofencePath = '/api/edit_geofence';
  static const String destroyGeofencePath = '/api/destroy_geofence';

  // Drivers
  static const String getUserDriversPath = '/api/get_user_drivers';
  static const String addUserDriverPath = '/api/add_user_driver';

  // History & geocoding
  static const String getHistoryPath = '/api/get_history';
  static const String geoAddressPath = '/api/geo_address';

  // Reports
  static const String generateReportPath = '/api/generate_report';

  // Commands
  static const String getDeviceCommandsPath = '/api/get_device_commands';
  static const String sendGprsCommandPath = '/api/send_gprs_command';
  static const String sendCommandDataPath = '/api/send_command_data';

  // Sensors
  static const String addSensorPath = '/api/add_sensor';
  static const String editSensorPath = '/api/edit_sensor';
  static const String editSensorDataPath = '/api/edit_sensor_data';
  static const String destroySensorPath = '/api/destroy_sensor';

  // Tasks & sharing
  static const String getTasksPath = '/api/get_tasks';
  static const String addTaskPath = '/api/add_task';
  static const String sharingPath = '/api/sharing';

  // User & push
  static const String getUserDataPath = '/api/get_user_data';
  static const String fcmTokenPath = '/api/fcm_token';
  static const String deleteFcmTokenPath = '/api/delete_fcm_token';

  /// GPS panel base URL for each login-server option.
  static const Map<String, String> serverBaseUrls = <String, String>{
    'Server 1 (Live)': 'https://gps.m-track.net.pk',
    'Server 1': 'https://gps.m-track.net.pk',
    'Server 2': 'http://62.171.139.5',
    'Nostrum Track': 'http://62.171.139.5',
    'Fleet Wox': 'http://62.171.139.5',
    'Server 3': 'https://gps.m-track.net.pk',
  };

  static String baseUrlFor(String server) {
    final String trimmed = server.trim();
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed.replaceAll(RegExp(r'/+$'), '');
    }
    for (final MapEntry<String, String> entry in serverBaseUrls.entries) {
      if (entry.key.toLowerCase() == trimmed.toLowerCase() ||
          trimmed.toLowerCase().startsWith(entry.key.toLowerCase()) ||
          entry.key.toLowerCase().startsWith(trimmed.toLowerCase())) {
        return entry.value.replaceAll(RegExp(r'/+$'), '');
      }
    }
    return defaultBaseUrl;
  }

  static Uri apiUri(
    String server,
    String path, {
    String? token,
    Map<String, String>? queryParams,
  }) {
    final String baseUrl = baseUrlFor(server);
    final Map<String, String> params = <String, String>{};
    if (token != null && token.isNotEmpty) {
      params['user_api_hash'] = token;
    }
    if (queryParams != null) {
      params.addAll(queryParams);
    }
    final Uri base = Uri.parse('$baseUrl$path');
    if (params.isEmpty) {
      return base;
    }
    return base.replace(queryParameters: params);
  }

  static Uri loginUri(String server) => apiUri(server, loginPath);

  static Uri getDevicesUri(String server, {String? token}) =>
      apiUri(server, getDevicesPath, token: token);

  static Uri getEventsUri(
    String server, {
    String? token,
    int? deviceId,
    int? page,
  }) {
    final Map<String, String> queryParams = <String, String>{};
    if (deviceId != null) {
      queryParams['device_id'] = deviceId.toString();
    }
    if (page != null) {
      queryParams['page'] = page.toString();
    }
    return apiUri(server, getEventsPath, token: token, queryParams: queryParams);
  }

  static Uri alertsUri(String server, {String? token}) =>
      apiUri(server, alertsPath, token: token);

  static Uri getGeofencesUri(String server, {String? token}) =>
      apiUri(server, getGeofencesPath, token: token);

  static Uri addGeofenceUri(String server) => apiUri(server, addGeofencePath);

  static Uri editGeofenceUri(String server) => apiUri(server, editGeofencePath);

  static Uri destroyGeofenceUri(String server) =>
      apiUri(server, destroyGeofencePath);

  static Uri getUserDriversUri(String server, {String? token}) =>
      apiUri(server, getUserDriversPath, token: token);

  static Uri addUserDriverUri(String server) =>
      apiUri(server, addUserDriverPath);

  static Uri getHistoryUri(
    String server, {
    String? token,
    int? deviceId,
    String? from,
    String? to,
  }) {
    final Map<String, String> queryParams = <String, String>{};
    if (deviceId != null) {
      queryParams['device_id'] = deviceId.toString();
    }
    if (from != null && from.isNotEmpty) {
      queryParams['from'] = from;
    }
    if (to != null && to.isNotEmpty) {
      queryParams['to'] = to;
    }
    return apiUri(server, getHistoryPath, token: token, queryParams: queryParams);
  }

  static Uri geoAddressUri(
    String server, {
    String? token,
    required double lat,
    required double lng,
    String lang = 'en',
  }) =>
      apiUri(
        server,
        geoAddressPath,
        token: token,
        queryParams: <String, String>{
          'lat': lat.toString(),
          'lon': lng.toString(),
          'lang': lang,
        },
      );

  static Uri generateReportUri(String server) =>
      apiUri(server, generateReportPath);

  static Uri getUserDataUri(String server, {String? token}) =>
      apiUri(server, getUserDataPath, token: token);

  static Uri fcmTokenUri(String server, {String? token, required String fcmToken}) =>
      apiUri(
        server,
        fcmTokenPath,
        token: token,
        queryParams: <String, String>{'token': fcmToken},
      );

  static Uri deleteFcmTokenUri(String server, {required String fcmToken}) =>
      apiUri(
        server,
        deleteFcmTokenPath,
        queryParams: <String, String>{'token': fcmToken},
      );

  static Uri getDeviceCommandsUri(String server, {String? token, int? deviceId}) {
    final Map<String, String> queryParams = <String, String>{};
    if (deviceId != null) {
      queryParams['device_id'] = deviceId.toString();
    }
    return apiUri(server, getDeviceCommandsPath, token: token, queryParams: queryParams);
  }

  static Uri sendGprsCommandUri(String server) =>
      apiUri(server, sendGprsCommandPath);

  static Uri sendCommandDataUri(String server) =>
      apiUri(server, sendCommandDataPath);

  static Uri addDeviceUri(String server) => apiUri(server, addDevicePath);

  static Uri editDeviceUri(String server) => apiUri(server, editDevicePath);

  static Uri getTasksUri(String server, {String? token}) =>
      apiUri(server, getTasksPath, token: token);

  static Uri addTaskUri(String server) => apiUri(server, addTaskPath);

  static Uri sharingUri(String server) => apiUri(server, sharingPath);

  static Uri addSensorUri(String server) => apiUri(server, addSensorPath);

  static Uri editSensorUri(String server) => apiUri(server, editSensorPath);

  static Uri editSensorDataUri(String server) =>
      apiUri(server, editSensorDataPath);

  static Uri destroySensorUri(String server) =>
      apiUri(server, destroySensorPath);

  static bool usesRemoteApi(String server) => baseUrlFor(server).isNotEmpty;
}
