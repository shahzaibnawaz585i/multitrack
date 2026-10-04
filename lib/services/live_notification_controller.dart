import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';

import '../data/notification_data.dart';
import '../models/notification_model.dart';
import '../widgets/live_alert_banner.dart';
import 'app_lifecycle_gate.dart';
import 'local_notification_service.dart';
import 'notification_location_resolver.dart';
import 'voice_alert_service.dart';
import '../utils/live_location_text.dart';
import '../utils/live_overspeed_guard.dart';
import '../data/vehicle_data.dart';
import '../utils/notification_location_text.dart';

/// Singleton [ChangeNotifier] that drives the live in-app alert banner.
class LiveNotificationController extends ChangeNotifier {
  LiveNotificationController._();

  static final LiveNotificationController instance =
      LiveNotificationController._();

  // ─── Queue ────────────────────────────────────────────────────────────────

  final Queue<AppNotification> _queue = Queue<AppNotification>();
  LiveAlertItem? _current;
  Timer? _advanceTimer;
  Future<void>? _pushChain;
  static const int _maxQueue = 100;

  /// When false (Settings → Notification OFF), in-app banner + tray alerts stay off.
  /// Voice still runs via [VoiceAlertService] when Voice Command is ON.
  bool bannersEnabled = true;

  /// The alert currently being shown (null = banner hidden).
  LiveAlertItem? get currentAlert => _current;

  /// Alerts waiting after the visible banner.
  int get queuedAlertCount => _queue.length;

  /// Alerts already placed in the banner queue this session (avoid repeats).
  final Set<String> _queuedBannerKeys = <String>{};

  // ─── Deduplication ────────────────────────────────────────────────────────

  /// Key → expiry time.
  final Map<String, DateTime> _seen = <String, DateTime>{};
  static const Duration _dedupWindow = Duration(seconds: 12);

  // ─── Public API ───────────────────────────────────────────────────────────

  void applySettings({required bool notificationOn}) {
    bannersEnabled = notificationOn;
    if (!bannersEnabled) {
      _advanceTimer?.cancel();
      _queue.clear();
      if (_current != null) {
        _current = null;
        notifyListeners();
      }
    }
  }

  /// Push an [AppNotification] from any screen / service.
  void push(AppNotification notification) {
    _pushChain = (_pushChain ?? Future<void>.value())
        .then((_) => _pushResolved(notification));
    unawaited(_pushChain);
  }

  /// Queue many alerts for the banner (e.g. after API load). Newest shown first.
  void enqueueBatch(
    Iterable<AppNotification> notifications, {
    int maxCount = 100,
  }) {
    final List<AppNotification> sorted = notifications.toList()
      ..sort(
        (AppNotification a, AppNotification b) =>
            b.timestamp.compareTo(a.timestamp),
      );
    int added = 0;
    for (final AppNotification raw in sorted) {
      if (added >= maxCount) {
        break;
      }
      final String key = _dedupKey(raw);
      if (_queuedBannerKeys.contains(key)) {
        continue;
      }
      _queuedBannerKeys.add(key);
      if (bannersEnabled) {
        _enqueueForBanner(raw);
      }
      _playVoiceIfAllowed(raw);
      added++;
    }
    if (bannersEnabled && _current == null && _queue.isNotEmpty) {
      _showNext();
    }
  }

  Future<void> _pushResolved(AppNotification notification) async {
    if (notification.eventType == NotificationEventType.overSpeed &&
        !LiveOverspeedGuard.shouldPushApiOverSpeed(
          notification,
          liveVehicle: LiveOverspeedGuard.matchVehicle(
            notification,
            VehicleData.vehicles,
          ),
        )) {
      return;
    }

    AppNotification enriched = notification.copyWith(
      location: NotificationLocationResolver.resolveSync(notification),
    );

    final String key = _dedupKey(enriched);
    final DateTime now = DateTime.now();

    _seen.removeWhere((_, DateTime exp) => now.isAfter(exp));

    if (_seen.containsKey(key)) {
      return;
    }
    _seen[key] = now.add(_dedupWindow);
    if (_seen.length > 64) {
      _seen.remove(_seen.keys.first);
    }

    _commitAlert(enriched);
    _queuedBannerKeys.add(key);
    if (bannersEnabled) {
      _enqueueForBanner(enriched);
    }
    _playVoiceIfAllowed(enriched);

    if (bannersEnabled && !AppLifecycleGate.instance.isForeground) {
      unawaited(LocalNotificationService.showAlert(enriched));
    }

    if (!LiveLocationText.isUsableAddress(enriched.location)) {
      try {
        final AppNotification resolved =
            await NotificationLocationResolver.withLiveAddress(notification);
        if (!LiveLocationText.isUsableAddress(resolved.location)) {
          return;
        }
        _commitAlert(resolved);
        if (bannersEnabled &&
            _current != null &&
            _current!.vehicleName == resolved.vehicleId &&
            _current!.timestamp == resolved.timestamp) {
          _current = _toAlertItem(resolved);
          notifyListeners();
        }
      } catch (_) {}
    }
  }

