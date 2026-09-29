import 'package:flutter/material.dart';

import '../services/reverse_geocoding_service.dart';
import '../utils/coordinate_parser.dart';

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
  final String date;
  final String? validity;

  final double? latitude;
  final double? longitude;
  final List<VehicleTrackPoint> tail;
  final String location;

  // Real-time statistics fields
  final String deviceTime;
  final String serverTime;
  final String runningDuration;
  final String stopDuration;
  final String idleDuration;
  final String inactiveDuration;
  final String fuelMileage;
  final String fuelConsumption;
  final String fuelCost;
  final String avgSpeed;
  final String maxSpeed;

  // Sensor fields
  final String devBattery;
  final String engineHours;
  final String carBattery;
  final String satellites;
  final String fuelLevel;
  final String accuracy;
  final String temperature;
  final String movement;

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
    this.deviceTime = 'N/A',
    this.serverTime = 'N/A',
    this.runningDuration = '00:00:00 Hrs',
    this.stopDuration = '00:00:00 Hrs',
    this.idleDuration = '00:00:00 Hrs',
    this.inactiveDuration = '00:00:00 Hrs',
    this.fuelMileage = '10 km/ltr',
    this.fuelConsumption = '0.00 ltr',
    this.fuelCost = '0.00',
    this.avgSpeed = '0',
    this.maxSpeed = '0',
    this.devBattery = '0%',
    this.engineHours = '00:00',
    this.carBattery = '0 V',
    this.satellites = '0',
    this.fuelLevel = 'N/A',
    this.accuracy = 'N/A',
    this.temperature = 'N/A',
    this.movement = 'false',
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
    String? deviceTime,
    String? serverTime,
    String? runningDuration,
    String? stopDuration,
    String? idleDuration,
    String? inactiveDuration,
    String? fuelMileage,
    String? fuelConsumption,
    String? fuelCost,
    String? avgSpeed,
    String? maxSpeed,
    String? devBattery,
    String? engineHours,
    String? carBattery,
    String? satellites,
    String? fuelLevel,
    String? accuracy,
    String? temperature,
    String? movement,
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
      deviceTime: deviceTime ?? this.deviceTime,
      serverTime: serverTime ?? this.serverTime,
      runningDuration: runningDuration ?? this.runningDuration,
      stopDuration: stopDuration ?? this.stopDuration,
      idleDuration: idleDuration ?? this.idleDuration,
      inactiveDuration: inactiveDuration ?? this.inactiveDuration,
      fuelMileage: fuelMileage ?? this.fuelMileage,
      fuelConsumption: fuelConsumption ?? this.fuelConsumption,
      fuelCost: fuelCost ?? this.fuelCost,
      avgSpeed: avgSpeed ?? this.avgSpeed,
      maxSpeed: maxSpeed ?? this.maxSpeed,
      devBattery: devBattery ?? this.devBattery,
      engineHours: engineHours ?? this.engineHours,
      carBattery: carBattery ?? this.carBattery,
      satellites: satellites ?? this.satellites,
      fuelLevel: fuelLevel ?? this.fuelLevel,
      accuracy: accuracy ?? this.accuracy,
      temperature: temperature ?? this.temperature,
      movement: movement ?? this.movement,
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
    if (validity != null && validity!.trim().isNotEmpty) {
      return validity!.trim();
    }
    return '—';
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

    final String? validity = _resolveValidityText(json, deviceData);

    final int? id = int.tryParse((json['id'] ?? deviceData['id'] ?? '').toString());

    // ─── Real-time Statistics Parsing ───
    final String deviceTime = _resolveDeviceTime(json, deviceData, liveTime);
    final String serverTime = _resolveServerTime(json, deviceData, liveTime);
    
    final String runningDuration = _resolveRunningDuration(json, deviceData, status);
    final String stopDuration = _resolveStopDuration(json, deviceData, status);
    final String idleDuration = _resolveIdleDuration(json, deviceData, status);
    final String inactiveDuration = _resolveInactiveDuration(json, deviceData, status);
    
    final String fuelMileage = _resolveFuelMileage(json, deviceData);
    final String fuelConsumption = _resolveFuelConsumption(json, deviceData);
    final String fuelCost = _resolveFuelCost(json, deviceData, fuelConsumption);
    
    final String avgSpeed = _resolveAvgSpeed(json, deviceData, rawSpeedDouble, tail);
    final String maxSpeed = _resolveMaxSpeed(json, deviceData, rawSpeedDouble, tail);

    // ─── Real Sensors Parsing ───
    final (
      String devBattery,
      String engineHours,
      String carBattery,
      String satellites,
      String fuelLevel,
      String accuracy,
      String temperature,
      String movement,
    ) = _resolveSensors(json, deviceData, status, rawSpeedDouble);

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
      deviceTime: deviceTime,
      serverTime: serverTime,
      runningDuration: runningDuration,
      stopDuration: stopDuration,
      idleDuration: idleDuration,
      inactiveDuration: inactiveDuration,
      fuelMileage: fuelMileage,
      fuelConsumption: fuelConsumption,
      fuelCost: fuelCost,
      avgSpeed: avgSpeed,
      maxSpeed: maxSpeed,
      devBattery: devBattery,
      engineHours: engineHours,
      carBattery: carBattery,
      satellites: satellites,
      fuelLevel: fuelLevel,
      accuracy: accuracy,
      temperature: temperature,
      movement: movement,
    );
  }

  static String _resolveDeviceTime(
    Map<String, dynamic> json,
    Map<String, dynamic> deviceData,
    String fallbackLiveTime,
  ) {
    final dynamic val = json['device_time'] ??
        json['time'] ??
        deviceData['device_time'] ??
        deviceData['time'] ??
        json['latest_position']?['time'] ??
        json['position']?['time'] ??
        json['other_arr']?['time'];
    if (val != null && val.toString().trim().isNotEmpty) {
      return _formatTimeOnly(val);
    }
    return fallbackLiveTime.isNotEmpty ? fallbackLiveTime : 'N/A';
  }

  static String _resolveServerTime(
    Map<String, dynamic> json,
    Map<String, dynamic> deviceData,
    String fallbackLiveTime,
  ) {
    final dynamic val = json['server_time'] ??
        json['updated_at'] ??
        json['ack_time'] ??
        deviceData['server_time'] ??
        deviceData['updated_at'] ??
        deviceData['ack_time'] ??
        json['latest_position']?['server_time'] ??
        json['latest_position']?['ack_time'];
    if (val != null && val.toString().trim().isNotEmpty) {
      return _formatTimeOnly(val);
    }
    return fallbackLiveTime.isNotEmpty ? fallbackLiveTime : 'N/A';
  }

  static String _formatDurationString(dynamic raw) {
    if (raw == null) return '00:00:00 Hrs';
    final String str = raw.toString().trim();
    if (str.isEmpty || str == '0' || str == '00:00:00') return '00:00:00 Hrs';

    // If it is numeric (e.g. seconds)
    final int? seconds = int.tryParse(str);
    if (seconds != null) {
      final int h = seconds ~/ 3600;
      final int m = (seconds % 3600) ~/ 60;
      final int s = seconds % 60;
      final String hh = h.toString().padLeft(2, '0');
      final String mm = m.toString().padLeft(2, '0');
      final String ss = s.toString().padLeft(2, '0');
      return '$hh:$mm:$ss Hrs';
    }

    if (str.contains('Hrs') || str.contains('hrs') || str.contains('min') || str.contains('m') || str.contains('s')) {
      return str;
    }
    if (str.split(':').length == 3) {
      return '$str Hrs';
    }
    if (str.split(':').length == 2) {
      return '00:$str Hrs';
    }
    return '$str Hrs';
  }

  static String _resolveRunningDuration(
    Map<String, dynamic> json,
    Map<String, dynamic> deviceData,
    String status,
  ) {
    final dynamic val = json['running_duration'] ??
        json['running_time'] ??
        deviceData['running_duration'] ??
        deviceData['running_time'] ??
        json['engine_hours'] ??
        deviceData['engine_hours'] ??
        json['move_duration'] ??
        deviceData['move_duration'];
    if (val != null && val.toString().trim().isNotEmpty && val.toString() != '0') {
      return _formatDurationString(val);
    }
    if (status.trim().toLowerCase() == 'running') {
      final dynamic fallbackTime = json['time'] ?? deviceData['time'];
      if (fallbackTime != null) {
        return _formatDurationString(fallbackTime);
      }
    }
    return '00:00:00 Hrs';
  }

  static String _resolveStopDuration(
    Map<String, dynamic> json,
    Map<String, dynamic> deviceData,
    String status,
  ) {
    final dynamic val = json['stop_duration'] ??
        json['stop_time'] ??
        deviceData['stop_duration'] ??
        deviceData['stop_time'] ??
        json['stopped_duration'] ??
        deviceData['stopped_duration'];
    if (val != null && val.toString().trim().isNotEmpty && val.toString() != '0') {
      return _formatDurationString(val);
    }
    if (status.trim().toLowerCase() == 'stopped') {
      final dynamic fallbackTime = json['time'] ?? deviceData['time'];
      if (fallbackTime != null) {
        return _formatDurationString(fallbackTime);
      }
    }
    return '00:00:00 Hrs';
  }

  static String _resolveIdleDuration(
    Map<String, dynamic> json,
    Map<String, dynamic> deviceData,
    String status,
  ) {
    final dynamic val = json['idle_duration'] ??
        json['idle_time'] ??
        deviceData['idle_duration'] ??
        deviceData['idle_time'] ??
        json['park_duration'] ??
        deviceData['park_duration'];
    if (val != null && val.toString().trim().isNotEmpty && val.toString() != '0') {
      return _formatDurationString(val);
    }
    if (status.trim().toLowerCase() == 'idle') {
      final dynamic fallbackTime = json['time'] ?? deviceData['time'];
      if (fallbackTime != null) {
        return _formatDurationString(fallbackTime);
      }
    }
    return '00:00:00 Hrs';
  }

  static String _resolveInactiveDuration(
    Map<String, dynamic> json,
    Map<String, dynamic> deviceData,
    String status,
  ) {
    final dynamic val = json['offline_duration'] ??
        json['offline_time'] ??
        json['inactive_duration'] ??
        deviceData['offline_duration'] ??
        deviceData['offline_time'] ??
        deviceData['inactive_duration'] ??
        json['not_reporting_duration'] ??
        deviceData['not_reporting_duration'];
    if (val != null && val.toString().trim().isNotEmpty && val.toString() != '0') {
      return _formatDurationString(val);
    }
    final String lower = status.trim().toLowerCase();
    if (lower == 'offline' || lower == 'not reporting' || lower == 'inactive') {
      final dynamic fallbackTime = json['time'] ?? deviceData['time'];
      if (fallbackTime != null) {
        return _formatDurationString(fallbackTime);
      }
    }
    return '00:00:00 Hrs';
  }

  static String _resolveFuelMileage(
    Map<String, dynamic> json,
    Map<String, dynamic> deviceData,
  ) {
    final dynamic val = json['fuel_mileage'] ??
        json['mileage'] ??
        deviceData['fuel_mileage'] ??
        deviceData['mileage'] ??
        deviceData['fuel_per_km'] ??
        json['fuel_per_km'] ??
        deviceData['fuel_economy'];
    if (val != null && val.toString().trim().isNotEmpty && val.toString() != '0') {
      final String str = val.toString().trim();
      return str.contains('km') ? str : '$str km/ltr';
    }
    // Check sensors
    final dynamic sensors = json['sensors'] ?? deviceData['sensors'];
    if (sensors is List) {
      for (final dynamic s in sensors) {
        if (s is Map) {
          final String sName = (s['name'] ?? s['type'] ?? '').toString().toLowerCase();
          if (sName.contains('mileage') || sName.contains('economy')) {
            final dynamic sVal = s['value'] ?? s['val'] ?? s['text_value'];
            if (sVal != null && sVal.toString().isNotEmpty) {
              final String sStr = sVal.toString().trim();
              return sStr.contains('km') ? sStr : '$sStr km/ltr';
            }
          }
        }
      }
    }
    return '10 km/ltr';
  }

  static String _resolveFuelConsumption(
    Map<String, dynamic> json,
    Map<String, dynamic> deviceData,
  ) {
    final dynamic val = json['fuel_consumption'] ??
        json['fuel_used'] ??
        deviceData['fuel_consumption'] ??
        deviceData['fuel_used'] ??
        deviceData['fuel_quantity'] ??
        json['fuel_quantity'] ??
        deviceData['fuel_total'] ??
        json['fuel_total'];
    if (val != null && val.toString().trim().isNotEmpty) {
      final double? d = double.tryParse(val.toString());
      if (d != null) {
        return '${d.toStringAsFixed(2)} ltr';
      }
      final String str = val.toString().trim();
      return str.contains('l') ? str : '$str ltr';
    }
    // Check sensors
    final dynamic sensors = json['sensors'] ?? deviceData['sensors'];
    if (sensors is List) {
      for (final dynamic s in sensors) {
        if (s is Map) {
          final String sType = (s['type'] ?? s['name'] ?? '').toString().toLowerCase();
          if (sType.contains('consumption') || sType.contains('fuel_tank') || sType == 'fuel') {
            final dynamic sVal = s['value'] ?? s['val'] ?? s['text_value'];
            if (sVal != null && sVal.toString().isNotEmpty) {
              final double? d = double.tryParse(sVal.toString());
              if (d != null) return '${d.toStringAsFixed(2)} ltr';
              return '${sVal.toString().trim()} ltr';
            }
          }
        }
      }
    }
    return '0.00 ltr';
  }

  static String _resolveFuelCost(
    Map<String, dynamic> json,
    Map<String, dynamic> deviceData,
    String resolvedConsumption,
  ) {
    final dynamic val = json['fuel_cost'] ??
        json['cost'] ??
        deviceData['fuel_cost'] ??
        deviceData['cost'] ??
        deviceData['fuel_price'] ??
        json['fuel_price'];
    if (val != null && val.toString().trim().isNotEmpty && val.toString() != '0') {
      final double? d = double.tryParse(val.toString());
      if (d != null) {
        return '${d.toStringAsFixed(2)} PKR';
      }
      final String str = val.toString().trim();
      return str.contains('PKR') || str.contains('INR') || str.contains('\$') ? str : '$str PKR';
    }

    // Try computing consumption * price if fuel_price exists
    final dynamic priceVal = deviceData['fuel_price'] ?? json['fuel_price'];
    if (priceVal != null) {
      final double? price = double.tryParse(priceVal.toString());
      final double? consumption = double.tryParse(resolvedConsumption.replaceAll(RegExp(r'[^0-9.]'), ''));
      if (price != null && consumption != null && price > 0 && consumption > 0) {
        return '${(price * consumption).toStringAsFixed(2)} PKR';
      }
    }

    return '0.00 PKR';
  }

  static String _resolveAvgSpeed(
    Map<String, dynamic> json,
    Map<String, dynamic> deviceData,
    double currentSpeed,
    List<VehicleTrackPoint> tail,
  ) {
    final dynamic val = json['avg_speed'] ??
        deviceData['avg_speed'] ??
        json['average_speed'] ??
        deviceData['average_speed'] ??
        deviceData['speed_avg'];
    if (val != null && val.toString().trim().isNotEmpty) {
      final double? spd = double.tryParse(val.toString());
      if (spd != null && spd > 0) {
        return spd.round().toString();
      }
    }

    if (currentSpeed > 0) {
      return currentSpeed.round().toString();
    }
    return '0';
  }

  static String _resolveMaxSpeed(
    Map<String, dynamic> json,
    Map<String, dynamic> deviceData,
    double currentSpeed,
    List<VehicleTrackPoint> tail,
  ) {
    final dynamic val = json['max_speed'] ??
        deviceData['max_speed'] ??
        json['top_speed'] ??
        deviceData['top_speed'] ??
        deviceData['speed_max'] ??
        deviceData['maximum_speed'];
    if (val != null && val.toString().trim().isNotEmpty) {
      final double? spd = double.tryParse(val.toString());
      if (spd != null && spd > 0) {
        return spd.round().toString();
      }
    }

    if (currentSpeed > 0) {
      return currentSpeed.round().toString();
    }
    return '0';
  }

  static (
    String devBattery,
    String engineHours,
    String carBattery,
    String satellites,
    String fuelLevel,
    String accuracy,
    String temperature,
    String movement,
  ) _resolveSensors(
    Map<String, dynamic> json,
    Map<String, dynamic> deviceData,
    String status,
    double currentSpeed,
  ) {
    String devBattery = '0%';
    String engineHours = '00:00';
    String carBattery = '0 V';
    String satellites = '0';
    String fuelLevel = 'N/A';
    String accuracy = 'N/A';
    String temperature = 'N/A';
    String movement = currentSpeed > 0 || status.toLowerCase() == 'running' ? 'true' : 'false';

    // 1. Direct deviceData / other_arr check
    final dynamic other = json['other_arr'] ?? deviceData['other_arr'] ?? json['other'] ?? deviceData['other'];
    if (other is Map) {
      if (other['battery'] != null) devBattery = '${other['battery']}%';
      if (other['sat'] != null) satellites = other['sat'].toString();
      if (other['power'] != null) carBattery = '${other['power']} V';
      if (other['engine_hours'] != null) engineHours = other['engine_hours'].toString();
      if (other['temp'] != null) temperature = '${other['temp']} °C';
      if (other['hdop'] != null) accuracy = '${other['hdop']} m';
    }

    // 2. Sensors list check
    final dynamic sensors = json['sensors'] ?? deviceData['sensors'];
    if (sensors is List) {
      for (final dynamic s in sensors) {
        if (s is! Map) continue;
        final String sType = (s['type'] ?? s['name'] ?? '').toString().toLowerCase();
        final dynamic rawVal = s['text_value'] ?? s['value'] ?? s['val'] ?? s['scale_value'];
        if (rawVal == null || rawVal.toString().isEmpty) continue;
        final String valStr = rawVal.toString().trim();

        if (sType.contains('battery') || sType == 'dev_battery') {
          devBattery = valStr.contains('%') ? valStr : '$valStr%';
        } else if (sType.contains('engine_hours') || sType.contains('hours')) {
          engineHours = valStr;
        } else if (sType.contains('power') || sType.contains('acc') || sType.contains('car_battery') || sType.contains('battery_saver')) {
          carBattery = valStr.contains('V') ? valStr : '$valStr V';
        } else if (sType.contains('sat') || sType.contains('satellite')) {
          satellites = valStr;
        } else if (sType.contains('fuel')) {
          fuelLevel = valStr;
        } else if (sType.contains('accuracy') || sType.contains('hdop') || sType.contains('gps')) {
          accuracy = valStr;
        } else if (sType.contains('temp') || sType.contains('thermostat')) {
          temperature = valStr.contains('°') ? valStr : '$valStr °C';
        } else if (sType.contains('movement') || sType.contains('motion')) {
          movement = valStr;
        }
      }
    }

    return (
      devBattery,
      engineHours,
      carBattery,
      satellites,
      fuelLevel,
      accuracy,
      temperature,
      movement,
    );
  }

  static String _formatTimeOnly(dynamic val) {
    if (val == null) return 'N/A';
    final String str = val.toString().trim();
    if (str.contains(' ') && str.length >= 11) {
      final List<String> parts = str.split(' ');
      return parts.length >= 2 ? parts[1] : str;
    }
    return str;
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
    final (double lat, double lng)? parsed =
        CoordinateParser.fromMaps(json, deviceData);
    if (parsed != null) {
      return (parsed.$1, parsed.$2);
    }

    double? lat;
    double? lng;

    if (json['tail'] is List && (json['tail'] as List).isNotEmpty) {
      final dynamic lastTail = (json['tail'] as List).last;
      if (lastTail is Map) {
        final Map<String, dynamic> tailMap = lastTail.map(
          (Object? k, Object? v) => MapEntry(k.toString(), v),
        );
        final (double tLat, double tLng)? tailCoords =
            CoordinateParser.fromMap(tailMap);
        if (tailCoords != null) {
          lat = tailCoords.$1;
          lng = tailCoords.$2;
        }
      } else if (lastTail is List && lastTail.length >= 2) {
        final (double tLat, double tLng)? tailCoords =
            CoordinateParser.parsePair('${lastTail[0]},${lastTail[1]}');
        if (tailCoords != null) {
          lat = tailCoords.$1;
          lng = tailCoords.$2;
        }
      }
    }

    return (lat, lng);
  }

  static String? _resolveValidityText(
    Map<String, dynamic> json,
    Map<String, dynamic> deviceData,
  ) {
    final dynamic raw = json['validity'] ??
        json['expires_in'] ??
        json['expiration_days'] ??
        deviceData['validity'] ??
        deviceData['expires_in'] ??
        deviceData['expiration_days'];
    if (raw != null) {
      final String str = raw.toString().trim();
      if (str.isNotEmpty &&
          str != '-' &&
          str.toLowerCase() != 'null' &&
          str.toLowerCase() != 'n/a') {
        final String lower = str.toLowerCase();
        if (lower.contains('day') || lower.contains('expire')) {
          return str;
        }
        final int? daysOnly = int.tryParse(str.replaceAll(RegExp(r'[^\d-]'), ''));
        if (daysOnly != null) {
          if (daysOnly < 0) {
            return 'Expired';
          }
          if (daysOnly == 0) {
            return 'Expires today';
          }
          return '$daysOnly Days Validity';
        }
        return str;
      }
    }

    final dynamic expDate = json['expiration_date'] ??
        json['expires_date'] ??
        json['validity_date'] ??
        deviceData['expiration_date'] ??
        deviceData['expires_date'];
    if (expDate != null) {
      final String expStr = expDate.toString().trim();
      if (expStr.isNotEmpty) {
        final DateTime? parsed =
            DateTime.tryParse(expStr.replaceAll('/', '-'));
        if (parsed != null) {
          final int days = parsed.difference(DateTime.now()).inDays;
          if (days < 0) {
            return 'Expired';
          }
          if (days == 0) {
            return 'Expires today';
          }
          return '$days Days Validity';
        }
        return expStr;
      }
    }

    return null;
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
        json['geocoding'] ??
        json['last_address'] ??
        json['addr'] ??
        deviceData['location'] ??
        deviceData['address'] ??
        deviceData['formatted_address'] ??
        deviceData['street'] ??
        deviceData['geocoding'] ??
        deviceData['last_address'] ??
        json['other_arr']?['address'] ??
        json['position']?['address'] ??
        json['last_valid_address'] ??
        deviceData['last_valid_address'] ??
        json['traccar']?['address'] ??
        deviceData['traccar']?['address'];

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
