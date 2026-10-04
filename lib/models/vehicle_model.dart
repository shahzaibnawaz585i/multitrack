import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../services/reverse_geocoding_service.dart';
import '../utils/coordinate_parser.dart';
import '../utils/vehicle_speed_utils.dart';

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
  final String fuelPricePerLiter;
  final String speedLimitKmph;
  final String engineWorkCost;
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
  final String mapIcon;
  final String driverPhone;
  final int? driverId;
  final String engineNumber;
  final int? groupId;
  final String groupName;

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
    this.fuelMileage = 'N/A',
    this.fuelConsumption = '0.00 ltr',
    this.fuelCost = '0.00',
    this.fuelPricePerLiter = '',
    this.speedLimitKmph = '',
    this.engineWorkCost = '',
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
    this.mapIcon = '',
    this.driverPhone = '',
    this.driverId,
    this.engineNumber = '',
    this.groupId,
    this.groupName = '',
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
    String? fuelPricePerLiter,
    String? speedLimitKmph,
    String? engineWorkCost,
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
    String? mapIcon,
    String? driverPhone,
    int? driverId,
    String? engineNumber,
    int? groupId,
    String? groupName,
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
      fuelPricePerLiter: fuelPricePerLiter ?? this.fuelPricePerLiter,
      speedLimitKmph: speedLimitKmph ?? this.speedLimitKmph,
      engineWorkCost: engineWorkCost ?? this.engineWorkCost,
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
      mapIcon: mapIcon ?? this.mapIcon,
      driverPhone: driverPhone ?? this.driverPhone,
      driverId: driverId ?? this.driverId,
      engineNumber: engineNumber ?? this.engineNumber,
      groupId: groupId ?? this.groupId,
      groupName: groupName ?? this.groupName,
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
    final String mapIcon = _resolveMapIcon(json, deviceData);
    final ({String phone, int? driverId}) driverInfo =
        _resolveDriverInfo(json, deviceData);
    final String engineNumber = _resolveEngineNumber(json, deviceData);
    final ({int? id, String name}) groupInfo =
        _resolveGroupInfo(json, deviceData);

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
    final String fuelPricePerLiter =
        _resolveFuelPricePerLiter(json, deviceData);
    final String speedLimitKmph = _resolveSpeedLimitKmph(json, deviceData);
    final String engineWorkCost = _resolveEngineWorkCost(json, deviceData);
    
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
      fuelPricePerLiter: fuelPricePerLiter,
      speedLimitKmph: speedLimitKmph,
      engineWorkCost: engineWorkCost,
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
      mapIcon: mapIcon,
      driverPhone: driverInfo.phone,
      driverId: driverInfo.driverId,
      engineNumber: engineNumber,
      groupId: groupInfo.id,
      groupName: groupInfo.name,
    );
  }

  static String _resolveEngineNumber(
    Map<String, dynamic> json,
    Map<String, dynamic> deviceData,
  ) {
    final dynamic raw = json['engine_number'] ??
        deviceData['engine_number'] ??
        json['engine_no'] ??
        deviceData['engine_no'] ??
        json['object_engine'] ??
        deviceData['object_engine'] ??
        json['engine_num'] ??
        deviceData['engine_num'];
    return raw?.toString().trim() ?? '';
  }

  static ({int? id, String name}) _resolveGroupInfo(
    Map<String, dynamic> json,
    Map<String, dynamic> deviceData,
  ) {
    int? groupId = int.tryParse(
      (json['group_id'] ??
              deviceData['group_id'] ??
              json['p_group_id'] ??
              deviceData['p_group_id'] ??
              '')
          .toString(),
    );

    String groupName = (json['group_name'] ??
            deviceData['group_name'] ??
            json['group_title'] ??
            deviceData['group_title'] ??
            '')
        .toString()
        .trim();

    final dynamic groupNode = json['group'] ?? deviceData['group'];
    if (groupNode is Map) {
      final Map<String, dynamic> g = groupNode.map(
        (Object? k, Object? v) => MapEntry(k.toString(), v),
      );
      groupId ??= int.tryParse((g['id'] ?? g['group_id'] ?? '').toString());
      if (groupName.isEmpty) {
        groupName = (g['title'] ?? g['name'] ?? '').toString().trim();
      }
    }

    final dynamic groupsList = json['groups'] ?? deviceData['groups'];
    if (groupId == null && groupsList is List && groupsList.isNotEmpty) {
      final dynamic first = groupsList.first;
      if (first is int) {
        groupId = first;
      } else if (first is Map) {
        groupId = int.tryParse((first['id'] ?? first['group_id'] ?? '').toString());
        if (groupName.isEmpty) {
          groupName = (first['title'] ?? first['name'] ?? '').toString().trim();
        }
      } else {
        groupId = int.tryParse(first.toString());
      }
    }

    return (id: groupId, name: groupName);
  }

  static ({String phone, int? driverId}) _resolveDriverInfo(
    Map<String, dynamic> json,
    Map<String, dynamic> deviceData,
  ) {
    int? driverId = int.tryParse(
      (json['driver_id'] ?? deviceData['driver_id'] ?? '').toString(),
    );

    String phone = (json['driver_phone'] ??
            deviceData['driver_phone'] ??
            json['driver_mobile'] ??
            deviceData['driver_mobile'] ??
            '')
        .toString()
        .trim();

    final dynamic driverNode =
        json['driver'] ?? deviceData['driver'] ?? json['current_driver'];
    if (driverNode is Map) {
      final Map<String, dynamic> driverMap = driverNode.map(
        (Object? k, Object? v) => MapEntry(k.toString(), v),
      );
      if (phone.isEmpty) {
        phone = (driverMap['phone'] ??
                driverMap['mobile'] ??
                driverMap['phone_number'] ??
                '')
            .toString()
            .trim();
      }
      driverId ??= int.tryParse('${driverMap['id']}');
    }

    final dynamic driversList = json['drivers'] ?? deviceData['drivers'];
    if (phone.isEmpty && driversList is List && driversList.isNotEmpty) {
      final dynamic first = driversList.first;
      if (first is Map) {
        final Map<String, dynamic> dm = first.map(
          (Object? k, Object? v) => MapEntry(k.toString(), v),
        );
        phone = (dm['phone'] ?? dm['mobile'] ?? dm['phone_number'] ?? '')
            .toString()
            .trim();
        driverId ??= int.tryParse('${dm['id']}');
      }
    }

    return (phone: phone, driverId: driverId);
  }

  static String _resolveMapIcon(
    Map<String, dynamic> json,
    Map<String, dynamic> deviceData,
  ) {
    final dynamic raw = json['icon'] ??
        json['icon_type'] ??
        json['device_icon'] ??
        deviceData['icon'] ??
        deviceData['icon_type'] ??
        deviceData['device_icon'];
    return raw?.toString().trim().toLowerCase() ?? '';
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
    return 'N/A';
  }

  static String _resolveFuelPricePerLiter(
    Map<String, dynamic> json,
    Map<String, dynamic> deviceData,
  ) {
    final dynamic val = json['fuel_price'] ??
        deviceData['fuel_price'] ??
        json['fuel_cost_per_liter'] ??
        deviceData['fuel_cost_per_liter'] ??
        json['cost_per_liter'] ??
        deviceData['cost_per_liter'];
    if (val != null && val.toString().trim().isNotEmpty) {
      return val.toString().trim();
    }
    return '';
  }

  static String _resolveEngineWorkCost(
    Map<String, dynamic> json,
    Map<String, dynamic> deviceData,
  ) {
    final dynamic val = json['engine_work_cost'] ??
        deviceData['engine_work_cost'] ??
        json['engine_work'] ??
        deviceData['engine_work'] ??
        json['engine_cost'] ??
        deviceData['engine_cost'];
    if (val != null && val.toString().trim().isNotEmpty) {
      return val.toString().trim();
    }
    return '';
  }

  static String _resolveSpeedLimitKmph(
    Map<String, dynamic> json,
    Map<String, dynamic> deviceData,
  ) {
    final dynamic val = json['speed_limit'] ??
        deviceData['speed_limit'] ??
        json['overspeed'] ??
        deviceData['overspeed'] ??
        json['overspeed_limit'] ??
        deviceData['overspeed_limit'] ??
        json['max_speed_limit'] ??
        deviceData['max_speed_limit'] ??
        json['alert_speed'] ??
        deviceData['alert_speed'];
    if (val != null && val.toString().trim().isNotEmpty) {
      return val.toString().trim();
    }
    return '';
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

    void applyTopLevel(String key, void Function(String value) apply) {
      final dynamic raw = json[key] ?? deviceData[key];
      if (raw == null) {
        return;
      }
      final String str = raw.toString().trim();
      if (str.isEmpty || str == '-' || str.toLowerCase() == 'null') {
        return;
      }
      apply(str);
    }

    applyTopLevel('satellites', (String v) => satellites = v);
    applyTopLevel('sat', (String v) => satellites = v);
    applyTopLevel('battery', (String v) {
      devBattery = v.contains('%') ? v : '$v%';
    });
    applyTopLevel('battery_level', (String v) {
      devBattery = v.contains('%') ? v : '$v%';
    });
    applyTopLevel('engine_hours', (String v) => engineHours = v);
    applyTopLevel('power', (String v) {
      carBattery = v.contains('V') ? v : '$v V';
    });
    applyTopLevel('fuel', (String v) => fuelLevel = v);
    applyTopLevel('fuel_level', (String v) => fuelLevel = v);
    applyTopLevel('temperature', (String v) {
      temperature = v.contains('°') ? v : '$v °C';
    });
    applyTopLevel('temp', (String v) {
      temperature = v.contains('°') ? v : '$v °C';
    });
    applyTopLevel('accuracy', (String v) => accuracy = v);
    applyTopLevel('hdop', (String v) {
      accuracy = v.contains('m') ? v : '$v m';
    });

    final dynamic parameters =
        json['parameters'] ?? deviceData['parameters'] ?? json['params'];
    if (parameters is Map) {
      final Map<String, dynamic> params = parameters.map(
        (Object? k, Object? v) => MapEntry(k.toString().toLowerCase(), v),
      );
      void fromParam(String key, void Function(String value) apply) {
        final dynamic raw = params[key];
        if (raw == null) {
          return;
        }
        final String str = raw.toString().trim();
        if (str.isNotEmpty) {
          apply(str);
        }
      }

      fromParam('sat', (String v) => satellites = v);
      fromParam('satellites', (String v) => satellites = v);
      fromParam('battery', (String v) {
        devBattery = v.contains('%') ? v : '$v%';
      });
      fromParam('enginehours', (String v) => engineHours = v);
      fromParam('engine_hours', (String v) => engineHours = v);
      fromParam('power', (String v) {
        carBattery = v.contains('V') ? v : '$v V';
      });
      fromParam('fuel', (String v) => fuelLevel = v);
      fromParam('temp', (String v) {
        temperature = v.contains('°') ? v : '$v °C';
      });
      fromParam('hdop', (String v) {
        accuracy = v.contains('m') ? v : '$v m';
      });
      fromParam('motion', (String v) => movement = v);
      fromParam('movement', (String v) => movement = v);
    }

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

    // 2. Cached geocode or coordinate fallback (never leave map empty while resolving).
    if (lat != null && lng != null && (lat != 0.0 || lng != 0.0)) {
      final String? cached = ReverseGeocodingService.getCached(lat, lng);
      if (cached != null &&
          cached.isNotEmpty &&
          cached != 'Location not available') {
        return cached;
      }
      return '${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}';
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

  /// GPSWOX `get_devices` top-level `speed` (km/h when `distance_unit_hour` is kph).
  static double? _readGpswoxPanelSpeed(
    Map<String, dynamic> json,
    Map<String, dynamic> deviceData,
  ) {
    for (final Map<String, dynamic> source in <Map<String, dynamic>>[
      json,
      deviceData,
    ]) {
      if (!source.containsKey('speed')) {
        continue;
      }
      final dynamic raw = source['speed'];
      if (raw == null) {
        continue;
      }
      final double kmh = _applyDisplaySpeedUnit(
        _coerceSpeedToKmh(raw),
        json,
        deviceData,
      );
      return kmh < 0 ? 0 : kmh;
    }
    return null;
  }

  static String _resolveSpeedUnit(
    Map<String, dynamic> json,
    Map<String, dynamic> deviceData,
  ) {
    return (json['distance_unit_hour'] ??
            deviceData['distance_unit_hour'] ??
            json['speed_unit'] ??
            deviceData['speed_unit'] ??
            json['distance_unit'] ??
            deviceData['distance_unit'] ??
            json['unit_of_distance'] ??
            deviceData['unit_of_distance'] ??
            '')
        .toString()
        .toLowerCase();
  }

  static double _resolveRawSpeed(
    Map<String, dynamic> json,
    Map<String, dynamic> deviceData,
  ) {
    final double? panelSpeed = _readGpswoxPanelSpeed(json, deviceData);
    if (panelSpeed != null) {
      return panelSpeed;
    }

    final List<double> displayKmh = <double>[];
    final List<double> positionKmh = <double>[];

    void addDisplay(dynamic value) {
      if (value == null) return;
      final double kmh = _applyDisplaySpeedUnit(
        _coerceSpeedToKmh(value),
        json,
        deviceData,
      );
      if (kmh > 0 && kmh <= 220) {
        displayKmh.add(kmh);
      }
    }

    void addPosition(dynamic value) {
      if (value == null) return;
      final double raw = _coerceSpeedToKmh(value);
      if (raw <= 0 || raw > 220) return;
      final double kmh = _knotsToKmhIfNeeded(raw, json, deviceData);
      if (kmh > 0 && kmh <= 220) {
        positionKmh.add(kmh);
      }
    }

    void readSpeedKeysFromMap(Map<String, dynamic> m, void Function(dynamic) add) {
      for (final String key in <String>[
        'speed',
        'speed_kmh',
        'speedKmh',
        'device_speed',
        'last_speed',
        'current_speed',
        'spd',
        'velocity',
      ]) {
        add(m[key]);
      }
      final dynamic attributes = m['attributes'];
      if (attributes is Map) {
        final Map<String, dynamic> attr = attributes.map(
          (Object? k, Object? v) => MapEntry(k.toString(), v),
        );
        add(attr['speed'] ?? attr['speed_kmh']);
      }
    }

    // GPSWOX panel speed — already in user display units (usually km/h).
    readSpeedKeysFromMap(json, addDisplay);
    readSpeedKeysFromMap(deviceData, addDisplay);

    if (json['icon'] is Map) {
      final Map<String, dynamic> icon = (json['icon'] as Map).map(
        (Object? k, Object? v) => MapEntry(k.toString(), v),
      );
      readSpeedKeysFromMap(icon, addDisplay);
    }

    addDisplay(json['other_arr']?['speed']);
    addDisplay(json['other']?['speed']);
    addDisplay(json['parameters']?['speed']);
    addDisplay(json['params']?['speed']);

    final dynamic traccar = json['traccar'] ?? deviceData['traccar'];
    if (traccar is Map) {
      final Map<String, dynamic> t = traccar.map(
        (Object? k, Object? v) => MapEntry(k.toString(), v),
      );
      readSpeedKeysFromMap(t, addPosition);
    }

    for (final String nestedKey in <String>[
      'latest_position',
      'position',
      'last_position',
      'current_position',
    ]) {
      final dynamic nested = json[nestedKey] ?? deviceData[nestedKey];
      if (nested is Map) {
        final Map<String, dynamic> m = nested.map(
          (Object? k, Object? v) => MapEntry(k.toString(), v),
        );
        readSpeedKeysFromMap(m, addPosition);
      }
    }

    for (final String listKey in <String>[
      'latest_positions',
      'latestPositions',
      'positions',
      'tail',
    ]) {
      final dynamic list = json[listKey] ?? deviceData[listKey];
      if (list is! List || list.isEmpty) continue;
      for (int i = list.length - 1; i >= 0 && i >= list.length - 3; i--) {
        final dynamic item = list[i];
        if (item is Map) {
          final Map<String, dynamic> m = item.map(
            (Object? k, Object? v) => MapEntry(k.toString(), v),
          );
          readSpeedKeysFromMap(m, addPosition);
        }
      }
    }

    final dynamic sensors = json['sensors'] ?? deviceData['sensors'];
    if (sensors is List) {
      for (final dynamic sensor in sensors) {
        if (sensor is! Map) continue;
        final String sType =
            (sensor['type'] ?? sensor['name'] ?? sensor['tag_name'] ?? '')
                .toString()
                .toLowerCase();
        if (sType.contains('speed') ||
            sType.contains('velocity') ||
            sType.contains('spd')) {
          addDisplay(
            sensor['text_value'] ??
                sensor['value'] ??
                sensor['val'] ??
                sensor['data'] ??
                sensor['scale_value'],
          );
        }
      }
    }

    final String rawStatus = (json['status'] ??
            json['online'] ??
            deviceData['status'] ??
            deviceData['online'] ??
            json['time'] ??
            deviceData['time'] ??
            '')
        .toString();
    final double? fromText = _speedKmhFromText(rawStatus);
    if (fromText != null && fromText > 0 && fromText <= 220) {
      displayKmh.add(fromText);
    }

    if (displayKmh.isNotEmpty) {
      return displayKmh.reduce(math.max);
    }
    if (positionKmh.isNotEmpty) {
      return positionKmh.reduce(math.max);
    }
    return 0.0;
  }

  static double _coerceSpeedToKmh(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }
    return parseSpeedKmh(value.toString());
  }

  static double? _speedKmhFromText(String text) {
    if (text.trim().isEmpty) return null;
    final RegExpMatch? match = RegExp(
      r'(\d+(?:\.\d+)?)\s*(?:km/h|kmph|kph|kmh|km\s*h)',
      caseSensitive: false,
    ).firstMatch(text);
    if (match != null) {
      return double.tryParse(match.group(1)!);
    }
    return null;
  }

  static double _applyDisplaySpeedUnit(
    double value,
    Map<String, dynamic> json,
    Map<String, dynamic> deviceData,
  ) {
    if (value <= 0) return 0;
    final String unit = _resolveSpeedUnit(json, deviceData);
    if (unit.contains('kn')) {
      return value * 1.852;
    }
    if (unit.contains('mi')) {
      return value * 1.60934;
    }
    return value;
  }

  /// Traccar position records store speed in knots unless the server says otherwise.
  static double _knotsToKmhIfNeeded(
    double value,
    Map<String, dynamic> json,
    Map<String, dynamic> deviceData,
  ) {
    if (value <= 0) return 0;
    final String unit = _resolveSpeedUnit(json, deviceData);
    if (unit.contains('kp') ||
        unit.contains('km') ||
        unit == 'kph' ||
        unit == 'km/h') {
      return value;
    }
    if (unit.contains('mi')) {
      return value * 1.60934;
    }
    if (unit.contains('kn')) {
      return value * 1.852;
    }
    return value * 1.852;
  }

  static String? _resolveIconColor(
    Map<String, dynamic> json,
    Map<String, dynamic> deviceData,
  ) {
    final dynamic raw = json['icon_color'] ?? deviceData['icon_color'];
    if (raw == null) {
      return null;
    }
    final String color = raw.toString().trim().toLowerCase();
    return color.isEmpty ? null : color;
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

    final String? iconColor = _resolveIconColor(json, deviceData);
    if (iconColor == 'red') {
      return 'Not Reporting';
    }
    if (iconColor == 'green') {
      if (speed >= 8) {
        return 'RUNNING';
      }
      if (speed >= 3) {
        return 'IDLE';
      }
    }
    if (iconColor == 'yellow') {
      return speed >= 3 ? 'IDLE' : 'STOPPED';
    }
    if (iconColor == 'blue') {
      return 'IDLE';
    }

    // 3. Speed-based (match GPSWOX web: 0 idle when parked, RUNNING when clearly moving).
    if (speed >= 8) {
      return 'RUNNING';
    }

    // 4. Server-reported stop/park beats noisy GPS speed while parked.
    if (lower == 'stop' ||
        lower == 'stopped' ||
        lower == 'parked' ||
        lower == 'stop detected') {
      return speed >= 3 ? 'IDLE' : 'STOPPED';
    }

    if (lower == 'idle' ||
        lower == 'engine' ||
        lower == 'standby' ||
        lower.contains('idle')) {
      return 'IDLE';
    }

    if (lower == 'running' ||
        lower == 'move' ||
        lower == 'moving' ||
        lower.contains('drive')) {
      if (speed >= 8) {
        return 'RUNNING';
      }
      return speed >= 3 ? 'IDLE' : 'IDLE';
    }

    if (speed >= 3) {
      return 'IDLE';
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

    if (isEngineOn && speed > 0) {
      return speed >= 8 ? 'RUNNING' : 'IDLE';
    }

    if (isEngineOff) {
      return 'STOPPED';
    }

    if (lower == 'online' || lower == 'ack') {
      return speed >= 8 ? 'RUNNING' : (speed >= 3 ? 'IDLE' : 'STOPPED');
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

  /// Parses UI or API speed text (e.g. `"09"`, `"45 km/h"`) to km/h.
  static double parseSpeedKmh(String speed) {
    final String trimmed = speed.trim();
    if (trimmed.isEmpty) return 0;
    final double? direct = double.tryParse(trimmed);
    if (direct != null && !direct.isNaN) {
      return direct < 0 ? 0 : direct;
    }
    final RegExpMatch? match =
        RegExp(r'(\d+(?:\.\d+)?)').firstMatch(trimmed);
    if (match != null) {
      final double? v = double.tryParse(match.group(1)!);
      if (v != null && !v.isNaN) {
        return v < 0 ? 0 : v;
      }
    }
    return 0;
  }

  /// Merges a partial WebSocket/push payload onto [base] with normalized status/speed.
  static VehicleModel mergeSocketUpdate(
    VehicleModel base,
    Map<String, dynamic> patch,
  ) {
    final Map<String, dynamic> json = <String, dynamic>{
      'id': base.id,
      'name': base.name,
      if (base.latitude != null) 'lat': base.latitude,
      if (base.longitude != null) 'lng': base.longitude,
      'speed': parseSpeedKmh(base.speed),
      'status': base.status,
    };
    json.addAll(patch);
    for (final String metaKey in <String>[
      'online',
      'icon_color',
      'icon_colors',
      'distance_unit_hour',
      'distance_unit',
      'speed_unit',
    ]) {
      if (!json.containsKey(metaKey) && patch.containsKey(metaKey)) {
        json[metaKey] = patch[metaKey];
      }
    }

    final double? lat = _readFirstDouble(
      json,
      <String>['lat', 'latitude', 'last_lat'],
    );
    final double? lng = _readFirstDouble(
      json,
      <String>['lng', 'lon', 'longitude', 'last_lng'],
    );
    if (lat != null) json['lat'] = lat;
    if (lng != null) json['lng'] = lng;

    final VehicleModel live = VehicleModel.fromJson(json);
    return live.copyWith(
      location: live.location.trim().isNotEmpty ? live.location : base.location,
      tail: live.tail.isNotEmpty ? live.tail : base.tail,
      odometer: _preferNonEmpty(live.odometer, base.odometer),
      mapIcon: base.mapIcon.isNotEmpty ? base.mapIcon : live.mapIcon,
      driverPhone: _preferNonEmpty(live.driverPhone, base.driverPhone),
      driverId: live.driverId ?? base.driverId,
      deviceTime: _preferNonEmpty(live.deviceTime, base.deviceTime),
      serverTime: _preferNonEmpty(live.serverTime, base.serverTime),
      fuelLevel: _preferNonEmpty(live.fuelLevel, base.fuelLevel),
      movement: _preferNonEmpty(live.movement, base.movement),
    );
  }

  static String _preferNonEmpty(String primary, String fallback) {
    return primary.trim().isNotEmpty ? primary : fallback;
  }

  static double? _readFirstDouble(
    Map<String, dynamic> map,
    List<String> keys,
  ) {
    for (final String key in keys) {
      final dynamic value = map[key];
      if (value == null) continue;
      if (value is num) return value.toDouble();
      final double? parsed = double.tryParse(value.toString());
      if (parsed != null && !parsed.isNaN) return parsed;
    }
    return null;
  }

  static String _formatSpeed(dynamic speed) {
    if (speed == null) return '00';
    final double parsed = speed is num
        ? speed.toDouble()
        : parseSpeedKmh(speed.toString());
    return VehicleSpeed.formatLabel(parsed);
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
