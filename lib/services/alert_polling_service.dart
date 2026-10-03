import 'dart:async';

import 'package:flutter/widgets.dart';

import '../constants/api_config.dart';
import 'alert_service.dart';
import 'auth_service.dart';

/// Polls `/api/get_events` while app is open or in background (best effort).
class AlertPollingService with WidgetsBindingObserver {
  AlertPollingService._();

  static final AlertPollingService instance = AlertPollingService._();

  Timer? _timer;
  bool _started = false;
  bool _pollInFlight = false;

  static const Duration _foregroundInterval = Duration(seconds: 90);
  static const Duration _backgroundInterval = Duration(seconds: 180);

  void start() {
    if (_started) {
      return;
    }
    _started = true;
    WidgetsBinding.instance.addObserver(this);
    _scheduleTimer(_foregroundInterval);
    Future<void>.delayed(const Duration(seconds: 20), () {
      if (_started) {
        unawaited(_poll(force: false));
      }
    });
  }

  void stop() {
    if (!_started) {
      return;
    }
    _started = false;
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _timer = null;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_started) {
      return;
    }
    switch (state) {
      case AppLifecycleState.resumed:
        _scheduleTimer(_foregroundInterval);
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
        _scheduleTimer(_backgroundInterval);
      case AppLifecycleState.detached:
        _timer?.cancel();
    }
  }

  void _scheduleTimer(Duration interval) {
    _timer?.cancel();
    _timer = Timer.periodic(interval, (_) {
      unawaited(_poll(force: false));
    });
  }

  Future<void> _poll({required bool force}) async {
    if (_pollInFlight) {
      return;
    }
    if (!await AuthService.isLoggedIn()) {
      return;
    }
    final String server = await AuthService.server();
    if (!ApiConfig.usesRemoteApi(server)) {
      return;
    }

    _pollInFlight = true;
    try {
      await AlertService.getEvents(forceRefresh: force);
    } catch (_) {
      // Ignore — next tick retries.
    } finally {
      _pollInFlight = false;
    }
  }
}
