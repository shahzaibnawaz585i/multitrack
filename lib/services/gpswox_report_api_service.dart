import 'dart:async';
import 'dart:developer' as developer;

import 'package:intl/intl.dart';

import '../constants/api_config.dart';
import '../constants/report_ids.dart';
import '../utils/report_response_parser.dart';
import 'api_client.dart';
import 'auth_service.dart';
import 'dashboard_chart_service.dart';
import '../models/daily_report_day.dart';
import '../models/vehicle_model.dart';
import '../utils/report_period.dart';

/// GPS server reports (`/api/generate_report`) + app-side fallbacks from history.
class GpswoxReportApiService {
  GpswoxReportApiService._();

  static final DateFormat _full = DateFormat('yyyy-MM-dd HH:mm:ss');

  /// Tries several GPSWOX body shapes until rows are returned.
  static Future<dynamic> fetchBestResponse({
    required int reportId,
    required int deviceId,
    required DateTime from,
    required DateTime to,
  }) async {
    final String server = await AuthService.server();
    final String? token = await AuthService.token();
    if (token == null || token.isEmpty) {
      return null;
    }

    final Uri uri = ApiConfig.generateReportUri(server);
    dynamic lastResponse;

    for (final Map<String, dynamic> body in _bodyVariants(
      token: token,
      reportId: reportId,
      deviceId: deviceId,
      from: from,
      to: to,
    )) {
      try {
        final dynamic response = await ApiClient.postFormRaw(
          uri,
          body: body,
          token: token,
        ).timeout(const Duration(seconds: 45));
        lastResponse = response;
        if (!ReportResponseParser.isEmptyReport(response)) {
          return response;
        }
      } catch (e, stack) {
        developer.log(
          'generate_report variant failed reportId=$reportId: $e',
          error: e,
          stackTrace: stack,
          name: 'GpswoxReportApiService',
        );
      }
    }

    return lastResponse;
  }

  static Future<List<Map<String, dynamic>>> fetchRows({
    required int reportId,
    required int deviceId,
    required DateTime from,
    required DateTime to,
  }) async {
    final dynamic response = await fetchBestResponse(
      reportId: reportId,
      deviceId: deviceId,
      from: from,
      to: to,
    );
    if (response == null) {
      return <Map<String, dynamic>>[];
    }
    return ReportResponseParser.rowsFromResponse(response);
  }

  /// Trip → summary → GPS history when daily report API returns nothing.
  static Future<List<DailyReportDay>> fetchDailyFallbackDays({
    required VehicleModel vehicle,
    required DateTime from,
    required DateTime to,
  }) async {
    if (vehicle.id == null) {
      return <DailyReportDay>[];
    }

    final int deviceId = vehicle.id!;
    final DateTime rangeFrom = ReportPeriod.startOfDay(from);
    final DateTime rangeTo = _normalizeRangeEnd(to);

    for (final int reportId in <int>[ReportIds.trip, ReportIds.summary]) {
      final List<Map<String, dynamic>> rows = await fetchRows(
        reportId: reportId,
        deviceId: deviceId,
        from: rangeFrom,
        to: rangeTo,
      );
      final List<DailyReportDay> days = _daysFromRows(
        rows,
        vehicle: vehicle,
        rangeFrom: rangeFrom,
      );
      if (days.any((DailyReportDay d) => d.hasMeaningfulData)) {
        return days;
      }
    }

    return DashboardChartService.loadDaysFromHistoryWeek(
      vehicle: vehicle,
      from: rangeFrom,
      to: rangeTo,
    );
  }

  static List<DailyReportDay> _daysFromRows(
    List<Map<String, dynamic>> rows, {
    required VehicleModel vehicle,
    required DateTime rangeFrom,
  }) {
    final List<DailyReportDay> days = <DailyReportDay>[];
    for (final Map<String, dynamic> raw in rows) {
      final Map<String, dynamic> item = _normalizeDailyRow(raw);
      final DateTime dayDate = _resolveDayDate(item, rangeFrom);
      days.add(
        DailyReportDay.fromApiMap(
          item,
          vehicle.name,
          dayDate: dayDate,
          fallbackLocation: vehicle.location,
        ),
      );
    }
    return days;
  }

