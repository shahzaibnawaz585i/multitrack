import 'package:shared_preferences/shared_preferences.dart';

import '../constants/api_config.dart';
import '../models/login_result.dart';
import '../data/notification_data.dart';
import '../models/notification_model.dart';
import 'alert_service.dart';
import 'auth_api.dart';
import 'fcm_service.dart';
import 'alert_polling_service.dart';
import 'live_notification_controller.dart';
import 'app_cache_service.dart';
import 'vehicle_service.dart';
import 'voice_alert_service.dart';

class AuthService {
  AuthService._();

  static const String _loggedInKey = 'is_logged_in';
  static const String _userIdKey = 'logged_in_user_id';
  static const String _userNameKey = 'logged_in_user_name';
  static const String _tokenKey = 'auth_token';
  static const String _serverKey = 'logged_in_server';
  static const String demoUserId = 'mtdemo1';

  static Future<bool> isLoggedIn() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_loggedInKey) ?? false;
  }

  static Future<String> userId() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? saved = prefs.getString(_userIdKey);
    if (saved != null && saved.trim().isNotEmpty) {
      return saved.trim();
    }
    return demoUserId;
  }

  static Future<String> userName() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? saved = prefs.getString(_userNameKey);
    if (saved != null && saved.trim().isNotEmpty) {
      return saved.trim();
    }
    return userId();
  }

  static Future<String?> token() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? saved = prefs.getString(_tokenKey);
    if (saved == null || saved.trim().isEmpty) {
      return null;
    }
    return saved.trim();
  }

  static Future<String> server() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? saved = prefs.getString(_serverKey);
    if (saved != null && saved.trim().isNotEmpty) {
      return saved.trim();
    }
    return ApiConfig.appServerId;
  }

  static Future<LoginResult> login({
    required String userId,
    required String password,
    required String server,
  }) async {
    final LoginResult result = await AuthApi.login(
      userId: userId.trim(),
      password: password,
      server: server,
    );

    if (!result.success || result.userId == null) {
      return result.success ? LoginResult.failure('Login failed') : result;
    }

    await _persistSession(
      userId: result.userId!,
      name: result.name ?? result.userId!,
      token:
          result.token ??
          'mt_${result.userId}_${DateTime.now().millisecondsSinceEpoch}',
      server: server,
    );
    return result;
  }

  static Future<void> _persistSession({
    required String userId,
    required String name,
    required String token,
    required String server,
  }) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_loggedInKey, true);
    await prefs.setString(_userIdKey, userId.trim());
    await prefs.setString(_userNameKey, name.trim());
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_serverKey, server);
  }

  static Future<void> logout() async {
    await FcmService.unregister();
    AlertService.resetBaseline();
    VehicleService.resetBaseline();
    VehicleService.clearFleetCache();
    await AppCacheService.clearSessionCaches();
    NotificationData.assignAlerts(<AppNotification>[]);
    LiveNotificationController.instance.clear();
    AlertPollingService.instance.stop();
    await VoiceAlertService.instance.dispose();
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_loggedInKey, false);
    await prefs.remove(_userIdKey);
    await prefs.remove(_userNameKey);
    await prefs.remove(_tokenKey);
    await prefs.remove(_serverKey);
  }
}
