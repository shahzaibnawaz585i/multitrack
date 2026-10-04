import 'dart:async';

import 'package:intl/intl.dart';

import '../constants/report_ids.dart';
import '../models/daily_report_day.dart';
import '../models/vehicle_model.dart';
import '../utils/history_route_utils.dart';
import '../utils/report_period.dart';
import '../utils/report_response_parser.dart';
import 'gpswox_report_api_service.dart';
import 'history_service.dart';
import 'tracking_api_service.dart';
import 'vehicle_service.dart';

/// Aggregated stats for vehicle detail → Statistics tab (real server reports).
class VehiclePeriodStats {
  const VehiclePeriodStats({
    this.errorMessage,
    this.routeLengthKm = '0.00 km',
    this.moveDuration = '00:00:00',
    this.stopDuration = '00:00:00',
    this.idleDuration = '00:00:00',
    this.topSpeedKmph = '0.00 kmph',
    this.avgSpeedKmph = '0.00 kmph',
    this.overspeedCount = '0',
    this.stopCount = '0',
    this.avgFuelCons = '—',
    this.fuelCostPkr = 'PKR 0.00',
    this.engineWorkPkr = 'PKR 0.00',
    this.fuelConsumption = '—',
    this.odometer = '—',
    this.engineHours = '—',
  });

  final String? errorMessage;
  final String routeLengthKm;
  final String moveDuration;
  final String stopDuration;
  final String idleDuration;
  final String topSpeedKmph;
  final String avgSpeedKmph;
  final String overspeedCount;
  final String stopCount;
  final String avgFuelCons;
  final String fuelCostPkr;
  final String engineWorkPkr;
  final String fuelConsumption;
  final String odometer;
  final String engineHours;

  bool get hasError => errorMessage != null && errorMessage!.isNotEmpty;
}

/// History + statistics API for [VehicleDetailScreen] (cache + fast report path).
class VehicleDetailApiService {
  VehicleDetailApiService._();

  static final DateFormat _reportFormat = DateFormat('yyyy-MM-dd HH:mm:ss');
  static final Map<String, HistoryRoute> _historyCache = <String, HistoryRoute>{};
  static final Map<String, VehiclePeriodStats> _statsCache =
      <String, VehiclePeriodStats>{};
  static final Map<String, Future<VehiclePeriodStats>> _statsInflight =
      <String, Future<VehiclePeriodStats>>{};
  static final Map<String, Future<HistoryRoute>> _historyInflight =
      <String, Future<HistoryRoute>>{};
  static const int _maxCache = 24;
  static const Duration _reportWaitTimeout = Duration(seconds: 45);

  static String _key(int deviceId, DateTime from, DateTime to, String kind) {
    return '$kind|$deviceId|${from.millisecondsSinceEpoch}|${to.millisecondsSinceEpoch}';
  }

  static void _trimCache<T>(Map<String, T> cache) {
    while (cache.length > _maxCache) {
      cache.remove(cache.keys.first);
    }
  }

  static HistoryRoute? peekHistory({
    required int deviceId,
    required DateTime from,
    required DateTime to,
  }) {
    final String key = _key(deviceId, from, to, 'history');
    return _historyCache[key];
  }

  /// Preload today's route while user is on Track tab.
  static void warmHistoryCache(int deviceId) {
    final DateTime now = DateTime.now();
    final ({DateTime from, DateTime to}) range =
        ReportPeriod.historyRangeFor('today', now);
    unawaited(
      loadHistory(
        deviceId: deviceId,
        from: range.from,
        to: range.to,
        forceRefresh: false,
      ),
    );
  }

