import 'dart:math' as math;

import 'package:intl/intl.dart';

import '../constants/report_ids.dart';
import '../models/trip_report_event.dart';
import '../models/vehicle_model.dart';
import '../utils/coordinate_parser.dart';
import '../utils/report_period.dart';
import '../utils/report_response_parser.dart';
import 'history_service.dart';
import 'tracking_api_service.dart';
import 'vehicle_service.dart';

class TripReportService {
  TripReportService._();

  static final DateFormat _displayFormat = DateFormat('dd MMM yyyy hh:mm a');

  static Future<VehicleModel> _resolveVehicle(VehicleModel vehicle) async {
    if (vehicle.id != null) {
      return vehicle;
    }
    final List<VehicleModel> devices =
        await VehicleService.getDevices(forceRefresh: false);
    for (final VehicleModel item in devices) {
      if (item.name.trim().toLowerCase() == vehicle.name.trim().toLowerCase()) {
        return item;
      }
    }
    return vehicle;
  }

  static Future<List<TripReportEvent>> loadEventsForFleet({
    required List<VehicleModel> vehicles,
    required DateTime from,
    required DateTime to,
  }) async {
    final List<VehicleModel> resolved = await Future.wait(
      vehicles.map(_resolveVehicle),
    );
    final List<VehicleModel> withIds = resolved
        .where((VehicleModel v) => v.id != null)
        .toList(growable: false);

    const int maxConcurrent = 8;
    final List<TripReportEvent> merged = <TripReportEvent>[];

    for (int i = 0; i < withIds.length; i += maxConcurrent) {
      final int end = math.min(i + maxConcurrent, withIds.length);
      final List<VehicleModel> batch = withIds.sublist(i, end);
      final List<List<TripReportEvent>> chunks = await Future.wait(
        batch.map(
          (VehicleModel v) => loadEvents(vehicle: v, from: from, to: to),
        ),
      );
      for (final List<TripReportEvent> chunk in chunks) {
        merged.addAll(chunk);
      }
    }

    merged.sort((TripReportEvent a, TripReportEvent b) {
      final DateTime? ad = a.startDateTime ?? a.endDateTime;
      final DateTime? bd = b.startDateTime ?? b.endDateTime;
      if (ad == null || bd == null) {
        return 0;
      }
      return bd.compareTo(ad);
    });
    return _dedupe(merged);
  }

  static Future<List<TripReportEvent>> loadEvents({
    required VehicleModel vehicle,
    required DateTime from,
    required DateTime to,
  }) async {
    final VehicleModel resolved = await _resolveVehicle(vehicle);
    if (resolved.id == null) {
      return <TripReportEvent>[];
    }

    final DateTime queryFrom = ReportPeriod.startOfDay(from);
    final DateTime queryTo = ReportPeriod.endOfDay(to);

    final dynamic response = await TrackingApiService.generateReport(
      reportId: ReportIds.trip,
      deviceId: resolved.id!,
      from: HistoryService.formatForApi(queryFrom),
      to: HistoryService.formatForApi(queryTo),
    );

    if (response == null) {
      return <TripReportEvent>[];
    }

    final List<Map<String, dynamic>> items =
        ReportResponseParser.rowsFromResponse(response);
    if (items.isEmpty) {
      return <TripReportEvent>[];
    }

    final List<TripReportEvent> out = <TripReportEvent>[];
    for (final Map<String, dynamic> item in items) {
      final TripReportEvent? event = _eventFromMap(
        item,
        vehicle: resolved,
      );
      if (event != null) {
        out.add(event);
      }
    }

    out.sort((TripReportEvent a, TripReportEvent b) {
      final DateTime? ad = a.startDateTime ?? a.endDateTime;
      final DateTime? bd = b.startDateTime ?? b.endDateTime;
      if (ad == null || bd == null) {
        return 0;
      }
      return bd.compareTo(ad);
    });
    return _dedupe(out);
  }

  static List<TripReportEvent> _dedupe(List<TripReportEvent> events) {
    final Set<String> keys = <String>{};
    final List<TripReportEvent> out = <TripReportEvent>[];
    for (final TripReportEvent event in events) {
      final String key =
          '${event.vehicleName}|${event.startTimeLabel}|${event.endTimeLabel}|${event.distanceLabel}';
      if (keys.add(key)) {
        out.add(event);
      }
    }
    return out;
  }

