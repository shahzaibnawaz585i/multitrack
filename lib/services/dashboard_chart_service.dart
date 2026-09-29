import 'package:intl/intl.dart';

import '../models/daily_report_day.dart';
import '../models/vehicle_model.dart';
import '../utils/history_route_utils.dart';
import '../utils/report_period.dart';
import 'history_service.dart';

/// Builds dashboard chart series from GPS history (real track data).
class DashboardChartService {
  DashboardChartService._();

  static final DateFormat _dayKey = DateFormat('yyyy-MM-dd');

  static Future<List<DailyReportDay>> loadDaysFromHistoryWeek({
    required VehicleModel vehicle,
    required DateTime from,
    required DateTime to,
  }) async {
    if (vehicle.id == null) {
      return <DailyReportDay>[];
    }

    final DateTime rangeFrom = ReportPeriod.startOfDay(from);
    final DateTime rangeTo = ReportPeriod.endOfDay(to);

    try {
      final HistoryRoute route = await HistoryService.loadRouteForRange(
        deviceId: vehicle.id!,
        from: rangeFrom,
        to: rangeTo,
        forceRefresh: false,
      );

      return _daysFromRoute(
        route: route,
        vehicle: vehicle,
        rangeFrom: rangeFrom,
        rangeTo: rangeTo,
      );
    } catch (_) {
      return <DailyReportDay>[];
    }
  }

  static List<DailyReportDay> _daysFromRoute({
    required HistoryRoute route,
    required VehicleModel vehicle,
    required DateTime rangeFrom,
    required DateTime rangeTo,
  }) {
    final List<DailyReportDay> days = <DailyReportDay>[];
    final DateTime lastDay = ReportPeriod.startOfDay(rangeTo);

    final Map<String, List<HistoryPoint>> byDay =
        <String, List<HistoryPoint>>{};
    for (final HistoryPoint point in route.points) {
      final DateTime? time = point.time;
      if (time == null) {
        continue;
      }
      final String key = _dayKey.format(ReportPeriod.startOfDay(time));
      byDay.putIfAbsent(key, () => <HistoryPoint>[]).add(point);
    }

    DateTime cursor = rangeFrom;
    while (!cursor.isAfter(lastDay)) {
      final String key = _dayKey.format(cursor);
      final List<HistoryPoint> dayPoints = byDay[key] ?? <HistoryPoint>[];
      double km = 0;
      double hours = 0;

      if (dayPoints.length >= 2) {
        km = HistoryRouteUtils.totalDistanceKm(dayPoints);
        final Duration? drive = HistoryRouteUtils.drivingDuration(dayPoints);
        if (drive != null) {
          hours = drive.inSeconds / 3600.0;
        }
      }

      if (km > 0 || hours > 0) {
        days.add(
          DailyReportDay(
            dayDate: cursor,
            vehicleName: vehicle.name,
            distanceLabel: '${km.toStringAsFixed(2)} km',
            startTimeLabel: '-',
            endTimeLabel: '-',
            engineHours: _hoursLabel(hours),
            runningTime: _hoursLabel(hours),
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

      cursor = cursor.add(const Duration(days: 1));
    }

    if (days.isEmpty &&
        route.points.isNotEmpty &&
        (route.distanceKm ?? 0) > 0) {
      final double km = route.distanceKm ??
          HistoryRouteUtils.totalDistanceKm(route.points);
      final Duration? drive = HistoryRouteUtils.drivingDuration(route.points);
      final double hours = drive != null ? drive.inSeconds / 3600.0 : 0;
      days.add(
        DailyReportDay(
          dayDate: lastDay,
          vehicleName: vehicle.name,
          distanceLabel: '${km.toStringAsFixed(2)} km',
          startTimeLabel: '-',
          endTimeLabel: '-',
          engineHours: _hoursLabel(hours),
          runningTime: _hoursLabel(hours),
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

    return days;
  }

  static String _hoursLabel(double hours) {
    if (hours <= 0) {
      return '-';
    }
    final int h = hours.floor();
    final int m = ((hours - h) * 60).round();
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }
}
