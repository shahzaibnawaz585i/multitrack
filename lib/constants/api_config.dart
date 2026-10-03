class ApiConfig {
  ApiConfig._();

  static const Duration timeout = Duration(seconds: 45);
  static const String defaultBaseUrl = 'https://gps.m-track.net.pk';

  /// Stored server id for login session (maps to [defaultBaseUrl]).
  static const String appServerId = 'Server 1';

  // Auth & devices
  static const String loginPath = '/api/login';
  static const String getDevicesPath = '/api/get_devices';
  static const String addDevicePath = '/api/add_device';
  static const String editDevicePath = '/api/edit_device';

  // Events & alerts
  static const String getEventsPath = '/api/get_events';
  static const String alertsPath = '/api/alerts';
  static const String alertTypesPath = '/api/alert-types';

  // Geofences
  static const String getGeofencesPath = '/api/get_geofences';
  static const String addGeofencePath = '/api/add_geofence';
  static const String editGeofencePath = '/api/edit_geofence';
  static const String destroyGeofencePath = '/api/destroy_geofence';

  // Drivers
  static const String getUserDriversPath = '/api/get_user_drivers';
  static const String addUserDriverPath = '/api/add_user_driver';

  // Device groups
  static const String getGroupsPath = '/api/get_groups';

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

  // Maintenance / reminders (services)
  static const String getServicesPath = '/api/get_services';
  static const String addServicePath = '/api/add_service';

  // Device documents
  static const String getDeviceDocumentsPath = '/api/get_device_documents';
  static const String addDeviceDocumentPath = '/api/add_device_document';
  static const String editDeviceDocumentPath = '/api/edit_device_document';
  static const String destroyDeviceDocumentPath = '/api/destroy_device_document';

  // Tasks & sharing
  static const String getTasksPath = '/api/get_tasks';
  static const String addTaskPath = '/api/add_task';
  static const String sharingPath = '/api/sharing';

  // User & push
  static const String getUserDataPath = '/api/get_user_data';
  static const String fcmTokenPath = '/api/fcm_token';
  static const String deleteFcmTokenPath = '/api/delete_fcm_token';

  static const Map<String, String> serverBaseUrls = <String, String>{
    appServerId: defaultBaseUrl,
  };

  static String baseUrlFor(String server) => defaultBaseUrl;

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
    int? limit,
  }) {
    final Map<String, String> queryParams = <String, String>{};
    if (deviceId != null) {
      queryParams['device_id'] = deviceId.toString();
    }
    if (page != null) {
      queryParams['page'] = page.toString();
    }
    if (limit != null) {
      queryParams['limit'] = limit.toString();
    }
    return apiUri(server, getEventsPath, token: token, queryParams: queryParams);
  }

  static Uri alertsUri(String server, {String? token}) =>
      apiUri(server, alertsPath, token: token);

  static Uri alertTypesUri(String server, {String? token}) =>
      apiUri(server, alertTypesPath, token: token);

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

  /// GPSWOX `GET /api/get_history` query (lang, device_id, from_date/time, to_date/time).
  static Map<String, String> getHistoryQueryParams({
    required DateTime from,
    required DateTime to,
    int? deviceId,
    int? page,
    int? limit,
    String lang = 'en',
  }) {
    String two(int n) => n.toString().padLeft(2, '0');
    String date(DateTime d) =>
        '${d.year}-${two(d.month)}-${two(d.day)}';
    String time(DateTime d) =>
        '${two(d.hour)}:${two(d.minute)}:${two(d.second)}';

    final Map<String, String> queryParams = <String, String>{
      'lang': lang,
      'from_date': date(from),
      'from_time': time(from),
      'to_date': date(to),
      'to_time': time(to),
    };
    if (deviceId != null) {
      queryParams['device_id'] = deviceId.toString();
    }
    if (page != null) {
      queryParams['page'] = page.toString();
    }
    if (limit != null) {
      queryParams['limit'] = limit.toString();
    }
    return queryParams;
  }

  static Uri getHistoryUri(
    String server, {
    String? token,
    int? deviceId,
    DateTime? from,
    DateTime? to,
    int? page,
    int? limit,
    String lang = 'en',
  }) {
    final Map<String, String> queryParams = from != null && to != null
        ? getHistoryQueryParams(
            from: from,
            to: to,
            deviceId: deviceId,
            page: page,
            limit: limit,
            lang: lang,
          )
        : <String, String>{'lang': lang};
    if (deviceId != null && !queryParams.containsKey('device_id')) {
      queryParams['device_id'] = deviceId.toString();
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
          'lng': lng.toString(),
          'lang': lang,
        },
      );

  static Uri generateReportUri(String server) =>
      apiUri(server, generateReportPath);

  static Uri getUserDataUri(String server, {String? token}) =>
      apiUri(server, getUserDataPath, token: token);

  static Uri getGroupsUri(String server, {String? token}) =>
      apiUri(server, getGroupsPath, token: token);

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

  static Uri getDeviceDocumentsUri(
    String server, {
    String? token,
    int? deviceId,
  }) {
    final Map<String, String> queryParams = <String, String>{};
    if (deviceId != null) {
      queryParams['device_id'] = deviceId.toString();
    }
    return apiUri(
      server,
      getDeviceDocumentsPath,
      token: token,
      queryParams: queryParams,
    );
  }

  static Uri addDeviceDocumentUri(String server) =>
      apiUri(server, addDeviceDocumentPath);

  static Uri destroyDeviceDocumentUri(String server) =>
      apiUri(server, destroyDeviceDocumentPath);

  static Uri addSensorUri(String server) => apiUri(server, addSensorPath);

  static Uri editSensorUri(String server) => apiUri(server, editSensorPath);

  static Uri editSensorDataUri(String server) =>
      apiUri(server, editSensorDataPath);

  static Uri destroySensorUri(String server) =>
      apiUri(server, destroySensorPath);

  static Uri addServiceUri(String server) => apiUri(server, addServicePath);

  static Uri getServicesUri(String server, {String? token, int? deviceId}) {
    final Map<String, String> queryParams = <String, String>{};
    if (deviceId != null) {
      queryParams['device_id'] = deviceId.toString();
    }
    return apiUri(server, getServicesPath, token: token, queryParams: queryParams);
  }

  static bool usesRemoteApi(String server) => baseUrlFor(server).isNotEmpty;
}
