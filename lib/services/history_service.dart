import 'dart:developer' as developer;

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';

import '../utils/coordinate_parser.dart';
import '../utils/history_route_utils.dart';
import '../utils/polyline_utils.dart';
import 'api_client.dart';
import 'tracking_api_service.dart';

class HistoryPoint {
  const HistoryPoint({
    required this.position,
    this.time,
    this.speed,
    this.course,
    this.address,
    this.eventType,
    this.isStop = false,
  });

  final LatLng position;
  final DateTime? time;
  final double? speed;
  final double? course;
  final String? address;
  final String? eventType;
  final bool isStop;
}

class HistoryRoute {
  const HistoryRoute({
    required this.points,
    this.distanceKm,
    this.durationLabel,
    this.avgSpeed,
    this.topSpeedKmph,
    this.moveDurationLabel,
    this.stopDurationLabel,
    this.fuelConsumption,
    this.fuelCost,
    this.engineHours,
    this.idleDurationLabel,
    this.overspeedCount,
    this.avgFuelMileage,
    this.engineWorkCost,
    this.odometerKm,
    this.rangeFrom,
    this.rangeTo,
    this.itemCount = 0,
    this.errorMessage,
  });

  final List<HistoryPoint> points;
  final double? distanceKm;
  final String? durationLabel;
  final double? avgSpeed;
  final double? topSpeedKmph;
  final String? moveDurationLabel;
  final String? stopDurationLabel;
  final double? fuelConsumption;
  final double? fuelCost;
  final String? engineHours;
  final String? idleDurationLabel;
  final int? overspeedCount;
  final double? avgFuelMileage;
  final double? engineWorkCost;
  final double? odometerKm;
  final DateTime? rangeFrom;
  final DateTime? rangeTo;
  final int itemCount;
  final String? errorMessage;

  bool get isEmpty => points.isEmpty;
  bool get hasError => errorMessage != null && errorMessage!.isNotEmpty;

  DateTime? get startTime =>
      points.isNotEmpty ? points.first.time ?? rangeFrom : rangeFrom;

  DateTime? get endTime =>
      points.isNotEmpty ? points.last.time ?? rangeTo : rangeTo;
}

class HistoryService {
  HistoryService._();

  static final DateFormat _apiFormat = DateFormat('yyyy-MM-dd HH:mm:ss');
  static final Map<String, HistoryRoute> _cache = <String, HistoryRoute>{};
  static const int _maxCacheEntries = 32;
  static const Duration _historyChunk = Duration(days: 3);
  static const int _pageSize = 500;
  static const int _maxParseDepth = 24;
  static const int _maxPointsPerChunk = 25000;
  /// Cap GPS points kept in memory for map playback (stats still from API meta).
  static const int _maxRoutePoints = 2000;

  static String formatForApi(DateTime value) => _apiFormat.format(value);

  static String _cacheKey(int deviceId, DateTime from, DateTime to) {
    return '$deviceId|${formatForApi(from)}|${formatForApi(to)}';
  }

