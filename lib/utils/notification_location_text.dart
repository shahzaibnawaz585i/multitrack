import '../models/notification_model.dart';
import '../services/notification_location_resolver.dart';

class NotificationLocationText {
  NotificationLocationText._();

  static String resolve(AppNotification notification) {
    return NotificationLocationResolver.resolveSync(notification);
  }
}
