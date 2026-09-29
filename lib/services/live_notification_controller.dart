import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';

import '../data/notification_data.dart';
import '../models/notification_model.dart';
import '../widgets/live_alert_banner.dart';
import 'voice_alert_service.dart';

/// Singleton [ChangeNotifier] that drives the live in-app alert banner.
class LiveNotificationController extends ChangeNotifier {
  LiveNotificationController._();

  static final LiveNotificationController instance =
      LiveNotificationController._();

  // ─── Queue ────────────────────────────────────────────────────────────────

  final Queue<AppNotification> _queue = Queue<AppNotification>();
  LiveAlertItem? _current;
  Timer? _advanceTimer;

  /// The alert currently being shown (null = banner hidden).
  LiveAlertItem? get currentAlert => _current;

  // ─── Deduplication ────────────────────────────────────────────────────────

  /// Key → expiry time.
  final Map<String, DateTime> _seen = <String, DateTime>{};
  static const Duration _dedupWindow = Duration(seconds: 30);

  // ─── Public API ───────────────────────────────────────────────────────────

  /// Push an [AppNotification] from any screen / service.
  void push(AppNotification notification) {
    final String key = _dedupKey(notification);
    final DateTime now = DateTime.now();

    // Clean stale entries
    _seen.removeWhere((_, DateTime exp) => now.isAfter(exp));

    if (_seen.containsKey(key)) return; // duplicate
    _seen[key] = now.add(_dedupWindow);

    // ── Keep Alerts list in sync with all live alerts ──────────────────────
    final bool alreadyInList = NotificationData.alerts.any((AppNotification a) =>
        a.id == notification.id &&
        a.vehicleId == notification.vehicleId &&
        a.timestamp.difference(notification.timestamp).abs().inSeconds < 5);
    if (!alreadyInList) {
      NotificationData.alerts.insert(0, notification);
      NotificationData.alertsRevision.value++;
    }

    _queue.addLast(notification);

    if (_current == null) {
      _showNext();
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
    VoiceAlertService.instance.stop();
    notifyListeners();
  }

  // ─── Internal ─────────────────────────────────────────────────────────────

  void _showNext() {
    if (_queue.isEmpty) return;
    final AppNotification notif = _queue.removeFirst();
    _current = _toAlertItem(notif);

    // Speak aloud when the banner actually shows on screen
    VoiceAlertService.instance.speak(notif);

    notifyListeners();
  }

  String _dedupKey(AppNotification n) {
    if (n.id != null) return 'id_${n.id}';
    final int minuteBucket =
        n.timestamp.millisecondsSinceEpoch ~/ 60000;
    return '${n.vehicleId}_${n.eventType.name}_$minuteBucket';
  }

  LiveAlertItem _toAlertItem(AppNotification n) {
    return LiveAlertItem(
      title: _title(n),
      message: _message(n),
      eventType: n.eventType,
      timestamp: n.timestamp,
      vehicleName: n.vehicleId,
      speed: n.speed,
    );
  }

  // ─── Message templates ────────────────────────────────────────────────────

  String _title(AppNotification n) {
    switch (n.eventType) {
      case NotificationEventType.ignitionOn:
        return '🔑 Ignition ON — ${n.vehicleId}';
      case NotificationEventType.ignitionOff:
        return '🔴 Ignition OFF — ${n.vehicleId}';
      case NotificationEventType.overSpeed:
        return '⚡ Overspeed Alert — ${n.vehicleId}';
      case NotificationEventType.geofenceIn:
        return '📍 Geofence Entered — ${n.vehicleId}';
      case NotificationEventType.geofenceOut:
        return '🚪 Geofence Exited — ${n.vehicleId}';
      case NotificationEventType.offline:
        return '📵 Device Offline — ${n.vehicleId}';
      case NotificationEventType.movement:
        return '🚗 Movement Detected — ${n.vehicleId}';
      case NotificationEventType.generic:
        return '🔔 Alert — ${n.vehicleId}';
    }
  }

  String _message(AppNotification n) {
    final String loc = n.location.isNotEmpty &&
            n.location != 'Location not available'
        ? n.location
        : 'Location not available';

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