  /// Full GPS route for History map (`GET /api/get_history`, chunked).
  static Future<HistoryRoute> loadHistory({
    required int deviceId,
    required DateTime from,
    required DateTime to,
    bool forceRefresh = false,
  }) async {
    final String key = _key(deviceId, from, to, 'history');
    if (!forceRefresh && _historyCache.containsKey(key)) {
      final HistoryRoute cached = _historyCache[key]!;
      if (!cached.isEmpty) {
        return cached;
      }
      _historyCache.remove(key);
    }
    if (!forceRefresh) {
      final Future<HistoryRoute>? inFlight = _historyInflight[key];
      if (inFlight != null) {
        return inFlight;
      }
    }

    final bool singleWindow =
        to.difference(from) <= const Duration(days: 3);
    final Future<HistoryRoute> load = (singleWindow
            ? HistoryService.getRoute(
                deviceId: deviceId,
                from: from,
                to: to,
                forceRefresh: forceRefresh,
              )
            : HistoryService.loadRouteForRange(
                deviceId: deviceId,
                from: from,
                to: to,
                forceRefresh: forceRefresh,
              ))
        .then((HistoryRoute route) {
      if (!route.isEmpty) {
        _historyCache[key] = route;
        _trimCache(_historyCache);
        final String statsKey = _key(deviceId, from, to, 'stats');
        _statsCache[statsKey] = statsFromHistoryRoute(route);
        _trimCache(_statsCache);
      }
      return route;
    });

    if (!forceRefresh) {
      _historyInflight[key] = load;
    }
    try {
      return await load;
    } finally {
      _historyInflight.remove(key);
    }
  }

  /// Instant UI from memory (stats cache or loaded history for same range).
  static VehiclePeriodStats? peekStatistics({
    required int deviceId,
    required DateTime from,
    required DateTime to,
  }) {
    final String statsKey = _key(deviceId, from, to, 'stats');
    final VehiclePeriodStats? cached = _statsCache[statsKey];
    if (cached != null) {
      return cached;
    }
    final VehiclePeriodStats? fromDevice =
        statsFromCachedDevice(deviceId: deviceId, from: from, to: to);
    if (fromDevice != null) {
      return fromDevice;
    }
    final String historyKey = _key(deviceId, from, to, 'history');
    final HistoryRoute? route = _historyCache[historyKey];
    if (route != null && !route.isEmpty) {
      return statsFromHistoryRoute(route);
    }
    return null;
  }

  static const List<String> _statisticsWarmFilters = <String>[
    'Today',
    'Yesterday',
  ];

  /// Preload common ranges in background (Today / Yesterday / Week / Month).
  static void warmStatisticsCache(int deviceId) {
    final DateTime now = DateTime.now();
    for (final String filter in _statisticsWarmFilters) {
      final ({DateTime from, DateTime to}) range =
          ReportPeriod.statisticsRangeFor(filter, now);
      if (peekStatistics(
            deviceId: deviceId,
            from: range.from,
            to: range.to,
          ) !=
          null) {
        continue;
      }
      unawaited(
        loadStatistics(
          deviceId: deviceId,
          from: range.from,
          to: range.to,
        ),
      );
    }
  }

  /// Today only: instant stats from last [get_devices] payload (not Yesterday).
  static VehiclePeriodStats? statsFromCachedDevice({
    required int deviceId,
    required DateTime from,
    required DateTime to,
  }) {
    if (!_rangeWithinSingleDay(from, to)) {
      return null;
    }
    final DateTime now = DateTime.now();
    final ({DateTime from, DateTime to}) today =
        ReportPeriod.statisticsRangeFor('Today', now);
    if (from.millisecondsSinceEpoch != today.from.millisecondsSinceEpoch ||
        to.millisecondsSinceEpoch != today.to.millisecondsSinceEpoch) {
      return null;
    }
    final VehicleModel? device = VehicleService.findCachedDevice(deviceId);
    if (device == null) {
      return null;
    }
    return statsFromVehicleModel(device);
  }

  static VehiclePeriodStats statsFromVehicleModel(VehicleModel device) {
    String stripHrs(String value) =>
        value.replaceAll(RegExp(r'\s*Hrs\s*$', caseSensitive: false), '').trim();

    final String distance = device.distance.trim();
    final String routeKm = distance.toLowerCase().contains('km')
        ? distance
        : (distance.isEmpty ? '0.00 km' : '$distance km');

    return VehiclePeriodStats(
      routeLengthKm: routeKm,
      moveDuration: _normalizeDurationLabel(stripHrs(device.runningDuration)),
      stopDuration: _normalizeDurationLabel(stripHrs(device.stopDuration)),
      idleDuration: _normalizeDurationLabel(stripHrs(device.idleDuration)),
      topSpeedKmph: '${device.maxSpeed} kmph',
      avgSpeedKmph: '${device.avgSpeed} kmph',
      fuelCostPkr: device.fuelCost.contains('PKR')
          ? device.fuelCost
          : _formatPkr(device.fuelCost),
      fuelConsumption: device.fuelConsumption,
      odometer: device.odometer,
      engineHours: device.engineHours,
    );
  }

