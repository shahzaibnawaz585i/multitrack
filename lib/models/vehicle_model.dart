import 'package:flutter/material.dart';

import '../services/reverse_geocoding_service.dart';

class VehicleTrackPoint {
  const VehicleTrackPoint({
    required this.latitude,
    required this.longitude,
  });

  final double latitude;
  final double longitude;
}

class VehicleModel {
  final int? id;
  final String name;
  final String status;
  final Color color;
  final String speed;
  final String distance;
  final String odometer;
  final String time;
  final String liveTime;
  final String location;
  final String date;
  final String? validity;

  final double? latitude;
  final double? longitude;
  final List<VehicleTrackPoint> tail;

  const VehicleModel({
    this.id,
    required this.name,
    required this.status,
    required this.color,
    required this.speed,
    required this.distance,
    required this.odometer,
    required this.time,
    required this.liveTime,
    required this.location,
    required this.date,
    this.validity,
    this.latitude,
    this.longitude,
    this.tail = const <VehicleTrackPoint>[],
  });

  VehicleModel copyWith({
    int? id,
    String? name,
    String? status,
    Color? color,
    String? speed,
    String? distance,
    String? odometer,
    String? time,
    String? liveTime,
    String? location,
    String? date,
    String? validity,
    double? latitude,
    double? longitude,
    List<VehicleTrackPoint>? tail,
  }) {
    return VehicleModel(
      id: id ?? this.id,
      name: name ?? this.name,
      status: status ?? this.status,
      color: color ?? this.color,
      speed: speed ?? this.speed,
      distance: distance ?? this.distance,
      odometer: odometer ?? this.odometer,
      time: time ?? this.time,
      liveTime: liveTime ?? this.liveTime,
      location: location ?? this.location,
      date: date ?? this.date,
      validity: validity ?? this.validity,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      tail: tail ?? this.tail,
    );
  }

  String get validityLabel {
    if (status.trim().toLowerCase() == 'expired') {
      if (validity != null && validity!.isNotEmpty) {
        return validity!.toLowerCase().contains('expire')
            ? validity!
            : 'Expired: $validity';
      }
      return 'Expired';
    }
    return validity ?? '449 Days Validity';
  }

  factory VehicleModel.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> deviceData =
        json['device_data'] is Map<String, dynamic>
            ? json['device_data'] as Map<String, dynamic>
            : (json['device_data'] is Map
                ? (json['device_data'] as Map).map(
                    (Object? k, Object? v) => MapEntry(k.toString(), v),
                  )
                : <String, dynamic>{});

    final String name = (json['name'] ??
            deviceData['name'] ??
            json['title'] ??
            json['plate_number'] ??
            json['device_name'] ??
            json['car_number'] ??
            'Vehicle')
        .toString()
        .trim();

    final double rawSpeedDouble = _resolveRawSpeed(json, deviceData);
    final String speed = _formatSpeed(rawSpeedDouble);

    final String rawStatus = (json['status'] ??
            json['online'] ??
            deviceData['status'] ??
            deviceData['online'] ??
            json['device_status'] ??
            json['state'] ??
            '')
        .toString()
        .trim();

    final String status = _normalizeStatus(rawStatus, json, deviceData, rawSpeedDouble);
    final Color color = _statusColor(status);

    final String distance = (json['distance'] ??
            json['today_distance'] ??
            deviceData['distance'] ??
            deviceData['today_distance'] ??
            '0 km')
        .toString();

    final String odometer = _resolveOdometer(json, deviceData);

    final String time = (json['time'] ??
            json['stop_duration'] ??
            json['idle_duration'] ??
            json['duration'] ??
            json['ack_time'] ??
            deviceData['stop_duration'] ??
            '')
        .toString();

    final (double? lat, double? lng) = _resolveLatLng(json, deviceData);
    final List<VehicleTrackPoint> tail = _resolveTail(json, deviceData);
    final String liveTime = _resolveLiveTime(json, deviceData);
    final String location = _resolveLocation(json, deviceData, lat, lng);
    final String date = _resolveDate(json, deviceData);

    final String? validity = (json['validity'] ??
            json['expiration_date'] ??
            json['expires_in'] ??
            deviceData['expiration_date'])
        ?.toString();

    final int? id = int.tryParse((json['id'] ?? deviceData['id'] ?? '').toString());

