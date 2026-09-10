import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/api_config.dart';

class ReverseGeocodingService {
  ReverseGeocodingService._();

  static final Map<String, String> _memoryCache = <String, String>{};
  static bool _cacheLoaded = false;

  static String _cacheKey(double lat, double lng) {
    return '${lat.toStringAsFixed(4)},${lng.toStringAsFixed(4)}';
  }

  static Future<void> _loadCache() async {
    if (_cacheLoaded) return;
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final List<String>? keys = prefs.getStringList('geo_cache_keys');
      if (keys != null) {
        for (final String key in keys) {
          final String? val = prefs.getString('geo_addr_$key');
          if (val != null && val.isNotEmpty) {
            _memoryCache[key] = val;
          }
        }
      }
      _cacheLoaded = true;
    } catch (_) {}
  }

  static String? getCached(double lat, double lng) {
    final String key = _cacheKey(lat, lng);
    return _memoryCache[key];
  }

  /// Resolves coordinates using the GPS server `/api/geo_address` endpoint only.
  static Future<String> resolveAddress({
    required double lat,
    required double lng,
    String? token,
    String? server,
  }) async {
    if (lat == 0.0 && lng == 0.0) {
      return 'Location not available';
    }

    await _loadCache();
    final String key = _cacheKey(lat, lng);
    if (_memoryCache.containsKey(key)) {
      return _memoryCache[key]!;
    }

    if (server == null || !ApiConfig.usesRemoteApi(server)) {
      return 'Location not available';
    }

    final Uri uri =
        ApiConfig.geoAddressUri(server, token: token, lat: lat, lng: lng);

    try {
      final http.Response res = await http.get(uri, headers: {
        'Accept': 'application/json',
        if (token != null && token.isNotEmpty)
          'Authorization': 'Bearer $token',
      }).timeout(const Duration(seconds: 6));

      if (res.statusCode == 200 && res.body.isNotEmpty) {
        final dynamic decoded = jsonDecode(res.body);
        String? addr;
        if (decoded is Map) {
          addr = decoded['address']?.toString() ??
              decoded['formatted_address']?.toString() ??
              decoded['display_name']?.toString();
        } else if (decoded is String && decoded.trim().isNotEmpty) {
          addr = decoded;
        }
        if (addr != null && _isValidAddress(addr)) {
          final String cleaned = _cleanAddress(addr);
          await _saveToCache(key, cleaned);
          return cleaned;
        }
      }
    } catch (_) {}

    return 'Location not available';
  }

  static bool _isValidAddress(String str) {
    final String s = str.trim().toLowerCase();
    if (s.isEmpty ||
        s == '-' ||
        s == '--' ||
        s == 'no data' ||
        s == 'null' ||
        s == 'n/a' ||
        s == 'na' ||
        s == 'none' ||
        s == 'nil' ||
        s == 'unknown' ||
        s == 'nodata') {
      return false;
    }
    return true;
  }

  static String _cleanAddress(String address) {
    final List<String> segments = address
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    if (segments.length > 3) {
      return '${segments[0]}, ${segments[1]}, ${segments[2]}';
    }
    return address.trim();
  }

  static Future<void> _saveToCache(String key, String address) async {
    _memoryCache[key] = address;
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('geo_addr_$key', address);
      final List<String> keys =
          prefs.getStringList('geo_cache_keys') ?? <String>[];
      if (!keys.contains(key)) {
        keys.add(key);
        if (keys.length > 200) {
          final String oldKey = keys.removeAt(0);
          await prefs.remove('geo_addr_$oldKey');
        }
        await prefs.setStringList('geo_cache_keys', keys);
      }
    } catch (_) {}
  }
}
