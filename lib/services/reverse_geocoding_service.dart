import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/api_config.dart';

class ReverseGeocodingService {
  ReverseGeocodingService._();

  static final Map<String, String> _memoryCache = <String, String>{};
  static bool _cacheLoaded = false;

  static String _cacheKey(double lat, double lng) {
    // Round to 4 decimal places (~11 meters precision) for optimal caching
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

  /// Resolves coordinates (lat, lng) to a clean human-readable street/place text address
  /// (e.g. "Railway Station, Circular Road, Lahore").
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

    // 1. Try GPS server geo_address endpoint if available
    if (server != null && ApiConfig.usesRemoteApi(server)) {
      final Uri uri =
          ApiConfig.geoAddressUri(server, token: token, lat: lat, lng: lng);

      try {
        final http.Response res = await http.get(uri, headers: {
          'Accept': 'application/json',
          if (token != null && token.isNotEmpty)
            'Authorization': 'Bearer $token',
        }).timeout(const Duration(seconds: 4));

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
    }

    // 2. Try OpenStreetMap Nominatim reverse geocoding
    try {
      final Uri osmUri = Uri.parse(
          'https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lng&zoom=18&addressdetails=1');
      final http.Response res = await http.get(osmUri, headers: {
        'User-Agent': 'MultiTrackGPS/1.0',
        'Accept-Language': 'en,ur',
      }).timeout(const Duration(seconds: 4));

      if (res.statusCode == 200 && res.body.isNotEmpty) {
        final dynamic decoded = jsonDecode(res.body);
        if (decoded is Map) {
          final String? displayName = decoded['display_name']?.toString();
          final Map? addressMap = decoded['address'] as Map?;

          String? formatted;
          if (addressMap != null) {
            final List<String> parts = <String>[];
            final dynamic road = addressMap['road'] ??
                addressMap['pedestrian'] ??
                addressMap['street'] ??
                addressMap['building'] ??
                addressMap['amenity'] ??
                addressMap['suburb'] ??
                addressMap['neighbourhood'];
            if (road != null && road.toString().trim().isNotEmpty) {
              parts.add(road.toString().trim());
            }

            final dynamic area = addressMap['suburb'] ??
                addressMap['neighbourhood'] ??
                addressMap['residential'] ??
                addressMap['commercial'] ??
                addressMap['city_district'];
            if (area != null &&
                area.toString().trim().isNotEmpty &&
                !parts.contains(area.toString().trim())) {
              parts.add(area.toString().trim());
            }

            final dynamic city = addressMap['city'] ??
                addressMap['town'] ??
                addressMap['village'] ??
                addressMap['county'];
            if (city != null &&
                city.toString().trim().isNotEmpty &&
                !parts.contains(city.toString().trim())) {
              parts.add(city.toString().trim());
            }

            if (parts.isNotEmpty) {
              formatted = parts.join(', ');
            }
          }

          formatted ??= displayName;
          if (formatted != null && _isValidAddress(formatted)) {
            final String cleaned = _cleanAddress(formatted);
            await _saveToCache(key, cleaned);
            return cleaned;
          }
        }
      }
    } catch (_) {}

    // 3. Try BigDataCloud free client reverse geocoding
    try {
      final Uri bdcUri = Uri.parse(
          'https://api.bigdatacloud.net/data/reverse-geocode-client?latitude=$lat&longitude=$lng&localityLanguage=en');
      final http.Response res =
          await http.get(bdcUri).timeout(const Duration(seconds: 4));

      if (res.statusCode == 200 && res.body.isNotEmpty) {
        final dynamic decoded = jsonDecode(res.body);
        if (decoded is Map) {
          final List<String> parts = <String>[];
          final dynamic locality = decoded['locality'];
          final dynamic city = decoded['city'] ?? decoded['principalSubdivision'];
          final dynamic country = decoded['countryName'];

          if (locality != null && locality.toString().trim().isNotEmpty) {
            parts.add(locality.toString().trim());
          }
          if (city != null &&
              city.toString().trim().isNotEmpty &&
              !parts.contains(city.toString().trim())) {
            parts.add(city.toString().trim());
          }
          if (country != null &&
              country.toString().trim().isNotEmpty &&
              !parts.contains(country.toString().trim())) {
            parts.add(country.toString().trim());
          }

          if (parts.isNotEmpty) {
            final String formatted = parts.join(', ');
            if (_isValidAddress(formatted)) {
              final String cleaned = _cleanAddress(formatted);
              await _saveToCache(key, cleaned);
              return cleaned;
            }
          }
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
