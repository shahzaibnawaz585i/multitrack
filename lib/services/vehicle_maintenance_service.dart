import '../constants/api_config.dart';
import 'api_client.dart';
import 'auth_service.dart';

class VehicleMaintenanceService {
  VehicleMaintenanceService._();

  static Future<void> addOdometerReminder({
    required int deviceId,
    required String name,
    required double intervalKm,
    required double lastServiceKm,
  }) async {
    final String? token = await AuthService.token();
    if (token == null || token.isEmpty) {
      throw const ApiException('Not logged in');
    }
    final String server = await AuthService.server();
    if (!ApiConfig.usesRemoteApi(server)) {
      return;
    }

    final Uri uri = ApiConfig.addServiceUri(server);
    final List<Map<String, dynamic>> bodies = <Map<String, dynamic>>[
      <String, dynamic>{
        'user_api_hash': token,
        'device_id': deviceId.toString(),
        'name': name,
        'expiration_by': 'odometer',
        'interval': intervalKm.toStringAsFixed(0),
        'last_service': lastServiceKm.toStringAsFixed(0),
        'odometer_interval': intervalKm.toStringAsFixed(0),
        'odometer_last': lastServiceKm.toStringAsFixed(0),
      },
      <String, dynamic>{
        'user_api_hash': token,
        'device_id': deviceId.toString(),
        'title': name,
        'type': 'odometer',
        'period': intervalKm.toStringAsFixed(0),
        'previous': lastServiceKm.toStringAsFixed(0),
      },
    ];

    Object? lastError;
    for (final Map<String, dynamic> body in bodies) {
      try {
        final dynamic response =
            await ApiClient.postFormRaw(uri, body: body, token: token);
        if (_isSuccess(response)) {
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
      lastError?.toString() ?? 'Could not save reminder',
    );
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
      final String message = response['message']?.toString().toLowerCase() ?? '';
      if (message.contains('success') || message.contains('added')) {
        return true;
      }
    }
    return false;
  }
}
