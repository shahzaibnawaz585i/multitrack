import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/api_config.dart';
import 'api_client.dart';

class ReverseGeocodingService {
  ReverseGeocodingService._();

  static final Map<String, String> _memoryCache = <String, String>{};
  static bool _cacheLoaded = false;

  /// GPSWOX geo_address can take 10–20s; Nominatim requires ≥1 req/s globally.
  static const Duration _serverTimeout = Duration(seconds: 14);
  static const Duration _nominatimTimeout = Duration(seconds: 15);
  static const String _nominatimUserAgent =
      'MultiTrack/1.0 (vehicle tracking; contact: support@m-track.net.pk)';

  static DateTime? _lastNominatimRequest;
  static Future<void>? _nominatimChain;

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

  /// Server `/api/geo_address` first, then OpenStreetMap Nominatim fallback.
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

    if (server != null && ApiConfig.usesRemoteApi(server)) {
      final String? fromServer = await _resolveFromGpsServer(
        lat: lat,
        lng: lng,
        token: token,
        server: server,
      );
      if (fromServer != null) {
        await _saveToCache(key, fromServer);
        return fromServer;
      }
    }

    final String? fromNominatim = await _resolveFromNominatim(lat: lat, lng: lng);
    if (fromNominatim != null) {
      await _saveToCache(key, fromNominatim);
      return fromNominatim;
    }

