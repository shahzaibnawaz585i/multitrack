import 'dart:math' as math;

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';

import '../constants/report_ids.dart';
import '../models/notification_model.dart';
import '../models/over_speed_report_event.dart';
import '../models/vehicle_model.dart';
import '../utils/coordinate_parser.dart';
import '../utils/report_period.dart';
import '../utils/report_response_parser.dart';
import 'alert_service.dart';
import 'history_service.dart';
import 'tracking_api_service.dart';
import 'vehicle_service.dart';

class OverSpeedReportService {
  OverSpeedReportService._();

  static final DateFormat _displayFormat = DateFormat('MMM dd yyyy hh:mm a');
  static const double _defaultLimitKmph = 40;
  static const Duration _historyChunk = Duration(days: 3);
  static const Duration _sessionGap = Duration(minutes: 4);

  static Future<List<OverSpeedReportEvent>> loadEvents({
    required VehicleModel vehicle,
    required DateTime from,
    required DateTime to,
    double speedLimitKmph = _defaultLimitKmph,
  }) async {
    final VehicleModel resolved = await _resolveVehicle(vehicle);
    final DateTime queryFrom = ReportPeriod.startOfDay(from);
    final DateTime queryTo = ReportPeriod.endOfDay(to);
    final List<OverSpeedReportEvent> merged = <OverSpeedReportEvent>[];

    merged.addAll(
      await _fromGenerateReport(
        vehicle: resolved,
        from: queryFrom,
        to: queryTo,
        speedLimitKmph: speedLimitKmph,
      ),
    );
    merged.addAll(
      await _fromHistory(
        vehicle: resolved,
        from: queryFrom,
        to: queryTo,
        speedLimitKmph: speedLimitKmph,
      ),
    );
    merged.addAll(
      await _fromAlerts(
        vehicle: resolved,
        from: queryFrom,
        to: queryTo,
        speedLimitKmph: speedLimitKmph,
      ),
    );

    final List<OverSpeedReportEvent> filtered =
        _dedupeSessions(_filterDateRange(merged, queryFrom, queryTo));

    filtered.sort((OverSpeedReportEvent a, OverSpeedReportEvent b) {
      final DateTime? ad = a.dateTime;
      final DateTime? bd = b.dateTime;
      if (ad == null || bd == null) {
        return 0;
      }
      return bd.compareTo(ad);
    });

    return filtered
        .where(
          (OverSpeedReportEvent e) =>
              _hasValidCoords(e.latitude, e.longitude),
        )
        .toList();
  }

  static bool _hasValidCoords(double lat, double lng) {
    return CoordinateParser.fromMap(<String, dynamic>{
          'lat': lat,
          'lng': lng,
        }) !=
        null;
  }

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

  static Future<List<OverSpeedReportEvent>> _fromGenerateReport({
    required VehicleModel vehicle,
    required DateTime from,
    required DateTime to,
    required double speedLimitKmph,
  }) async {
    if (vehicle.id == null) {
      return <OverSpeedReportEvent>[];
    }

    final dynamic response = await TrackingApiService.generateReport(
      reportId: ReportIds.speed,
      deviceId: vehicle.id!,
      from: HistoryService.formatForApi(from),
      to: HistoryService.formatForApi(to),
    );

    if (response == null) {
      return <OverSpeedReportEvent>[];
    }

    final List<Map<String, dynamic>> items =
        ReportResponseParser.rowsFromResponse(response);
    if (items.isEmpty) {
      return <OverSpeedReportEvent>[];
    }

    final List<OverSpeedReportEvent> events = <OverSpeedReportEvent>[];

    for (final Map<String, dynamic> item in items) {
      final OverSpeedReportEvent? event = _mapRow(
        vehicle,
        item,
        speedLimitKmph: speedLimitKmph,
      );
      if (event != null) {
        events.add(event);
      }
    }

    return events;
  }

  static Future<List<OverSpeedReportEvent>> _fromHistory({
    required VehicleModel vehicle,
    required DateTime from,
    required DateTime to,
    required double speedLimitKmph,
  }) async {
    if (vehicle.id == null) {
      return <OverSpeedReportEvent>[];
    }

    final List<HistoryPoint> points = await _loadHistoryPoints(
      deviceId: vehicle.id!,
      from: from,
      to: to,
    );

    if (points.isEmpty) {
      return <OverSpeedReportEvent>[];
    }

    return _sessionsFromHistory(
      vehicle: vehicle,
      points: points,
      from: from,
      to: to,
      speedLimitKmph: speedLimitKmph,
    );
  }

