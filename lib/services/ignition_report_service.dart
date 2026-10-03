import 'dart:math' as math;

import 'package:intl/intl.dart';

import '../constants/report_ids.dart';

import '../models/ignition_report_event.dart';

import '../models/notification_model.dart';

import '../models/vehicle_model.dart';

import '../utils/coordinate_parser.dart';

import '../utils/report_period.dart';

import '../utils/report_response_parser.dart';

import 'alert_service.dart';

import 'history_service.dart';

import 'tracking_api_service.dart';

import 'vehicle_service.dart';

class IgnitionReportService {
  IgnitionReportService._();

  static final DateFormat _displayFormat = DateFormat('MMM dd yyyy hh:mm a');

  static const Duration _historyChunk = Duration(days: 3);

  static Future<VehicleModel> _resolveVehicle(VehicleModel vehicle) async {
    if (vehicle.id != null) {
      return vehicle;
    }

    final List<VehicleModel> devices = await VehicleService.getDevices(
      forceRefresh: false,
    );

    for (final VehicleModel item in devices) {
      if (item.name.trim().toLowerCase() == vehicle.name.trim().toLowerCase()) {
        return item;
      }
    }

    return vehicle;
  }

  static Future<List<IgnitionReportEvent>> loadEventsForFleet({
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

    final List<IgnitionReportEvent> merged = <IgnitionReportEvent>[];

    for (int i = 0; i < withIds.length; i += maxConcurrent) {
      final int end = math.min(i + maxConcurrent, withIds.length);

      final List<VehicleModel> batch = withIds.sublist(i, end);

      final List<List<IgnitionReportEvent>> chunks = await Future.wait(
        batch.map(
          (VehicleModel v) => loadEvents(vehicle: v, from: from, to: to),
        ),
      );

      for (final List<IgnitionReportEvent> chunk in chunks) {
        merged.addAll(chunk);
      }
    }

    merged.sort((IgnitionReportEvent a, IgnitionReportEvent b) {
      final DateTime? ad = a.dateTime;

      final DateTime? bd = b.dateTime;

      if (ad == null || bd == null) {
        return 0;
      }

      return bd.compareTo(ad);
    });

    return _dedupe(merged);
  }

  static Future<List<IgnitionReportEvent>> loadEvents({
    required VehicleModel vehicle,

    required DateTime from,

    required DateTime to,
  }) async {
    final VehicleModel resolved = await _resolveVehicle(vehicle);

    if (resolved.id == null) {
      return <IgnitionReportEvent>[];
    }

    final DateTime queryFrom = ReportPeriod.startOfDay(from);

    final DateTime queryTo = ReportPeriod.endOfDay(to);

    final List<IgnitionReportEvent> merged = <IgnitionReportEvent>[];

    merged.addAll(
      await _fromGenerateReport(
        vehicle: resolved,

        from: queryFrom,

        to: queryTo,
      ),
    );

    merged.addAll(
      await _fromHistory(vehicle: resolved, from: queryFrom, to: queryTo),
    );

    merged.addAll(
      await _fromAlerts(vehicle: resolved, from: queryFrom, to: queryTo),
    );

    merged.sort((IgnitionReportEvent a, IgnitionReportEvent b) {
      final DateTime? ad = a.dateTime;

      final DateTime? bd = b.dateTime;

      if (ad == null || bd == null) {
        return 0;
      }

      return bd.compareTo(ad);
    });

    return _dedupe(merged);
  }

  static Future<List<IgnitionReportEvent>> _fromGenerateReport({
    required VehicleModel vehicle,

    required DateTime from,

    required DateTime to,
  }) async {
    final dynamic response = await TrackingApiService.generateReport(
      reportId: ReportIds.ignition,

      deviceId: vehicle.id!,

      from: HistoryService.formatForApi(from),

      to: HistoryService.formatForApi(to),
    );

    if (response == null) {
      return <IgnitionReportEvent>[];
    }

    final List<Map<String, dynamic>> items =
        ReportResponseParser.rowsFromResponse(response);

    final List<IgnitionReportEvent> out = <IgnitionReportEvent>[];

    for (final Map<String, dynamic> item in items) {
      final IgnitionReportEvent? event = _eventFromMap(
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

  static Future<List<IgnitionReportEvent>> _fromHistory({
    required VehicleModel vehicle,

    required DateTime from,

    required DateTime to,
  }) async {
    final List<HistoryPoint> points = await _loadHistoryPoints(
      deviceId: vehicle.id!,

      from: from,

      to: to,
    );

    final List<IgnitionReportEvent> out = <IgnitionReportEvent>[];

    for (final HistoryPoint point in points) {
      final String blob = <String?>[
        point.eventType,
        point.address,
      ].whereType<String>().join(' ').toLowerCase();

      if (blob.isEmpty ||
          (!blob.contains('ignition') &&
              !blob.contains('acc') &&
              !blob.contains('engine') &&
              !blob.contains('power'))) {
        continue;
      }

      final bool? isOn = _resolveIgnitionState(blob);

      if (isOn == null) {
        continue;
      }

      final DateTime? at = point.time;

      if (at == null || at.isBefore(from) || at.isAfter(to)) {
        continue;
      }

      out.add(
        IgnitionReportEvent(
          vehicleName: vehicle.name,

          timeLabel: _displayFormat.format(at),

          statusLabel: isOn ? 'Ignition On' : 'Ignition Off',

          isOn: isOn,

          address: point.address ?? vehicle.location,

          latitude: point.position.latitude,

          longitude: point.position.longitude,

          dateTime: at,
        ),
      );
    }

    return out;
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

        forceRefresh: false,
      );

      collected.addAll(route.points);

      if (chunkEnd.isAtSameMomentAs(to)) {
        break;
      }

      cursor = chunkEnd.add(const Duration(seconds: 1));
    }

    return collected;
  }

  static Future<List<IgnitionReportEvent>> _fromAlerts({
    required VehicleModel vehicle,

    required DateTime from,

    required DateTime to,
  }) async {
    final List<IgnitionReportEvent> out = <IgnitionReportEvent>[];

    for (int page = 1; page <= 8; page++) {
      final List<AppNotification> alerts = await AlertService.getEvents(
        deviceId: vehicle.id,

        page: page,

        limit: 500,

        forceRefresh: page == 1,
      );

      if (alerts.isEmpty) {
        break;
      }

      for (final AppNotification alert in alerts) {
        if (!_matchesVehicle(alert, vehicle)) {
          continue;
        }

        if (alert.eventType != NotificationEventType.ignitionOn &&
            alert.eventType != NotificationEventType.ignitionOff) {
          continue;
        }

        if (alert.timestamp.isBefore(from) || alert.timestamp.isAfter(to)) {
          continue;
        }

        final bool isOn = alert.eventType == NotificationEventType.ignitionOn;

        final (double lat, double lng)? coords = _coordsFromAlert(alert);

        out.add(
          IgnitionReportEvent(
            vehicleName: vehicle.name,

            timeLabel: _displayFormat.format(alert.timestamp),

            statusLabel: isOn ? 'Ignition On' : 'Ignition Off',

            isOn: isOn,

            address: alert.location,

            latitude: coords?.$1 ?? 0,

            longitude: coords?.$2 ?? 0,

            dateTime: alert.timestamp,
          ),
        );
      }

      if (alerts.length < 500) {
        break;
      }
    }

    return out;
  }

  static (double lat, double lng)? _coordsFromAlert(AppNotification alert) {
    if (alert.latitude != null && alert.longitude != null) {
      final (double lat, double lng)? fromFields = CoordinateParser.fromMap(
        <String, dynamic>{'lat': alert.latitude, 'lng': alert.longitude},
      );

      if (fromFields != null) {
        return fromFields;
      }
    }

    return CoordinateParser.parsePair(alert.location);
  }

  static bool _matchesVehicle(AppNotification alert, VehicleModel vehicle) {
    if (vehicle.id != null && alert.vehicleId.trim() == vehicle.id.toString()) {
      return true;
    }

    final String alertName = alert.vehicleId.trim().toLowerCase();

    final String vehicleName = vehicle.name.trim().toLowerCase();

    if (alertName == vehicleName) {
      return true;
    }

    return alertName.contains(vehicleName) || vehicleName.contains(alertName);
  }

  static IgnitionReportEvent? _eventFromMap(
    Map<String, dynamic> item, {

    required String vehicleName,

    required String fallbackLocation,
  }) {
    final String rawType = _collectTextBlob(item);

    final bool? fromFields = _ignitionStateFromFields(item);

    final bool? fromText = _resolveIgnitionState(rawType);

    bool? isOn = fromFields ?? fromText;

    if (isOn == null && rawType.isNotEmpty) {
      if (rawType.contains('ignition') ||
          rawType.contains('acc') ||
          rawType.contains('engine')) {
        isOn = !rawType.contains('off') && !rawType.contains('stop');
      }
    }

    if (isOn == null) {
      return null;
    }

    final DateTime? time = _parseTime(
      item['time'] ??
          item['start_time'] ??
          item['timestamp'] ??
          item['date'] ??
          item['datetime'],
    );

    if (time == null) {
      return null;
    }

    final (double lat, double lng)? coords = CoordinateParser.fromMap(item);

    final String address =
        (item['address'] ??
                item['location'] ??
                item['place'] ??
                fallbackLocation)
            .toString()
            .trim();

    final String resolvedName =
        (item['device_name'] ?? item['vehicle_name'] ?? vehicleName)
            .toString()
            .trim();

    return IgnitionReportEvent(
      vehicleName: resolvedName.isNotEmpty ? resolvedName : vehicleName,

      timeLabel: _displayFormat.format(time),

      statusLabel: isOn ? 'Ignition On' : 'Ignition Off',

      isOn: isOn,

      address: address,

      latitude: coords?.$1 ?? 0,

      longitude: coords?.$2 ?? 0,

      dateTime: time,
    );
  }

  static String _collectTextBlob(Map<String, dynamic> item) {
    final StringBuffer buffer = StringBuffer();

    void walk(dynamic node) {
      if (node == null) {
        return;
      }

      if (node is String || node is num || node is bool) {
        buffer.write(' ${node.toString()}');

        return;
      }

      if (node is Map) {
        for (final dynamic value in node.values) {
          walk(value);
        }

        return;
      }

      if (node is List) {
        for (final dynamic value in node) {
          walk(value);
        }
      }
    }

    walk(item);

    return buffer.toString().toLowerCase();
  }

  static bool? _ignitionStateFromFields(Map<String, dynamic> item) {
    for (final String key in <String>[
      'ignition',

      'acc',

      'engine',

      'ignition_status',

      'acc_status',

      'engine_status',

      'status',

      'type',

      'event',
    ]) {
      if (!item.containsKey(key)) {
        continue;
      }

      final bool? parsed = _resolveIgnitionState(item[key].toString());

      if (parsed != null) {
        return parsed;
      }
    }

    return null;
  }

  static bool? _resolveIgnitionState(String raw) {
    final String lower = raw.toLowerCase();

    if (lower.isEmpty) {
      return null;
    }

    if (lower.contains('ignition off') ||
        lower.contains('ignition_off') ||
        lower.contains('acc off') ||
        lower.contains('acc_off') ||
        lower.contains('engine off') ||
        lower.contains('engine_off') ||
        RegExp(r'\boff\b').hasMatch(lower) && lower.contains('ignition')) {
      return false;
    }

    if (lower.contains('ignition on') ||
        lower.contains('ignition_on') ||
        lower.contains('acc on') ||
        lower.contains('acc_on') ||
        lower.contains('engine on') ||
        lower.contains('engine_on') ||
        lower.contains('start') ||
        RegExp(r'\bon\b').hasMatch(lower) && lower.contains('ignition')) {
      return true;
    }

    if (lower == '1' || lower == 'true' || lower == 'yes' || lower == 'on') {
      return true;
    }

    if (lower == '0' || lower == 'false' || lower == 'no' || lower == 'off') {
      return false;
    }

    return null;
  }

  static List<IgnitionReportEvent> _dedupe(List<IgnitionReportEvent> events) {
    final Set<String> keys = <String>{};

    final List<IgnitionReportEvent> out = <IgnitionReportEvent>[];

    for (final IgnitionReportEvent event in events) {
      final String key =
          '${event.vehicleName}|${event.timeLabel}|${event.statusLabel}|${event.latitude}|${event.longitude}';

      if (keys.add(key)) {
        out.add(event);
      }
    }

    return out;
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

      DateFormat('dd-MM-yyyy hh:mm:ss a'),

      DateFormat('dd-MM-yyyy hh:mm a'),

      DateFormat('yyyy-MM-dd HH:mm'),

      DateFormat('MMM dd yyyy hh:mm a'),

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
