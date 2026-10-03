import '../constants/api_config.dart';
import 'api_client.dart';
import 'auth_service.dart';
import 'vehicle_service.dart';

/// Map icon categories shown in vehicle detail → Update Icon dialog.
class VehicleIconCategory {
  const VehicleIconCategory({
    required this.label,
    required this.apiSlug,
    required this.iconId,
    this.serverSlugs = const <String>[],
  });

  final String label;
  final String apiSlug;
  final String iconId;
  /// Extra GPSWOX / Traccar icon keys to try on [edit_device].
  final List<String> serverSlugs;

  static const List<VehicleIconCategory> all = <VehicleIconCategory>[
    VehicleIconCategory(
      label: 'Bus',
      apiSlug: 'bus',
      iconId: '4',
      serverSlugs: <String>['bus'],
    ),
    VehicleIconCategory(
      label: 'Truck',
      apiSlug: 'truck',
      iconId: '3',
      serverSlugs: <String>['truck', 'van'],
    ),
    VehicleIconCategory(
      label: 'Scooter',
      apiSlug: 'scooter',
      iconId: '6',
      serverSlugs: <String>['scooter', 'bicycle'],
    ),
    VehicleIconCategory(
      label: 'User',
      apiSlug: 'user',
      iconId: '7',
      serverSlugs: <String>['person', 'user'],
    ),
    VehicleIconCategory(
      label: 'Jcb',
      apiSlug: 'jcb',
      iconId: '8',
      serverSlugs: <String>['offroad', 'jcb'],
    ),
    VehicleIconCategory(
      label: 'Rickshaw',
      apiSlug: 'rickshaw',
      iconId: '9',
      serverSlugs: <String>['rickshaw', 'scooter'],
    ),
    VehicleIconCategory(
      label: 'Pickup',
      apiSlug: 'pickup',
      iconId: '10',
      serverSlugs: <String>['pickup', 'car'],
    ),
    VehicleIconCategory(
      label: 'Tractor',
      apiSlug: 'tractor',
      iconId: '11',
      serverSlugs: <String>['tractor'],
    ),
    VehicleIconCategory(
      label: 'Motorcycle',
      apiSlug: 'motorcycle',
      iconId: '5',
      serverSlugs: <String>['motorcycle', 'bicycle'],
    ),
    VehicleIconCategory(
      label: 'Ambulance',
      apiSlug: 'ambulance',
      iconId: '12',
      serverSlugs: <String>['ambulance', 'car'],
    ),
    VehicleIconCategory(
      label: 'Crane',
      apiSlug: 'crane',
      iconId: '13',
      serverSlugs: <String>['crane', 'offroad'],
    ),
    VehicleIconCategory(
      label: 'Machine',
      apiSlug: 'machine',
      iconId: '2',
      serverSlugs: <String>['default', 'car', 'machine'],
    ),
  ];

  Iterable<String> get allServerIconValues sync* {
    yield apiSlug;
    for (final String s in serverSlugs) {
      yield s;
    }
    yield iconId;
  }

  static VehicleIconCategory? byLabel(String label) {
    final String trimmed = label.trim();
    for (final VehicleIconCategory c in all) {
      if (c.label.toLowerCase() == trimmed.toLowerCase()) {
        return c;
      }
    }
    return null;
  }

  static VehicleIconCategory? byApiSlug(String slug) {
    final String normalized = slug.trim().toLowerCase();
    if (normalized.isEmpty) {
      return null;
    }
    for (final VehicleIconCategory c in all) {
      if (c.apiSlug == normalized) {
        return c;
      }
    }
    for (final VehicleIconCategory c in all) {
      if (c.iconId == normalized) {
        return c;
      }
    }
    return null;
  }

  static String labelForDeviceIconField(String raw) {
    final VehicleIconCategory? match = byApiSlug(raw);
    return match?.label ?? _titleCase(raw);
  }

  static String _titleCase(String raw) {
    if (raw.isEmpty) {
      return 'Truck';
    }
    if (raw.length == 1) {
      return raw.toUpperCase();
    }
    return '${raw[0].toUpperCase()}${raw.substring(1).toLowerCase()}';
  }
}

class VehicleIconService {
  VehicleIconService._();

  static VehicleIconCategory initialCategoryForDevice(int deviceId) {
    final String? slug = VehicleService.mapIconSlugForDevice(deviceId);
    if (slug != null && slug.isNotEmpty) {
      final VehicleIconCategory? match = VehicleIconCategory.byApiSlug(slug);
      if (match != null) {
        return match;
      }
    }
    return VehicleIconCategory.all[1];
  }

  static Future<void> updateDeviceIcon({
    required int deviceId,
    required VehicleIconCategory category,
  }) async {
    VehicleService.patchDeviceMapIcon(deviceId, category.apiSlug);

    final String? token = await AuthService.token();
    if (token == null || token.isEmpty) {
      throw const ApiException('Not logged in');
    }
    final String server = await AuthService.server();
    final Uri uri = ApiConfig.editDeviceUri(server);
    final String deviceName =
        VehicleService.findCachedDevice(deviceId)?.name ?? '';

    final Set<String> iconValues = <String>{
      ...category.allServerIconValues,
    };

    final List<Map<String, dynamic>> bodies = <Map<String, dynamic>>[];
    for (final String iconValue in iconValues) {
      bodies.add(<String, dynamic>{
        'user_api_hash': token,
        'device_id': deviceId.toString(),
        'id': deviceId.toString(),
        'name': deviceName,
        'icon': iconValue,
      });
      bodies.add(<String, dynamic>{
        'user_api_hash': token,
        'device_id': deviceId.toString(),
        'icon_type': iconValue,
      });
      bodies.add(<String, dynamic>{
        'user_api_hash': token,
        'device_id': deviceId.toString(),
        'device_icon': iconValue,
      });
    }

    Object? lastError;
    for (final Map<String, dynamic> body in bodies) {
      try {
        final dynamic response =
            await ApiClient.postFormRaw(uri, body: body, token: token);
        if (_isSuccess(response)) {
          await VehicleService.getDevices(forceRefresh: true);
          return;
        }
        if (response is Map && response['message'] != null) {
          lastError = response['message'];
        }
      } catch (e) {
        lastError = e;
      }
    }

    throw ApiException(
      lastError?.toString() ?? 'Could not update vehicle icon',
    );
  }

  static bool _isSuccess(dynamic response) {
    if (response == null) {
      return false;
    }
    if (response is Map) {
      final dynamic status = response['status'];
      if (status == 1 || status == true || status == '1') {
        return true;
      }
      if (response['success'] == true) {
        return true;
      }
      if (response.containsKey('items')) {
        return true;
      }
      final String message = response['message']?.toString().toLowerCase() ?? '';
      if (message.contains('success') || message.contains('updated')) {
        return true;
      }
    }
    return false;
  }
}
