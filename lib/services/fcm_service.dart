import 'package:shared_preferences/shared_preferences.dart';

import 'tracking_api_service.dart';

/// Registers/deletes FCM tokens with the GPS server.
/// When Firebase Messaging is added, call [registerStoredToken] after obtaining the token.
class FcmService {
  FcmService._();

  static const String _tokenKey = 'fcm_token';

  static Future<void> saveToken(String token) async {
    if (token.trim().isEmpty) {
      return;
    }
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token.trim());
    await TrackingApiService.registerFcmToken(token.trim());
  }

  static Future<String?> storedToken() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString(_tokenKey);
    if (token == null || token.trim().isEmpty) {
      return null;
    }
    return token.trim();
  }

  static Future<void> registerStoredToken() async {
    final String? token = await storedToken();
    if (token != null) {
      await TrackingApiService.registerFcmToken(token);
    }
  }

  static Future<void> unregister() async {
    final String? token = await storedToken();
    if (token != null) {
      await TrackingApiService.deleteFcmToken(token);
    }
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }
}
