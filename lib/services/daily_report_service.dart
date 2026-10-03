import 'dart:async';
import 'dart:math' as math;

import 'package:intl/intl.dart';

import '../constants/report_ids.dart';
import '../models/daily_report_day.dart';
import '../models/vehicle_model.dart';
import '../utils/report_period.dart';
import '../utils/report_response_parser.dart';
import 'dashboard_chart_service.dart';
import 'gpswox_report_api_service.dart';
import 'tracking_api_service.dart';
import 'vehicle_service.dart';

class _ChartCacheEntry {
  _ChartCacheEntry(this.days, this.at);

  final List<DailyReportDay> days;
  final DateTime at;
}

class DailyReportService {
  DailyReportService._();

  static final DateFormat _apiFormat = DateFormat('yyyy-MM-dd HH:mm:ss');
  static final DateFormat _dayKeyFormat = DateFormat('yyyy-MM-dd');
  static const Duration _fastChartCacheTtl = Duration(minutes: 5);
  static final Map<String, _ChartCacheEntry> _fastChartCache =
      <String, _ChartCacheEntry>{};

  static String _fastChartCacheKey(int deviceId, DateTime rangeFrom) {
    return '$deviceId|${_dayKeyFormat.format(ReportPeriod.startOfDay(rangeFrom))}|fast';
  }

  static List<DailyReportDay>? peekFastChartCache({
    required int? deviceId,
    required DateTime from,
  }) {
    if (deviceId == null) {
      return null;
    }
    final String key = _fastChartCacheKey(
      deviceId,
      ReportPeriod.startOfDay(from),
    );
    final _ChartCacheEntry? hit = _fastChartCache[key];
    if (hit == null) {
      return null;
    }
    if (DateTime.now().difference(hit.at) > _fastChartCacheTtl) {
      _fastChartCache.remove(key);
      return null;
    }
    return hit.days;
  }

  /// One daily-report API call (~1s). No per-day / trip / history loops.
  static Future<List<DailyReportDay>> loadDaysFastForCharts({
    required VehicleModel vehicle,
    required DateTime from,
    required DateTime to,
  }) async {
    if (vehicle.id == null) {
      return <DailyReportDay>[];
    }

    final DateTime rangeFrom = ReportPeriod.startOfDay(from);
    final DateTime rangeTo = _normalizeRangeEnd(to);
    final String cacheKey = _fastChartCacheKey(vehicle.id!, rangeFrom);
    final _ChartCacheEntry? cached = _fastChartCache[cacheKey];
    if (cached != null &&
        DateTime.now().difference(cached.at) <= _fastChartCacheTtl) {
      return cached.days;
    }

    try {
      final dynamic response = await GpswoxReportApiService.fetchBestResponse(
        reportId: ReportIds.daily,
        deviceId: vehicle.id!,
        from: rangeFrom,
        to: rangeTo,
      ).timeout(const Duration(milliseconds: 4000));

      List<DailyReportDay> days = _parseResponse(
        response,
        vehicle: vehicle,
        rangeFrom: rangeFrom,
        rangeTo: rangeTo,
      );
      days = days.where((DailyReportDay d) => d.hasMeaningfulData).toList();
      if (days.isNotEmpty) {
        _fastChartCache[cacheKey] = _ChartCacheEntry(
          List<DailyReportDay>.from(days),
          DateTime.now(),
        );
        _trimFastChartCache();
      }
      return days;
    } on TimeoutException {
      return peekFastChartCache(deviceId: vehicle.id, from: from) ??
          <DailyReportDay>[];
    } catch (_) {
      return <DailyReportDay>[];
    }
  }

  static void _trimFastChartCache() {
    if (_fastChartCache.length <= 24) {
      return;
    }
    final List<MapEntry<String, _ChartCacheEntry>> entries =
        _fastChartCache.entries.toList()
          ..sort(
            (MapEntry<String, _ChartCacheEntry> a,
                    MapEntry<String, _ChartCacheEntry> b) =>
                a.value.at.compareTo(b.value.at),
          );
    while (_fastChartCache.length > 24) {
      _fastChartCache.remove(entries.removeAt(0).key);
    }
  }

