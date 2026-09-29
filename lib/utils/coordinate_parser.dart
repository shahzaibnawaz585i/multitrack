import 'dart:math' as math;

/// Parses latitude/longitude from GPS server JSON (GPSWOX / Traccar-style).
class CoordinateParser {
  CoordinateParser._();

  static const List<String> _latKeys = <String>[
    'lat',
    'latitude',
    'y',
    'last_valid_latitude',
  ];

  static const List<String> _lngKeys = <String>[
    'lng',
    'lon',
    'longitude',
    'x',
    'last_valid_longitude',
  ];

  static const List<String> _nestedKeys = <String>[
    'latest_position',
    'last_position',
    'lastPosition',
    'current_position',
    'position',
    'point',
    'device_data',
    'attributes',
    'data',
  ];

  static (double lat, double lng)? fromMaps(
    Map<String, dynamic> primary,
    Map<String, dynamic> secondary,
  ) {
    return fromMap(primary) ?? fromMap(secondary);
  }

  static (double lat, double lng)? fromMap(Map<String, dynamic> map) {
    final (double lat, double lng)? direct = _readPair(map);
    if (direct != null) {
      return direct;
    }

    for (final String key in _nestedKeys) {
      final dynamic nested = map[key];
      if (nested is Map) {
        final Map<String, dynamic> nestedMap = nested.map(
          (Object? k, Object? v) => MapEntry(k.toString(), v),
        );
        final (double lat, double lng)? found = fromMap(nestedMap);
        if (found != null) {
          return found;
        }
      }
    }

    final dynamic coordinates = map['coordinates'];
    if (coordinates is List && coordinates.length >= 2) {
      final double? a = _toDouble(coordinates[0]);
      final double? b = _toDouble(coordinates[1]);
      if (a != null && b != null) {
        if (a.abs() <= 90 && b.abs() <= 180) {
          return _normalize(a, b);
        }
        return _normalize(b, a);
      }
    }

    for (final String key in <String>['latlng', 'lat_lng', 'location', 'geo']) {
      final dynamic raw = map[key];
      if (raw is String) {
        final (double lat, double lng)? pair = parsePair(raw);
        if (pair != null) {
          return pair;
        }
      }
    }

    return null;
  }

  static (double lat, double lng)? parsePair(String raw) {
    final String trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return null;
    }

    final RegExp match = RegExp(
      r'(-?\d+(?:\.\d+)?)\s*[,;\s]\s*(-?\d+(?:\.\d+)?)',
    );
    final RegExpMatch? found = match.firstMatch(trimmed);
    if (found == null) {
      return null;
    }

    final double? a = double.tryParse(found.group(1)!);
    final double? b = double.tryParse(found.group(2)!);
    if (a == null || b == null) {
      return null;
    }

    if (a.abs() <= 90 && b.abs() <= 180) {
      return _normalize(a, b);
    }
    if (b.abs() <= 90 && a.abs() <= 180) {
      return _normalize(b, a);
    }
    return null;
  }

  static bool looksLikeCoordinatePair(String value) {
    return parsePair(value) != null;
  }

  static (double lat, double lng)? _readPair(Map<String, dynamic> map) {
    final double? lat = _pick(map, _latKeys);
    final double? lng = _pick(map, _lngKeys);
    if (lat == null || lng == null) {
      return null;
    }
    return _normalize(lat, lng);
  }

  static double? _pick(Map<String, dynamic> map, List<String> keys) {
    for (final String key in keys) {
      final double? value = _toDouble(map[key]);
      if (value != null) {
        return value;
      }
    }
    return null;
  }

  static double? _toDouble(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is num) {
      if (value.isNaN || value.isInfinite) {
        return null;
      }
      return value.toDouble();
    }
    final String raw = value.toString().trim();
    if (raw.isEmpty) {
      return null;
    }
    return double.tryParse(raw.replaceAll(',', ''));
  }

  static (double lat, double lng)? _normalize(double lat, double lng) {
    if (lat.abs() > 90 && lng.abs() <= 90) {
      final double swappedLat = lng;
      final double swappedLng = lat;
      lat = swappedLat;
      lng = swappedLng;
    }

    if (lat.abs() > 90 || lng.abs() > 180) {
      return null;
    }
    if (lat == 0.0 && lng == 0.0) {
      return null;
    }

    return (lat, lng);
  }

  static double haversineMeters(double lat1, double lng1, double lat2, double lng2) {
    const double r = 6371000;
    final double p1 = lat1 * math.pi / 180;
    final double p2 = lat2 * math.pi / 180;
    final double dLat = (lat2 - lat1) * math.pi / 180;
    final double dLng = (lng2 - lng1) * math.pi / 180;
    final double s = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(p1) *
            math.cos(p2) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    return r * 2 * math.atan2(math.sqrt(s), math.sqrt(1 - s));
  }
}
