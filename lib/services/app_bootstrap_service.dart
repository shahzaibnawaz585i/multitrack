import 'dart:async';

import '../constants/api_config.dart';
import '../models/vehicle_model.dart';
import 'alert_polling_service.dart';
import 'alert_service.dart';
import 'auth_service.dart';
import 'vehicle_service.dart';
import 'voice_alert_service.dart';

/// Prefetches shared app data after login or on dashboard load.
class AppBootstrapService {
  AppBootstrapService._();

  static Future<List<VehicleModel>> refreshVehicles({
    bool forceRefresh = true,
  }) async {
    return VehicleService.getDevices(forceRefresh: forceRefresh);
  }

  static Future<void> prefetchAfterLogin() async {
    if (!await AuthService.isLoggedIn()) {
      return;
    }

    // ── Pre-warm TTS engine FIRST so voice is ready before first alert ──────
    // Run in background — don't block login navigation.
    unawaited(VoiceAlertService.instance.prewarm());

    await refreshVehicles(forceRefresh: false);
    unawaited(refreshVehicles(forceRefresh: true));

    final String server = await AuthService.server();
    if (ApiConfig.usesRemoteApi(server)) {
      AlertPollingService.instance.start();
      unawaited(AlertService.getEvents(forceRefresh: true));
    }
  }
}
