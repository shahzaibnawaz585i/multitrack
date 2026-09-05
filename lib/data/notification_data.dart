import '../models/notification_model.dart';

class NotificationData {
  NotificationData._();

  static const String _location =
      'Jagdamba Packaging Industries, Samana - Sehjapur Kalan Rd, Samana Rural, Punjab 147101, India';

  static List<AppNotification> alerts = <AppNotification>[
    AppNotification(
      vehicleId: 'PB11DD9661',
      eventTitle: 'Ignition Off',
      location: _location,
      timestamp: DateTime(2026, 7, 22, 16, 50),
      category: NotificationCategory.alerts,
      eventType: NotificationEventType.ignitionOff,
    ),
    AppNotification(
      vehicleId: 'PB11DD9661',
      eventTitle: 'Ignition On',
      location: _location,
      timestamp: DateTime(2026, 7, 22, 16, 45),
      category: NotificationCategory.alerts,
      eventType: NotificationEventType.ignitionOn,
    ),
    AppNotification(
      vehicleId: 'PB11DD9661',
      eventTitle: 'Device OverSpeed',
      location: _location,
      timestamp: DateTime(2026, 7, 22, 16, 40),
      category: NotificationCategory.alerts,
      eventType: NotificationEventType.overSpeed,
    ),
    AppNotification(
      vehicleId: 'PB11DD9661',
      eventTitle: 'Ignition Off',
      location: _location,
      timestamp: DateTime(2026, 7, 22, 16, 35),
      category: NotificationCategory.alerts,
      eventType: NotificationEventType.ignitionOff,
    ),
    AppNotification(
      vehicleId: 'PB11DD9661',
      eventTitle: 'Ignition On',
      location: _location,
      timestamp: DateTime(2026, 7, 22, 16, 30),
      category: NotificationCategory.alerts,
      eventType: NotificationEventType.ignitionOn,
    ),
    AppNotification(
      vehicleId: 'PB11DD9661',
      eventTitle: 'Device OverSpeed',
      location: _location,
      timestamp: DateTime(2026, 7, 22, 16, 25),
      category: NotificationCategory.alerts,
      eventType: NotificationEventType.overSpeed,
    ),
  ];

  static final List<AppNotification> reminders = <AppNotification>[
    AppNotification(
      vehicleId: 'MH12RK8741',
      eventTitle: 'Document Expired',
      location: 'Renew vehicle documents before expiry.',
      timestamp: DateTime(2026, 7, 24, 10, 0),
      category: NotificationCategory.reminders,
    ),
    AppNotification(
      vehicleId: '5612',
      eventTitle: 'Maintenance Due',
      location: 'Schedule service for this vehicle.',
      timestamp: DateTime(2026, 7, 23, 9, 30),
      category: NotificationCategory.reminders,
    ),
  ];

  static int get alertCount => alerts.length;
  static int get announcementCount => 0;
  static int get reminderCount => reminders.length;
  static int get totalBadgeCount => alertCount + announcementCount + reminderCount;
}