  /// Dashboard charts: daily report, then per-day, then trip rows grouped by day.
  static Future<List<DailyReportDay>> loadDaysForCharts({
    required VehicleModel vehicle,
    required DateTime from,
    required DateTime to,
  }) async {
    List<DailyReportDay> days = await loadDays(
      vehicle: vehicle,
      from: from,
      to: to,
    );

    if (!_hasChartMetrics(days)) {
      days = await DashboardChartService.loadDaysFromHistoryWeek(
        vehicle: vehicle,
        from: from,
        to: to,
      );
    }

    if (!_hasChartMetrics(days)) {
      final DateTime rangeFrom = ReportPeriod.startOfDay(from);
      final DateTime rangeTo = _normalizeRangeEnd(to);
      days = await _loadPerDay(
        vehicle: vehicle,
        rangeFrom: rangeFrom,
        rangeTo: rangeTo,
      );
      days.sort(
        (DailyReportDay a, DailyReportDay b) =>
            b.dayDate.compareTo(a.dayDate),
      );
      days = days.where((DailyReportDay d) => d.hasMeaningfulData).toList();
    }

    if (!_hasChartMetrics(days)) {
      days = await _loadChartDaysFromTripReport(
        vehicle: vehicle,
        from: from,
        to: to,
      );
    }

    if (days.isNotEmpty && vehicle.id != null) {
      final String cacheKey = _fastChartCacheKey(
        vehicle.id!,
        ReportPeriod.startOfDay(from),
      );
      _fastChartCache[cacheKey] = _ChartCacheEntry(
        List<DailyReportDay>.from(days),
        DateTime.now(),
      );
      _trimFastChartCache();
    }

    return days;
  }