  /// Loads full GPS history for [from, to], merging API chunks/pages.
  static Future<HistoryRoute> loadRouteForRange({
    required int deviceId,
    required DateTime from,
    required DateTime to,
    bool forceRefresh = false,
  }) async {
    final List<HistoryPoint> collected = <HistoryPoint>[];
    Map<String, dynamic>? summaryMeta;
    String? loadError;
    DateTime cursor = from;

    try {
      while (cursor.isBefore(to) || cursor.isAtSameMomentAs(to)) {
        DateTime chunkEnd = cursor.add(_historyChunk);
        if (chunkEnd.isAfter(to)) {
          chunkEnd = to;
        }

        try {
          final _ChunkFetchResult chunk = await _fetchChunkPoints(
            deviceId: deviceId,
            from: cursor,
            to: chunkEnd,
            forceRefresh: forceRefresh,
          );
          collected.addAll(chunk.points);
          summaryMeta ??= chunk.responseMeta;
        } on ApiException catch (e) {
          if (collected.isEmpty) {
            rethrow;
          }
          loadError = e.message;
          developer.log(
            'HistoryService partial load after chunk error: $e',
            name: 'HistoryService',
          );
          break;
        }

        if (chunkEnd.isAtSameMomentAs(to) ||
            chunkEnd.millisecondsSinceEpoch >= to.millisecondsSinceEpoch) {
          break;
        }
        cursor = chunkEnd.add(const Duration(seconds: 1));
      }
    } on ApiException catch (e) {
      return HistoryRoute(
        points: const <HistoryPoint>[],
        rangeFrom: from,
        rangeTo: to,
        errorMessage: e.message,
      );
    }

    final List<HistoryPoint> points = _dedupeAndCap(collected);
    final HistoryRoute route = _enrichRoute(
      points: points,
      responseMeta: summaryMeta,
      rangeFrom: from,
      rangeTo: to,
    );
    if (loadError != null && points.isNotEmpty) {
      return HistoryRoute(
        points: route.points,
        distanceKm: route.distanceKm,
        durationLabel: route.durationLabel,
        avgSpeed: route.avgSpeed,
        topSpeedKmph: route.topSpeedKmph,
        moveDurationLabel: route.moveDurationLabel,
        stopDurationLabel: route.stopDurationLabel,
        fuelConsumption: route.fuelConsumption,
        fuelCost: route.fuelCost,
        engineHours: route.engineHours,
        idleDurationLabel: route.idleDurationLabel,
        overspeedCount: route.overspeedCount,
        avgFuelMileage: route.avgFuelMileage,
        engineWorkCost: route.engineWorkCost,
        odometerKm: route.odometerKm,
        rangeFrom: from,
        rangeTo: to,
        itemCount: route.itemCount,
        errorMessage: loadError,
      );
    }
    return route;
  }

  /// Single API window (used internally and by live bootstrap).
  static Future<HistoryRoute> getRoute({
    required int deviceId,
    required DateTime from,
    required DateTime to,
    bool forceRefresh = false,
  }) async {
    final String key = _cacheKey(deviceId, from, to);
    if (!forceRefresh) {
      final HistoryRoute? cached = _cache[key];
      if (cached != null) {
        return cached;
      }
    }

    try {
      final _ChunkFetchResult chunk = await _fetchChunkPoints(
        deviceId: deviceId,
        from: from,
        to: to,
        forceRefresh: forceRefresh,
      );
      final HistoryRoute route = _enrichRoute(
        points: _dedupeAndCap(chunk.points),
        responseMeta: chunk.responseMeta,
        rangeFrom: from,
        rangeTo: to,
      );
      if (_cache.length >= _maxCacheEntries) {
        _cache.remove(_cache.keys.first);
      }
      _cache[key] = route;
      return route;
    } on ApiException catch (e) {
      return HistoryRoute(
        points: const <HistoryPoint>[],
        rangeFrom: from,
        rangeTo: to,
        errorMessage: e.message,
      );
    } catch (e, stack) {
      developer.log(
        'HistoryService.getRoute failed: $e',
        error: e,
        stackTrace: stack,
      );
      return HistoryRoute(
        points: const <HistoryPoint>[],
        rangeFrom: from,
        rangeTo: to,
        errorMessage: e.toString(),
      );
    }
  }

