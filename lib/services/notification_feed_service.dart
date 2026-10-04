import 'package:intl/intl.dart';

import '../constants/api_config.dart';
import '../data/notification_data.dart';
import '../data/vehicle_data.dart';
import '../models/notification_model.dart';
import '../models/vehicle_model.dart';
import 'auth_service.dart';
import 'tracking_api_service.dart';

/// Loads announcements and maintenance reminders for the notifications hub.
class NotificationFeedService {
  NotificationFeedService._();

  static Future<List<AppNotification>> loadAnnouncements({
    int? deviceId,
    List<AppNotification>? recentEvents,
  }) async {
    final String server = await AuthService.server();
    final String? token = await AuthService.token();
    if (!ApiConfig.usesRemoteApi(server) || token == null || token.isEmpty) {
      return NotificationData.announcements;
    }

    final List<AppNotification> out = <AppNotification>[];
    final Set<String> keys = <String>{};

    void add(AppNotification n) {
      if (deviceId != null && !_matchesDevice(n, deviceId)) {
        return;
      }
      final String key = '${n.id}_${n.timestamp.millisecondsSinceEpoch}_${n.eventTitle}';
      if (keys.add(key)) {
        out.add(n);
      }
    }

    if (recentEvents != null) {
      for (final AppNotification event in recentEvents) {
        if (_isAnnouncementEvent(event)) {
          add(event.copyWith(category: NotificationCategory.announcements));
        }
      }
    }

    final Map<String, dynamic>? userData =
        _unwrapPayload(await TrackingApiService.getUserData());
    if (userData != null) {
      for (final AppNotification n in _announcementsFromUserData(userData)) {
        add(n);
      }
    }

    out.sort(
      (AppNotification a, AppNotification b) =>
          b.timestamp.compareTo(a.timestamp),
    );
    NotificationData.assignAnnouncements(out);
    return out;
  }

  static Future<List<AppNotification>> loadReminders({int? deviceId}) async {
    final String server = await AuthService.server();
    final String? token = await AuthService.token();
    if (!ApiConfig.usesRemoteApi(server) || token == null || token.isEmpty) {
      return NotificationData.reminders;
    }

    final List<AppNotification> out = <AppNotification>[];
    final Set<String> keys = <String>{};

    void add(AppNotification n) {
      if (deviceId != null && !_matchesDevice(n, deviceId)) {
        return;
      }
      final String key = '${n.id}_${n.timestamp.millisecondsSinceEpoch}_${n.eventTitle}';
      if (keys.add(key)) {
        out.add(n);
      }
    }

    final List<Map<String, dynamic>> tasks = await TrackingApiService.getTasks();
    for (final Map<String, dynamic> task in tasks) {
      add(_reminderFromTask(task));
    }

    final List<Map<String, dynamic>> services =
        await TrackingApiService.getServices(deviceId: deviceId);
    for (final Map<String, dynamic> service in services) {
      add(_reminderFromService(service));
    }

    out.sort(
      (AppNotification a, AppNotification b) =>
          b.timestamp.compareTo(a.timestamp),
    );
    NotificationData.assignReminders(out);
    return out;
  }

  static Map<String, dynamic>? _unwrapPayload(Map<String, dynamic>? raw) {
    if (raw == null || raw.isEmpty) {
      return raw;
    }
    for (final String key in <String>['user', 'data', 'result', 'payload']) {
      final dynamic nested = raw[key];
      if (nested is Map) {
        return nested.map(
          (Object? k, Object? v) => MapEntry(k.toString(), v),
        );
      }
    }
    return raw;
  }

  static bool _matchesDevice(AppNotification n, int deviceId) {
    for (final VehicleModel v in VehicleData.vehicles) {
      if (v.id == deviceId) {
        final String name = v.name.trim().toLowerCase();
        final String id = n.vehicleId.trim().toLowerCase();
        return id == name ||
            id.contains(name) ||
            name.contains(id) ||
            id == deviceId.toString();
      }
    }
    return n.vehicleId == deviceId.toString();
  }

  static bool _isAnnouncementEvent(AppNotification n) {
    final String blob = <String>[
      n.eventTitle,
      n.location,
    ].join(' ').toLowerCase();
    return blob.contains('announce') ||
        blob.contains('broadcast') ||
        blob.contains('news') ||
        blob.contains('company message') ||
        blob.contains('admin message');
  }

