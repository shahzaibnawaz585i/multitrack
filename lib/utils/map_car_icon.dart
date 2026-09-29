import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../constants/app_images.dart';

/// Cached top-down car markers for live map tracking.
class MapCarIcon {
  MapCarIcon._();

  static final Map<String, BitmapDescriptor> _cache = <String, BitmapDescriptor>{};

  /// Car center sits on the road coordinate.
  static const Offset markerAnchor = Offset(0.5, 0.5);

  static Future<BitmapDescriptor> forStatus(String status) async {
    final String key = status.trim().toLowerCase();
    final BitmapDescriptor? cached = _cache[key];
    if (cached != null) return cached;

    final BitmapDescriptor icon = await BitmapDescriptor.asset(
      const ImageConfiguration(size: Size(20, 25)),
      _assetForStatus(status),
    );
    _cache[key] = icon;
    return icon;
  }

  static String _assetForStatus(String status) {
    switch (status.trim().toLowerCase()) {
      case 'running':
      case 'moving':
        return AppImages.runningCar;
      case 'stopped':
      case 'stop':
      case 'parked':
        return AppImages.stopCar;
      case 'idle':
      case 'engine':
      case 'standby':
        return AppImages.idleCar;
      case 'not reporting':
      case 'inactive':
      case 'offline':
      case 'nodata':
      case 'disconnected':
        return AppImages.inactiveCar;
      case 'expired':
        return AppImages.stopCar;
      default:
        return AppImages.inactiveCar;
    }
  }

  /// Clears cached bitmaps after asset swap (e.g. new car artwork).
  static void clearCache() {
    _cache.clear();
  }
}
