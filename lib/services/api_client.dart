import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../constants/api_config.dart';

class ApiException implements Exception {
  const ApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

class ApiClient {
  ApiClient._();

  static Future<dynamic> get(
    Uri uri, {
    String? token,
  }) async {
    try {
      final http.Response response = await http
          .get(
            uri,
            headers: <String, String>{
              'Accept': 'application/json',
              if (token != null && token.isNotEmpty)
                'Authorization': 'Bearer $token',
            },
          )
          .timeout(ApiConfig.timeout);

      return _decodeDynamic(response);
    } on TimeoutException {
      throw const ApiException('Could not connect to server');
    } on ApiException {
      rethrow;
    } on FormatException {
      throw const ApiException('Failed to process response');
    } catch (_) {
      throw const ApiException('Could not connect to server');
    }
  }

  /// GET that returns null on 404 instead of throwing.
  static Future<dynamic> getOptional(
    Uri uri, {
    String? token,
  }) async {
    try {
      return await get(uri, token: token);
    } on ApiException catch (error) {
      if (error.message.contains('404') ||
          error.message.contains('could not be found')) {
        return null;
      }
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> postForm(
    Uri uri, {
    required Map<String, dynamic> body,
    String? token,
  }) async {
    try {
      final Map<String, String> stringBody = body.map(
        (String k, dynamic v) =>
            MapEntry<String, String>(k, v?.toString() ?? ''),
      );
      final http.Response response = await http
          .post(
            uri,
            headers: <String, String>{
              'Accept': 'application/json',
              'Content-Type': 'application/x-www-form-urlencoded',
              if (token != null && token.isNotEmpty)
                'Authorization': 'Bearer $token',
            },
            body: stringBody,
          )
          .timeout(ApiConfig.timeout);

      return _decode(response);
    } on TimeoutException {
      throw const ApiException('Could not connect to server');
    } on ApiException {
      rethrow;
    } on FormatException {
      throw const ApiException('Login failed');
    } catch (_) {
      throw const ApiException('Could not connect to server');
    }
  }

  static Future<Map<String, dynamic>> postJson(
    Uri uri, {
    required Map<String, dynamic> body,
    String? token,
  }) async {
    try {
      http.Response response = await http
          .post(
            uri,
            headers: <String, String>{
              'Accept': 'application/json',
              'Content-Type': 'application/json',
              if (token != null && token.isNotEmpty)
                'Authorization': 'Bearer $token',
            },
            body: jsonEncode(body),
          )
          .timeout(ApiConfig.timeout);

      // If rejected by server (e.g. 400, 415, 422), fallback to form-urlencoded for GPSWOX/PHP APIs
      if (response.statusCode >= 400 && response.statusCode <= 422) {
        try {
          final Map<String, String> stringBody = body.map(
            (String k, dynamic v) =>
                MapEntry<String, String>(k, v?.toString() ?? ''),
          );
          final http.Response formResponse = await http
              .post(
                uri,
                headers: <String, String>{
                  'Accept': 'application/json',
                  'Content-Type': 'application/x-www-form-urlencoded',
                  if (token != null && token.isNotEmpty)
                    'Authorization': 'Bearer $token',
                },
                body: stringBody,
              )
              .timeout(ApiConfig.timeout);

          if (formResponse.statusCode >= 200 &&
              formResponse.statusCode < 300) {
            response = formResponse;
          }
        } catch (_) {}
      }

      return _decode(response);
    } on TimeoutException {
      throw const ApiException('Could not connect to server');
    } on ApiException {
      rethrow;
    } on FormatException {
      throw const ApiException('Login failed');
    } catch (_) {
      throw const ApiException('Could not connect to server');
    }
  }

  static dynamic _decodeDynamic(http.Response response) {
    dynamic decoded;
    if (response.body.isNotEmpty) {
      decoded = jsonDecode(response.body);
    }

    if (response.statusCode == 401 || response.statusCode == 403) {
      final String message = (decoded is Map && decoded['message'] != null)
          ? decoded['message'].toString()
          : 'Unauthorized';
      throw ApiException(message);
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final String message = (decoded is Map && decoded['message'] != null)
          ? decoded['message'].toString()
          : 'Request failed (${response.statusCode})';
      throw ApiException(message);
    }

    return decoded;
  }

  static Map<String, dynamic> _decode(http.Response response) {
    final dynamic decoded = _decodeDynamic(response);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    } else if (decoded is Map) {
      return decoded.map(
        (Object? key, Object? value) => MapEntry(key.toString(), value),
      );
    }
    return <String, dynamic>{};
  }
}