  static bool _hasChartMetrics(List<DailyReportDay> days) {
    for (final DailyReportDay day in days) {
      if (_metricKm(day.distanceLabel) > 0) {
        return true;
      }
      if (_metricHours(day.engineHours) > 0 ||
          _metricHours(day.runningTime) > 0) {
        return true;
      }
    }
    return false;
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

  /// Daily rows for every device (matches multi-vehicle report list UI).
  static Future<List<DailyReportDay>> loadDaysForFleet({
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

    if (withIds.isEmpty) {
      return <DailyReportDay>[];
    }

    const int maxConcurrent = 8;
    final List<DailyReportDay> merged = <DailyReportDay>[];

    for (int i = 0; i < withIds.length; i += maxConcurrent) {
      final int end = math.min(i + maxConcurrent, withIds.length);
      final List<VehicleModel> batch = withIds.sublist(i, end);
      final List<List<DailyReportDay>> chunks = await Future.wait(
        batch.map(
          (VehicleModel vehicle) => loadDays(
            vehicle: vehicle,
            from: from,
            to: to,
          ),
        ),
      );
      for (final List<DailyReportDay> chunk in chunks) {
        merged.addAll(chunk);
      }
    }

    merged.sort(
      (DailyReportDay a, DailyReportDay b) => b.dayDate.compareTo(a.dayDate),
    );
    return merged;
  }

  static Future<List<DailyReportDay>> loadDays({
    required VehicleModel vehicle,
    required DateTime from,
    required DateTime to,
  }) async {
    final VehicleModel resolved = await _resolveVehicle(vehicle);
    if (resolved.id == null) {
      return <DailyReportDay>[];
    }

    final DateTime rangeFrom = ReportPeriod.startOfDay(from);
    final DateTime rangeTo = _normalizeRangeEnd(to);
    final int daySpan = ReportPeriod.startOfDay(rangeTo)
        .difference(ReportPeriod.startOfDay(rangeFrom))
        .inDays;

    final dynamic response = await GpswoxReportApiService.fetchBestResponse(
      reportId: ReportIds.daily,
      deviceId: resolved.id!,
      from: rangeFrom,
      to: rangeTo,
    );

    List<DailyReportDay> days = _parseResponse(
      response,
      vehicle: resolved,
      rangeFrom: rangeFrom,
      rangeTo: rangeTo,
    );

    final bool needsPerDayFetch =
        daySpan > 0 && days.length <= 1 && !_dayCoversFullRange(days, rangeFrom, rangeTo);

    if (needsPerDayFetch) {
      days = await _loadPerDay(
        vehicle: resolved,
        rangeFrom: rangeFrom,
        rangeTo: rangeTo,
      );
    }

    if (days.where((DailyReportDay d) => d.hasMeaningfulData).isEmpty) {
      days = await GpswoxReportApiService.fetchDailyFallbackDays(
        vehicle: resolved,
        from: rangeFrom,
        to: rangeTo,
      );
    }

    days.sort(
      (DailyReportDay a, DailyReportDay b) => b.dayDate.compareTo(a.dayDate),
    );

    return days.where((DailyReportDay d) => d.hasMeaningfulData).toList();
  }

  static DateTime _normalizeRangeEnd(DateTime value) {
    if (value.hour == 0 && value.minute == 0 && value.second == 0) {
      return ReportPeriod.endOfDay(value);
    }
    return value;
  }

  static bool _dayCoversFullRange(
    List<DailyReportDay> days,
    DateTime from,
    DateTime to,
  ) {
    if (days.isEmpty) {
      return false;
    }
    if (days.length > 1) {
      return true;
    }
    final DateTime only = ReportPeriod.startOfDay(days.first.dayDate);
    final DateTime fromDay = ReportPeriod.startOfDay(from);
    final DateTime toDay = ReportPeriod.startOfDay(to);
    return only == fromDay && fromDay == toDay;
  }

  static List<DailyReportDay> _parseResponse(
    dynamic response, {
    required VehicleModel vehicle,
    required DateTime rangeFrom,
    required DateTime rangeTo,
  }) {
    final List<Map<String, dynamic>> items = _rowsFromResponse(response);

    final List<DailyReportDay> days = <DailyReportDay>[];
    for (final Map<String, dynamic> item in items) {
      final Map<String, dynamic> row = _normalizeDailyRow(item);
      final DateTime dayDate = _resolveDayDate(row, rangeFrom);
      days.add(
        DailyReportDay.fromApiMap(
          row,
          vehicle.name,
          dayDate: dayDate,
          fallbackLocation: vehicle.location,
        ),
      );
    }
    return days;
  }

  /// Maps HTML table aliases and GPSWOX column labels to [DailyReportDay] keys.
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
    final List<String> patterns = <String>[
      'yyyy-MM-dd HH:mm:ss',
      'dd-MM-yyyy HH:mm:ss',
      'dd-MM-yyyy hh:mm:ss a',
      'yyyy-MM-dd',
      'dd-MM-yyyy',
      'dd MMM yyyy hh:mm a',
      'MMM dd yyyy hh:mm a',
    ];
    for (final String pattern in patterns) {
      try {
        return DateFormat(pattern).parse(trimmed);
      } catch (_) {}
    }
    return DateTime.tryParse(trimmed);
  }

  static Future<List<DailyReportDay>> _loadPerDay({
    required VehicleModel vehicle,
    required DateTime rangeFrom,
    required DateTime rangeTo,
  }) async {
    final List<DateTime> dayStarts = <DateTime>[];
    DateTime cursor = ReportPeriod.startOfDay(rangeFrom);
    final DateTime lastDay = ReportPeriod.startOfDay(rangeTo);

    while (!cursor.isAfter(lastDay)) {
      dayStarts.add(cursor);
      cursor = cursor.add(const Duration(days: 1));
    }

    final List<List<DailyReportDay>> batches = await Future.wait(
      dayStarts.map(
        (DateTime dayStart) => _loadSingleDay(vehicle: vehicle, dayStart: dayStart),
      ),
    );

    return batches.expand((List<DailyReportDay> batch) => batch).toList();
  }

  static Future<List<DailyReportDay>> _loadSingleDay({
    required VehicleModel vehicle,
    required DateTime dayStart,
  }) async {
    final DateTime dayEnd = ReportPeriod.endOfDay(dayStart);

    final dynamic response = await GpswoxReportApiService.fetchBestResponse(
      reportId: ReportIds.daily,
      deviceId: vehicle.id!,
      from: dayStart,
      to: dayEnd,
    );

    final List<DailyReportDay> parsed = _parseResponse(
      response,
      vehicle: vehicle,
      rangeFrom: dayStart,
      rangeTo: dayEnd,
    );

    if (parsed.isEmpty) {
      final DailyReportDay emptyDay = DailyReportDay.fromApiMap(
        <String, dynamic>{},
        vehicle.name,
        dayDate: dayStart,
        fallbackLocation: vehicle.location,
      );
      if (emptyDay.hasMeaningfulData) {
        return <DailyReportDay>[emptyDay];
      }
      return <DailyReportDay>[];
    }

    return parsed
        .map(
          (DailyReportDay day) => DailyReportDay(
            dayDate: dayStart,
            vehicleName: day.vehicleName,
            distanceLabel: day.distanceLabel,
            startTimeLabel: day.startTimeLabel,
            endTimeLabel: day.endTimeLabel,
            engineHours: day.engineHours,
            runningTime: day.runningTime,
            stopTime: day.stopTime,
            idleTime: day.idleTime,
            startLocation: day.startLocation,
            endLocation: day.endLocation,
            startOdometer: day.startOdometer,
            endOdometer: day.endOdometer,
            avgSpeedLabel: day.avgSpeedLabel,
            maxSpeedLabel: day.maxSpeedLabel,
          ),
        )
        .toList();
  }

  static List<Map<String, dynamic>> _rowsFromResponse(dynamic response) {
    return ReportResponseParser.rowsFromResponse(response);
  }

  static Future<List<DailyReportDay>> _loadChartDaysFromTripReport({
    required VehicleModel vehicle,
    required DateTime from,
    required DateTime to,
  }) async {
    if (vehicle.id == null) {
      return <DailyReportDay>[];
    }

    final DateTime rangeFrom = ReportPeriod.startOfDay(from);
    final DateTime rangeTo = _normalizeRangeEnd(to);

    final dynamic response = await TrackingApiService.generateReport(
      reportId: ReportIds.trip,
      deviceId: vehicle.id!,
      from: _apiFormat.format(rangeFrom),
      to: _apiFormat.format(rangeTo),
    );

    final List<Map<String, dynamic>> rows = _rowsFromResponse(response);
    if (rows.isEmpty) {
      return <DailyReportDay>[];
    }

    final Map<String, _ChartDayBucket> buckets = <String, _ChartDayBucket>{};

    for (final Map<String, dynamic> row in rows) {
      final DateTime dayDate = _resolveDayDate(row, rangeFrom);
      if (dayDate.isBefore(rangeFrom) || dayDate.isAfter(rangeTo)) {
        continue;
      }
      final String key = _dayKeyFormat.format(ReportPeriod.startOfDay(dayDate));
      final _ChartDayBucket bucket =
          buckets.putIfAbsent(key, () => _ChartDayBucket(dayDate: dayDate));

      bucket.distanceKm += _rowDistanceKm(row);
      bucket.runHours += _rowDurationHours(row);
    }

    final List<DailyReportDay> days = <DailyReportDay>[];
    for (final _ChartDayBucket bucket in buckets.values) {
      if (bucket.distanceKm <= 0 && bucket.runHours <= 0) {
        continue;
      }
      days.add(
        DailyReportDay(
          dayDate: bucket.dayDate,
          vehicleName: vehicle.name,
          distanceLabel: '${bucket.distanceKm.toStringAsFixed(2)} km',
          startTimeLabel: '-',
          endTimeLabel: '-',
          engineHours: _formatHoursLabel(bucket.runHours),
          runningTime: _formatHoursLabel(bucket.runHours),
          stopTime: '-',
          idleTime: '-',
          startLocation: vehicle.location,
          endLocation: vehicle.location,
          startOdometer: '-',
          endOdometer: '-',
          avgSpeedLabel: 'Avg. -',
          maxSpeedLabel: 'Max. -',
        ),
      );
    }

    days.sort(
      (DailyReportDay a, DailyReportDay b) => b.dayDate.compareTo(a.dayDate),
    );
    return days;
  }

  static double _rowDistanceKm(Map<String, dynamic> row) {
    final String raw = ReportResponseParser.summaryValue(
      row,
      <String>[
        'distance',
        'total_distance',
        'distance_sum',
        'route_length',
        'distance_km',
      ],
      fallback: '',
    );
    return _metricKm(raw);
  }

  static double _rowDurationHours(Map<String, dynamic> row) {
    final String raw = ReportResponseParser.summaryValue(
      row,
      <String>[
        'duration',
        'drive_duration',
        'move_duration',
        'running',
        'run_time',
        'engine_hours',
      ],
      fallback: '',
    );
    return _metricHours(raw);
  }

  static double _metricKm(dynamic raw) {
    if (raw == null) {
      return 0.0;
    }
    if (raw is num) {
      return raw.toDouble();
    }
    final String s = raw.toString().trim().toLowerCase();
    if (s.isEmpty || s == 'null' || s == '-') {
      return 0.0;
    }
    final RegExp reg = RegExp(r'([0-9]+(?:\.[0-9]+)?)');
    final Match? match = reg.firstMatch(s);
    if (match == null) {
      return 0.0;
    }
    final double val = double.tryParse(match.group(1) ?? '') ?? 0.0;
    if (s.contains('m') && !s.contains('km') && val > 1000) {
      return val / 1000.0;
    }
    return val;
  }

  static double _metricHours(dynamic raw) {
    if (raw == null) {
      return 0.0;
    }
    if (raw is num) {
      return raw.toDouble();
    }
    final String s = raw.toString().trim().toLowerCase();
    if (s.isEmpty ||
        s == 'null' ||
        s == '-' ||
        s == '00:00' ||
        s == '00:00:00') {
      return 0.0;
    }

    if (s.contains('h') || s.contains('m') || s.contains('d')) {
      double totalHours = 0.0;
      final RegExp dMatch = RegExp(r'(\d+)\s*d');
      final RegExp hMatch = RegExp(r'(\d+)\s*h');
      final RegExp mMatch = RegExp(r'(\d+)\s*m');
      final Match? d = dMatch.firstMatch(s);
      final Match? h = hMatch.firstMatch(s);
      final Match? m = mMatch.firstMatch(s);
      if (d != null) {
        totalHours += (double.tryParse(d.group(1)!) ?? 0) * 24;
      }
      if (h != null) {
        totalHours += double.tryParse(h.group(1)!) ?? 0;
      }
      if (m != null) {
        totalHours += (double.tryParse(m.group(1)!) ?? 0) / 60.0;
      }
      if (totalHours > 0) {
        return totalHours;
      }
    }

    if (s.contains(':')) {
      final List<String> parts = s.replaceAll(RegExp(r'[^\d:]'), '').split(':');
      if (parts.length >= 2) {
        final double hrs = double.tryParse(parts[0]) ?? 0.0;
        final double mins = double.tryParse(parts[1]) ?? 0.0;
        final double secs = parts.length >= 3
            ? (double.tryParse(parts[2]) ?? 0.0)
            : 0.0;
        return hrs + (mins / 60.0) + (secs / 3600.0);
      }
    }

    final RegExp reg = RegExp(r'([0-9]+(?:\.[0-9]+)?)');
    final Match? match = reg.firstMatch(s);
    if (match != null) {
      return double.tryParse(match.group(1) ?? '') ?? 0.0;
    }
    return 0.0;
  }

  static String _formatHoursLabel(double hours) {
    if (hours <= 0) {
      return '-';
    }
    final int h = hours.floor();
    final int m = ((hours - h) * 60).round();
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }
}

class _ChartDayBucket {
  _ChartDayBucket({required this.dayDate});

  final DateTime dayDate;
  double distanceKm = 0;
  double runHours = 0;
}