  void _commitAlert(AppNotification enriched) {
    final bool alreadyInList = NotificationData.alerts.any((AppNotification a) =>
        a.id == enriched.id &&
        a.vehicleId == enriched.vehicleId &&
        a.timestamp.difference(enriched.timestamp).abs().inSeconds < 5);
    if (!alreadyInList) {
      NotificationData.alerts.insert(0, enriched);
      if (NotificationData.alerts.length > 200) {
        NotificationData.alerts.removeRange(200, NotificationData.alerts.length);
      }
      NotificationData.alertsRevision.value++;
    }
  }

  /// Called by the banner's onDismiss callback.
  void dismiss() {
    _advanceTimer?.cancel();
    _current = null;
    notifyListeners();

    // Gap between consecutive alerts
    if (_queue.isNotEmpty) {
      _advanceTimer = Timer(const Duration(milliseconds: 500), _showNext);
    }
  }

  /// Clear everything (e.g. on logout).
  void clear() {
    _advanceTimer?.cancel();
    _queue.clear();
    _current = null;
    _seen.clear();
    _queuedBannerKeys.clear();
    VoiceAlertService.instance.stop();
    notifyListeners();
  }

  void _enqueueForBanner(AppNotification enriched) {
    if (!bannersEnabled) {
      return;
    }
    while (_queue.length >= _maxQueue) {
      _queue.removeFirst();
    }
    _queue.addLast(enriched);

    if (_current == null) {
      _showNext();
    }
  }

  // ─── Internal ─────────────────────────────────────────────────────────────

  void _showNext() {
    if (_queue.isEmpty) return;
    final AppNotification notif = _queue.removeFirst();
    _current = _toAlertItem(notif);
    notifyListeners();
  }

  void _playVoiceIfAllowed(AppNotification notification) {
    if (AppLifecycleGate.instance.isForegroundForVoice) {
      VoiceAlertService.instance.speak(notification);
    }
  }

  String _dedupKey(AppNotification n) {
    if (n.id != null) {
      return 'evt_${n.id}';
    }
    final int secBucket = n.timestamp.millisecondsSinceEpoch ~/ 1000;
    final String title = n.eventTitle.trim().toLowerCase();
    return '${n.vehicleId}_${n.eventType.name}_${title}_$secBucket';
  }

  LiveAlertItem _toAlertItem(AppNotification n) {
    return LiveAlertItem(
      title: _title(n),
      message: _message(n),
      eventType: n.eventType,
      timestamp: n.timestamp,
      vehicleName: n.vehicleId,
      speed: n.speed,
      queuedBehind: _queue.length,
    );
  }

  // ─── Message templates ────────────────────────────────────────────────────

  String _title(AppNotification n) {
    switch (n.eventType) {
      case NotificationEventType.ignitionOn:
        return 'Ignition ON';
      case NotificationEventType.ignitionOff:
        return 'Ignition OFF';
      case NotificationEventType.overSpeed:
        return 'Overspeed Alert';
      case NotificationEventType.geofenceIn:
        return 'Geofence Entered';
      case NotificationEventType.geofenceOut:
        return 'Geofence Exited';
      case NotificationEventType.offline:
        return 'Device Offline';
      case NotificationEventType.movement:
        return 'Movement Detected';
      case NotificationEventType.generic:
        return n.eventTitle.isNotEmpty ? n.eventTitle : 'Fleet Alert';
    }
  }

  String _message(AppNotification n) {
    final String loc = NotificationLocationText.resolve(n);

    switch (n.eventType) {
      case NotificationEventType.ignitionOn:
        return 'Engine started at $loc';
      case NotificationEventType.ignitionOff:
        return 'Engine turned off at $loc';
      case NotificationEventType.overSpeed:
        final String spd =
            n.speed != null ? '${n.speed!.toStringAsFixed(0)} km/h' : '';
        return spd.isNotEmpty
            ? 'Vehicle reached $spd — $loc'
            : 'Speed limit exceeded at $loc';
      case NotificationEventType.geofenceIn:
        return 'Vehicle entered the zone — $loc';
      case NotificationEventType.geofenceOut:
        return 'Vehicle left the zone — $loc';
      case NotificationEventType.offline:
        return 'No signal received from device — last seen at $loc';
      case NotificationEventType.movement:
        return 'Vehicle is moving — $loc';
      case NotificationEventType.generic:
        return n.eventTitle.isNotEmpty ? n.eventTitle : 'Alert at $loc';
    }
  }

  @override
  void dispose() {
    _advanceTimer?.cancel();
    super.dispose();
  }
}
