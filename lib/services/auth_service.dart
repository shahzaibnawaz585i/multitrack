import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  AuthService._();

  static const String _loggedInKey = 'is_logged_in';

  static Future<bool> isLoggedIn() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_loggedInKey) ?? false;
  }

  static Future<void> setLoggedIn(bool value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_loggedInKey, value);
  }

  static Future<void> logout() async {
    await setLoggedIn(false);
  }
}