  static bool _rangeWithinSingleDay(DateTime from, DateTime to) {
    return from.year == to.year &&
        from.month == to.month &&
        from.day == to.day;
  }

  static String _normalizeDurationLabel(String value) {
    if (value.isEmpty || value == '—') {
      return '00:00:00';
    }
    if (value.contains(':')) {
      return value;
    }
    return value;
  }

  static VehiclePeriodStats statsFromHistoryRoute(HistoryRoute route) {
    final double km = route.distanceKm ??
        (route.points.length >= 2
            ? HistoryRouteUtils.totalDistanceKm(route.points)
            : 0);

    return VehiclePeriodStats(
      routeLengthKm: '${km.toStringAsFixed(2)} km',
      moveDuration: route.moveDurationLabel ?? '00:00:00',
      stopDuration: route.stopDurationLabel ?? '00:00:00',
      idleDuration: route.idleDurationLabel ?? '00:00:00',
      topSpeedKmph: '${(route.topSpeedKmph ?? 0).toStringAsFixed(2)} kmph',
      avgSpeedKmph: '${(route.avgSpeed ?? 0).toStringAsFixed(2)} kmph',
      stopCount: route.points.length > 1500
          ? '—'
          : '${HistoryRouteUtils.stopAnchors(points: route.points).length}',
      avgFuelCons: route.avgFuelMileage != null
          ? '${route.avgFuelMileage!.toStringAsFixed(2)} km/Ltr'
          : '—',
      fuelCostPkr: _formatPkr(route.fuelCost?.toString()),
      engineWorkPkr: _formatPkr(
        (route.engineWorkCost ?? route.fuelCost)?.toString(),
      ),
      fuelConsumption: route.fuelConsumption != null
          ? '${route.fuelConsumption!.toStringAsFixed(1)} Liter'
          : '—',
      odometer: route.odometerKm != null
          ? '${route.odometerKm!.toStringAsFixed(2)} km'
          : '—',
      engineHours: route.engineHours ?? '—',
      errorMessage: route.errorMessage,
    );
  }

  /// Statistics via `POST /api/generate_report` (parallel summary + daily, no per-day loop).
  static Future<VehiclePeriodStats> loadStatistics({
    required int deviceId,
    required DateTime from,
    required DateTime to,
    bool forceRefresh = false,
  }) async {
    final String key = _key(deviceId, from, to, 'stats');
    if (!forceRefresh) {
      final VehiclePeriodStats? instant =
          peekStatistics(deviceId: deviceId, from: from, to: to);
      if (instant != null) {
        _statsCache[key] = instant;
        return instant;
      }
      final VehiclePeriodStats? deviceQuick = statsFromCachedDevice(
        deviceId: deviceId,
        from: from,
        to: to,
      );
      if (deviceQuick != null) {
        _statsCache[key] = deviceQuick;
      }
      final Future<VehiclePeriodStats>? inFlight = _statsInflight[key];
      if (inFlight != null) {
        return inFlight;
      }
    }

    final Future<VehiclePeriodStats> load = _fetchStatisticsFromReports(
      deviceId: deviceId,
      from: from,
      to: to,
      cacheKey: key,
    );
    if (!forceRefresh) {
      _statsInflight[key] = load;
    }
    try {
      return await load;
    } finally {
      _statsInflight.remove(key);
    }
  }

