import 'package:flutter/material.dart';

import '../models/notification_model.dart';

class NotificationData {
  NotificationData._();

  static final ValueNotifier<int> alertsRevision = ValueNotifier<int>(0);

  static void assignAlerts(List<AppNotification> next) {
    alerts = next;
    alertsRevision.value++;
  }

  static void assignAnnouncements(List<AppNotification> next) {
    announcements = next;
    alertsRevision.value++;
  }

  static void assignReminders(List<AppNotification> next) {
    reminders = next;
    alertsRevision.value++;
  }

  /// Filled from [AlertService.getEvents] — no seeded demo alerts.
  static List<AppNotification> alerts = <AppNotification>[];

  static List<AppNotification> announcements = <AppNotification>[];

  static List<AppNotification> reminders = <AppNotification>[];

  static int get alertCount => alerts.length;
  static int get announcementCount => announcements.length;
  static int get reminderCount => reminders.length;
  static int get totalBadgeCount => alertCount + announcementCount + reminderCount;
}
