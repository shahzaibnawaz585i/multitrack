import 'dart:async';

import '../data/vehicle_data.dart';
import '../models/notification_model.dart';
import '../models/vehicle_model.dart';
import '../utils/coordinate_parser.dart';
import '../utils/live_location_text.dart';
import 'auth_service.dart';
import 'reverse_geocoding_service.dart';
import 'vehicle_service.dart';

/// Resolves coordinates to street addresses for alerts (banner + status bar).
class NotificationLocationResolver {
  NotificationLocationResolver._();

  static const Duration _networkTimeout = Duration(seconds: 10);
  static final Map<String, Future<String>> _inflightByKey =
      <String, Future<String>>{};

  static Future<AppNotification> withLiveAddress(AppNotification notification) async {
    final String sync = resolveSync(notification);
    if (LiveLocationText.isUsableAddress(sync)) {
      return notification.copyWith(location: sync);
    }

    final double? lat =
        notification.latitude ?? _matchedVehicle(notification)?.latitude;
    final double? lng =
        notification.longitude ?? _matchedVehicle(notification)?.longitude;
    if (lat == null || lng == null || (lat == 0.0 && lng == 0.0)) {
      return notification.copyWith(location: LiveLocationText.unavailable);
    }

    final String resolved = await _resolveNetwork(lat, lng);
    if (LiveLocationText.isUsableAddress(resolved)) {
      final VehicleModel? vehicle = _matchedVehicle(notification);
      if (vehicle != null && vehicle.id != null) {
        VehicleService.patchCachedDevice(
          vehicle.copyWith(location: resolved.trim()),
        );
      }
      return notification.copyWith(location: resolved.trim());
    }

    return notification.copyWith(location: LiveLocationText.unavailable);
  }

  static Future<String> _resolveNetwork(double lat, double lng) async {
    final String key =
        '${lat.toStringAsFixed(4)},${lng.toStringAsFixed(4)}';
    final Future<String>? existing = _inflightByKey[key];
    if (existing != null) {
      return existing;
    }

    final Future<String> load = () async {
      try {
        final String server = await AuthService.server();
        final String? token = await AuthService.token();
        return await ReverseGeocodingService.resolveAddress(
          lat: lat,
          lng: lng,
          server: server,
          token: token,
        ).timeout(_networkTimeout);
      } on TimeoutException {
        return LiveLocationText.unavailable;
      } catch (_) {
        return LiveLocationText.unavailable;
      } finally {
        _inflightByKey.remove(key);
      }
    }();

    _inflightByKey[key] = load;
    return load;
  }

  /// Best-effort label without network (cache + fleet row).
  static String resolveSync(AppNotification notification) {
    String location = notification.location.trim();

    if (LiveLocationText.isUsableAddress(location)) {
      return location;
    }

    final VehicleModel? live = _matchedVehicle(notification);
    if (live != null && LiveLocationText.isUsableAddress(live.location)) {
      return live.location.trim();
    }

    final double? lat = notification.latitude ?? live?.latitude;
    final double? lng = notification.longitude ?? live?.longitude;
    if (lat != null && lng != null && (lat != 0.0 || lng != 0.0)) {
      final String? cached = ReverseGeocodingService.getCached(lat, lng);
      if (cached != null && LiveLocationText.isUsableAddress(cached)) {
        return cached.trim();
      }
    }

    if (CoordinateParser.looksLikeCoordinatePair(location)) {
      return LiveLocationText.unavailable;
    }

    if (!LiveLocationText.isPlaceholder(location)) {
      return location;
    }

    return LiveLocationText.unavailable;
  }

  static VehicleModel? _matchedVehicle(AppNotification notification) {
    final String id = notification.vehicleId.trim().toLowerCase();
    if (id.isEmpty) {
      return null;
    }

    for (final VehicleModel vehicle in VehicleData.vehicles) {
      final String name = vehicle.name.trim().toLowerCase();
      if (name == id || name.contains(id) || id.contains(name)) {
        return vehicle;
      }
    }
    return null;
  }
}
