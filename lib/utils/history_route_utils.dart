import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';

import '../services/history_service.dart';
import '../services/live_route_service.dart';

enum HistoryDriveState { stop, idle, running }

enum HistoryTimelineKind { trip, stop }

class HistoryTimelineSegment {
  const HistoryTimelineSegment({
    required this.kind,
    required this.start,
    required this.end,
    this.distanceKm = 0,
    this.maxSpeedKmph = 0,
  });

  final HistoryTimelineKind kind;
  final DateTime start;
  final DateTime end;
  final double distanceKm;
  final double maxSpeedKmph;

  Duration get duration {
    final Duration d = end.difference(start);
    return d.isNegative ? Duration.zero : d;
  }
}

class HistoryStopSession {
  const HistoryStopSession({
    required this.index,
    required this.arrival,
    required this.departure,
    required this.position,
    this.address,
  });

  final int index;
  final DateTime arrival;
  final DateTime departure;
  final LatLng position;
  final String? address;

  Duration get duration {
    final Duration d = departure.difference(arrival);
    return d.isNegative ? Duration.zero : d;
  }
}

class HistoryPlaybackSample {
  const HistoryPlaybackSample({
    required this.position,
    required this.bearing,
    required this.index,
    this.point,
  });

  final LatLng position;
  final double bearing;
  final int index;
  final HistoryPoint? point;
}

/// Map display + stats helpers for vehicle history routes.
class HistoryRouteUtils {
  HistoryRouteUtils._();

  static const int maxPolylineVertices = 1800;
  static const int _maxPolylineVertices = maxPolylineVertices;

  static final DateFormat _displayFormat = DateFormat('dd MMM yyyy HH:mm:ss');
  static final DateFormat _displayFormatShort = DateFormat('dd MMM yyyy HH:mm');
  static final DateFormat _timelineCardFormat =
      DateFormat('hh:mm:ss a - dd MMM, yyyy');

  static const Duration _minStopSegment = Duration(minutes: 2);
  static const Duration _minTripSegment = Duration(seconds: 45);
  static const double _stopSpeedKmph = 3;

  static String formatDateTime(DateTime? value, {bool short = false}) {
    if (value == null) {
      return '—';
    }
    return short ? _displayFormatShort.format(value) : _displayFormat.format(value);
  }

  static List<HistoryPoint> sortByTime(List<HistoryPoint> points) {
    final List<HistoryPoint> copy = List<HistoryPoint>.from(points);
    copy.sort((HistoryPoint a, HistoryPoint b) {
      final DateTime? at = a.time;
      final DateTime? bt = b.time;
      if (at == null && bt == null) {
        return 0;
      }
      if (at == null) {
        return 1;
      }
      if (bt == null) {
        return -1;
      }
      return at.compareTo(bt);
    });
    return copy;
  }

  static List<HistoryPoint> dedupePoints(List<HistoryPoint> points) {
    final Map<String, HistoryPoint> unique = <String, HistoryPoint>{};
    for (final HistoryPoint point in points) {
      final DateTime? time = point.time;
      final String key = time != null
          ? '${time.millisecondsSinceEpoch}_${point.position.latitude.toStringAsFixed(5)}_${point.position.longitude.toStringAsFixed(5)}'
          : '${point.position.latitude}_${point.position.longitude}_${point.speed}';
      unique[key] = point;
    }
    return sortByTime(unique.values.toList());
  }

  static List<LatLng> positions(List<HistoryPoint> points) {
    return points.map((HistoryPoint p) => p.position).toList();
  }

  /// Uniform decimation for map/playback (keeps first/last).
  static List<HistoryPoint> decimatePoints(
    List<HistoryPoint> points,
    int maxPoints,
  ) {
    if (points.length <= maxPoints || maxPoints < 2) {
      return points;
    }
    final List<HistoryPoint> out = <HistoryPoint>[points.first];
    final double step = (points.length - 2) / (maxPoints - 2);
    double cursor = step;
    for (int i = 0; i < maxPoints - 2; i++) {
      out.add(points[cursor.round().clamp(1, points.length - 2)]);
      cursor += step;
    }
    out.add(points.last);
    return out;
  }