  static Future<_ChunkFetchResult> _fetchChunkPoints({
    required int deviceId,
    required DateTime from,
    required DateTime to,
    required bool forceRefresh,
  }) async {
    final List<HistoryPoint> all = <HistoryPoint>[];
    Map<String, dynamic>? meta;

    final GetHistoryResult? firstResponse = await TrackingApiService.getHistory(
      deviceId: deviceId,
      from: from,
      to: to,
    );
    if (firstResponse == null) {
      throw const ApiException('Session expired. Please log in again.');
    }

    final HistoryRoute parsed = _parse(
      firstResponse.body,
      rangeFrom: from,
      rangeTo: to,
    );
    all.addAll(parsed.points);
    if (firstResponse.body is Map) {
      meta = (firstResponse.body as Map).map(
        (Object? k, Object? v) => MapEntry(k.toString(), v),
      );
    }

    developer.log(
      'HistoryService chunk device_id=$deviceId status=${firstResponse.statusCode} '
      'items=${_itemCount(firstResponse.body)} points=${parsed.points.length}',
      name: 'HistoryService',
    );

    if (!_shouldFetchNextPage(
      firstResponse.body,
      1,
      _itemCount(firstResponse.body),
    )) {
      return _ChunkFetchResult(points: all, responseMeta: meta);
    }

    int page = 2;
    while (page <= 50) {
      try {
        final GetHistoryResult? pageResponse =
            await TrackingApiService.getHistory(
          deviceId: deviceId,
          from: from,
          to: to,
          page: page,
          limit: _pageSize,
        );
        if (pageResponse == null) {
          break;
        }
        final HistoryRoute pageParsed = _parse(
          pageResponse.body,
          rangeFrom: from,
          rangeTo: to,
        );
        if (pageParsed.points.isEmpty && _itemCount(pageResponse.body) == 0) {
          break;
        }
        all.addAll(pageParsed.points);
        if (all.length >= 8000) {
          break;
        }
        if (!_shouldFetchNextPage(
          pageResponse.body,
          page,
          _itemCount(pageResponse.body),
        )) {
          break;
        }
        page++;
      } on ApiException catch (e) {
        developer.log(
          'HistoryService pagination stopped at page=$page: $e',
          name: 'HistoryService',
        );
        break;
      }
    }

    return _ChunkFetchResult(points: all, responseMeta: meta);
  }

  static int _itemCount(dynamic response) {
    if (response is! Map) {
      return 0;
    }
    final dynamic items = response['items'];
    return items is List ? items.length : 0;
  }

  static bool _shouldFetchNextPage(
    dynamic response,
    int currentPage,
    int pointsOnPage,
  ) {
    if (response is! Map) {
      return false;
    }
    final Map<String, dynamic> map = response.map(
      (Object? k, Object? v) => MapEntry(k.toString(), v),
    );

    final dynamic lastPage = map['last_page'] ?? map['total_pages'];
    if (lastPage is num && currentPage < lastPage.toInt()) {
      return true;
    }

    final dynamic current = map['current_page'] ?? map['page'];
    if (lastPage is num &&
        current is num &&
        current.toInt() < lastPage.toInt()) {
      return true;
    }

    final dynamic next = map['next_page_url'] ?? map['next'];
    if (next != null && next.toString().isNotEmpty) {
      return true;
    }

    // GPSWOX usually returns full history in one response; avoid extra page
    // requests unless the API explicitly exposes pagination metadata.
    return false;
  }

  static List<HistoryPoint> _dedupeAndCap(List<HistoryPoint> raw) {
    List<HistoryPoint> points = HistoryRouteUtils.dedupePoints(raw);
    if (points.length > _maxRoutePoints) {
      points = HistoryRouteUtils.decimatePoints(points, _maxRoutePoints);
    }
    return points;
  }