  static Future<VehiclePeriodStats> _fetchStatisticsFromReports({
    required int deviceId,
    required DateTime from,
    required DateTime to,
    required String cacheKey,
  }) async {
    try {
      final String fromStr = _reportFormat.format(from);
      final String toStr = _reportFormat.format(to);

      final List<dynamic> parallel = await Future.wait<dynamic>(
        <Future<dynamic>>[
          TrackingApiService.generateReport(
            reportId: ReportIds.summary,
            deviceId: deviceId,
            from: fromStr,
            to: toStr,
          ),
          TrackingApiService.generateReport(
            reportId: ReportIds.daily,
            deviceId: deviceId,
            from: fromStr,
            to: toStr,
          ),
          TrackingApiService.generateReport(
            reportId: ReportIds.trip,
            deviceId: deviceId,
            from: fromStr,
            to: toStr,
          ),
        ],
      ).timeout(_reportWaitTimeout);

      final dynamic summary = parallel[0];
      final dynamic daily = parallel[1];
      final dynamic trip = parallel[2];

      VehiclePeriodStats? parsed = _statsFromReportMap(
        ReportResponseParser.asReportMap(summary),
      );
      if (parsed != null && !_isEmptyStats(parsed)) {
        _statsCache[cacheKey] = parsed;
        _trimCache(_statsCache);
        return parsed;
      }

      parsed = _statsFromReportMap(ReportResponseParser.asReportMap(trip));
      if (parsed != null && !_isEmptyStats(parsed)) {
        _statsCache[cacheKey] = parsed;
        _trimCache(_statsCache);
        return parsed;
      }

      final List<DailyReportDay> days =
          _dailyDaysFromSingleResponse(daily, deviceId: deviceId);
      if (days.isNotEmpty) {
        parsed = _statsFromDailyDays(
          days,
          ReportResponseParser.asReportMap(summary),
        );
        _statsCache[cacheKey] = parsed;
        _trimCache(_statsCache);
        return parsed;
      }

      if (parsed != null) {
        _statsCache[cacheKey] = parsed;
        _trimCache(_statsCache);
        return parsed;
      }

      final VehiclePeriodStats? deviceFallback = statsFromCachedDevice(
        deviceId: deviceId,
        from: from,
        to: to,
      );
      if (deviceFallback != null) {
        _statsCache[cacheKey] = deviceFallback;
        _trimCache(_statsCache);
        return deviceFallback;
      }

      final VehicleModel? vehicle =
          VehicleService.findCachedDevice(deviceId);
      if (vehicle != null) {
        final List<DailyReportDay> fallbackDays =
            await GpswoxReportApiService.fetchDailyFallbackDays(
          vehicle: vehicle,
          from: from,
          to: to,
        );
        if (fallbackDays.isNotEmpty) {
          final VehiclePeriodStats fromDays = _statsFromDailyDays(
            fallbackDays,
            ReportResponseParser.asReportMap(summary),
          );
          if (!_isEmptyStats(fromDays)) {
            _statsCache[cacheKey] = fromDays;
            _trimCache(_statsCache);
            return fromDays;
          }
        }
      }

      final HistoryRoute historyRoute = await loadHistory(
        deviceId: deviceId,
        from: from,
        to: to,
        forceRefresh: false,
      );
      if (!historyRoute.isEmpty) {
        final VehiclePeriodStats fromHistory =
            statsFromHistoryRoute(historyRoute);
        _statsCache[cacheKey] = fromHistory;
        _trimCache(_statsCache);
        return fromHistory;
      }

      final VehiclePeriodStats empty = VehiclePeriodStats(
        errorMessage: 'No statistics for this period',
      );
      _statsCache[cacheKey] = empty;
      return empty;
    } on TimeoutException {
      final VehiclePeriodStats? fallback = peekStatistics(
        deviceId: deviceId,
        from: from,
        to: to,
      );
      if (fallback != null && !fallback.hasError) {
        return fallback;
      }
      final VehiclePeriodStats? deviceFallback = statsFromCachedDevice(
        deviceId: deviceId,
        from: from,
        to: to,
      );
      if (deviceFallback != null) {
        return deviceFallback;
      }
      return VehiclePeriodStats(
        errorMessage: 'Statistics request timed out. Try again.',
      );
    } catch (e) {
      return VehiclePeriodStats(errorMessage: e.toString());
    }
  }

  static List<DailyReportDay> _dailyDaysFromSingleResponse(
    dynamic response, {
    required int deviceId,
  }) {
    if (ReportResponseParser.isEmptyReport(response)) {
      return <DailyReportDay>[];
    }
    final List<Map<String, dynamic>> items =
        ReportResponseParser.listFromDynamic(response);
    if (items.isEmpty) {
      return <DailyReportDay>[];
    }
    final List<DailyReportDay> days = <DailyReportDay>[];
    for (final Map<String, dynamic> item in items) {
      days.add(
        DailyReportDay.fromApiMap(
          item,
          'Vehicle',
          dayDate: DateTime.now(),
        ),
      );
    }
    return days.where((DailyReportDay d) => d.hasMeaningfulData).toList();
  }

  static bool _isEmptyStats(VehiclePeriodStats s) {
    return s.routeLengthKm.startsWith('0.00') &&
        s.moveDuration == '00:00:00' &&
        s.topSpeedKmph.startsWith('0.00');
  }