    return 'Location not available';
  }

  static Future<String?> _resolveFromGpsServer({
    required double lat,
    required double lng,
    String? token,
    required String server,
  }) async {
    final Uri uri =
        ApiConfig.geoAddressUri(server, token: token, lat: lat, lng: lng);

    try {
      final http.Response res = await http.get(uri, headers: {
        'Accept': 'application/json, text/plain, */*',
      }).timeout(_serverTimeout);

      if (res.statusCode == 200 && res.body.isNotEmpty) {
        final String? addr = _addressFromResponseBody(res.body);
        if (addr != null && _isValidAddress(addr)) {
          return _cleanAddress(addr);
        }
      }
    } catch (_) {}

    try {
      final Uri postUri = ApiConfig.apiUri(server, ApiConfig.geoAddressPath);
      final dynamic postResponse = await ApiClient.postFormRaw(
        postUri,
        body: <String, dynamic>{
          if (token != null && token.isNotEmpty) 'user_api_hash': token,
          'lat': lat.toString(),
          'lon': lng.toString(),
          'lng': lng.toString(),
        },
        token: token,
      ).timeout(_serverTimeout);
      final String? postAddr = _addressFromDynamic(postResponse);
      if (postAddr != null && _isValidAddress(postAddr)) {
        return _cleanAddress(postAddr);
      }
    } catch (_) {}

    return null;
  }

  static Future<void> _throttleNominatim() async {
    final Future<void> previous =
        _nominatimChain ?? Future<void>.value();
    final Completer<void> gate = Completer<void>();
    _nominatimChain = gate.future;
    await previous;
    try {
      if (_lastNominatimRequest != null) {
        final Duration since =
            DateTime.now().difference(_lastNominatimRequest!);
        if (since.inMilliseconds < 1100) {
          await Future<void>.delayed(
            Duration(milliseconds: 1100 - since.inMilliseconds),
          );
        }
      }
      _lastNominatimRequest = DateTime.now();
    } finally {
      gate.complete();
    }
  }

  static Future<String?> _resolveFromNominatim({
    required double lat,
    required double lng,
  }) async {
    await _throttleNominatim();

    final Uri uri = Uri.https(
      'nominatim.openstreetmap.org',
      '/reverse',
      <String, String>{
        'lat': lat.toString(),
        'lon': lng.toString(),
        'format': 'json',
        'addressdetails': '1',
        'accept-language': 'en',
        'zoom': '18',
      },
    );

    try {
      final http.Response res = await http.get(
        uri,
        headers: <String, String>{'User-Agent': _nominatimUserAgent},
      ).timeout(_nominatimTimeout);

      if (res.statusCode != 200 || res.body.isEmpty) {
        return null;
      }

      final dynamic decoded = jsonDecode(res.body);
      if (decoded is! Map) {
        return null;
      }

      final Map<String, dynamic> map = decoded.map(
        (Object? k, Object? v) => MapEntry(k.toString(), v),
      );

      final String? built = _addressFromNominatimMap(map);
      if (built != null && _isValidAddress(built)) {
        return _cleanAddress(built);
      }

      final String? display = map['display_name']?.toString();
      if (display != null && _isValidAddress(display)) {
        return _cleanAddress(display);
      }
    } catch (_) {}

    return null;
  }

  static String? _addressFromNominatimMap(Map<String, dynamic> map) {
    final dynamic rawAddress = map['address'];
    if (rawAddress is! Map) {
      return null;
    }

    final Map<String, dynamic> addr = rawAddress.map(
      (Object? k, Object? v) => MapEntry(k.toString(), v),
    );

    final List<String> parts = <String>[];
    void addPart(String? value) {
      if (value == null) {
        return;
      }
      final String trimmed = value.trim();
      if (trimmed.isEmpty || parts.contains(trimmed)) {
        return;
      }
      parts.add(trimmed);
    }

    addPart(addr['road']?.toString());
    addPart(addr['neighbourhood']?.toString());
    addPart(addr['suburb']?.toString());
    addPart(addr['city']?.toString());
    addPart(addr['town']?.toString());
    addPart(addr['village']?.toString());
    addPart(addr['state']?.toString());
    addPart(addr['country']?.toString());

    if (parts.isEmpty) {
      return null;
    }
    if (parts.length > 3) {
      return '${parts[0]}, ${parts[1]}, ${parts[2]}';
    }
    return parts.join(', ');
  }

  static String? _addressFromDynamic(dynamic response) {
    if (response == null) {
      return null;
    }
    if (response is String) {
      return _addressFromResponseBody(response);
    }
    return _addressFromResponseBody(jsonEncode(response));
  }

  static String? _addressFromResponseBody(String body) {
    final String trimmed = body.trim();
    if (trimmed.isEmpty) {
      return null;
    }

    dynamic decoded;
    try {
      decoded = jsonDecode(trimmed);
    } catch (_) {
      if (_isValidAddress(trimmed)) {
        return trimmed;
      }
      return null;
    }

    if (decoded is String && _isValidAddress(decoded)) {
      return decoded;
    }

    if (decoded is Map) {
      final Map<String, dynamic> map = decoded.map(
        (Object? k, Object? v) => MapEntry(k.toString(), v),
      );
      for (final String key in <String>[
        'address',
        'formatted_address',
        'display_name',
        'value',
        'data',
        'result',
        'location',
      ]) {
        final dynamic raw = map[key];
        if (raw is String && _isValidAddress(raw)) {
          return raw;
        }
        if (raw is Map) {
          final String? nested = _addressFromResponseBody(jsonEncode(raw));
          if (nested != null) {
            return nested;
          }
        }
      }
      if (map['status'] == 1 && map['items'] is List) {
        for (final dynamic item in map['items'] as List<dynamic>) {
          if (item is Map) {
            final String? fromItem = _addressFromResponseBody(jsonEncode(item));
            if (fromItem != null) {
              return fromItem;
            }
          }
        }
      }
    }

    return null;
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
    while (_memoryCache.length > 120) {
      _memoryCache.remove(_memoryCache.keys.first);
    }
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('geo_addr_$key', address);
      final List<String> keys =
          prefs.getStringList('geo_cache_keys') ?? <String>[];
      if (!keys.contains(key)) {
        keys.add(key);
      }
      while (keys.length > 80) {
        final String oldKey = keys.removeAt(0);
        _memoryCache.remove(oldKey);
        await prefs.remove('geo_addr_$oldKey');
      }
      await prefs.setStringList('geo_cache_keys', keys);
    } catch (_) {}
  }

  /// Drops oldest saved addresses (SharedPreferences can grow large on big fleets).
  static Future<void> trimPersistentCache({required int maxEntries}) async {
    await _loadCache();
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      List<String> keys =
          prefs.getStringList('geo_cache_keys') ?? <String>[];
      while (keys.length > maxEntries) {
        final String oldKey = keys.removeAt(0);
        _memoryCache.remove(oldKey);
        await prefs.remove('geo_addr_$oldKey');
      }
      while (_memoryCache.length > maxEntries) {
        _memoryCache.remove(_memoryCache.keys.first);
      }
      await prefs.setStringList('geo_cache_keys', keys);
    } catch (_) {}
  }
}