  static HistoryRoute _enrichRoute({
    required List<HistoryPoint> points,
    required Map<String, dynamic>? responseMeta,
    required DateTime rangeFrom,
    required DateTime rangeTo,
  }) {
    double? distanceKm = responseMeta != null
        ? _parseDistanceKm(
            responseMeta['distance_sum'] ??
                responseMeta['distance'] ??
                responseMeta['total_distance'],
          )
        : null;
    final String? moveDuration = responseMeta != null
        ? (responseMeta['move_duration'] ??
                responseMeta['drive_duration'] ??
                responseMeta['duration'])
            ?.toString()
        : null;
    final String? stopDuration = responseMeta != null
        ? responseMeta['stop_duration']?.toString()
        : null;
    String? durationLabel = moveDuration;
    double? topSpeed = responseMeta != null
        ? _parseDouble(
            responseMeta['top_speed'] ??
                responseMeta['max_speed'] ??
                responseMeta['speed_max'],
          )
        : null;
    double? avgSpeed = responseMeta != null
        ? _parseDouble(
            responseMeta['avg_speed'] ??
                responseMeta['average_speed'] ??
                responseMeta['speed_avg'],
          )
        : null;

    if (points.isNotEmpty) {
      final double computedKm = HistoryRouteUtils.totalDistanceKm(points);
      if (distanceKm == null || points.length > 32) {
        distanceKm = computedKm;
      }
      final Duration? duration = HistoryRouteUtils.drivingDuration(points);
      durationLabel ??= HistoryRouteUtils.formatDuration(duration);
      topSpeed ??= _maxSpeedFromPoints(points);
      avgSpeed ??=
          HistoryRouteUtils.averageSpeedKmph(points, computedKm) ?? topSpeed;
    }

    if (moveDuration != null && stopDuration != null) {
      durationLabel = '$moveDuration / $stopDuration';
    }

    final int itemCount = responseMeta != null && responseMeta['items'] is List
        ? (responseMeta['items'] as List).length
        : 0;

    return HistoryRoute(
      points: points,
      distanceKm: distanceKm,
      durationLabel: durationLabel,
      avgSpeed: avgSpeed,
      topSpeedKmph: topSpeed,
      moveDurationLabel: moveDuration,
      stopDurationLabel: stopDuration,
      itemCount: itemCount,
      fuelConsumption: responseMeta != null
          ? _parseDouble(
              responseMeta['fuel_consumption'] ?? responseMeta['fuel_used'],
            )
          : null,
      fuelCost: responseMeta != null
          ? _parseDouble(responseMeta['fuel_cost'] ?? responseMeta['cost'])
          : null,
      engineHours: responseMeta != null
          ? (responseMeta['engine_hours'] ?? responseMeta['hours'])?.toString()
          : null,
      idleDurationLabel: responseMeta != null
          ? (responseMeta['idle_duration'] ??
                  responseMeta['idle_time'] ??
                  responseMeta['idle'])
              ?.toString()
          : null,
      overspeedCount: responseMeta != null
          ? _parseInt(
              responseMeta['overspeed_count'] ??
                  responseMeta['overspeeds'] ??
                  responseMeta['overspeed'],
            )
          : null,
      avgFuelMileage: responseMeta != null
          ? _parseDouble(
              responseMeta['fuel_mileage'] ??
                  responseMeta['avg_fuel'] ??
                  responseMeta['average_fuel_consumption'],
            )
          : null,
      engineWorkCost: responseMeta != null
          ? _parseDouble(
              responseMeta['engine_work'] ??
                  responseMeta['engine_work_cost'],
            )
          : null,
      odometerKm: responseMeta != null
          ? _parseDouble(
              responseMeta['odometer'] ??
                  responseMeta['odometer_value'] ??
                  responseMeta['total_distance'],
            )
          : null,
      rangeFrom: rangeFrom,
      rangeTo: rangeTo,
    );
  }

