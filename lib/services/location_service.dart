import 'dart:io';

import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationService {
  static Future<bool> isServiceEnabled() {
    return Geolocator.isLocationServiceEnabled();
  }

  static Future<LocationPermission> checkPermission() {
    return Geolocator.checkPermission();
  }

  /// Requests foreground + background location permissions where supported.
  static Future<bool> requestAllPermissions() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return false;
    }

    if (Platform.isAndroid) {
      final PermissionStatus whenInUse = await Permission.location.request();
      if (!whenInUse.isGranted) {
        return false;
      }

      final PermissionStatus always = await Permission.locationAlways.request();
      if (always.isGranted) {
        return true;
      }

      return whenInUse.isGranted;
    }

    if (Platform.isIOS) {
      final PermissionStatus whenInUse =
          await Permission.locationWhenInUse.request();
      if (!whenInUse.isGranted) {
        return false;
      }

      await Permission.locationAlways.request();
      return true;
    }

    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  static Future<Position?> getCurrentPosition() async {
    final bool ready = await requestAllPermissions();
    if (!ready) {
      return null;
    }

    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
    } catch (_) {
      return null;
    }
  }

  static Stream<Position> positionStream() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 8,
      ),
    );
  }

  static Future<void> openLocationSettings() {
    return Geolocator.openLocationSettings();
  }

  static Future<void> openAppSettings() {
    return Geolocator.openAppSettings();
  }
}
