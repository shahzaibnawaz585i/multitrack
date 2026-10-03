import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
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

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
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

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
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

  static Future<bool> requestForegroundPermission() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  static Future<Position?> getCurrentPosition() async {
    final bool ready = await requestForegroundPermission();
    if (!ready) {
      return null;
    }

    final Position? lastKnown = await Geolocator.getLastKnownPosition();

    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 2),
        ),
      );
    } catch (_) {
      return lastKnown;
    }
  }

  static Stream<Position> positionStream() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.medium,
        distanceFilter: 20,
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
