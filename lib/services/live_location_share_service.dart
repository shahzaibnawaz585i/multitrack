import '../constants/api_config.dart';
import '../utils/whatsapp_share_util.dart';
import '../widgets/share_live_location_dialog.dart';
import 'api_client.dart';
import 'auth_service.dart';

class LiveLocationShareResult {
  const LiveLocationShareResult({
    required this.shareUrl,
    required this.vehicleName,
  });

  final String shareUrl;
  final String vehicleName;

  String get whatsAppMessage {
    return 'Live location — $vehicleName\n$shareUrl';
  }
}

class LiveLocationShareService {
  LiveLocationShareService._();

  static final RegExp _httpRegex = RegExp(
    r'https?://[^\s<>"\]]+',
    caseSensitive: false,
  );

  static Future<LiveLocationShareResult> share({
    required int deviceId,
    required double latitude,
    required double longitude,
    required ShareLiveLocationChoice choice,
    required String vehicleName,
  }) async {
    final String? token = await AuthService.token();
    if (token == null || token.isEmpty) {
      throw const ApiException('Not logged in');
    }
    final String server = await AuthService.server();
    final String baseUrl = ApiConfig.baseUrlFor(server);

    final List<Map<String, dynamic>> bodies =
        _requestBodies(deviceId, latitude, longitude, choice);
    final List<Uri> endpoints = <Uri>[
      ApiConfig.sharingUri(server),
    ];

    Object? lastError;
    for (final Uri endpoint in endpoints) {
      for (final Map<String, dynamic> body in bodies) {
        try {
          final Map<String, dynamic>? response = await _postSharing(
            endpoint,
            body,
            token,
          );
          final String? url = _resolveShareUrl(response, baseUrl);
          if (url != null && url.startsWith('http')) {
            return LiveLocationShareResult(
              shareUrl: url,
              vehicleName: vehicleName.trim().isEmpty ? 'Vehicle' : vehicleName.trim(),
            );
          }
          if (response != null && response['message'] != null) {
            lastError = response['message'];
          }
        } catch (e) {
          lastError = e;
        }
      }
    }

    throw ApiException(
      lastError?.toString() ?? 'Could not create live location link',
    );
  }

  static Future<bool> openWhatsApp(LiveLocationShareResult result) {
    return WhatsAppShareUtil.shareText(result.whatsAppMessage);
  }

  static Future<Map<String, dynamic>?> _postSharing(
    Uri uri,
    Map<String, dynamic> body,
    String token,
  ) async {
    try {
      return await ApiClient.postForm(
        uri,
        body: <String, dynamic>{'user_api_hash': token, ...body},
        token: token,
      );
    } catch (_) {
      final dynamic raw = await ApiClient.postFormRaw(
        uri,
        body: <String, dynamic>{'user_api_hash': token, ...body},
        token: token,
      );
      if (raw is Map<String, dynamic>) {
        return raw;
      }
      if (raw is Map) {
        return raw.map(
          (Object? k, Object? val) => MapEntry(k.toString(), val),
        );
      }
      return null;
    }
  }

  static List<Map<String, dynamic>> _requestBodies(
    int deviceId,
    double latitude,
    double longitude,
    ShareLiveLocationChoice choice,
  ) {
    final String lat = latitude.toString();
    final String lng = longitude.toString();
    final String id = deviceId.toString();

    final ({String expirationBy, int? minutes}) timing =
        _expirationTiming(choice);

    final List<Map<String, dynamic>> variants = <Map<String, dynamic>>[
      if (choice.onlyOnce)
        <String, dynamic>{
          'devices[]': id,
          'expiration_by': 'none',
          'delete_after_expiration': '0',
        }
      else
        <String, dynamic>{
          'devices[]': id,
          'expiration_by': 'duration',
          'expiration_duration': timing.minutes.toString(),
          'delete_after_expiration': '0',
        },
      <String, dynamic>{
        'device_id': id,
        'devices[]': id,
        'expiration_by': timing.expirationBy,
        if (timing.minutes != null)
          'expiration_duration': timing.minutes.toString(),
        'lat': lat,
        'lng': lng,
      },
      <String, dynamic>{
        'device_id': id,
        'devices[]': id,
        'expiration_by': 'duration',
        'expiration_duration': (timing.minutes ?? 60).toString(),
      },
    ];

    return variants;
  }

  static ({String expirationBy, int? minutes}) _expirationTiming(
    ShareLiveLocationChoice choice,
  ) {
    if (choice.onlyOnce) {
      return (expirationBy: 'duration', minutes: 1);
    }
    final int hours = choice.hours ?? 1;
    final int minutes = hours * 60;
    if (hours >= 24 * 7) {
      return (expirationBy: 'duration', minutes: minutes);
    }
    return (expirationBy: 'duration', minutes: minutes);
  }

  static String? _resolveShareUrl(
    Map<String, dynamic>? response,
    String baseUrl,
  ) {
    if (response == null) {
      return null;
    }
    final String? direct = _extractFromNode(response, baseUrl);
    if (direct != null) {
      return direct;
    }
    final dynamic items = response['items'];
    if (items != null) {
      final String? fromItems = _extractFromNode(items, baseUrl);
      if (fromItems != null) {
        return fromItems;
      }
    }
    final String message = response['message']?.toString() ?? '';
    final RegExpMatch? match = _httpRegex.firstMatch(message);
    if (match != null) {
      return match.group(0);
    }
    return null;
  }

  static String? _extractFromNode(dynamic node, String baseUrl) {
    if (node == null) {
      return null;
    }
    if (node is String) {
      final String trimmed = node.trim();
      if (trimmed.startsWith('http')) {
        return trimmed;
      }
      if (trimmed.length >= 8 && !trimmed.contains(' ')) {
        return _urlFromHash(baseUrl, trimmed);
      }
      final RegExpMatch? match = _httpRegex.firstMatch(trimmed);
      return match?.group(0);
    }
    if (node is List) {
      for (final dynamic item in node) {
        final String? found = _extractFromNode(item, baseUrl);
        if (found != null) {
          return found;
        }
      }
      return null;
    }
    if (node is Map) {
      final Map<String, dynamic> map = node.map(
        (Object? k, Object? v) => MapEntry(k.toString(), v),
      );

      const List<String> urlKeys = <String>[
        'url',
        'link',
        'share_url',
        'sharing_url',
        'sharing_link',
        'public_url',
      ];
      for (final String key in urlKeys) {
        final dynamic raw = map[key];
        if (raw == null) {
          continue;
        }
        final String? resolved = _extractFromNode(raw, baseUrl);
        if (resolved != null && resolved.startsWith('http')) {
          return resolved;
        }
      }

      final dynamic hash = map['hash'] ?? map['sharing_hash'] ?? map['token'];
      if (hash != null) {
        final String? built = _urlFromHash(baseUrl, hash.toString());
        if (built != null) {
          return built;
        }
      }

      for (final dynamic value in map.values) {
        final String? nested = _extractFromNode(value, baseUrl);
        if (nested != null && nested.startsWith('http')) {
          return nested;
        }
      }
    }
    return null;
  }

  static String? _urlFromHash(String baseUrl, String hash) {
    final String clean = hash.trim();
    if (clean.isEmpty || clean.contains(' ')) {
      return null;
    }
    if (clean.startsWith('http')) {
      return clean;
    }
    final String root =
        baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
    return '$root/sharing/$clean';
  }
}