  static TripReportEvent? _eventFromMap(
    Map<String, dynamic> item, {
    required VehicleModel vehicle,
  }) {
    final String vehicleName = _pick(
      item,
      <String>['device_name', 'vehicle_name', 'vehicle', 'name'],
      fallback: vehicle.name,
    );

    final DateTime? startTime = _parseTime(
      item['start_time'] ??
          item['time_from'] ??
          item['date_from'] ??
          item['from_time'],
    );
    final DateTime? endTime = _parseTime(
      item['end_time'] ??
          item['time_to'] ??
          item['date_to'] ??
          item['to_time'] ??
          item['finish_time'],
    );

    final String durationRaw = _pick(
      item,
      <String>[
        'duration',
        'drive_duration',
        'move_duration',
        'trip_duration',
      ],
      fallback: '',
    );
    Duration? duration = _parseDuration(durationRaw);
    if (duration == null && startTime != null && endTime != null) {
      duration = endTime.difference(startTime);
      if (duration.isNegative) {
        duration = duration.abs();
      }
    }

    final String distanceRaw = ReportResponseParser.summaryValue(
      item,
      <String>[
        'distance',
        'total_distance',
        'route_length',
        'distance_km',
        'trip_distance',
      ],
      fallback: '',
    );

    final (double lat, double lng)? startCoords = _coordsForEnd(
      item,
      isStart: true,
      fallbackLat: vehicle.latitude,
      fallbackLng: vehicle.longitude,
    );
    final (double lat, double lng)? endCoords = _coordsForEnd(
      item,
      isStart: false,
      fallbackLat: vehicle.latitude,
      fallbackLng: vehicle.longitude,
    );

    if (startTime == null && endTime == null && distanceRaw.isEmpty) {
      return null;
    }

    final String startLocation = _pick(
      item,
      <String>[
        'start_location',
        'start_address',
        'from_address',
        'location_start',
        'start',
      ],
      fallback: vehicle.location,
    );
    final String endLocation = _pick(
      item,
      <String>[
        'end_location',
        'end_address',
        'to_address',
        'location_end',
        'end',
      ],
      fallback: vehicle.location,
    );

    return TripReportEvent(
      vehicleName: vehicleName,
      durationLabel: duration != null
          ? _formatDuration(duration)
          : _formatDurationLabelFromText(durationRaw),
      distanceLabel: _formatDistance(distanceRaw),
      startTimeLabel: startTime != null
          ? _displayFormat.format(startTime)
          : _formatTimeRaw(
              _pick(item, <String>['start_time', 'time_from'], fallback: '-'),
            ),
      endTimeLabel: endTime != null
          ? _displayFormat.format(endTime)
          : _formatTimeRaw(
              _pick(item, <String>['end_time', 'time_to'], fallback: '-'),
            ),
      startLocation: startLocation,
      endLocation: endLocation,
      startLatitude: startCoords?.$1 ?? 0,
      startLongitude: startCoords?.$2 ?? 0,
      endLatitude: endCoords?.$1 ?? 0,
      endLongitude: endCoords?.$2 ?? 0,
      deviceId: vehicle.id,
      startDateTime: startTime,
      endDateTime: endTime,
    );
  }

  static (double lat, double lng)? _coordsForEnd(
    Map<String, dynamic> item, {
    required bool isStart,
    double? fallbackLat,
    double? fallbackLng,
  }) {
    final String prefix = isStart ? 'start' : 'end';
    final String altPrefix = isStart ? 'from' : 'to';

    final dynamic nested = item['${prefix}_position'] ??
        item[prefix] ??
        item['${altPrefix}_position'] ??
        item[altPrefix];
    if (nested is Map) {
      final Map<String, dynamic> map = nested.map(
        (Object? k, Object? v) => MapEntry(k.toString(), v),
      );
      final (double lat, double lng)? found = CoordinateParser.fromMap(map);
      if (found != null) {
        return found;
      }
    }

    final Map<String, dynamic> slice = <String, dynamic>{
      'lat': item['${prefix}_lat'] ??
          item['${altPrefix}_lat'] ??
          item['${prefix}_latitude'] ??
          item['${altPrefix}_latitude'] ??
          (isStart ? item['lat'] : item['lat_end']),
      'lng': item['${prefix}_lng'] ??
          item['${altPrefix}_lng'] ??
          item['${prefix}_longitude'] ??
          item['${altPrefix}_longitude'] ??
          (isStart ? item['lng'] : item['lng_end']),
    };
    final (double lat, double lng)? direct = CoordinateParser.fromMap(slice);
    if (direct != null) {
      return direct;
    }

    if (isStart) {
      return CoordinateParser.fromMap(item);
    }
    return null;
  }

