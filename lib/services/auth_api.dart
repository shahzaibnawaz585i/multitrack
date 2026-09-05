import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';

import '../constants/api_config.dart';
import '../models/login_result.dart';
import 'api_client.dart';

/// MultiTrack login API.
///
/// Remote: `POST {baseUrl}/api/login`
/// Body: `{ "email": "...", "password": "..." }`
class AuthApi {
  AuthApi._();

  static const Map<String, _DemoAccount> _demoAccounts =
      <String, _DemoAccount>{
    'mtdemo1': _DemoAccount(password: '123456', name: 'mtdemo1'),
    'admin@gmail.com': _DemoAccount(password: 'admin123', name: 'Admin'),
  };

  static Future<LoginResult> login({
    required String userId,
    required String password,
    required String server,
  }) async {
    if (ApiConfig.usesRemoteApi(server)) {
      return _remoteLogin(
        userId: userId,
        password: password,
        server: server,
      );
    }
    return _builtInLogin(userId: userId, password: password);
  }

  static Future<LoginResult> _remoteLogin({
    required String userId,
    required String password,
    required String server,
  }) async {
    try {
      final Uri loginUri = ApiConfig.loginUri(server);
      if (kDebugMode) {
        print('AuthApi: Logging in to $loginUri for user: $userId');
      }

      final Map<String, dynamic> json = await ApiClient.postForm(
        loginUri,
        body: <String, dynamic>{
          'email': userId,
          'password': password,
        },
      );

      if (kDebugMode) {
        print('AuthApi: Login response: $json');
      }

      final LoginResult result =
          LoginResult.fromJson(json, fallbackUserId: userId);

      if (!result.success) {
        return LoginResult.failure(
          result.message.isEmpty
              ? 'Invalid User ID or Password'
              : result.message,
        );
      }
      return result;
    } on ApiException catch (error) {
      if (kDebugMode) {
        print('AuthApi ApiException: ${error.message}');
      }
      return LoginResult.failure(error.message);
    } catch (e, stack) {
      if (kDebugMode) {
        print('AuthApi Error: $e');
      }
      developer.log(
        'Login exception: $e',
        error: e,
        stackTrace: stack,
        name: 'AuthApi',
      );
      return LoginResult.failure('Could not connect to server');
    }
  }

  static Future<LoginResult> _builtInLogin({
    required String userId,
    required String password,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 350));

    final _DemoAccount? account = _demoAccounts[userId.toLowerCase()];
    if (account == null || account.password != password) {
      return LoginResult.failure('Invalid User ID or Password');
    }

    final String token =
        'mt_${userId}_${DateTime.now().millisecondsSinceEpoch}';
    return LoginResult(
      success: true,
      message: 'Login successful',
      token: token,
      userId: userId,
      name: account.name,
    );
  }
}

class _DemoAccount {
  const _DemoAccount({required this.password, required this.name});

  final String password;
  final String name;
}