  static Future<List<HistoryPoint>> _loadHistoryPoints({
    required int deviceId,
    required DateTime from,
    required DateTime to,
  }) async {
    final List<HistoryPoint> collected = <HistoryPoint>[];
    DateTime cursor = from;

    while (!cursor.isAfter(to)) {
      DateTime chunkEnd = cursor.add(_historyChunk);
      if (chunkEnd.isAfter(to)) {
        chunkEnd = to;
      }

      final HistoryRoute route = await HistoryService.getRoute(
        deviceId: deviceId,
        from: cursor,
        to: chunkEnd,
        forceRefresh: true,
      );
      collected.addAll(route.points);

      if (chunkEnd.isAtSameMomentAs(to) ||
          chunkEnd.millisecondsSinceEpoch >= to.millisecondsSinceEpoch) {
        break;
      }
      cursor = chunkEnd.add(const Duration(seconds: 1));
    }

    return _dedupeHistoryPoints(collected);
  }

  static List<HistoryPoint> _dedupeHistoryPoints(List<HistoryPoint> points) {
    final Map<String, HistoryPoint> unique = <String, HistoryPoint>{};
    for (final HistoryPoint point in points) {
      final DateTime? time = point.time;
      final String key = time != null
          ? '${time.millisecondsSinceEpoch}_${point.position.latitude.toStringAsFixed(5)}_${point.position.longitude.toStringAsFixed(5)}'
          : '${point.position.latitude}_${point.position.longitude}_${point.speed}';
      unique[key] = point;
    }

    final List<HistoryPoint> sorted = unique.values.toList();
    sorted.sort((HistoryPoint a, HistoryPoint b) {
      final DateTime? at = a.time;
      final DateTime? bt = b.time;
      if (at == null || bt == null) {
        return 0;
      }
      return at.compareTo(bt);
    });
    return sorted;
  }

  static List<OverSpeedReportEvent> _sessionsFromHistory({
    required VehicleModel vehicle,
    required List<HistoryPoint> points,
    required DateTime from,
    required DateTime to,
    required double speedLimitKmph,
  }) {
    final List<HistoryPoint> enriched = _enrichSpeeds(points);
    final bool useKnots = _shouldTreatAsKnots(enriched);

    final List<OverSpeedReportEvent> events = <OverSpeedReportEvent>[];
    HistoryPoint? sessionPeak;
    double sessionPeakSpeed = 0;
    DateTime? sessionPeakTime;
    DateTime? lastOverSpeedTime;

    void flushSession() {
      if (sessionPeak == null || sessionPeakTime == null) {
        return;
      }
      final DateTime peakTime = sessionPeakTime!;
      if (!ReportPeriod.contains(peakTime, from, to)) {
        sessionPeak = null;
        sessionPeakSpeed = 0;
        sessionPeakTime = null;
        lastOverSpeedTime = null;
        return;
      }

      if (!_hasValidCoords(
        sessionPeak!.position.latitude,
        sessionPeak!.position.longitude,
      )) {
        sessionPeak = null;
        sessionPeakSpeed = 0;
        sessionPeakTime = null;
        lastOverSpeedTime = null;
        return;
      }

      events.add(
        OverSpeedReportEvent(
          vehicleName: vehicle.name,
          dateTime: peakTime,
          timeLabel: _displayFormat.format(peakTime),
          speedKmph: sessionPeakSpeed,
          speedLabel: '${sessionPeakSpeed.toStringAsFixed(1)} kmph',
          address: (sessionPeak!.address?.trim().isNotEmpty ?? false)
              ? sessionPeak!.address!.trim()
              : vehicle.location,
          latitude: sessionPeak!.position.latitude,
          longitude: sessionPeak!.position.longitude,
        ),
      );

      sessionPeak = null;
      sessionPeakSpeed = 0;
      sessionPeakTime = null;
      lastOverSpeedTime = null;
    }

    for (final HistoryPoint point in enriched) {
      final double speedKmph = _toKmph(point.speed ?? 0, useKnots: useKnots);
      final DateTime? time = point.time;
      if (time == null) {
        continue;
      }

      if (speedKmph < speedLimitKmph) {
        flushSession();
        continue;
      }

      if (lastOverSpeedTime != null &&
          time.difference(lastOverSpeedTime!) > _sessionGap) {
        flushSession();
      }

      lastOverSpeedTime = time;

      if (sessionPeak == null || speedKmph >= sessionPeakSpeed) {
        sessionPeak = point;
        sessionPeakSpeed = speedKmph;
        sessionPeakTime = time;
      }
    }

    flushSession();
    return events;
  }