  static String _pick(
    Map<String, dynamic> item,
    List<String> keys, {
    required String fallback,
  }) {
    for (final String key in keys) {
      final dynamic value = item[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString().trim();
      }
    }
    return fallback;
  }

  static String _formatDistance(String raw) {
    final String trimmed = raw.trim();
    if (trimmed.isEmpty || trimmed == '-') {
      return '-';
    }
    if (trimmed.toLowerCase().contains('km')) {
      return trimmed;
    }
    final double? n = double.tryParse(trimmed.replaceAll(',', ''));
    if (n == null) {
      return trimmed;
    }
    return '${n.toStringAsFixed(2)} km';
  }

  static String _formatDuration(Duration duration) {
    final int hours = duration.inHours;
    final int minutes = duration.inMinutes.remainder(60);
    return '${hours.toString().padLeft(2, '0')} h ${minutes.toString().padLeft(2, '0')} m';
  }

  static String _formatDurationLabelFromText(String raw) {
    final Duration? parsed = _parseDuration(raw);
    if (parsed != null) {
      return _formatDuration(parsed);
    }
    if (raw.isEmpty || raw == '-') {
      return '-';
    }
    return raw;
  }

  static Duration? _parseDuration(String raw) {
    final String trimmed = raw.trim().toLowerCase();
    if (trimmed.isEmpty || trimmed == '-') {
      return null;
    }
    final RegExp hm = RegExp(r'(\d+)\s*h(?:ours?)?\s*(\d+)\s*m');
    final RegExpMatch? hmMatch = hm.firstMatch(trimmed);
    if (hmMatch != null) {
      return Duration(
        hours: int.tryParse(hmMatch.group(1)!) ?? 0,
        minutes: int.tryParse(hmMatch.group(2)!) ?? 0,
      );
    }
    if (trimmed.contains(':')) {
      final List<String> parts =
          trimmed.replaceAll(RegExp(r'[^\d:]'), '').split(':');
      if (parts.length >= 2) {
        return Duration(
          hours: int.tryParse(parts[0]) ?? 0,
          minutes: int.tryParse(parts[1]) ?? 0,
          seconds: parts.length >= 3 ? (int.tryParse(parts[2]) ?? 0) : 0,
        );
      }
    }
    return null;
  }

  static String _formatTimeRaw(String raw) {
    final DateTime? parsed = _parseTime(raw);
    if (parsed != null) {
      return _displayFormat.format(parsed);
    }
    return raw.trim().isEmpty ? '-' : raw.trim();
  }

  static DateTime? _parseTime(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is DateTime) {
      return value;
    }
    if (value is int) {
      if (value > 9999999999) {
        return DateTime.fromMillisecondsSinceEpoch(value);
      }
      return DateTime.fromMillisecondsSinceEpoch(value * 1000);
    }
    final String raw = value.toString().trim();
    if (raw.isEmpty || raw == '-') {
      return null;
    }
    final List<DateFormat> formats = <DateFormat>[
      DateFormat('yyyy-MM-dd HH:mm:ss'),
      DateFormat('dd-MM-yyyy HH:mm:ss'),
      DateFormat('yyyy-MM-dd HH:mm'),
      DateFormat('dd MMM yyyy hh:mm a'),
    ];
    for (final DateFormat format in formats) {
      try {
        return format.parse(raw);
      } catch (_) {}
    }
    return DateTime.tryParse(raw.replaceAll('/', '-'));
  }
}