  static VehiclePeriodStats? _statsFromReportMap(Map<String, dynamic>? response) {
    if (response == null || response.isEmpty) {
      return null;
    }
    final List<Map<String, dynamic>> items =
        ReportResponseParser.extractItems(response);
    final Map<String, dynamic> root = items.isNotEmpty ? items.first : response;

    String pick(List<String> keys, {String fallback = '—'}) {
      for (final String k in keys) {
        final dynamic v = root[k];
        if (v != null && v.toString().trim().isNotEmpty) {
          return v.toString().trim();
        }
      }
      final String deep = ReportResponseParser.summaryValue(response, keys);
      return deep == '-' ? fallback : deep;
    }

    final String distanceRaw = pick(
      <String>['distance', 'total_distance', 'distance_sum', 'route_length'],
      fallback: '0',
    );
    final double? distanceKm = double.tryParse(
      distanceRaw.replaceAll(RegExp(r'[^0-9.]'), ''),
    );

    final String fuelCostRaw = pick(
      <String>['fuel_cost', 'cost', 'fuel_price'],
      fallback: '0',
    );
    final String engineWorkRaw = pick(
      <String>['engine_work', 'engine_work_cost'],
      fallback: fuelCostRaw,
    );

    return VehiclePeriodStats(
      routeLengthKm: distanceKm != null
          ? '${distanceKm.toStringAsFixed(2)} km'
          : _formatDistanceLabel(distanceRaw),
      moveDuration: _normalizeDuration(
        pick(
          <String>['move_duration', 'running', 'run_time', 'drive_duration'],
          fallback: '00:00:00',
        ),
      ),
      stopDuration: _normalizeDuration(
        pick(
          <String>['stop_duration', 'stop_time', 'stops'],
          fallback: '00:00:00',
        ),
      ),
      idleDuration: _normalizeDuration(
        pick(
          <String>['idle_duration', 'idle', 'idle_time'],
          fallback: '00:00:00',
        ),
      ),
      topSpeedKmph: _formatSpeed(
        pick(
          <String>['top_speed', 'max_speed', 'speed_max'],
          fallback: '0',
        ),
      ),
      avgSpeedKmph: _formatSpeed(
        pick(
          <String>['avg_speed', 'average_speed', 'speed_avg'],
          fallback: '0',
        ),
      ),
      overspeedCount: pick(
        <String>['overspeed_count', 'overspeeds', 'overspeed'],
        fallback: '0',
      ),
      stopCount: pick(
        <String>['stop_count', 'stops_count', 'stops'],
        fallback: '0',
      ),
      avgFuelCons: _formatAvgFuel(
        pick(
          <String>['fuel_mileage', 'avg_fuel', 'average_fuel_consumption'],
        ),
      ),
      fuelCostPkr: _formatPkr(fuelCostRaw),
      engineWorkPkr: _formatPkr(engineWorkRaw),
      fuelConsumption: _formatLiters(
        pick(
          <String>['fuel_consumption', 'fuel_used', 'fuel'],
          fallback: '—',
        ),
      ),
      odometer: _formatOdometer(
        pick(
          <String>['odometer', 'odometer_value', 'end_odometer'],
        ),
      ),
      engineHours: pick(
        <String>['engine_hours', 'engine_hour', 'hours', 'work_time'],
      ),
    );
  }