  static List<AppNotification> _announcementsFromUserData(
    Map<String, dynamic> root,
  ) {
    final List<AppNotification> list = <AppNotification>[];
    void walk(dynamic node, {String? fallbackTitle}) {
      if (node == null) {
        return;
      }
      if (node is List) {
        for (final dynamic item in node) {
          walk(item, fallbackTitle: fallbackTitle);
        }
        return;
      }
      if (node is! Map) {
        final String text = node.toString().trim();
        if (text.length > 8) {
          list.add(
            AppNotification(
              vehicleId: 'M-Track',
              eventTitle: fallbackTitle ?? 'Announcement',
              location: text,
              timestamp: DateTime.now(),
              category: NotificationCategory.announcements,
            ),
          );
        }
        return;
      }
      final Map<String, dynamic> map = node.map(
        (Object? k, Object? v) => MapEntry(k.toString(), v),
      );
      final String title = (map['title'] ??
              map['name'] ??
              map['subject'] ??
              fallbackTitle ??
              'Announcement')
          .toString()
          .trim();
      final String body = (map['message'] ??
              map['body'] ??
              map['text'] ??
              map['content'] ??
              map['description'] ??
              '')
          .toString()
          .trim();
      if (body.isNotEmpty || (title.isNotEmpty && title != 'Announcement')) {
        list.add(
          AppNotification(
            id: int.tryParse(map['id']?.toString() ?? ''),
            vehicleId: (map['author'] ?? map['from'] ?? 'M-Track').toString(),
            eventTitle: title.isEmpty ? 'Announcement' : title,
            location: body.isEmpty ? title : body,
            timestamp: _parseDateTime(map['created_at'] ??
                    map['updated_at'] ??
                    map['time'] ??
                    map['date']) ??
                DateTime.now(),
            category: NotificationCategory.announcements,
          ),
        );
      }
      for (final String key in <String>[
        'news',
        'announcements',
        'announcement',
        'messages',
        'notifications',
        'items',
        'data',
      ]) {
        if (map.containsKey(key)) {
          walk(map[key], fallbackTitle: title);
        }
      }
      if (map['user'] is Map) {
        walk(map['user'], fallbackTitle: title);
      }
    }

    for (final String topKey in <String>[
      'news',
      'announcements',
      'announcement',
      'messages',
    ]) {
      if (root.containsKey(topKey)) {
        walk(root[topKey], fallbackTitle: 'Announcement');
      }
    }
    if (list.isEmpty && root['message'] != null) {
      walk(<String, dynamic>{'message': root['message']}, fallbackTitle: 'Announcement');
    }
    return list;
  }

  static AppNotification _reminderFromTask(Map<String, dynamic> task) {
    final String title =
        (task['title'] ?? task['name'] ?? 'Maintenance reminder').toString();
    final DateTime when =
        _parseDateTime(task['expires'] ??
                task['expires_at'] ??
                task['due_date'] ??
                task['remind_date'] ??
                task['time'] ??
                task['created_at']) ??
            DateTime.now();
    final String vehicle = _vehicleLabelFromRow(task);
    final String detail = _reminderDetailLine(task, when);
    return AppNotification(
      id: int.tryParse(task['id']?.toString() ?? ''),
      vehicleId: vehicle,
      eventTitle: title,
      location: detail,
      timestamp: when,
      category: NotificationCategory.reminders,
    );
  }

  static AppNotification _reminderFromService(Map<String, dynamic> row) {
    final String title =
        (row['name'] ?? row['title'] ?? row['description'] ?? 'Service reminder')
            .toString();
    final DateTime when =
        _parseDateTime(row['expires_at'] ??
                row['expiration'] ??
                row['next_service'] ??
                row['updated_at'] ??
                row['created_at']) ??
            DateTime.now();
    final String vehicle = _vehicleLabelFromRow(row);
    final String interval = (row['interval'] ??
            row['odometer_interval'] ??
            row['period'] ??
            '')
        .toString();
    final String last = (row['last_service'] ??
            row['odometer_last'] ??
            row['previous'] ??
            '')
        .toString();
    final StringBuffer detail = StringBuffer();
    if (interval.isNotEmpty) {
      detail.write('Interval: $interval');
    }
    if (last.isNotEmpty) {
      if (detail.isNotEmpty) {
        detail.write(' · ');
      }
      detail.write('Last: $last');
    }
    if (detail.isEmpty) {
      detail.write(_reminderDetailLine(row, when));
    }
    return AppNotification(
      id: int.tryParse(row['id']?.toString() ?? ''),
      vehicleId: vehicle,
      eventTitle: title,
      location: detail.toString(),
      timestamp: when,
      category: NotificationCategory.reminders,
    );
  }

  static String _vehicleLabelFromRow(Map<String, dynamic> row) {
    final String? direct = (row['device_name'] ?? row['vehicle'])?.toString();
    if (direct != null && direct.trim().isNotEmpty) {
      return direct.trim();
    }
    final int? id = int.tryParse(
      (row['device_id'] ?? row['deviceId'])?.toString() ?? '',
    );
    if (id != null) {
      for (final VehicleModel v in VehicleData.vehicles) {
        if (v.id == id) {
          return v.name;
        }
      }
      return 'Device $id';
    }
    return 'Fleet';
  }

  static String _reminderDetailLine(Map<String, dynamic> row, DateTime when) {
    final String due = DateFormat('dd MMM yyyy, hh:mm a').format(when);
    if (when.isBefore(DateTime.now())) {
      return 'Overdue · Due $due';
    }
    return 'Due $due';
  }

  static DateTime? _parseDateTime(dynamic raw) {
    if (raw == null) {
      return null;
    }
    if (raw is int) {
      return raw > 9999999999
          ? DateTime.fromMillisecondsSinceEpoch(raw)
          : DateTime.fromMillisecondsSinceEpoch(raw * 1000);
    }
    final String text = raw.toString().trim();
    if (text.isEmpty) {
      return null;
    }
    final DateTime? iso = DateTime.tryParse(text.replaceAll('/', '-'));
    if (iso != null) {
      return iso;
    }
    const List<String> patterns = <String>[
      'yyyy-MM-dd HH:mm:ss',
      'dd-MM-yyyy HH:mm:ss',
      'dd-MM-yyyy hh:mm:ss a',
      'yyyy-MM-dd',
      'dd-MM-yyyy',
    ];
    for (final String pattern in patterns) {
      try {
        return DateFormat(pattern).parse(text);
      } catch (_) {}
    }
    return null;
  }
}