  static Future<List<OverSpeedReportEvent>> _fromAlerts({
    required VehicleModel vehicle,
    required DateTime from,
    required DateTime to,
    required double speedLimitKmph,
  }) async {
    final List<AppNotification> alerts = await AlertService.getEvents(
      deviceId: vehicle.id,
      limit: 200,
      forceRefresh: true,
    );

    final List<OverSpeedReportEvent> events = <OverSpeedReportEvent>[];
    for (final AppNotification alert in alerts) {
      if (!_matchesVehicle(alert, vehicle)) {
        continue;
      }

      final bool isOverSpeed = alert.eventType == NotificationEventType.overSpeed ||
          alert.eventTitle.toLowerCase().contains('speed');
      if (!isOverSpeed) {
        continue;
      }

      if (!_inRange(alert.timestamp, from, to)) {
        continue;
      }

      final double? speed = alert.speed ??
          _parseSpeedFromText(alert.eventTitle) ??
          _parseSpeedFromText(alert.location);
      final double speedKmph = speed ?? speedLimitKmph;
      if (speed != null && speedKmph < speedLimitKmph) {
        continue;
      }

      final (double lat, double lng)? coords = _coordsFromAlert(alert);
      if (coords == null) {
        continue;
      }

      events.add(
        OverSpeedReportEvent(
          vehicleName: vehicle.name,
          dateTime: alert.timestamp,
          timeLabel: _displayFormat.format(alert.timestamp),
          speedKmph: speedKmph,
          speedLabel: '${speedKmph.toStringAsFixed(1)} kmph',
          address: alert.location,
          latitude: coords.$1,
          longitude: coords.$2,
        ),
      );
    }

    return events;
  }

  static (double lat, double lng)? _coordsFromAlert(AppNotification alert) {
    if (alert.latitude != null && alert.longitude != null) {
      final (double lat, double lng)? fromFields = CoordinateParser.fromMap(
        <String, dynamic>{
          'lat': alert.latitude,
          'lng': alert.longitude,
        },
      );
      if (fromFields != null) {
        return fromFields;
      }
    }
    return CoordinateParser.parsePair(alert.location);
  }

  static OverSpeedReportEvent? _mapRow(
    VehicleModel vehicle,
    Map<String, dynamic> item, {
    required double speedLimitKmph,
  }) {
    final String rawText = <String>[
      item['message']?.toString() ?? '',
      item['title']?.toString() ?? '',
      item['event']?.toString() ?? '',
      item['type']?.toString() ?? '',
      item['status']?.toString() ?? '',
    ].join(' ');

    final double? speed = _parseDouble(
          item['speed'] ??
              item['max_speed'] ??
              item['top_speed'] ??
              item['velocity'] ??
              item['value'] ??
              item['speed_kmh'],
        ) ??
        _parseSpeedFromText(rawText);

    if (speed == null || speed <= 0) {
      return null;
    }

    if (speed < speedLimitKmph) {
      return null;
    }

    final DateTime? time = _parseTime(
      item['time'] ??
          item['start_time'] ??
          item['timestamp'] ??
          item['date'] ??
          item['datetime'] ??
          item['created_at'],
    );

    final (double lat, double lng)? coords = CoordinateParser.fromMap(item);
    if (coords == null) {
      return null;
    }

    final String address = (item['address'] ??
            item['location'] ??
            item['place'] ??
            '')
        .toString()
        .trim();

    return OverSpeedReportEvent(
      vehicleName: vehicle.name,
      dateTime: time,
      timeLabel: time != null ? _displayFormat.format(time) : '-',
      speedKmph: speed,
      speedLabel: '${speed.toStringAsFixed(1)} kmph',
      address: address.isNotEmpty ? address : vehicle.location,
      latitude: coords.$1,
      longitude: coords.$2,
    );
  }