    return VehicleModel(
      id: id,
      name: name,
      status: status,
      color: color,
      speed: speed,
      distance: distance.isEmpty ? '0 km' : distance,
      odometer: odometer,
      time: time.isEmpty
          ? 'since 0d 0h 0m'
          : (time.startsWith('since ') || time.startsWith('3')
              ? time
              : 'since $time'),
      liveTime: liveTime.isEmpty ? '02:00:00 PM' : liveTime,
      location: location,
      date: date.isEmpty ? 'Today' : date,
      validity: validity,
      latitude: lat,
      longitude: lng,
      tail: tail,
    );
  }

  static List<VehicleTrackPoint> _resolveTail(
    Map<String, dynamic> json,
    Map<String, dynamic> deviceData,
  ) {
    final dynamic rawTail = json['tail'] ?? deviceData['tail'];
    if (rawTail is! List || rawTail.isEmpty) {
      return const <VehicleTrackPoint>[];
    }

    final List<VehicleTrackPoint> points = <VehicleTrackPoint>[];
    for (final dynamic item in rawTail) {
      if (item is! Map) continue;
      final Map<String, dynamic> map = item.map(
        (Object? k, Object? v) => MapEntry(k.toString(), v),
      );
      final double? lat = double.tryParse(
        (map['lat'] ?? map['latitude'])?.toString() ?? '',
      );
      final double? lng = double.tryParse(
        (map['lng'] ?? map['lon'] ?? map['longitude'])?.toString() ?? '',
      );
      if (lat != null &&
          lng != null &&
          (lat != 0.0 || lng != 0.0) &&
          lat.abs() <= 90 &&
          lng.abs() <= 180) {
        points.add(VehicleTrackPoint(latitude: lat, longitude: lng));
      }
    }
    return points;
  }

  static (double?, double?) _resolveLatLng(
    Map<String, dynamic> json,
    Map<String, dynamic> deviceData,
  ) {
    final dynamic latVal = json['lat'] ??
        json['latitude'] ??
        deviceData['lat'] ??
        deviceData['latitude'] ??
        json['last_valid_latitude'] ??
        deviceData['last_valid_latitude'] ??
        json['latest_position']?['lat'] ??
        json['latest_position']?['latitude'] ??
        json['point']?['lat'] ??
        json['position']?['latitude'] ??
        json['position']?['lat'];

    final dynamic lngVal = json['lng'] ??
        json['lon'] ??
        json['longitude'] ??
        deviceData['lng'] ??
        deviceData['lon'] ??
        deviceData['longitude'] ??
        json['last_valid_longitude'] ??
        deviceData['last_valid_longitude'] ??
        json['latest_position']?['lng'] ??
        json['latest_position']?['longitude'] ??
        json['point']?['lng'] ??
        json['position']?['longitude'] ??
        json['position']?['lng'] ??
        json['position']?['lon'];

    double? lat = double.tryParse(latVal?.toString() ?? '');
    double? lng = double.tryParse(lngVal?.toString() ?? '');

    // Check tail if lat/lng are null or (0,0)
    if ((lat == null || lng == null || (lat == 0.0 && lng == 0.0)) &&
        json['tail'] is List &&
        (json['tail'] as List).isNotEmpty) {
      final dynamic lastTail = (json['tail'] as List).last;
      if (lastTail is Map) {
        lat ??= double.tryParse(
            (lastTail['lat'] ?? lastTail['latitude'])?.toString() ?? '');
        lng ??= double.tryParse(
            (lastTail['lng'] ?? lastTail['lon'] ?? lastTail['longitude'])
                    ?.toString() ??
                '');
      }
    }

    return (lat, lng);
  }

  static String _resolveLocation(
    Map<String, dynamic> json,
    Map<String, dynamic> deviceData,
    double? lat,
    double? lng,
  ) {
    // 1. Direct text addresses
    final dynamic direct = json['location'] ??
        json['address'] ??
        json['formatted_address'] ??
        json['street'] ??
        deviceData['location'] ??
        deviceData['address'] ??
        deviceData['formatted_address'] ??
        deviceData['street'] ??
        json['other_arr']?['address'] ??
        json['position']?['address'] ??
        json['last_valid_address'] ??
        deviceData['last_valid_address'];

    if (direct != null) {
      final String directStr = direct.toString().trim();
      final String lower = directStr.toLowerCase();
      if (directStr.isNotEmpty &&
          directStr != '-' &&
          directStr != '--' &&
          directStr != '---' &&
          lower != 'no data' &&
          lower != 'null' &&
          lower != 'n/a' &&
          lower != 'na' &&
          lower != 'none' &&
          lower != 'nil' &&
          lower != 'no address' &&
          lower != 'unknown' &&
          lower != 'nodata') {
        return directStr;
      }
    }

    // 2. Check if already cached in ReverseGeocodingService
    if (lat != null && lng != null && (lat != 0.0 || lng != 0.0)) {
      final String? cached = ReverseGeocodingService.getCached(lat, lng);
      if (cached != null &&
          cached.isNotEmpty &&
          cached != 'Location not available') {
        return cached;
      }
    }

    return 'Location not available';
  }

  static String _resolveLiveTime(
    Map<String, dynamic> json,
    Map<String, dynamic> deviceData,
  ) {
    final dynamic val = json['liveTime'] ??
        json['time_formatted'] ??
        json['last_update'] ??
        json['updated_at'] ??
        json['time'] ??
        json['device_time'] ??
        json['server_time'] ??
        deviceData['time'] ??
        deviceData['last_update'];

    if (val != null && val.toString().trim().isNotEmpty) {
      final String str = val.toString().trim();
      // If contains full datetime (2025-09-04 14:26:00), extract time
      if (str.contains(' ') && str.length >= 16) {
        final List<String> parts = str.split(' ');
        if (parts.length >= 2) {
          return parts.sublist(1).join(' ');
        }
      }
      return str;
    }
    return '02:00:00 PM';
  }

  static String _resolveDate(
    Map<String, dynamic> json,
    Map<String, dynamic> deviceData,
  ) {
    final dynamic val = json['date'] ??
        json['device_date'] ??
        json['last_date'] ??
        json['time'] ??
        deviceData['time'] ??
        deviceData['date'];

    if (val != null && val.toString().trim().isNotEmpty) {
      final String str = val.toString().trim();
      if (str.contains(' ')) {
        return str.split(' ').first;
      }
      return str;
    }
    return 'Today';
  }

  static double _resolveRawSpeed(
    Map<String, dynamic> json,
    Map<String, dynamic> deviceData,
  ) {
    final dynamic speedVal = json['speed'] ??
        deviceData['speed'] ??
        json['latest_position']?['speed'] ??
        json['position']?['speed'] ??
        json['device_speed'] ??
        json['last_speed'] ??
        json['other_arr']?['speed'];

    if (speedVal != null) {
      final double? spd = double.tryParse(speedVal.toString());
      if (spd != null && !spd.isNaN) {
        return spd;
      }
    }

    // Check sensors if speed sensor exists
    final dynamic sensors = json['sensors'] ?? deviceData['sensors'];
    if (sensors is List) {
      for (final dynamic sensor in sensors) {
        if (sensor is Map) {
          final String sType =
              (sensor['type'] ?? sensor['name'] ?? '').toString().toLowerCase();
          if (sType.contains('speed')) {
            final dynamic val = sensor['value'] ?? sensor['val'];
            final double? spd = double.tryParse(val?.toString() ?? '');
            if (spd != null && !spd.isNaN) {
              return spd;
            }
          }
        }
      }
    }

    // Check tail if latest point has speed
    if (json['tail'] is List && (json['tail'] as List).isNotEmpty) {
      final dynamic lastTail = (json['tail'] as List).last;
      if (lastTail is Map) {
        final dynamic tailSpeed = lastTail['speed'];
        if (tailSpeed != null) {
          final double? spd = double.tryParse(tailSpeed.toString());
          if (spd != null && !spd.isNaN) {
            return spd;
          }
        }
      }
    }

    return 0.0;
  }

  static bool _checkIfExpired(
    Map<String, dynamic> json,
    Map<String, dynamic> deviceData,
    String rawStatus,
  ) {
    final String lower = rawStatus.toLowerCase().trim();
    if (lower.contains('expire')) {
      return true;
    }

    if (json['expired'] == true ||
        json['expired'] == 1 ||
        json['expired'] == '1' ||
        deviceData['expired'] == true ||
        deviceData['expired'] == 1 ||
        deviceData['expired'] == '1' ||
        json['is_expired'] == 1 ||
        deviceData['is_expired'] == 1) {
      return true;
    }

    // Check expiration_date
    final dynamic exp = json['expiration_date'] ??
        json['expires_date'] ??
        json['validity_date'] ??
        deviceData['expiration_date'];
    if (exp != null && exp.toString().trim().isNotEmpty) {
      final String expStr = exp.toString().trim();
      final DateTime? parsed = DateTime.tryParse(expStr.replaceAll('/', '-'));
      if (parsed != null && parsed.isBefore(DateTime.now())) {
        return true;
      }
    }

    // Check expires_in / validity string (e.g. "-10 days", "Expired", "0 days")
    final dynamic expiresIn = json['expires_in'] ??
        deviceData['expires_in'] ??
        json['validity'] ??
        deviceData['validity'];
    if (expiresIn != null) {
      final String str = expiresIn.toString().toLowerCase().trim();
      if (str.contains('expired') || str.contains('expire')) {
        return true;
      }
      if (str.startsWith('-') || str == '0 days' || str == '0d' || str == '0') {
        return true;
      }
    }

    // Check active == 0 / false combined with expiration or inactive
    final dynamic active = json['active'] ?? deviceData['active'];
    if (active == 0 || active == '0' || active == false) {
      if (exp != null && exp.toString().trim().isNotEmpty) {
        final DateTime? parsed =
            DateTime.tryParse(exp.toString().trim().replaceAll('/', '-'));
        if (parsed != null && parsed.isBefore(DateTime.now())) {
          return true;
        }
      }
      final dynamic plan = json['plan'] ?? deviceData['plan'];
      if (plan != null && plan.toString().toLowerCase().contains('expire')) {
        return true;
      }
    }

    return false;
  }

  static String _normalizeStatus(
    String raw,
    Map<String, dynamic> json,
    Map<String, dynamic> deviceData,
    double speed,
  ) {
    // 1. Expired check first (even if vehicle is offline / inactive)
    if (_checkIfExpired(json, deviceData, raw)) {
      return 'EXPIRED';
    }

    final String lower = raw.toLowerCase().trim();

    // 2. Offline / Inactive check
    if (lower == 'offline' ||
        lower == 'inactive' ||
        lower == 'not reporting' ||
        lower == 'nodata' ||
        lower == 'disconnected') {
      return 'Not Reporting';
    }

    // 3. Real movement check: if speed > 0, vehicle is RUNNING
    if (speed > 0) {
      return 'RUNNING';
    }

    // 4. If speed is 0:
    // Check if explicitly stopped / parked
    if (lower == 'stop' || lower == 'stopped' || lower == 'parked') {
      return 'STOPPED';
    }

    // Check ignition / engine status
    final dynamic ignition = json['ignition'] ??
        json['acc'] ??
        json['engine'] ??
        json['engine_status'] ??
        deviceData['engine_status'] ??
        deviceData['ignition'];

    final bool isEngineOn = ignition == true ||
        ignition == 1 ||
        ignition == '1' ||
        ignition == 'on' ||
        ignition == 'true';

    final bool isEngineOff = ignition == false ||
        ignition == 0 ||
        ignition == '0' ||
        ignition == 'off' ||
        ignition == 'false';

    if (lower == 'idle' || lower == 'engine' || lower == 'standby' || isEngineOn) {
      return 'IDLE';
    }

    if (isEngineOff) {
      return 'STOPPED';
    }

    // If online/ack or other status with speed == 0, it is STOPPED
    if (lower == 'online' ||
        lower == 'ack' ||
        lower == 'running' ||
        lower == 'moving') {
      return 'STOPPED';
    }

    return raw.isNotEmpty ? raw.toUpperCase() : 'Not Reporting';
  }

  static Color _statusColor(String status) {
    switch (status.trim().toLowerCase()) {
      case 'running':
        return Colors.green;
      case 'idle':
        return Colors.orange;
      case 'stopped':
        return Colors.red;
      case 'expired':
        return const Color(0xFFF43A6B);
      case 'not reporting':
      case 'inactive':
      default:
        return const Color(0xFF5B9BD5);
    }
  }

  static String _formatSpeed(dynamic speed) {
    if (speed == null) return '00';
    final double? parsed = double.tryParse(speed.toString());
    if (parsed == null || parsed <= 0) return '00';
    return parsed.round().toString().padLeft(2, '0');
  }

  static String _resolveOdometer(
    Map<String, dynamic> json,
    Map<String, dynamic> deviceData,
  ) {
    final dynamic raw = json['odometer'] ??
        deviceData['odometer'] ??
        json['total_distance'] ??
        deviceData['total_distance'] ??
        json['total_km'] ??
        deviceData['total_km'] ??
        json['odometer_value'] ??
        deviceData['odometer_value'];

    if (raw == null) return '0 km';

    final String str = raw.toString().trim();
    if (str.isEmpty) return '0 km';
    if (str.toLowerCase().contains('km')) return str;

    final double? parsed = double.tryParse(str.replaceAll(',', ''));
    if (parsed != null) {
      return '${parsed.toStringAsFixed(2)} km';
    }
    return str;
  }
}
