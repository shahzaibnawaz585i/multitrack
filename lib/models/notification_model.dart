import 'package:flutter/material.dart';

enum NotificationCategory { alerts, announcements, reminders }

enum NotificationEventType {
  ignitionOff,
  ignitionOn,
  overSpeed,
  generic,
}

class AppNotification {
  final String vehicleId;
  final String eventTitle;
  final String location;
  final DateTime timestamp;
  final NotificationCategory category;
  final NotificationEventType eventType;

  const AppNotification({
    required this.vehicleId,
    required this.eventTitle,
    required this.location,
    required this.timestamp,
    required this.category,
    this.eventType = NotificationEventType.generic,
  });
}

extension NotificationEventTypeStyle on NotificationEventType {
  IconData get icon {
    switch (this) {
      case NotificationEventType.ignitionOff:
      case NotificationEventType.ignitionOn:
        return Icons.power_settings_new;
      case NotificationEventType.overSpeed:
        return Icons.speed;
      case NotificationEventType.generic:
        return Icons.notifications_none;
    }
  }

  Color get iconColor {
    switch (this) {
      case NotificationEventType.ignitionOff:
        return Colors.red;
      case NotificationEventType.ignitionOn:
        return Colors.green;
      case NotificationEventType.overSpeed:
        return const Color(0xFFF43A6B);
      case NotificationEventType.generic:
        return const Color(0xFFF43A6B);
    }
  }
}
