import 'package:flutter/material.dart';

import '../data/vehicle_data.dart';
import 'vehicle_model.dart';
import '../utils/coordinate_parser.dart';

enum NotificationCategory { alerts, announcements, reminders }

enum NotificationEventType {
  ignitionOff,
  ignitionOn,
  overSpeed,
  geofenceIn,
  geofenceOut,
  offline,
  movement,
  generic,
}

class AppNotification {
  final int? id;
  final String vehicleId;
  final String eventTitle;
  final String location;
  final DateTime timestamp;
  final NotificationCategory category;
  final NotificationEventType eventType;
  final double? latitude;
  final double? longitude;
  final double? speed;

  const AppNotification({
    this.id,
    required this.vehicleId,
    required this.eventTitle,
    required this.location,
    required this.timestamp,
    required this.category,
    this.eventType = NotificationEventType.generic,
    this.latitude,
    this.longitude,
    this.speed,
  });

  AppNotification copyWith({
    int? id,
    String? vehicleId,
    String? eventTitle,
    String? location,
    DateTime? timestamp,
    NotificationCategory? category,
    NotificationEventType? eventType,
    double? latitude,
    double? longitude,
    double? speed,
  }) {
    return AppNotification(
      id: id ?? this.id,
      vehicleId: vehicleId ?? this.vehicleId,
      eventTitle: eventTitle ?? this.eventTitle,
      location: location ?? this.location,
      timestamp: timestamp ?? this.timestamp,
      category: category ?? this.category,
      eventType: eventType ?? this.eventType,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      speed: speed ?? this.speed,
    );
  }

