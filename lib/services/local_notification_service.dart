import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/notification_model.dart';
import '../utils/notification_location_text.dart';

/// Shows alerts in the phone status bar (foreground + background).
class LocalNotificationService {
  LocalNotificationService._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;
  static void Function(String? payload)? _onTapPayload;

  static const String _androidChannelId = 'multitrack_vehicle_alerts';
  static const String _androidChannelName = 'Vehicle alerts';

  static bool get _isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  static bool get _isIOS =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  static Future<void> initialize({
    void Function(String? payload)? onNotificationTap,
  }) async {
    if (kIsWeb || _initialized) {
      return;
    }
    _onTapPayload = onNotificationTap;

    try {
      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const DarwinInitializationSettings iosSettings =
          DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );

      final bool? ok = await _plugin.initialize(
        const InitializationSettings(
          android: androidSettings,
          iOS: iosSettings,
        ),
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          _onTapPayload?.call(response.payload);
        },
      );

      if (ok == false) {
        return;
      }

      if (_isAndroid) {
        await _plugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()
            ?.createNotificationChannel(
              const AndroidNotificationChannel(
                _androidChannelId,
                _androidChannelName,
                description: 'Ignition, overspeed, geofence and live alerts',
                importance: Importance.high,
                playSound: true,
                enableVibration: true,
              ),
            );
      }

      _initialized = true;
    } catch (e, stack) {
      _initialized = false;
      if (kDebugMode) {
        debugPrint('LocalNotificationService.initialize failed: $e\n$stack');
      }
    }
  }

  /// Call after first frame — avoids blocking cold start.
  static Future<void> warmUpPermissions() async {
    if (!_initialized) {
      return;
    }
    try {
      await requestPermissionIfNeeded();
    } catch (_) {}
  }

  static Future<void> requestPermissionIfNeeded() async {
    if (kIsWeb) {
      return;
    }
    if (_isAndroid) {
      final PermissionStatus status = await Permission.notification.status;
      if (!status.isGranted) {
        await Permission.notification.request();
      }
      return;
    }
    if (_isIOS) {
      await _plugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
    }
  }

  static Future<void> showAlert(AppNotification notification) async {
    if (kIsWeb || !_initialized) {
      return;
    }

    final String title = _titleFor(notification);
    final String body = _bodyFor(notification);
    final int id = _notificationId(notification);

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      _androidChannelId,
      _androidChannelName,
      channelDescription: 'Live vehicle tracking alerts',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'MultiTrack alert',
      visibility: NotificationVisibility.public,
      category: AndroidNotificationCategory.alarm,
      fullScreenIntent: false,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    try {
      await _plugin.show(
        id,
        title,
        body,
        const NotificationDetails(
          android: androidDetails,
          iOS: iosDetails,
        ),
        payload: notification.id?.toString() ?? notification.vehicleId,
      );
    } catch (e, stack) {
      if (kDebugMode) {
        debugPrint('LocalNotificationService.showAlert failed: $e\n$stack');
      }
    }
  }

  static int _notificationId(AppNotification n) {
    if (n.id != null) {
      return n.id! % 2147483647;
    }
    return Object.hash(
      n.vehicleId,
      n.eventType.name,
      n.timestamp.millisecondsSinceEpoch ~/ 1000,
    ).abs() % 2147483647;
  }

  static String _titleFor(AppNotification n) {
    switch (n.eventType) {
      case NotificationEventType.ignitionOn:
        return 'Ignition ON — ${n.vehicleId}';
      case NotificationEventType.ignitionOff:
        return 'Ignition OFF — ${n.vehicleId}';
      case NotificationEventType.overSpeed:
        return 'Overspeed — ${n.vehicleId}';
      case NotificationEventType.geofenceIn:
        return 'Geofence entered — ${n.vehicleId}';
      case NotificationEventType.geofenceOut:
        return 'Geofence exited — ${n.vehicleId}';
      case NotificationEventType.offline:
        return 'Device offline — ${n.vehicleId}';
      case NotificationEventType.movement:
        return 'Movement — ${n.vehicleId}';
      case NotificationEventType.generic:
        return n.eventTitle.isNotEmpty
            ? n.eventTitle
            : 'Alert — ${n.vehicleId}';
    }
  }

  static String _bodyFor(AppNotification n) {
    final String location = NotificationLocationText.resolve(n);
    if (n.eventType == NotificationEventType.overSpeed && n.speed != null) {
      return '${n.speed!.toStringAsFixed(0)} km/h — $location';
    }
    return location;
  }
}