  static DateTime _normalizeRangeEnd(DateTime value) {
    if (value.hour == 0 && value.minute == 0 && value.second == 0) {
      return ReportPeriod.endOfDay(value);
    }
    return value;
  }

  static DateTime _resolveDayDate(Map<String, dynamic> item, DateTime fallback) {
    final List<String> keys = <String>[
      'date',
      'day',
      'day_date',
      'date_from',
      'start_time',
      'time_from',
      'timestamp',
      'time',
      'from',
    ];
    for (final String key in keys) {
      final dynamic raw = item[key];
      if (raw == null) {
        continue;
      }
      final DateTime? parsed = _tryParseDate(raw.toString());
      if (parsed != null) {
        return ReportPeriod.startOfDay(parsed);
      }
    }
    return ReportPeriod.startOfDay(fallback);
  }

  static DateTime? _tryParseDate(String raw) {
    final String trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    const List<String> patterns = <String>[
      'yyyy-MM-dd HH:mm:ss',
      'dd-MM-yyyy HH:mm:ss',
      'dd-MM-yyyy hh:mm:ss a',
      'yyyy-MM-dd',
      'dd-MM-yyyy',
      'dd MMM yyyy hh:mm a',
    ];
    for (final String pattern in patterns) {
      try {
        return DateFormat(pattern).parse(trimmed);
      } catch (_) {}
    }
    return DateTime.tryParse(trimmed.replaceAll('/', '-'));
  }

  static Map<String, dynamic> _normalizeDailyRow(Map<String, dynamic> item) {
    final Map<String, dynamic> row = Map<String, dynamic>.from(item);

    void copyIfMissing(String target, List<String> sources) {
      if (row[target] != null && row[target].toString().trim().isNotEmpty) {
        return;
      }
      for (final String key in sources) {
        final dynamic v = row[key];
        if (v != null && v.toString().trim().isNotEmpty) {
          row[target] = v;
          return;
        }
      }
    }

    copyIfMissing('distance', <String>[
      'route_length',
      'total_distance',
      'distance_km',
      'route_km',
      'mileage',
      'km',
      'total',
    ]);
    copyIfMissing('running', <String>[
      'move_duration',
      'run_time',
      'drive_duration',
      'moving_duration',
      'moving',
    ]);
    copyIfMissing('engine_hours', <String>[
      'engine_hour',
      'work_time',
      'duration',
    ]);
    copyIfMissing('start_time', <String>['time', 'date', 'day', 'from']);
    copyIfMissing('end_time', <String>['time_to', 'end']);

    return row;
  }

  static List<Map<String, dynamic>> _bodyVariants({
    required String token,
    required int reportId,
    required int deviceId,
    required DateTime from,
    required DateTime to,
  }) {
    final String fromFull = _full.format(from);
    final String toFull = _full.format(to);
    String two(int n) => n.toString().padLeft(2, '0');
    String dateOnly(DateTime d) => '${d.year}-${two(d.month)}-${two(d.day)}';
    String timeOnly(DateTime d) => '${two(d.hour)}:${two(d.minute)}:${two(d.second)}';

    final Map<String, dynamic> base = <String, dynamic>{
      'user_api_hash': token,
      'report_id': reportId.toString(),
      'device_id': deviceId.toString(),
    };

    return <Map<String, dynamic>>[
      <String, dynamic>{...base, 'from': fromFull, 'to': toFull},
      <String, dynamic>{
        ...base,
        'from': fromFull,
        'to': toFull,
        'format': 'json',
      },
      <String, dynamic>{
        'user_api_hash': token,
        'report_id': reportId.toString(),
        'devices[]': deviceId.toString(),
        'from': fromFull,
        'to': toFull,
      },
      <String, dynamic>{
        ...base,
        'date_from': fromFull,
        'date_to': toFull,
      },
      <String, dynamic>{
        ...base,
        'from_date': dateOnly(from),
        'from_time': timeOnly(from),
        'to_date': dateOnly(to),
        'to_time': timeOnly(to),
      },
      <String, dynamic>{
        'user_api_hash': token,
        'type': reportId.toString(),
        'device_id': deviceId.toString(),
        'from': fromFull,
        'to': toFull,
      },
    ];
  }
}