  factory AppNotification.fromJson(
    Map<String, dynamic> json, {
    Map<int, String>? deviceNamesById,
  }) {
    final int? id = int.tryParse(json['id']?.toString() ?? '');
    final dynamic deviceIdVal = json['device_id'] ?? json['deviceId'];
    final int? deviceId = int.tryParse(deviceIdVal?.toString() ?? '');

    // Resolve vehicle name
    String vehicleName = '';
    if (json['device_name'] != null && json['device_name'].toString().isNotEmpty) {
      vehicleName = json['device_name'].toString();
    } else if (json['device'] is Map && json['device']['name'] != null) {
      vehicleName = json['device']['name'].toString();
    } else if (deviceId != null && deviceNamesById != null && deviceNamesById.containsKey(deviceId)) {
      vehicleName = deviceNamesById[deviceId]!;
    } else if (deviceIdVal != null) {
      vehicleName = deviceIdVal.toString();
    } else {
      vehicleName = 'Vehicle';
    }

    // Resolve event message / title
    String title = '';
    if (json['message'] != null && json['message'].toString().isNotEmpty) {
      title = json['message'].toString();
    } else if (json['alert'] is Map && json['alert']['name'] != null) {
      title = json['alert']['name'].toString();
    } else if (json['name'] != null && json['name'].toString().isNotEmpty) {
      title = json['name'].toString();
    } else if (json['title'] != null && json['title'].toString().isNotEmpty) {
      title = json['title'].toString();
    } else {
      title = 'Alert';
    }

    final (double lat, double lng)? coords = CoordinateParser.fromMap(json);

    // Resolve location / address
    String locationStr = '';
    if (json['address'] != null && json['address'].toString().trim().isNotEmpty) {
      locationStr = json['address'].toString().trim();
    } else if (json['location'] != null && json['location'].toString().trim().isNotEmpty) {
      locationStr = json['location'].toString().trim();
    } else if (coords != null) {
      locationStr = '${coords.$1}, ${coords.$2}';
    } else {
      locationStr = 'Location not available';
    }

    // Resolve timestamp
    DateTime time = DateTime.now();
    final dynamic rawTime =
        json['time'] ?? json['created_at'] ?? json['timestamp'] ?? json['date'];
    if (rawTime != null) {
      if (rawTime is int) {
        time = rawTime > 9999999999
            ? DateTime.fromMillisecondsSinceEpoch(rawTime)
            : DateTime.fromMillisecondsSinceEpoch(rawTime * 1000);
      } else {
        final DateTime? parsed =
            DateTime.tryParse(rawTime.toString().replaceAll('/', '-'));
        if (parsed != null) {
          time = parsed;
        }
      }
    }

    // Resolve type
    final String alertName = json['alert'] is Map
        ? (json['alert']['name'] ?? json['alert']['type'] ?? '').toString()
        : '';
    final String rawType = <String>[
      json['type']?.toString() ?? '',
      json['event_type']?.toString() ?? '',
      json['alert_type']?.toString() ?? '',
      alertName,
      title,
      json['message']?.toString() ?? '',
      json['name']?.toString() ?? '',
    ].join(' ').toLowerCase();

    NotificationEventType eventType = NotificationEventType.generic;
    if (rawType.contains('ignition off') ||
        rawType.contains('ignition_off') ||
        rawType.contains('acc off') ||
        rawType.contains('acc_off') ||
        rawType.contains('engine off') ||
        rawType.contains('engine_off') ||
        rawType.contains('power off')) {
      eventType = NotificationEventType.ignitionOff;
    } else if (rawType.contains('ignition on') ||
        rawType.contains('ignition_on') ||
        rawType.contains('acc on') ||
        rawType.contains('acc_on') ||
        rawType.contains('engine on') ||
        rawType.contains('engine_on') ||
        rawType.contains('power on')) {
      eventType = NotificationEventType.ignitionOn;
    } else if (rawType.contains('overspeed') ||
        rawType.contains('over speed') ||
        rawType.contains('over-speed') ||
        rawType.contains('speed limit') ||
        rawType.contains('max speed') ||
        (rawType.contains('speed') && !rawType.contains('speed limit reset'))) {
      eventType = NotificationEventType.overSpeed;
    } else if (rawType.contains('geofence_in') || rawType.contains('zone_in') || rawType.contains('enter')) {
      eventType = NotificationEventType.geofenceIn;
    } else if (rawType.contains('geofence_out') || rawType.contains('zone_out') || rawType.contains('exit')) {
      eventType = NotificationEventType.geofenceOut;
    } else if (rawType.contains('offline') || rawType.contains('disconnect')) {
      eventType = NotificationEventType.offline;
    } else if (rawType.contains('move') || rawType.contains('movement')) {
      eventType = NotificationEventType.movement;
    }

    double? lat = coords?.$1;
    double? lng = coords?.$2;

    if (lat == null || lng == null) {
      final (double pLat, double pLng)? fromText =
          CoordinateParser.parsePair(locationStr);
      lat ??= fromText?.$1;
      lng ??= fromText?.$2;
    }

    if ((lat == null || lng == null) && deviceId != null) {
      for (final VehicleModel vehicle in VehicleData.vehicles) {
        if (vehicle.id == deviceId) {
          lat ??= vehicle.latitude;
          lng ??= vehicle.longitude;
          if (locationStr == 'Location not available' ||
              CoordinateParser.looksLikeCoordinatePair(locationStr)) {
            locationStr = vehicle.location;
          }
          break;
        }
      }
    }

    if ((lat == null || lng == null) && vehicleName.isNotEmpty) {
      for (final VehicleModel vehicle in VehicleData.vehicles) {
        if (vehicle.name.trim().toLowerCase() ==
            vehicleName.trim().toLowerCase()) {
          lat ??= vehicle.latitude;
          lng ??= vehicle.longitude;
          if (locationStr == 'Location not available' ||
              CoordinateParser.looksLikeCoordinatePair(locationStr)) {
            locationStr = vehicle.location;
          }
          break;
        }
      }
    }

    double? speed = double.tryParse((json['speed'])?.toString() ?? '');
    speed ??= _parseSpeedFromMessage(title) ?? _parseSpeedFromMessage(json['message']?.toString());

    return AppNotification(
      id: id,
      vehicleId: vehicleName,
      eventTitle: title,
      location: locationStr,
      timestamp: time,
      category: NotificationCategory.alerts,
      eventType: eventType,
      latitude: lat,
      longitude: lng,
      speed: speed,
    );
  }

  static double? _parseSpeedFromMessage(String? text) {
    if (text == null || text.trim().isEmpty) {
      return null;
    }
    final RegExp match = RegExp(
      r'(\d+(?:\.\d+)?)\s*(?:km/h|kmph|kmh|kph)',
      caseSensitive: false,
    );
    final RegExpMatch? found = match.firstMatch(text);
    if (found != null) {
      return double.tryParse(found.group(1)!);
    }
    return null;
  }
}

extension NotificationEventTypeStyle on NotificationEventType {
  IconData get icon {
    switch (this) {
      case NotificationEventType.ignitionOff:
      case NotificationEventType.ignitionOn:
        return Icons.power_settings_new;
      case NotificationEventType.overSpeed:
        return Icons.speed;
      case NotificationEventType.geofenceIn:
      case NotificationEventType.geofenceOut:
        return Icons.location_on_outlined;
      case NotificationEventType.offline:
        return Icons.signal_cellular_off;
      case NotificationEventType.movement:
        return Icons.directions_car;
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
      case NotificationEventType.geofenceIn:
        return const Color(0xFF2E7D32);
      case NotificationEventType.geofenceOut:
        return const Color(0xFFE65100);
      case NotificationEventType.offline:
        return Colors.grey;
      case NotificationEventType.movement:
        return const Color(0xFF1976D2);
      case NotificationEventType.generic:
        return const Color(0xFFF43A6B);
    }
  }
}
