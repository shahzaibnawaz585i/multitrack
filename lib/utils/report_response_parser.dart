import 'package:flutter/material.dart';

import '../models/vehicle_model.dart';
import '../screens/report_screens/report_content_widgets.dart';

class ReportResponseParser {
  ReportResponseParser._();

  /// Normalizes list/map API payloads (tasks, reports, events).
  static List<Map<String, dynamic>> listFromDynamic(dynamic response) {
    if (response == null) {
      return <Map<String, dynamic>>[];
    }
    if (response is List) {
      final List<Map<String, dynamic>> out = <Map<String, dynamic>>[];
      for (final dynamic item in response) {
        final Map<String, dynamic>? map = _asStringKeyMap(item);
        if (map != null) {
          out.add(map);
        }
      }
      return out;
    }
    if (response is Map) {
      final Map<String, dynamic> root = response.map(
        (Object? k, Object? v) => MapEntry(k.toString(), v),
      );
      for (final String key in <String>[
        'items',
        'data',
        'rows',
        'table',
        'results',
        'report',
        'tasks',
        'events',
      ]) {
        if (root[key] is List) {
          return listFromDynamic(root[key]);
        }
      }
      return extractItems(root);
    }
    return <Map<String, dynamic>>[];
  }

  static Map<String, dynamic>? _asStringKeyMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return value.map((Object? k, Object? v) => MapEntry(k.toString(), v));
    }
    return null;
  }

  static List<Map<String, dynamic>> extractItems(
    Map<String, dynamic>? response,
  ) {
    if (response == null || response.isEmpty) {
      return <Map<String, dynamic>>[];
    }

    final List<Map<String, dynamic>> items = <Map<String, dynamic>>[];
    _collectMaps(response, items);
    return items;
  }

  static int itemCount(Map<String, dynamic>? response) =>
      extractItems(response).length;

  static int itemCountDynamic(dynamic response) =>
      listFromDynamic(response).length;

  static bool isEmptyReport(dynamic response) {
    return rowsFromResponse(response).isEmpty;
  }

  /// Normalizes JSON/list/map **or HTML table** report payloads into row maps.
  static List<Map<String, dynamic>> rowsFromResponse(dynamic response) {
    if (response == null) {
      return <Map<String, dynamic>>[];
    }

    List<Map<String, dynamic>> items = listFromDynamic(response);
    if (items.isEmpty) {
      items = extractItems(asReportMap(response));
    }
    if (items.isNotEmpty) {
      return items;
    }

    if (response is Map) {
      final Map<String, dynamic> map = response.map(
        (Object? k, Object? v) => MapEntry(k.toString(), v),
      );
      for (final String key in <String>[
        'html',
        'content',
        'report',
        'body',
        'table',
      ]) {
        final dynamic raw = map[key];
        if (raw is String && raw.toLowerCase().contains('<table')) {
          items = itemsFromHtmlTable(raw);
          if (items.isNotEmpty) {
            return items;
          }
        }
      }
      if (map.isNotEmpty) {
        return <Map<String, dynamic>>[map];
      }
    }

    if (response is String && response.toLowerCase().contains('<table')) {
      return itemsFromHtmlTable(response);
    }

    final String? nestedHtml = _findHtmlTable(response);
    if (nestedHtml != null) {
      items = itemsFromHtmlTable(nestedHtml);
      if (items.isNotEmpty) {
        return items;
      }
    }

    return <Map<String, dynamic>>[];
  }

  static String? _findHtmlTable(dynamic node) {
    if (node is String) {
      final String trimmed = node.trim();
      if (trimmed.toLowerCase().contains('<table')) {
        return trimmed;
      }
      return null;
    }
    if (node is Map) {
      for (final dynamic value in node.values) {
        final String? found = _findHtmlTable(value);
        if (found != null) {
          return found;
        }
      }
    }
    if (node is List) {
      for (final dynamic value in node) {
        final String? found = _findHtmlTable(value);
        if (found != null) {
          return found;
        }
      }
    }
    return null;
  }

  /// Parses simple GPSWOX-style HTML report tables into row maps.
  static List<Map<String, dynamic>> itemsFromHtmlTable(String html) {
    if (html.trim().isEmpty) {
      return <Map<String, dynamic>>[];
    }

    final List<String> headers = <String>[];
    final List<Map<String, dynamic>> rows = <Map<String, dynamic>>[];

    final RegExp rowPattern = RegExp(
      r'<tr[^>]*>([\s\S]*?)</tr>',
      caseSensitive: false,
    );
    final RegExp cellPattern = RegExp(
      r'<t[dh][^>]*>([\s\S]*?)</t[dh]>',
      caseSensitive: false,
    );

    for (final RegExpMatch rowMatch in rowPattern.allMatches(html)) {
      final String rowHtml = rowMatch.group(1) ?? '';
      final List<String> cells = cellPattern
          .allMatches(rowHtml)
          .map((RegExpMatch m) => _stripHtmlTags(m.group(1) ?? ''))
          .toList();

      if (cells.isEmpty) {
        continue;
      }

      if (rowHtml.toLowerCase().contains('<th')) {
        headers
          ..clear()
          ..addAll(cells.map(_normalizeHtmlHeader));
        continue;
      }

      if (headers.isNotEmpty && cells.isNotEmpty) {
        final Map<String, dynamic> row = <String, dynamic>{};
        final int n = headers.length < cells.length ? headers.length : cells.length;
        for (int i = 0; i < n; i++) {
          if (cells[i].trim().isEmpty) {
            continue;
          }
          row[headers[i]] = cells[i];
        }
        if (row.isNotEmpty) {
          rows.add(row);
        }
        continue;
      }

      if (cells.length >= 2) {
        rows.add(<String, dynamic>{
          'time': cells[0],
          'status': cells.length > 1 ? cells[1] : '',
          'address': cells.length > 2 ? cells[2] : '',
          'location': cells.length > 2 ? cells[2] : '',
        });
      }
    }

    return rows;
  }

  static String _stripHtmlTags(String value) {
    return value
        .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), ' ')
        .replaceAll(RegExp(r'<[^>]+>'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static String _normalizeHtmlHeader(String header) {
    final String lower = header.toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
    if (lower.contains('time') || lower.contains('date')) {
      return 'time';
    }
    if (lower.contains('location') ||
        lower.contains('address') ||
        lower.contains('place')) {
      return 'address';
    }
    if (lower.contains('status') ||
        lower.contains('event') ||
        lower.contains('type') ||
        lower.contains('ignition') ||
        lower.contains('engine')) {
      return 'status';
    }
    if (lower.contains('duration') || lower.contains('stop')) {
      return 'duration';
    }
    if (lower.contains('distance') ||
        lower.contains('route') ||
        lower.contains('mileage') ||
        lower.contains(' kilomet') ||
        lower.contains(' km')) {
      return 'distance';
    }
    if (lower.contains('running') ||
        lower.contains('moving') ||
        lower.contains('move time') ||
        lower.contains('drive')) {
      return 'running';
    }
    if (lower.contains('engine')) {
      return 'engine_hours';
    }
    if (lower.contains('start') &&
        (lower.contains('time') || lower.contains('date'))) {
      return 'start_time';
    }
    if (lower.contains('end') &&
        (lower.contains('time') || lower.contains('date'))) {
      return 'end_time';
    }
    if (lower.contains('odometer') || lower.contains(' odo')) {
      return 'start_odometer';
    }
    if (lower.contains('avg') && lower.contains('speed')) {
      return 'average_speed';
    }
    if (lower.contains('max') && lower.contains('speed')) {
      return 'max_speed';
    }
    if (lower.contains('idle')) {
      return 'idle';
    }
    return lower.replaceAll(' ', '_');
  }

  static Map<String, dynamic>? asReportMap(dynamic response) {
    if (response == null) {
      return null;
    }
    if (response is Map<String, dynamic>) {
      return response;
    }
    if (response is Map) {
      return response.map((Object? k, Object? v) => MapEntry(k.toString(), v));
    }
    if (response is List) {
      if (response.isEmpty) {
        return null;
      }
      return <String, dynamic>{'items': response};
    }
    return null;
  }

  static String summaryValue(
    Map<String, dynamic>? response,
    List<String> keys, {
    String fallback = '-',
  }) {
    if (response == null) {
      return fallback;
    }
    for (final String key in keys) {
      final dynamic value = _deepFind(response, key);
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString();
      }
    }
    return fallback;
  }

  static Widget buildTimeline(
    Map<String, dynamic>? response,
    VehicleModel vehicle, {
    Color defaultColor = Colors.green,
  }) {
    final List<Map<String, dynamic>> items = rowsFromResponse(response);
    if (items.isEmpty) {
      return ReportTimelineEvent(
        time: '-',
        duration: '',
        status: 'No data',
        statusColor: Colors.grey,
        location: vehicle.location,
        isLast: true,
      );
    }

    return Column(
      children: List<Widget>.generate(items.length, (int index) {
        final Map<String, dynamic> item = items[index];
        final String status =
            (item['status'] ??
                    item['type'] ??
                    item['event'] ??
                    item['title'] ??
                    item['name'] ??
                    'Event')
                .toString();
        final String time =
            (item['time'] ??
                    item['start_time'] ??
                    item['timestamp'] ??
                    item['date'] ??
                    '-')
                .toString();
        final String duration =
            (item['duration'] ??
                    item['stop_duration'] ??
                    item['drive_duration'] ??
                    '')
                .toString();
        final String location =
            (item['address'] ??
                    item['location'] ??
                    item['place'] ??
                    vehicle.location)
                .toString();
        final Color color = _statusColor(status, defaultColor);

        return ReportTimelineEvent(
          time: time,
          duration: duration.isNotEmpty ? 'Duration: $duration' : '',
          status: status,
          statusColor: color,
          location: location,
          isLast: index == items.length - 1,
        );
      }),
    );
  }

  static Widget buildSummaryCard(
    Map<String, dynamic>? response,
    VehicleModel vehicle,
  ) {
    final String distance = summaryValue(response, <String>[
      'distance',
      'total_distance',
    ], fallback: vehicle.distance);
    final String engineHours = summaryValue(response, <String>[
      'engine_hours',
      'drive_duration',
      'duration',
    ]);
    final String running = summaryValue(response, <String>[
      'running',
      'run_time',
    ]);
    final String stops = summaryValue(response, <String>[
      'stops',
      'stop_count',
      'stop_time',
    ]);
    final String idle = summaryValue(response, <String>['idle', 'idle_time']);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SummaryReportCard(vehicle: vehicle),
        const SizedBox(height: 12),
        _metricRow('Distance', distance),
        _metricRow('Engine hours', engineHours),
        _metricRow('Running', running),
        _metricRow('Stops', stops),
        _metricRow('Idle', idle),
      ],
    );
  }

  static Widget _metricRow(String label, String value) {
    if (value == '-') {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          Text(value),
        ],
      ),
    );
  }

  static void _collectMaps(dynamic node, List<Map<String, dynamic>> target) {
    if (node is List) {
      for (final dynamic item in node) {
        _collectMaps(item, target);
      }
      return;
    }

    if (node is! Map) {
      return;
    }

    final Map<String, dynamic> map = node.map(
      (Object? k, Object? v) => MapEntry(k.toString(), v),
    );

    if (_looksLikeReportRow(map)) {
      target.add(map);
      return;
    }

    for (final String key in <String>[
      'items',
      'data',
      'rows',
      'table',
      'results',
      'events',
      'reports',
    ]) {
      if (map.containsKey(key)) {
        _collectMaps(map[key], target);
      }
    }
  }

  static bool _looksLikeReportRow(Map<String, dynamic> map) {
    return map.containsKey('time') ||
        map.containsKey('timestamp') ||
        map.containsKey('date') ||
        map.containsKey('day') ||
        map.containsKey('status') ||
        map.containsKey('type') ||
        map.containsKey('event') ||
        map.containsKey('distance') ||
        map.containsKey('total_distance') ||
        map.containsKey('route_length') ||
        map.containsKey('route_km') ||
        map.containsKey('move_duration') ||
        map.containsKey('engine_hours') ||
        map.containsKey('start_time') ||
        map.containsKey('end_time') ||
        map.containsKey('title') ||
        map.containsKey('expires') ||
        map.containsKey('remind_date') ||
        map.containsKey('due_date') ||
        (map.containsKey('lat') && map.containsKey('lng'));
  }

  static dynamic _deepFind(Map<String, dynamic> map, String key) {
    if (map.containsKey(key)) {
      return map[key];
    }
    for (final dynamic value in map.values) {
      if (value is Map) {
        final Map<String, dynamic> nested = value.map(
          (Object? k, Object? v) => MapEntry(k.toString(), v),
        );
        final dynamic found = _deepFind(nested, key);
        if (found != null) {
          return found;
        }
      }
    }
    return null;
  }

  static Color _statusColor(String status, Color fallback) {
    final String lower = status.toLowerCase();
    if (lower.contains('off') ||
        lower.contains('stop') ||
        lower.contains('exit')) {
      return Colors.redAccent;
    }
    if (lower.contains('on') ||
        lower.contains('start') ||
        lower.contains('enter') ||
        lower.contains('running')) {
      return Colors.green;
    }
    if (lower.contains('speed') || lower.contains('over')) {
      return Colors.orange;
    }
    return fallback;
  }
}
