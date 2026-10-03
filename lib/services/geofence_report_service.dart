import 'package:intl/intl.dart';

import '../constants/report_ids.dart';
import '../models/geofence_report_event.dart';
import '../models/notification_model.dart';
import '../models/vehicle_model.dart';
import '../utils/coordinate_parser.dart';
import '../utils/report_period.dart';
import '../utils/report_response_parser.dart';
import 'alert_service.dart';
import 'tracking_api_service.dart';

class GeofenceReportService {
  GeofenceReportService._();

  static final DateFormat _displayFormat = DateFormat('MMM dd yyyy hh:mm a');

  static Future<List<GeofenceReportEvent>> loadEvents({
    required VehicleModel vehicle,
    required DateTime from,
    required DateTime to,
  }) async {
    final DateTime queryFrom = ReportPeriod.startOfDay(from);
    final DateTime queryTo = ReportPeriod.endOfDay(to);
    final List<GeofenceReportEvent> merged = <GeofenceReportEvent>[];

    if (vehicle.id != null) {
      merged.addAll(
        await _fromGenerateReport(
          vehicle: vehicle,
          from: queryFrom,
          to: queryTo,
        ),
      );
    }

    merged.addAll(
      await _fromAlerts(
        vehicle: vehicle,
        from: queryFrom,
        to: queryTo,
      ),
    );

    merged.sort((GeofenceReportEvent a, GeofenceReportEvent b) {
      final DateTime? ad = a.dateTime;
      final DateTime? bd = b.dateTime;
      if (ad == null || bd == null) {
        return 0;
      }
      return bd.compareTo(ad);
    });

    return _dedupe(merged);
  }

  static List<GeofenceReportEvent> _dedupe(List<GeofenceReportEvent> events) {
    final Set<String> keys = <String>{};
    final List<GeofenceReportEvent> out = <GeofenceReportEvent>[];
    for (final GeofenceReportEvent event in events) {
      final String key =
          '${event.timeLabel}|${event.statusLabel}|${event.latitude}|${event.longitude}';
      if (keys.add(key)) {
        out.add(event);
      }
    }
    return out;
  }

  static Future<List<GeofenceReportEvent>> _fromGenerateReport({
    required VehicleModel vehicle,
    required DateTime from,
    required DateTime to,
  }) async {
    final dynamic response = await TrackingApiService.generateReport(
      reportId: ReportIds.geofence,
      deviceId: vehicle.id!,
      from: DateFormat('yyyy-MM-dd HH:mm:ss').format(from),
      to: DateFormat('yyyy-MM-dd HH:mm:ss').format(to),
    );

    if (response == null) {
      return <GeofenceReportEvent>[];
    }

    final List<Map<String, dynamic>> items =
        ReportResponseParser.rowsFromResponse(response);

    final List<GeofenceReportEvent> out = <GeofenceReportEvent>[];
    for (final Map<String, dynamic> item in items) {
      final GeofenceReportEvent? parsed =
          _eventFromMap(item, vehicle.name, fallbackLocation: vehicle.location);
      if (parsed != null) {
        out.add(parsed);
      }
    }
    return out;
  }

  static Future<List<GeofenceReportEvent>> _fromAlerts({
    required VehicleModel vehicle,
    required DateTime from,
    required DateTime to,
  }) async {
    final List<AppNotification> alerts = await AlertService.getEvents(
      deviceId: vehicle.id,
      limit: 200,
      forceRefresh: false,
    );
    final List<GeofenceReportEvent> out = <GeofenceReportEvent>[];

    for (final AppNotification alert in alerts) {
      if (alert.eventType != NotificationEventType.geofenceIn &&
          alert.eventType != NotificationEventType.geofenceOut) {
        continue;
      }

      final DateTime at = alert.timestamp;
      if (at.isBefore(from) || at.isAfter(to)) {
        continue;
      }

      final bool isEnter =
          alert.eventType == NotificationEventType.geofenceIn;

      out.add(
        GeofenceReportEvent(
          vehicleName: vehicle.name,
          timeLabel: _displayFormat.format(at),
          statusLabel: isEnter ? 'Geofence Enter' : 'Geofence Exit',
          isEnter: isEnter,
          address: alert.location.isNotEmpty
              ? alert.location
              : vehicle.location,
          latitude: alert.latitude ?? vehicle.latitude ?? 0,
          longitude: alert.longitude ?? vehicle.longitude ?? 0,
          dateTime: at,
        ),
      );
    }

    return out;
  }

  static GeofenceReportEvent? _eventFromMap(
    Map<String, dynamic> item,
    String vehicleName, {
    required String fallbackLocation,
  }) {
    final String rawType = (item['type'] ??
            item['status'] ??
            item['event'] ??
            item['title'] ??
            item['name'] ??
            '')
        .toString()
        .toLowerCase();

    if (rawType.isNotEmpty &&
        !rawType.contains('geofence') &&
        !rawType.contains('zone') &&
        !rawType.contains('enter') &&
        !rawType.contains('exit') &&
        !rawType.contains('in') &&
        !rawType.contains('out')) {
      return null;
    }

    final bool isEnter = rawType.contains('enter') ||
        rawType.contains('_in') ||
        rawType.contains(' zone in') ||
        rawType == 'in';
    final bool isExit = rawType.contains('exit') ||
        rawType.contains('_out') ||
        rawType.contains(' zone out') ||
        rawType == 'out';

    if (!isEnter && !isExit && rawType.contains('geofence')) {
      // Default ambiguous rows to exit if message says exit.
      final String msg = (item['message'] ?? '').toString().toLowerCase();
      if (msg.contains('enter') || msg.contains('inside')) {
        return _buildEvent(
          item,
          vehicleName,
          fallbackLocation: fallbackLocation,
          isEnter: true,
        );
      }
    }

    return _buildEvent(
      item,
      vehicleName,
      fallbackLocation: fallbackLocation,
      isEnter: isEnter || !isExit,
    );
  }

  static GeofenceReportEvent _buildEvent(
    Map<String, dynamic> item,
    String vehicleName, {
    required String fallbackLocation,
    required bool isEnter,
  }) {
    final String timeRaw = (item['time'] ??
            item['start_time'] ??
            item['timestamp'] ??
            item['date'] ??
            '')
        .toString();
    DateTime? parsedTime = DateTime.tryParse(timeRaw);
    final String timeLabel = parsedTime != null
        ? _displayFormat.format(parsedTime)
        : (timeRaw.isNotEmpty ? timeRaw : '-');

    final (double lat, double lng)? coords =
        CoordinateParser.fromMap(item);

    final String address = (item['address'] ??
            item['location'] ??
            item['place'] ??
            fallbackLocation)
        .toString();

    return GeofenceReportEvent(
      vehicleName: vehicleName,
      timeLabel: timeLabel,
      statusLabel: isEnter ? 'Geofence Enter' : 'Geofence Exit',
      isEnter: isEnter,
      address: address,
      latitude: coords?.$1 ?? 0,
      longitude: coords?.$2 ?? 0,
      dateTime: parsedTime,
    );
  }
}
