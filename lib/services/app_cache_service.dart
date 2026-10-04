import 'package:flutter/painting.dart';

import '../utils/history_numbered_stop_icon.dart';
import '../utils/map_car_icon.dart';
import '../utils/vehicle_category_map_icon.dart';
import 'history_service.dart';
import 'reverse_geocoding_service.dart';
import 'vehicle_detail_api_service.dart';

/// Keeps on-device cache from growing without bound.
class AppCacheService {
  AppCacheService._();

  /// Call once after login restore — trims stale disk + in-memory caches.
  static Future<void> trimOnStartup() async {
    PaintingBinding.instance.imageCache.maximumSize = 120;
    PaintingBinding.instance.imageCache.maximumSizeBytes = 48 << 20;
    if (PaintingBinding.instance.imageCache.currentSizeBytes > (40 << 20)) {
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();
    }
    await ReverseGeocodingService.trimPersistentCache(maxEntries: 80);
    HistoryService.clearMemoryCache();
    VehicleDetailApiService.clearMemoryCaches();
    MapCarIcon.clearCache();
    VehicleCategoryMapIcon.clearCache();
    HistoryNumberedStopIcon.clearCache();
  }

  /// Frees heavy session data (logout); fleet disk cleared separately.
  static Future<void> clearSessionCaches() async {
    HistoryService.clearMemoryCache();
    VehicleDetailApiService.clearMemoryCaches();
    MapCarIcon.clearCache();
    VehicleCategoryMapIcon.clearCache();
    HistoryNumberedStopIcon.clearCache();
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
    await ReverseGeocodingService.trimPersistentCache(maxEntries: 40);
  }
}