  static int? _parseInt(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.round();
    }
    return int.tryParse(value.toString().trim());
  }

  static HistoryRoute _parse(
    dynamic response, {
    required DateTime rangeFrom,
    required DateTime rangeTo,
  }) {
    final List<HistoryPoint> points = <HistoryPoint>[];
    Map<String, dynamic>? meta;

    if (response is Map) {
      meta = response.map((Object? k, Object? v) => MapEntry(k.toString(), v));
    } else if (response is List) {
      _collectPoints(response, points, fromList: true);
    }

    if (meta != null && meta['items'] is List) {
      final List<dynamic> rawItems = meta['items'] as List<dynamic>;
      if (rawItems.isNotEmpty) {
        points.addAll(_pointsFromItems(meta));
      }
    }
    if (points.isEmpty) {
      _collectPoints(response, points, fromList: false);
    }
    if (points.isEmpty && meta != null) {
      final dynamic messages = meta['messages'];
      if (messages is List && messages.isNotEmpty) {
        _collectPoints(messages, points, fromList: true);
      }
      if (points.isEmpty) {
        for (final String key in <String>[
          'groups',
          'trips',
          'routes',
          'history',
          'result',
        ]) {
          final dynamic nested = meta[key];
          if (nested is List && nested.isNotEmpty) {
            _collectPoints(nested, points, fromList: true);
          }
        }
      }
      if (points.isEmpty && meta['device'] is Map) {
        _collectPoints(meta['device'], points, fromList: false);
      }
    }

    if (points.length > _maxPointsPerChunk) {
      points.removeRange(_maxPointsPerChunk, points.length);
    }

    return _enrichRoute(
      points: HistoryRouteUtils.sortByTime(points),
      responseMeta: meta,
      rangeFrom: rangeFrom,
      rangeTo: rangeTo,
    );
  }

  static void _collectPoints(
    dynamic node,
    List<HistoryPoint> target, {
    required bool fromList,
  }) {
    if (node is List) {
      for (final dynamic item in node) {
        _collectPoints(item, target, fromList: true);
      }
      return;
    }

    if (node is! Map) {
      return;
    }

    final Map<String, dynamic> map = node.map(
      (Object? k, Object? v) => MapEntry(k.toString(), v),
    );

    const Set<String> skipKeys = <String>{
      'device',
      'latest_positions',
      'sensors',
      'status',
    };

    for (final String key in <String>[
      'data',
      'history',
      'points',
      'route',
      'positions',
      'records',
      'result',
      'messages',
    ]) {
      if (!skipKeys.contains(key) && map.containsKey(key)) {
        _collectPoints(map[key], target, fromList: false);
      }
    }

    for (final String key in <String>[
      'polyline',
      'encoded_polyline',
      'route_polyline',
      'overview_polyline',
    ]) {
      final dynamic raw = map[key];
      if (raw is String && raw.isNotEmpty) {
        _addPolylinePoints(raw, target);
      } else if (raw is Map && raw['points'] != null) {
        final dynamic pointsField = raw['points'];
        if (pointsField is String && pointsField.isNotEmpty) {
          _addPolylinePoints(pointsField, target);
        }
      }
    }

    if (fromList || _looksLikeTrackPoint(map)) {
      _tryAddPoint(map, target);
    }
  }

  static bool _looksLikeTrackPoint(Map<String, dynamic> map) {
    if (_parseTime(map['time'] ?? map['timestamp'] ?? map['server_time']) !=
        null) {
      return true;
    }
    final dynamic type = map['type'] ?? map['event'];
    if (type != null && type.toString().toLowerCase().contains('position')) {
      return true;
    }
    return CoordinateParser.fromMap(map) != null &&
        (map.containsKey('speed') ||
            map.containsKey('speed_kmh') ||
            map.containsKey('course'));
  }

  static void _tryAddPoint(
    Map<String, dynamic> map,
    List<HistoryPoint> target,
  ) {
    final (double lat, double lng)? coords = CoordinateParser.fromMap(map);
    if (coords == null) {
      return;
    }

    final String? eventType =
        (map['type'] ?? map['event'] ?? map['status'])?.toString();
    target.add(
      HistoryPoint(
        position: LatLng(coords.$1, coords.$2),
        time: _parseTime(
          map['time'] ??
              map['timestamp'] ??
              map['server_time'] ??
              map['device_time'],
        ),
        speed: _parseSpeed(map),
        course: _parseDouble(
          map['course'] ?? map['bearing'] ?? map['heading'] ?? map['angle'],
        ),
        address: (map['address'] ?? map['location'] ?? map['show'])
            ?.toString(),
        eventType: eventType,
        isStop: _isStopEvent(map, eventType),
      ),
    );
  }

  static List<HistoryPoint> _pointsFromItems(Map<String, dynamic> map) {
    final dynamic items = map['items'];
    if (items is! List) {
      return <HistoryPoint>[];
    }
    final List<HistoryPoint> points = <HistoryPoint>[];
    for (final dynamic item in items) {
      if (points.length >= _maxPointsPerChunk) {
        break;
      }
      _collectHistoryItemNode(item, points);
    }
    return points;
  }

  /// GPSWOX history rows may be flat points or nested segments with coordinates.
  static void _collectHistoryItemNode(
    dynamic node,
    List<HistoryPoint> target, {
    int depth = 0,
  }) {
    if (depth > _maxParseDepth || target.length >= _maxPointsPerChunk) {
      return;
    }
    if (node is List) {
      for (final dynamic child in node) {
        if (target.length >= _maxPointsPerChunk) {
          break;
        }
        if (_tryAddLatLngPair(child, target)) {
          continue;
        }
        _collectHistoryItemNode(child, target, depth: depth + 1);
      }
      return;
    }
    if (node is! Map) {
      return;
    }
    final Map<String, dynamic> map = node.map(
      (Object? k, Object? v) => MapEntry(k.toString(), v),
    );
    final DateTime? nodeTime = _parseTime(map['time'] ?? map['timestamp']);

    for (final String key in <String>[
      'items',
      'coordinates',
      'points',
      'positions',
      'history',
      'data',
    ]) {
      if (map[key] is List) {
        _collectHistoryItemNode(map[key], target, depth: depth + 1);
      }
    }

    _addSegmentEndpoints(map, target);

    for (final String key in <String>['polyline', 'encoded_polyline', 'c']) {
      final dynamic raw = map[key];
      if (raw is String && raw.isNotEmpty) {
        _addPolylinePoints(raw, target, time: nodeTime);
      }
    }

    final dynamic show = map['show'];
    if (show is String && show.isNotEmpty) {
      final (double lat, double lng)? pair = CoordinateParser.parsePair(show);
      if (pair != null) {
        target.add(
          HistoryPoint(
            position: LatLng(pair.$1, pair.$2),
            time: nodeTime ?? _parseTime(map['start_time'] ?? map['time']),
            eventType: map['status']?.toString(),
            isStop: _isStopEvent(map, map['status']?.toString()),
          ),
        );
      }
    }

    _tryAddPoint(map, target);
  }

  static void _addPolylinePoints(
    String encoded,
    List<HistoryPoint> target, {
    DateTime? time,
  }) {
    try {
      final List<LatLng> decoded = PolylineUtils.decode(encoded);
      for (final LatLng position in decoded) {
        if (target.length >= _maxPointsPerChunk) {
          break;
        }
        target.add(HistoryPoint(position: position, time: time));
      }
    } catch (e, stack) {
      developer.log(
        'HistoryService polyline decode skipped: $e',
        error: e,
        stackTrace: stack,
        name: 'HistoryService',
      );
    }
  }

  static bool _tryAddLatLngPair(dynamic entry, List<HistoryPoint> target) {
    if (entry is! List || entry.length < 2) {
      return false;
    }
    final double? a = _parseDouble(entry[0]);
    final double? b = _parseDouble(entry[1]);
    if (a == null || b == null) {
      return false;
    }
    final (double lat, double lng)? pair = a.abs() <= 90 && b.abs() <= 180
        ? CoordinateParser.fromMap(<String, dynamic>{
            'latitude': a,
            'longitude': b,
          })
        : CoordinateParser.fromMap(<String, dynamic>{
            'latitude': b,
            'longitude': a,
          });
    if (pair == null) {
      return false;
    }
    target.add(HistoryPoint(position: LatLng(pair.$1, pair.$2)));
    return true;
  }

  /// GPSWOX drive/stop rows often expose endpoints as `left`/`right` strings.
  static DateTime? _segmentEndpointTime(
    Map<String, dynamic> map,
    String key,
  ) {
    if (key == 'left' || key == 'start') {
      return _parseTime(
        map['start_time'] ??
            map['time_from'] ??
            map['from_time'] ??
            map['time'] ??
            map['timestamp'],
      );
    }
    if (key == 'right' || key == 'end') {
      return _parseTime(
        map['end_time'] ??
            map['time_to'] ??
            map['to_time'] ??
            map['finish_time'] ??
            map['time'] ??
            map['timestamp'],
      );
    }
    return _parseTime(map['time'] ?? map['timestamp']);
  }

  static void _addSegmentEndpoints(
    Map<String, dynamic> map,
    List<HistoryPoint> target,
  ) {
    final String? eventType =
        map['status']?.toString() ?? map['type']?.toString();
    for (final String key in <String>['left', 'right', 'start', 'end']) {
      final dynamic raw = map[key];
      if (raw is String && raw.isNotEmpty) {
        final (double lat, double lng)? pair = CoordinateParser.parsePair(raw);
        if (pair != null) {
          target.add(
            HistoryPoint(
              position: LatLng(pair.$1, pair.$2),
              time: _segmentEndpointTime(map, key),
              eventType: eventType,
              isStop: _isStopEvent(map, eventType),
            ),
          );
        }
        continue;
      }
      if (raw is Map) {
        final Map<String, dynamic> nested = raw.map(
          (Object? k, Object? v) => MapEntry(k.toString(), v),
        );
        _tryAddPoint(nested, target);
      }
    }

    for (final String prefix in <String>['left', 'right', 'start', 'end']) {
      final double? lat = _parseDouble(
        map['${prefix}_latitude'] ??
            map['${prefix}_lat'] ??
            map['${prefix}Latitude'],
      );
      final double? lng = _parseDouble(
        map['${prefix}_longitude'] ??
            map['${prefix}_lng'] ??
            map['${prefix}Longitude'],
      );
      if (lat != null && lng != null) {
        final (double normLat, double normLng)? normalized =
            CoordinateParser.fromMap(<String, dynamic>{
          'latitude': lat,
          'longitude': lng,
        });
        if (normalized != null) {
          target.add(
            HistoryPoint(
              position: LatLng(normalized.$1, normalized.$2),
              time: _segmentEndpointTime(map, prefix),
              eventType: eventType,
              isStop: _isStopEvent(map, eventType),
            ),
          );
        }
      }
    }
  }

  static bool _isStopEvent(Map<String, dynamic> map, String? eventType) {
    final dynamic statusRaw = map['status'];
    if (statusRaw == 2 || statusRaw == '2') {
      return true;
    }
    final String hay =
        '${eventType ?? ''} ${map['status'] ?? ''}'.toLowerCase();
    if (hay.contains('stop') || hay.contains('park') || hay.contains('idle')) {
      return true;
    }
    final double? speed = _parseSpeed(map);
    return speed != null && speed <= 1;
  }

  static double? _maxSpeedFromPoints(List<HistoryPoint> points) {
    double? max;
    for (final HistoryPoint p in points) {
      final double? s = p.speed;
      if (s == null) {
        continue;
      }
      if (max == null || s > max) {
        max = s;
      }
    }
    return max;
  }

  static double? _parseDistanceKm(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is num) {
      final double v = value.toDouble();
      return v > 10000 ? v / 1000.0 : v;
    }
    final String raw = value.toString().trim().toLowerCase();
    final double? n = double.tryParse(
      raw.replaceAll(RegExp(r'[^0-9.\-]'), ''),
    );
    if (n == null) {
      return null;
    }
    if (raw.contains('m') && !raw.contains('km')) {
      return n / 1000.0;
    }
    return n;
  }

  static double? _parseSpeed(Map<String, dynamic> map) {
    final dynamic attributes = map['attributes'];
    final Map<String, dynamic>? attrMap = attributes is Map
        ? attributes.map((Object? k, Object? v) => MapEntry(k.toString(), v))
        : null;

    return _parseDouble(
      map['speed'] ??
          map['speed_kmh'] ??
          map['speedKmh'] ??
          map['velocity'] ??
          attrMap?['speed'] ??
          attrMap?['speed_kmh'],
    );
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(
      value.toString().replaceAll(RegExp(r'[^0-9.\-]'), ''),
    );
  }

  static DateTime? _parseTime(dynamic value) {
    if (value == null) {
      return null;
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
    try {
      return DateTime.parse(raw);
    } catch (_) {
      try {
        return DateFormat('dd-MM-yyyy hh:mm:ss a').parse(raw);
      } catch (_) {
        return null;
      }
    }
  }
}

class _ChunkFetchResult {
  const _ChunkFetchResult({
    required this.points,
    this.responseMeta,
  });

  final List<HistoryPoint> points;
  final Map<String, dynamic>? responseMeta;
}