  static List<HistoryPoint> _enrichSpeeds(List<HistoryPoint> points) {
    if (points.length < 2) {
      return points;
    }

    final List<HistoryPoint> out = <HistoryPoint>[];
    for (int i = 0; i < points.length; i++) {
      HistoryPoint point = points[i];
      double? speed = point.speed;

      if ((speed == null || speed <= 0) && i > 0) {
        final HistoryPoint prev = points[i - 1];
        if (prev.time != null && point.time != null) {
          final double hours = point.time!
              .difference(prev.time!)
              .inMilliseconds
              .abs()
              .toDouble() /
              3600000.0;
          if (hours > 0 && hours < 3) {
            final double km =
                _haversineKm(prev.position, point.position);
            if (km > 0.01) {
              speed = km / hours;
            }
          }
        }
      }

      out.add(
        HistoryPoint(
          position: point.position,
          time: point.time,
          speed: speed,
          course: point.course,
          address: point.address,
        ),
      );
    }
    return out;
  }

  static bool _shouldTreatAsKnots(List<HistoryPoint> points) {
    final List<double> raw = points
        .map((HistoryPoint p) => p.speed ?? 0)
        .where((double s) => s > 3)
        .toList();
    if (raw.isEmpty) {
      return false;
    }
    final double max = raw.reduce(math.max);
    return max <= 45;
  }

  static double _toKmph(double raw, {required bool useKnots}) {
    if (raw <= 0) {
      return 0;
    }
    return useKnots ? raw * 1.852 : raw;
  }

  static double _haversineKm(LatLng a, LatLng b) {
    const double r = 6371;
    final double lat1 = a.latitude * math.pi / 180;
    final double lat2 = b.latitude * math.pi / 180;
    final double dLat = (b.latitude - a.latitude) * math.pi / 180;
    final double dLng = (b.longitude - a.longitude) * math.pi / 180;
    final double s = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1) *
            math.cos(lat2) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    return r * 2 * math.atan2(math.sqrt(s), math.sqrt(1 - s));
  }

  static bool _matchesVehicle(AppNotification alert, VehicleModel vehicle) {
    if (vehicle.id != null &&
        alert.vehicleId.trim() == vehicle.id.toString()) {
      return true;
    }
    final String alertName = alert.vehicleId.trim().toLowerCase();
    final String vehicleName = vehicle.name.trim().toLowerCase();
    if (alertName == vehicleName) {
      return true;
    }
    return alertName.contains(vehicleName) || vehicleName.contains(alertName);
  }

  static bool _inRange(DateTime value, DateTime from, DateTime to) {
    return ReportPeriod.contains(value, from, to);
  }

  static List<OverSpeedReportEvent> _filterDateRange(
    List<OverSpeedReportEvent> events,
    DateTime from,
    DateTime to,
  ) {
    return events.where((OverSpeedReportEvent event) {
      final DateTime? time = event.dateTime;
      if (time == null) {
        return true;
      }
      return _inRange(time, from, to);
    }).toList();
  }

  static List<OverSpeedReportEvent> _dedupeSessions(
    List<OverSpeedReportEvent> events,
  ) {
    final Map<String, OverSpeedReportEvent> unique =
        <String, OverSpeedReportEvent>{};
    for (final OverSpeedReportEvent event in events) {
      final DateTime? time = event.dateTime;
      final String minuteBucket = time != null
          ? '${time.year}-${time.month}-${time.day}-${time.hour}-${time.minute}'
          : event.timeLabel;
      final String key =
          '${event.vehicleName}_${minuteBucket}_${event.speedKmph.round()}';
      final OverSpeedReportEvent? existing = unique[key];
      if (existing == null || event.speedKmph > existing.speedKmph) {
        unique[key] = event;
      }
    }
    return unique.values.toList();
  }

  static double? _parseSpeedFromText(String? text) {
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
    final double? plain = double.tryParse(text.replaceAll(RegExp(r'[^\d.]'), ''));
    if (plain != null && plain > 0 && plain < 300) {
      return plain;
    }
    return null;
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is num) {
      return value.toDouble();
    }
    final String raw = value.toString().replaceAll(RegExp(r'[^0-9.\-]'), '');
    if (raw.isEmpty) {
      return null;
    }
    return double.tryParse(raw);
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
    if (raw.isEmpty) {
      return null;
    }

    final List<DateFormat> formats = <DateFormat>[
      DateFormat('yyyy-MM-dd HH:mm:ss'),
      DateFormat('dd-MM-yyyy HH:mm:ss'),
      DateFormat('yyyy-MM-dd HH:mm'),
      DateFormat('dd MMM yyyy hh:mm a'),
      DateFormat('MMM dd yyyy hh:mm a'),
    ];

    for (final DateFormat format in formats) {
      try {
        return format.parse(raw);
      } catch (_) {}
    }

    return DateTime.tryParse(raw);
  }
}
