import 'package:intl/intl.dart';

import '../utils/report_response_parser.dart';

class DailyReportDay {
  const DailyReportDay({
    required this.dayDate,
    required this.vehicleName,
    required this.distanceLabel,
    required this.startTimeLabel,
    required this.endTimeLabel,
    required this.engineHours,
    required this.runningTime,
    required this.stopTime,
    required this.idleTime,
    required this.startLocation,
    required this.endLocation,
    required this.startOdometer,
    required this.endOdometer,
    required this.avgSpeedLabel,
    required this.maxSpeedLabel,
  });

  final DateTime dayDate;
  final String vehicleName;
  final String distanceLabel;
  final String startTimeLabel;
  final String endTimeLabel;
  final String engineHours;
  final String runningTime;
  final String stopTime;
  final String idleTime;
  final String startLocation;
  final String endLocation;
  final String startOdometer;
  final String endOdometer;
  final String avgSpeedLabel;
  final String maxSpeedLabel;

  static DailyReportDay fromApiMap(
    Map<String, dynamic> item,
    String vehicleName, {
    required DateTime dayDate,
    String fallbackLocation = '-',
  }) {
    String pick(List<String> keys, {String fallback = '-'}) {
      for (final String key in keys) {
        final dynamic value = item[key];
        if (value != null && value.toString().trim().isNotEmpty) {
          return value.toString().trim();
        }
      }
      return fallback;
    }

    String pickOrDeep(List<String> keys, {String fallback = '-'}) {
      final String shallow = pick(keys, fallback: '');
      if (shallow.isNotEmpty && shallow != '-') {
        return shallow;
      }
      final String deep =
          ReportResponseParser.summaryValue(item, keys, fallback: fallback);
      return deep;
    }

    String formatDistance(String raw) {
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

    String formatSpeed(String raw, {required String prefix}) {
      final String trimmed = raw.trim();
      if (trimmed.isEmpty || trimmed == '-') {
        return '$prefix 0.00 kmph';
      }
      if (trimmed.toLowerCase().contains('km')) {
        return '$prefix ${trimmed.replaceAll(RegExp(r'^(avg\.?|max\.?)\s*', caseSensitive: false), '').trim()}';
      }
      final double? n = double.tryParse(trimmed.replaceAll(',', ''));
      if (n == null) {
        return '$prefix $trimmed';
      }
      return '$prefix ${n.toStringAsFixed(2)} kmph';
    }

    String formatTimeLabel(String raw) {
      final String trimmed = raw.trim();
      if (trimmed.isEmpty || trimmed == '-') {
        return '-';
      }
      final List<String> patterns = <String>[
        'yyyy-MM-dd HH:mm:ss',
        'dd-MM-yyyy HH:mm:ss',
        'yyyy-MM-dd HH:mm',
        'dd MMM yyyy hh:mm a',
        'MMM dd yyyy hh:mm a',
      ];
      for (final String pattern in patterns) {
        try {
          final DateTime parsed = DateFormat(pattern).parse(trimmed);
          return DateFormat('dd MMM yyyy hh:mm a').format(parsed);
        } catch (_) {}
      }
      final DateTime? iso = DateTime.tryParse(trimmed.replaceAll('/', '-'));
      if (iso != null) {
        return DateFormat('dd MMM yyyy hh:mm a').format(iso);
      }
      return trimmed;
    }

    String formatDuration(String raw) {
      final String trimmed = raw.trim();
      if (trimmed.isEmpty || trimmed == '-') {
        return '-';
      }
      if (RegExp(r'^\d{1,2}:\d{2}(:\d{2})?$').hasMatch(trimmed)) {
        final List<String> parts = trimmed.split(':');
        if (parts.length == 2) {
          return '${parts[0].padLeft(2, '0')}:${parts[1].padLeft(2, '0')}:00';
        }
        return '${parts[0].padLeft(2, '0')}:${parts[1].padLeft(2, '0')}:${parts[2].padLeft(2, '0')}';
      }
      return trimmed;
    }

    String formatOdometer(String raw) {
      final String trimmed = raw.trim();
      if (trimmed.isEmpty || trimmed == '-') {
        return '-';
      }
      final String digits = trimmed.replaceAll(RegExp(r'[^\d]'), '');
      if (digits.isEmpty) {
        return trimmed;
      }
      return digits.padLeft(9, '0');
    }

    final String resolvedVehicleName = pick(
      <String>['device_name', 'vehicle_name', 'vehicle', 'name'],
      fallback: vehicleName,
    );

    final String distanceRaw = pickOrDeep(
      <String>[
        'distance',
        'total_distance',
        'distance_sum',
        'route_length',
        'distance_km',
        'total_km',
        'route_km',
        'mileage',
        'route',
        'km',
        'total',
      ],
    );

    return DailyReportDay(
      dayDate: dayDate,
      vehicleName: resolvedVehicleName,
      distanceLabel: formatDistance(distanceRaw),
      startTimeLabel: formatTimeLabel(
        pick(
          <String>[
            'start_time',
            'time_from',
            'date_from',
            'from_time',
            'start',
          ],
        ),
      ),
      endTimeLabel: formatTimeLabel(
        pick(
          <String>['end_time', 'time_to', 'date_to', 'to_time', 'end'],
        ),
      ),
      engineHours: formatDuration(
        pickOrDeep(
          <String>[
            'engine_hours',
            'engine_hour',
            'work_time',
            'duration',
            'engine_work',
          ],
        ),
      ),
      runningTime: formatDuration(
        pickOrDeep(
          <String>[
            'running',
            'run_time',
            'drive_duration',
            'moving_duration',
            'move_duration',
          ],
        ),
      ),
      stopTime: formatDuration(
        pick(
          <String>['stop', 'stop_time', 'stop_duration', 'stops_duration'],
        ),
      ),
      idleTime: formatDuration(
        pick(
          <String>['idle', 'idle_time', 'idle_duration'],
        ),
      ),
      startLocation: pick(
        <String>[
          'start_location',
          'start_address',
          'location_start',
          'from_address',
          'start',
        ],
        fallback: fallbackLocation,
      ),
      endLocation: pick(
        <String>[
          'end_location',
          'end_address',
          'location_end',
          'to_address',
          'end',
        ],
        fallback: fallbackLocation,
      ),
      startOdometer: formatOdometer(
        pick(
          <String>['start_odometer', 'odometer_start', 'odo_start'],
        ),
      ),
      endOdometer: formatOdometer(
        pick(
          <String>['end_odometer', 'odometer_end', 'odo_end'],
        ),
      ),
      avgSpeedLabel: formatSpeed(
        pick(<String>['average_speed', 'avg_speed', 'speed_avg']),
        prefix: 'Avg.',
      ),
      maxSpeedLabel: formatSpeed(
        pick(<String>['max_speed', 'speed_max', 'top_speed']),
        prefix: 'Max.',
      ),
    );
  }

  bool get hasMeaningfulData {
    if (_numericKm(distanceLabel) > 0) {
      return true;
    }
    if (_durationPositive(engineHours) || _durationPositive(runningTime)) {
      return true;
    }
    return startTimeLabel != '-' || endTimeLabel != '-';
  }

  static double _numericKm(String label) {
    final String s = label.trim().toLowerCase();
    if (s.isEmpty || s == '-') {
      return 0;
    }
    final RegExp reg = RegExp(r'([0-9]+(?:\.[0-9]+)?)');
    final Match? m = reg.firstMatch(s);
    if (m == null) {
      return 0;
    }
    return double.tryParse(m.group(1) ?? '') ?? 0;
  }

  static bool _durationPositive(String value) {
    final String s = value.trim();
    if (s.isEmpty || s == '-') {
      return false;
    }
    if (RegExp(r'[1-9]').hasMatch(s)) {
      return true;
    }
    return false;
  }
}