  /// Uniform decimation for Google Maps polylines (keeps first/last).
  static List<LatLng> simplifyForMap(List<LatLng> points) {
    if (points.length <= _maxPolylineVertices) {
      return points;
    }
    final List<LatLng> out = <LatLng>[points.first];
    final double step = (points.length - 2) / (_maxPolylineVertices - 2);
    double cursor = step;
    for (int i = 0; i < _maxPolylineVertices - 2; i++) {
      out.add(points[cursor.round().clamp(1, points.length - 2)]);
      cursor += step;
    }
    out.add(points.last);
    return out;
  }

  static double totalDistanceKm(List<HistoryPoint> points) {
    if (points.length < 2) {
      return 0;
    }
    double meters = 0;
    for (int i = 1; i < points.length; i++) {
      meters += LiveRouteService.haversineMeters(
        points[i - 1].position,
        points[i].position,
      );
    }
    return meters / 1000.0;
  }

  static Duration? drivingDuration(List<HistoryPoint> points) {
    if (points.isEmpty) {
      return null;
    }
    final DateTime? start = points.first.time;
    final DateTime? end = points.last.time;
    if (start == null || end == null || !end.isAfter(start)) {
      return null;
    }
    return end.difference(start);
  }

  static String formatDuration(Duration? duration) {
    if (duration == null) {
      return '00:00 Hrs';
    }
    final int hours = duration.inHours;
    final int minutes = duration.inMinutes.remainder(60);
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')} Hrs';
    }
    return '${minutes.toString().padLeft(2, '0')} min';
  }

  /// Timeline position 0..1 from wall clock (smooth playback at any speed).
  static double playbackFractionFromClock({
    required DateTime wallStart,
    required double startFraction,
    required double speed,
    required Duration routeTotal,
    required int pointCount,
  }) {
    final double clampedSpeed = speed.clamp(0.25, 10.0);
    final int elapsedMs =
        (DateTime.now().difference(wallStart).inMilliseconds * clampedSpeed)
            .round();

    if (routeTotal == Duration.zero || routeTotal.inMilliseconds <= 0) {
      final double spanSec = (pointCount / 8).clamp(8.0, 600.0);
      final double elapsedSec = elapsedMs / 1000.0;
      return (startFraction + elapsedSec / spanSec).clamp(0.0, 1.0);
    }

    final int startMs =
        (routeTotal.inMilliseconds * startFraction.clamp(0.0, 1.0)).round();
    final int nextMs =
        (startMs + elapsedMs).clamp(0, routeTotal.inMilliseconds);
    return nextMs / routeTotal.inMilliseconds;
  }

  static String formatPlaybackClock(Duration elapsed, Duration total) {
    String two(int n) => n.toString().padLeft(2, '0');
    String fmt(Duration d) =>
        '${two(d.inHours)}:${two(d.inMinutes.remainder(60))}:${two(d.inSeconds.remainder(60))}';
    return '${fmt(elapsed)} / ${fmt(total)}';
  }

  static double? averageSpeedKmph(List<HistoryPoint> points, double distanceKm) {
    final Duration? duration = drivingDuration(points);
    if (duration == null || duration.inSeconds <= 0 || distanceKm <= 0) {
      return null;
    }
    final double hours = duration.inSeconds / 3600.0;
    return distanceKm / hours;
  }

  /// Stopped segments: speed below [speedThresholdKmph] for at least [minStopDuration].
  static List<HistoryPoint> stopAnchors({
    required List<HistoryPoint> points,
    double speedThresholdKmph = 3,
    Duration minStopDuration = const Duration(minutes: 3),
    int maxStops = 24,
  }) {
    if (points.length < 2) {
      return <HistoryPoint>[];
    }

    final List<HistoryPoint> stops = <HistoryPoint>[];
    HistoryPoint? stopStart;
    DateTime? stopStartTime;

    void flushStop() {
      if (stopStart == null || stopStartTime == null) {
        return;
      }
      stops.add(stopStart!);
      stopStart = null;
      stopStartTime = null;
    }

    for (final HistoryPoint point in points) {
      final DateTime? time = point.time;
      if (time == null) {
        continue;
      }
      final double speed = point.speed ?? 0;
      if (speed <= speedThresholdKmph) {
        stopStart ??= point;
        stopStartTime ??= time;
        if (time.difference(stopStartTime!) >= minStopDuration &&
            !stops.contains(stopStart)) {
          stops.add(stopStart!);
          if (stops.length >= maxStops) {
            return stops;
          }
        }
      } else {
        flushStop();
      }
    }
    return stops;
  }

  static bool hasTimeTimeline(List<HistoryPoint> points) {
    if (points.length < 2) {
      return false;
    }
    int withTime = 0;
    for (final HistoryPoint p in points) {
      if (p.time != null) {
        withTime++;
      }
    }
    final DateTime? start = points.first.time;
    final DateTime? end = points.last.time;
    if (start == null || end == null || !end.isAfter(start)) {
      return false;
    }
    return withTime >= 2 && withTime >= points.length ~/ 3;
  }

  /// Parallel to [points]: playback fraction 0..1 at each GPS sample.
  static List<double> buildPointTimeFractions(List<HistoryPoint> points) {
    if (points.isEmpty) {
      return <double>[];
    }
    if (points.length == 1) {
      return <double>[0];
    }
    if (!hasTimeTimeline(points)) {
      return List<double>.generate(
        points.length,
        (int i) => i / (points.length - 1),
      );
    }
    final DateTime start = points.first.time!;
    final DateTime end = points.last.time!;
    final int totalMs = end.difference(start).inMilliseconds;
    if (totalMs <= 0) {
      return List<double>.generate(
        points.length,
        (int i) => i / (points.length - 1),
      );
    }
    return points.map((HistoryPoint p) {
      final DateTime? t = p.time;
      if (t == null) {
        return 0.0;
      }
      return (t.difference(start).inMilliseconds / totalMs).clamp(0.0, 1.0);
    }).toList();
  }

  static int _segmentIndexAtFraction(
    List<double> timeFractions,
    double fraction,
  ) {
    if (timeFractions.length < 2) {
      return 0;
    }
    final double t = fraction.clamp(0.0, 1.0);
    if (t <= timeFractions.first) {
      return 0;
    }
    if (t >= timeFractions.last) {
      return timeFractions.length - 2;
    }
    for (int i = 0; i < timeFractions.length - 1; i++) {
      if (t <= timeFractions[i + 1]) {
        return i;
      }
    }
    return timeFractions.length - 2;
  }

  static int indexAtFraction(
    List<HistoryPoint> points,
    double fraction, {
    List<double>? timeFractions,
  }) {
    if (points.isEmpty) {
      return 0;
    }
    if (points.length == 1) {
      return 0;
    }
    final List<double> fracs =
        timeFractions ?? buildPointTimeFractions(points);
    return _segmentIndexAtFraction(fracs, fraction) + 1;
  }

  static HistoryPoint? pointAtFraction(
    List<HistoryPoint> points,
    double fraction, {
    List<double>? timeFractions,
  }) {
    if (points.isEmpty) {
      return null;
    }
    return points[
        indexAtFraction(points, fraction, timeFractions: timeFractions)
            .clamp(0, points.length - 1)];
  }

  static double lerpAngleDegrees(double from, double to, double weight) {
    double delta = ((to - from + 540) % 360) - 180;
    return (from + delta * weight + 360) % 360;
  }

  static HistoryDriveState driveState(HistoryPoint point) {
    if (point.isStop) {
      return HistoryDriveState.stop;
    }
    final double speed = point.speed ?? 0;
    if (speed <= 2) {
      return HistoryDriveState.stop;
    }
    if (speed <= 20) {
      return HistoryDriveState.idle;
    }
    return HistoryDriveState.running;
  }

  static bool pointIsStopped(HistoryPoint point) {
    if (point.isStop) {
      return true;
    }
    final String? type = point.eventType?.toLowerCase();
    if (type != null &&
        (type.contains('stop') ||
            type.contains('park') ||
            type.contains('idle'))) {
      return true;
    }
    return (point.speed ?? 0) <= _stopSpeedKmph;
  }

  static String formatHumanDuration(Duration duration) {
    final int hours = duration.inHours;
    final int minutes = duration.inMinutes.remainder(60);
    final int seconds = duration.inSeconds.remainder(60);
    return '$hours hr $minutes min ${seconds}s';
  }

  static String formatTimelineCardTime(DateTime? value) {
    if (value == null) {
      return '—';
    }
    return _timelineCardFormat.format(value);
  }

  /// Best route order for map markers (time when available, else API order).
  static List<HistoryPoint> orderPointsForRoute(List<HistoryPoint> raw) {
    if (raw.isEmpty) {
      return raw;
    }
    final int withTime = raw.where((HistoryPoint p) => p.time != null).length;
    if (withTime >= raw.length * 0.45) {
      return sortByTime(List<HistoryPoint>.from(raw));
    }
    return List<HistoryPoint>.from(raw);
  }

  /// Fills missing timestamps so stop detection works on polyline-heavy routes.
  static List<HistoryPoint> withInterpolatedTimes(
    List<HistoryPoint> points, {
    DateTime? rangeFrom,
    DateTime? rangeTo,
  }) {
    if (points.isEmpty) {
      return points;
    }
    DateTime? start;
    DateTime? end;
    for (final HistoryPoint p in points) {
      final DateTime? t = p.time;
      if (t == null) {
        continue;
      }
      start ??= t;
      end = t;
    }
    start ??= rangeFrom;
    end ??= rangeTo;
    if (start == null) {
      start = DateTime.now().subtract(Duration(seconds: points.length));
    }
    if (end == null || !end.isAfter(start)) {
      end = start.add(Duration(seconds: math.max(2, points.length)));
    }

    final int n = points.length;
    return List<HistoryPoint>.generate(n, (int i) {
      final HistoryPoint p = points[i];
      if (p.time != null) {
        return p;
      }
      final double w = n <= 1 ? 0.0 : i / (n - 1);
      final int ms = start!.millisecondsSinceEpoch +
          ((end!.millisecondsSinceEpoch - start.millisecondsSinceEpoch) * w)
              .round();
      return HistoryPoint(
        position: p.position,
        time: DateTime.fromMillisecondsSinceEpoch(ms),
        speed: p.speed,
        course: p.course,
        address: p.address,
        eventType: p.eventType,
        isStop: p.isStop,
      );
    });
  }

  static bool _looksLikeStopEvent(HistoryPoint point) {
    if (point.isStop) {
      return true;
    }
    final String? type = point.eventType?.toLowerCase();
    return type != null &&
        (type.contains('stop') ||
            type.contains('park') ||
            type.contains('idle'));
  }

  static List<HistoryStopSession> _stopSessionsFromExplicitEvents(
    List<HistoryPoint> ordered,
    int maxSessions,
  ) {
    final List<HistoryStopSession> sessions = <HistoryStopSession>[];
    for (final HistoryPoint p in ordered) {
      if (!_looksLikeStopEvent(p)) {
        continue;
      }
      final DateTime? arrival = p.time;
      if (arrival == null) {
        continue;
      }
      sessions.add(
        HistoryStopSession(
          index: 0,
          arrival: arrival,
          departure: arrival.add(const Duration(minutes: 1)),
          position: p.position,
          address: p.address,
        ),
      );
      if (sessions.length >= maxSessions) {
        break;
      }
    }
    sessions.sort(
      (HistoryStopSession a, HistoryStopSession b) =>
          a.arrival.compareTo(b.arrival),
    );
    return _dedupeStopSessionsByLocation(sessions, mergeRadiusMeters: 90);
  }

  static List<HistoryStopSession> _routeWaypointStopSessions(
    List<HistoryPoint> ordered, {
    required int maxSessions,
  }) {
    if (ordered.length < 3) {
      return const <HistoryStopSession>[];
    }
    final List<HistoryPoint> inner =
        ordered.sublist(1, ordered.length - 1);
    if (inner.isEmpty) {
      return const <HistoryStopSession>[];
    }

    double pathMeters = 0;
    for (int i = 1; i < ordered.length; i++) {
      pathMeters += LiveRouteService.haversineMeters(
        ordered[i - 1].position,
        ordered[i].position,
      );
    }
    final int target = math.min(
      maxSessions,
      math.max(8, (pathMeters / 4500).ceil()),
    );
    final double stepMeters = pathMeters / (target + 1);

    final List<HistoryStopSession> sessions = <HistoryStopSession>[];
    double walked = 0;
    double nextMark = stepMeters;
    DateTime? routeStart = ordered.first.time;
    DateTime? routeEnd = ordered.last.time;
    routeStart ??= DateTime.now().subtract(const Duration(hours: 1));
    routeEnd ??= routeStart.add(const Duration(hours: 1));

    for (int i = 1; i < ordered.length; i++) {
      final double seg = LiveRouteService.haversineMeters(
        ordered[i - 1].position,
        ordered[i].position,
      );
      walked += seg;
      while (sessions.length < target && walked >= nextMark) {
        final HistoryPoint p = ordered[i];
        final DateTime markTime = DateTime.fromMillisecondsSinceEpoch(
          (routeStart.millisecondsSinceEpoch +
                  (routeEnd.millisecondsSinceEpoch -
                          routeStart.millisecondsSinceEpoch) *
                      (sessions.length + 1) /
                      (target + 1))
              .round(),
        );
        sessions.add(
          HistoryStopSession(
            index: 0,
            arrival: p.time ?? markTime,
            departure: (p.time ?? markTime).add(const Duration(minutes: 1)),
            position: p.position,
            address: p.address,
          ),
        );
        nextMark += stepMeters;
      }
    }

    return _dedupeStopSessionsByLocation(sessions, mergeRadiusMeters: 120);
  }

  static List<HistoryStopSession> _dedupeStopSessionsByLocation(
    List<HistoryStopSession> sessions, {
    required double mergeRadiusMeters,
  }) {
    if (sessions.length < 2) {
      return sessions;
    }
    final List<HistoryStopSession> out = <HistoryStopSession>[];
    for (final HistoryStopSession s in sessions) {
      final bool dup = out.any(
        (HistoryStopSession o) =>
            LiveRouteService.haversineMeters(o.position, s.position) <
            mergeRadiusMeters,
      );
      if (!dup) {
        out.add(s);
      }
    }
    return out;
  }

  static List<HistoryStopSession> _mergeStopSessions(
    List<HistoryStopSession> primary,
    List<HistoryStopSession> secondary,
    int maxSessions,
  ) {
    final List<HistoryStopSession> merged = <HistoryStopSession>[
      ...primary,
      ...secondary,
    ];
    merged.sort(
      (HistoryStopSession a, HistoryStopSession b) =>
          a.arrival.compareTo(b.arrival),
    );
    final List<HistoryStopSession> deduped =
        _dedupeStopSessionsByLocation(merged, mergeRadiusMeters: 100);
    return _capAndRenumber(deduped, maxSessions);
  }

  static List<HistoryStopSession> _capAndRenumber(
    List<HistoryStopSession> sessions,
    int maxSessions,
  ) {
    final List<HistoryStopSession> capped = sessions.length <= maxSessions
        ? sessions
        : _sampleStopSessionsEvenly(sessions, maxSessions);
    return _renumberStopSessions(capped);
  }

  /// Numbered red squares between route start/end (reference playback map).
  static List<HistoryStopSession> buildStopSessionsForMap(
    List<HistoryPoint> raw, {
    Duration minStopDuration = const Duration(minutes: 5),
    int maxSessions = 250,
    DateTime? rangeFrom,
    DateTime? rangeTo,
  }) {
    if (raw.length < 2) {
      return const <HistoryStopSession>[];
    }

    final List<HistoryPoint> ordered = orderPointsForRoute(raw);
    final List<HistoryPoint> timed = withInterpolatedTimes(
      ordered,
      rangeFrom: rangeFrom,
      rangeTo: rangeTo,
    );
    final List<HistoryStopSession> fromEvents =
        _stopSessionsFromExplicitEvents(timed, maxSessions);
    if (fromEvents.length >= 3) {
      return _capAndRenumber(fromEvents, maxSessions);
    }
    final Duration mapMin = minStopDuration < const Duration(minutes: 1)
        ? minStopDuration
        : const Duration(minutes: 1);

    List<HistoryStopSession> sessions = buildStopSessions(
      timed,
      minStopDuration: mapMin,
      maxSessions: maxSessions,
    );

    if (sessions.length < 3) {
      final List<HistoryStopSession> waypoints = _routeWaypointStopSessions(
        timed,
        maxSessions: maxSessions,
      );
      if (waypoints.length > sessions.length) {
        sessions = waypoints;
      }
    }

    if (fromEvents.isNotEmpty) {
      sessions = _mergeStopSessions(fromEvents, sessions, maxSessions);
    }

    return _capAndRenumber(sessions, maxSessions);
  }

  /// Park/stop sessions for map markers and info popups.
  static List<HistoryStopSession> buildStopSessions(
    List<HistoryPoint> raw, {
    Duration minStopDuration = const Duration(minutes: 5),
    int maxSessions = 250,
  }) {
    final List<HistoryPoint> points = sortByTime(
      raw.where((HistoryPoint p) => p.time != null).toList(),
    );
    if (points.length < 2) {
      return const <HistoryStopSession>[];
    }

    final List<HistoryStopSession> sessions = <HistoryStopSession>[];
    int index = 0;
    while (index < points.length) {
      if (!pointIsStopped(points[index])) {
        index++;
        continue;
      }
      int end = index + 1;
      while (end < points.length && pointIsStopped(points[end])) {
        end++;
      }
      final List<HistoryPoint> slice = points.sublist(index, end);
      final DateTime arrival = slice.first.time!;
      final DateTime departure = slice.last.time!;
      final Duration span = departure.difference(arrival);
      if (!departure.isBefore(arrival) && span >= minStopDuration) {
        String? address;
        for (final HistoryPoint p in slice) {
          final String? a = p.address?.trim();
          if (a != null && a.isNotEmpty && a != '-') {
            address = a;
            break;
          }
        }
        sessions.add(
          HistoryStopSession(
            index: 0,
            arrival: arrival,
            departure: departure,
            position: slice.first.position,
            address: address,
          ),
        );
      }
      index = end;
    }

    sessions.sort(
      (HistoryStopSession a, HistoryStopSession b) =>
          a.arrival.compareTo(b.arrival),
    );
    final List<HistoryStopSession> capped = sessions.length <= maxSessions
        ? sessions
        : _sampleStopSessionsEvenly(sessions, maxSessions);
    return _renumberStopSessions(capped);
  }

  static List<HistoryStopSession> _renumberStopSessions(
    List<HistoryStopSession> sessions,
  ) {
    final List<HistoryStopSession> out = <HistoryStopSession>[];
    for (int i = 0; i < sessions.length; i++) {
      final HistoryStopSession s = sessions[i];
      out.add(
        HistoryStopSession(
          index: i + 1,
          arrival: s.arrival,
          departure: s.departure,
          position: s.position,
          address: s.address,
        ),
      );
    }
    return out;
  }

  /// Keeps stops spread across the whole date range when capping map markers.
  static List<HistoryStopSession> _sampleStopSessionsEvenly(
    List<HistoryStopSession> sessions,
    int max,
  ) {
    if (sessions.length <= max) {
      return sessions;
    }
    final List<HistoryStopSession> out = <HistoryStopSession>[];
    for (int i = 0; i < max; i++) {
      final int idx =
          ((i + 0.5) * sessions.length / max).floor().clamp(
            0,
            sessions.length - 1,
          );
      out.add(sessions[idx]);
    }
    return out;
  }

  static HistoryStopSession? nearestStopSession(
    LatLng tap,
    List<HistoryStopSession> sessions, {
    double maxMeters = 220,
  }) {
    HistoryStopSession? best;
    double bestM = maxMeters;
    for (final HistoryStopSession session in sessions) {
      final double m = LiveRouteService.haversineMeters(tap, session.position);
      if (m <= bestM) {
        bestM = m;
        best = session;
      }
    }
    return best;
  }

  /// Trip / stop cards for history playback list (newest first).
  static List<HistoryTimelineSegment> buildTimelineSegments(
    List<HistoryPoint> raw, {
    Duration minStopDuration = _minStopSegment,
  }) {
    final List<HistoryPoint> points = sortByTime(
      raw.where((HistoryPoint p) => p.time != null).toList(),
    );
    if (points.length < 2) {
      return const <HistoryTimelineSegment>[];
    }

    final List<HistoryTimelineSegment> segments = <HistoryTimelineSegment>[];
    int index = 0;
    while (index < points.length) {
      final bool stopped = pointIsStopped(points[index]);
      int end = index + 1;
      while (end < points.length &&
          pointIsStopped(points[end]) == stopped) {
        end++;
      }
      final List<HistoryPoint> slice = points.sublist(index, end);
      final DateTime start = slice.first.time!;
      final DateTime endTime = slice.last.time!;
      final Duration span = endTime.difference(start);
      if (!endTime.isBefore(start)) {
        if (stopped) {
          if (span >= minStopDuration) {
            segments.add(
              HistoryTimelineSegment(
                kind: HistoryTimelineKind.stop,
                start: start,
                end: endTime,
              ),
            );
          }
        } else if (span >= _minTripSegment || slice.length >= 3) {
          double maxSpeed = 0;
          for (final HistoryPoint p in slice) {
            final double s = p.speed ?? 0;
            if (s > maxSpeed) {
              maxSpeed = s;
            }
          }
          segments.add(
            HistoryTimelineSegment(
              kind: HistoryTimelineKind.trip,
              start: start,
              end: endTime,
              distanceKm: totalDistanceKm(slice),
              maxSpeedKmph: maxSpeed,
            ),
          );
        }
      }
      index = end;
    }

    segments.sort(
      (HistoryTimelineSegment a, HistoryTimelineSegment b) =>
          b.start.compareTo(a.start),
    );
    return segments;
  }

  /// Smooth arrow position + heading between GPS samples ([fraction] = timeline 0..1).
  static HistoryPlaybackSample sampleAtFraction(
    List<HistoryPoint> points,
    double fraction, {
    List<double>? timeFractions,
  }) {
    if (points.isEmpty) {
      return const HistoryPlaybackSample(
        position: LatLng(0, 0),
        bearing: 0,
        index: 0,
      );
    }
    if (points.length == 1) {
      return HistoryPlaybackSample(
        position: points.first.position,
        bearing: points.first.course ?? 0,
        index: 0,
        point: points.first,
      );
    }

    final List<double> fracs =
        timeFractions ?? buildPointTimeFractions(points);
    final double t = fraction.clamp(0.0, 1.0);
    final int i0 = _segmentIndexAtFraction(fracs, t);
    final int i1 = math.min(i0 + 1, fracs.length - 1);
    final double t0 = fracs[i0];
    final double t1 = fracs[i1];
    final double w = t1 > t0 ? ((t - t0) / (t1 - t0)).clamp(0.0, 1.0) : 0.0;

    final LatLng a = points[i0].position;
    final LatLng b = points[i1].position;
    final LatLng position = LatLng(
      a.latitude + (b.latitude - a.latitude) * w,
      a.longitude + (b.longitude - a.longitude) * w,
    );

    final double segBearing = _bearingDegrees(a, b);
    final double? c0 = points[i0].course;
    final double? c1 = points[i1].course;
    final double bearing = c0 != null && c1 != null
        ? lerpAngleDegrees(c0, c1, w)
        : (c0 ?? c1 ?? segBearing);

    return HistoryPlaybackSample(
      position: position,
      bearing: bearing,
      index: i1,
      point: w >= 0.5 ? points[i1] : points[i0],
    );
  }

  /// Full GPS polyline from start through [fraction] (growing playback line).
  static List<LatLng> polylineUntilFraction(
    List<HistoryPoint> points,
    double fraction, {
    List<double>? timeFractions,
  }) {
    if (points.isEmpty) {
      return <LatLng>[];
    }
    if (points.length == 1) {
      return <LatLng>[points.first.position];
    }
    final List<double> fracs =
        timeFractions ?? buildPointTimeFractions(points);
    final double t = fraction.clamp(0.0, 1.0);
    final HistoryPlaybackSample sample = sampleAtFraction(
      points,
      fraction,
      timeFractions: fracs,
    );

    int endIdx = 0;
    for (int i = 0; i < fracs.length; i++) {
      if (fracs[i] <= t + 1e-9) {
        endIdx = i;
      }
    }
    endIdx = endIdx.clamp(0, points.length - 1);

    final List<LatLng> slice = points
        .sublist(0, endIdx + 1)
        .map((HistoryPoint p) => p.position)
        .toList();
    if (slice.isEmpty ||
        _distanceMeters(slice.last, sample.position) > 0.5) {
      slice.add(sample.position);
    }
    return slice.length > _maxPolylineVertices
        ? simplifyForMap(slice)
        : slice;
  }

  /// Circles at stop / idle / running segment changes (not every GPS tick).
  static Set<Circle> eventCircles(List<HistoryPoint> points) {
    final Set<Circle> circles = <Circle>{};
    if (points.length < 2) {
      return circles;
    }

    HistoryDriveState? prev;
    int circleId = 0;
    for (int i = 0; i < points.length; i++) {
      final HistoryDriveState state = driveState(points[i]);
      final bool stateChange = prev == null || state != prev;
      prev = state;

      if (!stateChange && state != HistoryDriveState.stop) {
        continue;
      }
      if (circleId >= 80) {
        break;
      }

      Color fill;
      double radius;
      switch (state) {
        case HistoryDriveState.stop:
          fill = const Color(0xCCFF5252);
          radius = 14;
        case HistoryDriveState.idle:
          fill = const Color(0xCCFFC107);
          radius = 11;
        case HistoryDriveState.running:
          fill = const Color(0xCC4CAF50);
          radius = 9;
      }

      circles.add(
        Circle(
          circleId: CircleId('hist_evt_$circleId'),
          center: points[i].position,
          radius: radius,
          fillColor: fill,
          strokeColor: const Color(0xFFFFFFFF),
          strokeWidth: 1,
          zIndex: 1,
        ),
      );
      circleId++;
    }
    return circles;
  }

  static double _bearingDegrees(LatLng from, LatLng to) {
    final double lat1 = from.latitude * math.pi / 180;
    final double lat2 = to.latitude * math.pi / 180;
    final double dLng = (to.longitude - from.longitude) * math.pi / 180;
    final double y = math.sin(dLng) * math.cos(lat2);
    final double x = math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLng);
    return (math.atan2(y, x) * 180 / math.pi + 360) % 360;
  }

  static double _distanceMeters(LatLng a, LatLng b) {
    return LiveRouteService.haversineMeters(a, b);
  }

  static LatLngBounds? boundsFor(List<LatLng> points) {
    if (points.isEmpty) {
      return null;
    }
    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;
    for (final LatLng p in points) {
      minLat = minLat < p.latitude ? minLat : p.latitude;
      maxLat = maxLat > p.latitude ? maxLat : p.latitude;
      minLng = minLng < p.longitude ? minLng : p.longitude;
      maxLng = maxLng > p.longitude ? maxLng : p.longitude;
    }
    const double pad = 0.002;
    if ((maxLat - minLat).abs() < pad) {
      minLat -= pad;
      maxLat += pad;
    }
    if ((maxLng - minLng).abs() < pad) {
      minLng -= pad;
      maxLng += pad;
    }
    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }
}