  static VehiclePeriodStats _statsFromDailyDays(
    List<DailyReportDay> days,
    Map<String, dynamic>? summaryExtra,
  ) {
    double distanceKm = 0;
    Duration move = Duration.zero;
    Duration stop = Duration.zero;
    Duration idle = Duration.zero;
    double maxSpeed = 0;
    double speedSum = 0;
    int speedSamples = 0;
    String engineHours = '—';
    String odometer = '—';

    for (final DailyReportDay day in days) {
      distanceKm += _parseKm(day.distanceLabel);
      move += _parseDuration(day.runningTime);
      stop += _parseDuration(day.stopTime);
      idle += _parseDuration(day.idleTime);
      maxSpeed = mathMax(maxSpeed, _parseSpeed(day.maxSpeedLabel));
      final double avg = _parseSpeed(day.avgSpeedLabel);
      if (avg > 0) {
        speedSum += avg;
        speedSamples++;
      }
      if (day.engineHours != '-') {
        engineHours = day.engineHours;
      }
      if (day.endOdometer != '-') {
        odometer = day.endOdometer.contains('km')
            ? day.endOdometer
            : '${day.endOdometer} km';
      }
    }

    final VehiclePeriodStats? summaryPart = _statsFromReportMap(summaryExtra);

    return VehiclePeriodStats(
      routeLengthKm: '${distanceKm.toStringAsFixed(2)} km',
      moveDuration: _formatDuration(move),
      stopDuration: _formatDuration(stop),
      idleDuration: _formatDuration(idle),
      topSpeedKmph: '${maxSpeed.toStringAsFixed(2)} kmph',
      avgSpeedKmph: speedSamples > 0
          ? '${(speedSum / speedSamples).toStringAsFixed(2)} kmph'
          : (summaryPart?.avgSpeedKmph ?? '0.00 kmph'),
      overspeedCount: summaryPart?.overspeedCount ?? '0',
      stopCount: summaryPart?.stopCount ?? '0',
      avgFuelCons: summaryPart?.avgFuelCons ?? '—',
      fuelCostPkr: summaryPart?.fuelCostPkr ?? 'PKR 0.00',
      engineWorkPkr: summaryPart?.engineWorkPkr ?? summaryPart?.fuelCostPkr ?? 'PKR 0.00',
      fuelConsumption: summaryPart?.fuelConsumption ?? '—',
      odometer: odometer,
      engineHours: engineHours,
    );
  }

  static double mathMax(double a, double b) => a > b ? a : b;

  static String _formatPkr(String? raw) {
    if (raw == null || raw == '—') {
      return 'PKR 0.00';
    }
    final double? v = double.tryParse(raw.replaceAll(RegExp(r'[^0-9.]'), ''));
    if (v == null) {
      return raw.contains('PKR') ? raw : 'PKR $raw';
    }
    return 'PKR ${v.toStringAsFixed(2)}';
  }

  static String _formatSpeed(String raw) {
    final double? v = double.tryParse(raw.replaceAll(RegExp(r'[^0-9.]'), ''));
    if (v == null) {
      return raw.contains('kmph') ? raw : '$raw kmph';
    }
    return '${v.toStringAsFixed(2)} kmph';
  }

  static String _formatDistanceLabel(String raw) {
    if (raw.contains('km')) {
      return raw;
    }
    final double? v = double.tryParse(raw.replaceAll(RegExp(r'[^0-9.]'), ''));
    return v != null ? '${v.toStringAsFixed(2)} km' : raw;
  }

  static String _formatLiters(String raw) {
    if (raw == '—') {
      return raw;
    }
    final double? v = double.tryParse(raw.replaceAll(RegExp(r'[^0-9.]'), ''));
    return v != null ? '${v.toStringAsFixed(1)} Liter' : raw;
  }

  static String _formatOdometer(String raw) {
    if (raw == '—') {
      return raw;
    }
    return raw.contains('km') ? raw : '$raw km';
  }

  static String _formatAvgFuel(String raw) {
    if (raw == '—') {
      return raw;
    }
    return raw.contains('km') || raw.contains('Ltr') ? raw : '$raw km/Ltr';
  }

  static String _normalizeDuration(String raw) {
    if (raw == '—' || raw.isEmpty) {
      return '00:00:00';
    }
    if (RegExp(r'\d:\d').hasMatch(raw)) {
      return raw;
    }
    return raw;
  }

  static double _parseKm(String label) {
    final double? v = double.tryParse(
      label.replaceAll(RegExp(r'[^0-9.]'), ''),
    );
    return v ?? 0;
  }

  static double _parseSpeed(String label) {
    return _parseKm(label);
  }

  static Duration _parseDuration(String label) {
    if (label == '-' || label.isEmpty) {
      return Duration.zero;
    }
    final List<String> parts = label.split(':');
    if (parts.length == 3) {
      final int? h = int.tryParse(parts[0]);
      final int? m = int.tryParse(parts[1]);
      final int? s = int.tryParse(parts[2].split('.').first);
      if (h != null && m != null && s != null) {
        return Duration(hours: h, minutes: m, seconds: s);
      }
    }
    if (parts.length == 2) {
      final int? m = int.tryParse(parts[0]);
      final int? s = int.tryParse(parts[1]);
      if (m != null && s != null) {
        return Duration(minutes: m, seconds: s);
      }
    }
    return Duration.zero;
  }

  static String _formatDuration(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.inHours)}:${two(d.inMinutes.remainder(60))}:${two(d.inSeconds.remainder(60))}';
  }
}
