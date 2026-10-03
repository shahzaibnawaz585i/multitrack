import 'dart:math' as math;

import 'package:intl/intl.dart';

import '../constants/report_ids.dart';
import '../models/stoppage_report_event.dart';
import '../models/vehicle_model.dart';
import '../utils/coordinate_parser.dart';
import '../utils/report_period.dart';
import '../utils/report_response_parser.dart';
import 'history_service.dart';
import 'tracking_api_service.dart';
import 'vehicle_service.dart';

class StoppageReportService {
  StoppageReportService._();

  static final DateFormat _displayFormat = DateFormat('dd MMM yyyy hh:mm a');
  static const Duration _historyChunk = Duration(days: 3);
  static const Duration _sessionGap = Duration(minutes: 4);
  static const Duration _minStopDuration = Duration(minutes: 3);
  static const double _stopSpeedKmph = 3;

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

  static Future<List<StoppageReportEvent>> loadEventsForFleet({
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
    final List<StoppageReportEvent> merged = <StoppageReportEvent>[];

    for (int i = 0; i < withIds.length; i += maxConcurrent) {
      final int end = math.min(i + maxConcurrent, withIds.length);
      final List<VehicleModel> batch = withIds.sublist(i, end);
      final List<List<StoppageReportEvent>> chunks = await Future.wait(
        batch.map(
          (VehicleModel v) => loadEvents(vehicle: v, from: from, to: to),
        ),
      );
      for (final List<StoppageReportEvent> chunk in chunks) {
        merged.addAll(chunk);
      }
    }

    merged.sort((StoppageReportEvent a, StoppageReportEvent b) {
      final DateTime? ad = a.dateTime;
      final DateTime? bd = b.dateTime;
      if (ad == null || bd == null) {
        return 0;
      }
      return bd.compareTo(ad);
    });
    return merged;
  }

  static Future<List<StoppageReportEvent>> loadEvents({
    required VehicleModel vehicle,
    required DateTime from,
    required DateTime to,
  }) async {
    final VehicleModel resolved = await _resolveVehicle(vehicle);
    if (resolved.id == null) {
      return <StoppageReportEvent>[];
    }

    final DateTime queryFrom = ReportPeriod.startOfDay(from);
    final DateTime queryTo = ReportPeriod.endOfDay(to);
    final List<StoppageReportEvent> merged = <StoppageReportEvent>[];

    merged.addAll(
      await _fromGenerateReport(
        vehicle: resolved,
        from: queryFrom,
        to: queryTo,
      ),
    );
    merged.addAll(
      await _fromHistory(
        vehicle: resolved,
        from: queryFrom,
        to: queryTo,
      ),
    );

    final List<StoppageReportEvent> sorted = _dedupe(merged);
    sorted.sort((StoppageReportEvent a, StoppageReportEvent b) {
      final DateTime? ad = a.dateTime;
      final DateTime? bd = b.dateTime;
      if (ad == null || bd == null) {
        return 0;
      }
      return bd.compareTo(ad);
    });
    return sorted;
  }

  static Future<List<StoppageReportEvent>> _fromGenerateReport({
    required VehicleModel vehicle,
    required DateTime from,
    required DateTime to,
  }) async {
    final dynamic response = await TrackingApiService.generateReport(
      reportId: ReportIds.stoppage,
      deviceId: vehicle.id!,
      from: HistoryService.formatForApi(from),
      to: HistoryService.formatForApi(to),
    );

    if (response == null) {
      return <StoppageReportEvent>[];
    }

    final List<Map<String, dynamic>> items =
        ReportResponseParser.rowsFromResponse(response);
    if (items.isEmpty) {
      return <StoppageReportEvent>[];
    }

    final List<StoppageReportEvent> out = <StoppageReportEvent>[];
    for (final Map<String, dynamic> item in items) {
      final StoppageReportEvent? event = _eventFromMap(
        item,
        vehicleName: vehicle.name,
        fallbackLocation: vehicle.location,
      );
      if (event != null) {
        out.add(event);
      }
    }
    return out;
  }

  static Future<List<StoppageReportEvent>> _fromHistory({
    required VehicleModel vehicle,
    required DateTime from,
    required DateTime to,
  }) async {
    final List<HistoryPoint> points = await _loadHistoryPoints(
      deviceId: vehicle.id!,
      from: from,
      to: to,
    );
    return _sessionsFromHistory(
      vehicle: vehicle,
      points: points,
      from: from,
      to: to,
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

    return collected;
  }

  static List<StoppageReportEvent> _sessionsFromHistory({
    required VehicleModel vehicle,
    required List<HistoryPoint> points,
    required DateTime from,
    required DateTime to,
  }) {
    final List<StoppageReportEvent> events = <StoppageReportEvent>[];
    HistoryPoint? sessionStart;
    HistoryPoint? sessionEnd;
    DateTime? lastStopTime;

    void flushSession() {
      if (sessionStart == null ||
          sessionEnd == null ||
          sessionStart!.time == null ||
          sessionEnd!.time == null) {
        sessionStart = null;
        sessionEnd = null;
        lastStopTime = null;
        return;
      }

      final DateTime start = sessionStart!.time!;
      final DateTime end = sessionEnd!.time!;
      final Duration duration = end.difference(start);
      if (duration < _minStopDuration) {
        sessionStart = null;
        sessionEnd = null;
        lastStopTime = null;
        return;
      }
      if (!ReportPeriod.contains(start, from, to)) {
        sessionStart = null;
        sessionEnd = null;
        lastStopTime = null;
        return;
      }

      final double lat = sessionStart!.position.latitude;
      final double lng = sessionStart!.position.longitude;
      final String address = (sessionStart!.address?.trim().isNotEmpty ?? false)
          ? sessionStart!.address!.trim()
          : vehicle.location;

      events.add(
        StoppageReportEvent(
          vehicleName: vehicle.name,
          startTimeLabel: _displayFormat.format(start),
          endTimeLabel: _displayFormat.format(end),
          durationLabel: _formatDuration(duration),
          address: address,
          latitude: lat,
          longitude: lng,
          dateTime: start,
        ),
      );

      sessionStart = null;
      sessionEnd = null;
      lastStopTime = null;
    }

    for (final HistoryPoint point in points) {
      final DateTime? time = point.time;
      if (time == null) {
        continue;
      }

      if (_isStopped(point)) {
        if (lastStopTime != null &&
            time.difference(lastStopTime!) > _sessionGap) {
          flushSession();
        }
        sessionStart ??= point;
        sessionEnd = point;
        lastStopTime = time;
      } else {
        flushSession();
      }
    }
    flushSession();
    return events;
  }

  static bool _isStopped(HistoryPoint point) {
    if (point.isStop) {
      return true;
    }
    final String? type = point.eventType?.toLowerCase();
    if (type != null &&
        (type.contains('stop') || type.contains('park') || type.contains('idle'))) {
      return true;
    }
    return (point.speed ?? 0) <= _stopSpeedKmph;
  }

  static StoppageReportEvent? _eventFromMap(
    Map<String, dynamic> item, {
    required String vehicleName,
    required String fallbackLocation,
  }) {
    final String deviceName = (item['device_name'] ??
            item['vehicle_name'] ??
            item['vehicle'] ??
            vehicleName)
        .toString()
        .trim();

    final DateTime? startTime = _parseTime(
      item['start_time'] ??
          item['time_from'] ??
          item['time'] ??
          item['timestamp'] ??
          item['date_from'],
    );
    final DateTime? endTime = _parseTime(
      item['end_time'] ??
          item['time_to'] ??
          item['date_to'] ??
          item['finish_time'],
    );

    final String durationRaw = (item['duration'] ??
            item['stop_duration'] ??
            item['stop_time'] ??
            item['idle_duration'] ??
            '')
        .toString()
        .trim();

    Duration? duration = _parseDuration(durationRaw);
    if (duration == null && startTime != null && endTime != null) {
      duration = endTime.difference(startTime);
    }
    if (duration != null && duration.isNegative) {
      duration = duration.abs();
    }

    final (double lat, double lng)? coords = CoordinateParser.fromMap(item);
    final String address = (item['address'] ??
            item['location'] ??
            item['place'] ??
            fallbackLocation)
        .toString()
        .trim();

    final String startLabel = startTime != null
        ? _displayFormat.format(startTime)
        : _formatTimeRaw(
            (item['start_time'] ?? item['time'] ?? '-').toString(),
          );
    final String endLabel = endTime != null
        ? _displayFormat.format(endTime)
        : _formatTimeRaw(
            (item['end_time'] ?? item['time_to'] ?? '-').toString(),
          );

    final String durationLabel = duration != null
        ? _formatDuration(duration)
        : _formatDurationLabelFromText(durationRaw);

    if (startTime == null &&
        endTime == null &&
        durationLabel == '-' &&
        durationRaw.isEmpty) {
      return null;
    }

    return StoppageReportEvent(
      vehicleName: deviceName.isNotEmpty ? deviceName : vehicleName,
      startTimeLabel: startLabel,
      endTimeLabel: endLabel,
      durationLabel: durationLabel,
      address: address,
      latitude: coords?.$1 ?? 0,
      longitude: coords?.$2 ?? 0,
      dateTime: startTime ?? endTime,
    );
  }

  static String _formatTimeRaw(String raw) {
    final DateTime? parsed = _parseTime(raw);
    if (parsed != null) {
      return _displayFormat.format(parsed);
    }
    return raw.trim().isEmpty ? '-' : raw.trim();
  }

  static List<StoppageReportEvent> _dedupe(List<StoppageReportEvent> events) {
    final Set<String> keys = <String>{};
    final List<StoppageReportEvent> out = <StoppageReportEvent>[];
    for (final StoppageReportEvent event in events) {
      final String key =
          '${event.vehicleName}|${event.startTimeLabel}|${event.endTimeLabel}|${event.latitude}|${event.longitude}';
      if (keys.add(key)) {
        out.add(event);
      }
    }
    return out;
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
      final int h = int.tryParse(hmMatch.group(1)!) ?? 0;
      final int m = int.tryParse(hmMatch.group(2)!) ?? 0;
      return Duration(hours: h, minutes: m);
    }

    if (trimmed.contains(':')) {
      final List<String> parts =
          trimmed.replaceAll(RegExp(r'[^\d:]'), '').split(':');
      if (parts.length >= 2) {
        final int h = int.tryParse(parts[0]) ?? 0;
        final int m = int.tryParse(parts[1]) ?? 0;
        final int s = parts.length >= 3 ? (int.tryParse(parts[2]) ?? 0) : 0;
        return Duration(hours: h, minutes: m, seconds: s);
      }
    }

    final RegExp minOnly = RegExp(r'(\d+)\s*min');
    final RegExpMatch? minMatch = minOnly.firstMatch(trimmed);
    if (minMatch != null) {
      return Duration(minutes: int.tryParse(minMatch.group(1)!) ?? 0);
    }

    return null;
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
      DateFormat('MMM dd yyyy hh:mm a'),
    ];
    for (final DateFormat format in formats) {
      try {
        return format.parse(raw);
      } catch (_) {}
    }
    return DateTime.tryParse(raw.replaceAll('/', '-'));
  }
}
