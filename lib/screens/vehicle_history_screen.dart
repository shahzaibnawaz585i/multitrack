import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../l10n/app_l10n.dart';
import '../services/general_settings_controller.dart';
import '../services/history_service.dart';
import '../services/vehicle_detail_api_service.dart';
import '../services/vehicle_service.dart';
import '../models/vehicle_model.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../theme/app_theme_tokens.dart';
import '../utils/history_route_utils.dart';
import '../utils/report_period.dart';
import '../services/vehicle_device_edit_service.dart';
import '../widgets/history_map.dart';
import '../widgets/history_playback_settings_dialog.dart';
import '../widgets/history_stop_info_card.dart';
import 'notification_filter_screen.dart';

class VehicleHistoryScreen extends StatefulWidget {
  const VehicleHistoryScreen({
    super.key,
    this.deviceId,
    required this.name,
    required this.accentColor,
    required this.fallbackLocation,
    this.onClose,
    this.speedLimitKmph,
    this.isTabActive = true,
  });

  final int? deviceId;
  final String name;
  final Color accentColor;
  final String fallbackLocation;
  final double? speedLimitKmph;
  final bool isTabActive;

  /// When embedded in vehicle detail tabs, returns to Track instead of popping route.
  final VoidCallback? onClose;

  @override
  State<VehicleHistoryScreen> createState() => _VehicleHistoryScreenState();
}

class _VehicleHistoryScreenState extends State<VehicleHistoryScreen> {
  bool _historyLoading = false;
  bool _historyLoaded = false;
  bool _historyEmptyDialogDismissed = false;
  String? _historyError;
  HistoryRoute _historyRoute = const HistoryRoute(points: <HistoryPoint>[]);
  String _historyPeriod = 'today';
  DateTime _historyFrom = ReportPeriod.startOfDay(DateTime.now());
  DateTime _historyTo = DateTime.now();
  Timer? _historyPlaybackTimer;
  double _historyPlaybackSpeed = 1.0;
  DateTime? _historyPlayWallClockStart;
  double _historyPlayRouteFractionStart = 0;
  final ValueNotifier<double> _historySliderValue = ValueNotifier<double>(0.0);
  final ValueNotifier<bool> _isHistoryPlaying = ValueNotifier<bool>(false);
  HistoryStopSession? _selectedStop;
  final ValueNotifier<Offset?> _stopPopupScreen = ValueNotifier<Offset?>(null);
  List<HistoryStopSession> _stopSessions = const <HistoryStopSession>[];
  List<HistoryTimelineSegment> _timelineSegments = const <HistoryTimelineSegment>[];
  int _stoppageMinutes = 5;
  late int _overspeedLimitKmph;
  final GlobalKey<HistoryMapState> _historyMapKey = GlobalKey<HistoryMapState>();
  int _historyLoadSeq = 0;
  String? _loadedHistoryRangeKey;
  bool _screenDisposed = false;

  void _safeSetState(VoidCallback fn) {
    if (_screenDisposed || !mounted) {
      return;
    }
    setState(fn);
  }

  @override
  void initState() {
    super.initState();
    _overspeedLimitKmph = _initialOverspeedKmph();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_screenDisposed || !mounted) {
        return;
      }
      _stoppageMinutes =
          context.read<GeneralSettingsController>().historyStoppageMinutes;
      _refreshHistoryRangeForCurrentPeriod();
      _loadHistory();
    });
  }

  @override
  void dispose() {
    _screenDisposed = true;
    _historyLoadSeq++;
    _historyPlaybackTimer?.cancel();
    _historyPlaybackTimer = null;
    _historyPlayWallClockStart = null;
    _historySliderValue.dispose();
    _isHistoryPlaying.dispose();
    _stopPopupScreen.dispose();
    super.dispose();
  }

  void _dismissStopPopup() {
    _stopPopupScreen.value = null;
    _safeSetState(() => _selectedStop = null);
  }

  HistoryRoute _historyRouteForDisplay(HistoryRoute route) {
    if (!context.read<GeneralSettingsController>().filterHistoryFluctuation ||
        route.points.isEmpty) {
      return route;
    }
    return HistoryRoute(
      points: HistoryRouteUtils.dedupePoints(route.points),
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
      rangeFrom: route.rangeFrom,
      rangeTo: route.rangeTo,
      itemCount: route.itemCount,
      errorMessage: route.errorMessage,
    );
  }

  int _initialOverspeedKmph() {
    final double? fromWidget = widget.speedLimitKmph;
    if (fromWidget != null && fromWidget > 0) {
      return fromWidget.round();
    }
    return 80;
  }

  Duration get _minStopDuration => Duration(minutes: _stoppageMinutes);

  String _historyRangeKey() {
    return '${_historyFrom.millisecondsSinceEpoch}|${_historyTo.millisecondsSinceEpoch}';
  }

  void _refreshHistoryRangeForCurrentPeriod() {
    if (_historyPeriod == 'custom') {
      return;
    }
    final ({DateTime from, DateTime to}) range = ReportPeriod.historyRangeFor(
      _historyPeriod,
      DateTime.now(),
    );
    _historyFrom = range.from;
    _historyTo = range.to;
  }

  Duration _historyFetchTimeout() {
    final int days = _historyTo.difference(_historyFrom).inDays;
    if (days <= 1) {
      return const Duration(seconds: 35);
    }
    if (days <= 7) {
      return const Duration(seconds: 75);
    }
    return const Duration(seconds: 150);
  }

  void _prepareForHistoryReload() {
    _stopHistoryPlayback();
    _loadedHistoryRangeKey = null;
    _historyError = null;
    _stopPopupScreen.value = null;
    _selectedStop = null;
  }

  HistoryRoute _clipRouteToSelectedRange(HistoryRoute route) {
    if (route.points.isEmpty) {
      return route;
    }
    final DateTime from = _historyFrom;
    final DateTime to = _historyTo;
    final List<HistoryPoint> timed = HistoryRouteUtils.withInterpolatedTimes(
      route.points,
      rangeFrom: route.rangeFrom ?? from,
      rangeTo: route.rangeTo ?? to,
    );
    final List<HistoryPoint> inRange = timed
        .where(
          (HistoryPoint p) =>
              p.time != null && ReportPeriod.contains(p.time!, from, to),
        )
        .toList();
    if (inRange.length >= 2) {
      if (timed.length >= 3 &&
          inRange.length <
              (timed.length * 0.08).ceil().clamp(2, timed.length)) {
        return route;
      }
      final double km = HistoryRouteUtils.totalDistanceKm(inRange);
      final Duration? span = HistoryRouteUtils.drivingDuration(inRange);
      final String? moveLabel = span != null
          ? HistoryRouteUtils.formatDuration(span)
          : route.moveDurationLabel;
      double? topKmph;
      for (final HistoryPoint p in inRange) {
        final double? s = p.speed;
        if (s != null && (topKmph == null || s > topKmph)) {
          topKmph = s;
        }
      }
      return HistoryRoute(
        points: inRange,
        distanceKm: km,
        durationLabel: moveLabel,
        avgSpeed: HistoryRouteUtils.averageSpeedKmph(inRange, km) ?? route.avgSpeed,
        topSpeedKmph: topKmph ?? route.topSpeedKmph,
        moveDurationLabel: moveLabel,
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
        itemCount: inRange.length,
        errorMessage: route.errorMessage,
      );
    }
    return route;
  }

  HistoryRoute _routePreparedForPlayback(HistoryRoute route) {
    final HistoryRoute base = _historyRouteForDisplay(
      _clipRouteToSelectedRange(route),
    );
    if (base.points.isEmpty) {
      return base;
    }
    final List<HistoryPoint> timed = HistoryRouteUtils.withInterpolatedTimes(
      base.points,
      rangeFrom: base.rangeFrom ?? _historyFrom,
      rangeTo: base.rangeTo ?? _historyTo,
    );
    return HistoryRoute(
      points: timed,
      distanceKm: base.distanceKm,
      durationLabel: base.durationLabel,
      avgSpeed: base.avgSpeed,
      topSpeedKmph: base.topSpeedKmph,
      moveDurationLabel: base.moveDurationLabel,
      stopDurationLabel: base.stopDurationLabel,
      fuelConsumption: base.fuelConsumption,
      fuelCost: base.fuelCost,
      engineHours: base.engineHours,
      idleDurationLabel: base.idleDurationLabel,
      overspeedCount: base.overspeedCount,
      avgFuelMileage: base.avgFuelMileage,
      engineWorkCost: base.engineWorkCost,
      odometerKm: base.odometerKm,
      rangeFrom: base.rangeFrom ?? _historyFrom,
      rangeTo: base.rangeTo ?? _historyTo,
      itemCount: base.itemCount,
      errorMessage: base.errorMessage,
    );
  }

  void _rebuildDerivedHistoryDataFor(HistoryRoute route) {
    final Duration minStop = _minStopDuration;
    _stopSessions = HistoryRouteUtils.buildStopSessionsForMap(
      route.points,
      minStopDuration: minStop,
      rangeFrom: route.rangeFrom ?? _historyFrom,
      rangeTo: route.rangeTo ?? _historyTo,
    );
    final List<HistoryPoint> timed = HistoryRouteUtils.withInterpolatedTimes(
      route.points,
      rangeFrom: route.rangeFrom ?? _historyFrom,
      rangeTo: route.rangeTo ?? _historyTo,
    );
    _timelineSegments = HistoryRouteUtils.buildTimelineSegments(
      timed,
      minStopDuration: minStop,
    );
  }

  HistoryRoute? _routeFromCachedDeviceTail({
    required int deviceId,
    required DateTime from,
    required DateTime to,
  }) {
    final VehicleModel? device = VehicleService.findCachedDevice(deviceId);
    if (device == null || device.tail.length < 2) {
      return null;
    }
    final List<HistoryPoint> raw = device.tail
        .map(
          (VehicleTrackPoint t) => HistoryPoint(
            position: LatLng(t.latitude, t.longitude),
          ),
        )
        .toList();
    final List<HistoryPoint> timed = HistoryRouteUtils.withInterpolatedTimes(
      raw,
      rangeFrom: from,
      rangeTo: to,
    );
    if (timed.length < 2) {
      return null;
    }
    final double? km = double.tryParse(
      device.distance.replaceAll(RegExp(r'[^0-9.]'), ''),
    );
    return HistoryRoute(
      points: timed,
      distanceKm: km,
      durationLabel: device.runningDuration,
      avgSpeed: double.tryParse(device.avgSpeed.replaceAll(RegExp(r'[^0-9.]'), '')),
      topSpeedKmph: double.tryParse(device.maxSpeed.replaceAll(RegExp(r'[^0-9.]'), '')),
      moveDurationLabel: device.runningDuration,
      stopDurationLabel: device.stopDuration,
      rangeFrom: from,
      rangeTo: to,
    );
  }

  void _applyHistoryRoute(
    HistoryRoute route, {
    required bool stillLoading,
    required int loadSeq,
  }) {
    if (_screenDisposed || !mounted || loadSeq != _historyLoadSeq) {
      return;
    }
    final HistoryRoute displayRoute = _routePreparedForPlayback(route);
    _rebuildDerivedHistoryDataFor(displayRoute);
    _safeSetState(() {
      _historyLoading = stillLoading;
      _historyLoaded = true;
      _loadedHistoryRangeKey = _historyRangeKey();
      _historyRoute = displayRoute;
      _historyError = route.errorMessage;
      _stopPopupScreen.value = null;
      _selectedStop = null;
      if (!stillLoading) {
        _historySliderValue.value = 0;
      }
    });
  }

  Future<void> _loadHistory({bool force = false}) async {
    final int? deviceId = widget.deviceId;
    if (deviceId == null) {
      _safeSetState(() {
        _historyError = context.tr('No device selected');
        _historyLoaded = true;
        _historyRoute = const HistoryRoute(points: <HistoryPoint>[]);
        _historyLoading = false;
      });
      return;
    }

    _refreshHistoryRangeForCurrentPeriod();
    final int loadSeq = _historyLoadSeq;
    final String rangeKey = _historyRangeKey();
    final DateTime fetchFrom = _historyFrom;
    final DateTime fetchTo = _historyTo;

    if (!force &&
        _historyLoaded &&
        _historyError == null &&
        !_historyRoute.isEmpty &&
        _loadedHistoryRangeKey == rangeKey) {
      return;
    }

    if (!force && _historyLoading) {
      return;
    }

    if (!force) {
      try {
        final HistoryRoute cached = await VehicleDetailApiService.loadHistory(
          deviceId: deviceId,
          from: fetchFrom,
          to: fetchTo,
          forceRefresh: false,
        );
        if (_screenDisposed || !mounted || loadSeq != _historyLoadSeq) {
          return;
        }
        if (!cached.isEmpty) {
          _stopHistoryPlayback();
          _applyHistoryRoute(
            cached,
            stillLoading: false,
            loadSeq: loadSeq,
          );
          return;
        }
      } catch (_) {
        if (_screenDisposed || !mounted) {
          return;
        }
      }
    }

    if (_screenDisposed || !mounted) {
      return;
    }

    _stopHistoryPlayback();
    _safeSetState(() {
      _historyLoading = true;
      _historyError = null;
      _historyLoaded = false;
    });

    await _fetchHistoryFromNetwork(
      deviceId: deviceId,
      force: force,
      loadSeq: loadSeq,
      fetchFrom: fetchFrom,
      fetchTo: fetchTo,
    );
  }

  Future<void> _fetchHistoryFromNetwork({
    required int deviceId,
    required bool force,
    required int loadSeq,
    required DateTime fetchFrom,
    required DateTime fetchTo,
  }) async {
    try {
      HistoryRoute route = await VehicleDetailApiService.loadHistory(
        deviceId: deviceId,
        from: fetchFrom,
        to: fetchTo,
        forceRefresh: force,
      ).timeout(_historyFetchTimeout());
      if (_screenDisposed || !mounted || loadSeq != _historyLoadSeq) {
        return;
      }
      if (route.isEmpty && loadSeq == _historyLoadSeq) {
        final HistoryRoute retry = await VehicleDetailApiService.loadHistory(
          deviceId: deviceId,
          from: fetchFrom,
          to: fetchTo,
          forceRefresh: true,
        );
        if (!retry.isEmpty) {
          route = retry;
        }
      }
      if (route.isEmpty &&
          (_historyPeriod == 'today' || _historyPeriod == '1h') &&
          loadSeq == _historyLoadSeq) {
        final HistoryRoute? tailRoute = _routeFromCachedDeviceTail(
          deviceId: deviceId,
          from: fetchFrom,
          to: fetchTo,
        );
        if (tailRoute != null) {
          route = tailRoute;
        }
      }
      _applyHistoryRoute(
        route,
        stillLoading: false,
        loadSeq: loadSeq,
      );
    } catch (e) {
      if (_screenDisposed || !mounted) {
        return;
      }
      if (loadSeq != _historyLoadSeq) {
        return;
      }
      _safeSetState(() {
        _historyLoading = false;
        _historyLoaded = true;
        _loadedHistoryRangeKey = _historyRangeKey();
        if (_historyRoute.isEmpty) {
          _historyRoute = const HistoryRoute(points: <HistoryPoint>[]);
        }
        _historyError = e.toString();
      });
    } finally {
      if (!_screenDisposed &&
          mounted &&
          loadSeq == _historyLoadSeq &&
          _historyLoading) {
        _safeSetState(() => _historyLoading = false);
      }
    }
  }

  void _applyHistoryPeriod(String period) {
    if (period == _historyPeriod &&
        _historyLoaded &&
        !_historyLoading &&
        !_historyRoute.isEmpty &&
        period != 'today' &&
        period != '1h') {
      return;
    }
    if (period == 'custom') {
      _pickCustomHistoryRange();
      return;
    }
    final DateTime now = DateTime.now();
    final ({DateTime from, DateTime to}) range = ReportPeriod.historyRangeFor(
      period,
      now,
    );
    _safeSetState(() {
      _historyPeriod = period;
      _historyFrom = range.from;
      _historyTo = range.to;
      _historyLoaded = false;
      _historyEmptyDialogDismissed = false;
      _prepareForHistoryReload();
      _historyLoadSeq++;
    });
    _loadHistory(force: true);
  }

  Future<void> _pickCustomHistoryRange() async {
    final DateTime now = DateTime.now();
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now,
      initialDateRange: DateTimeRange(
        start: _historyFrom,
        end: _historyTo.isAfter(now) ? now : _historyTo,
      ),
    );
    if (picked == null || _screenDisposed || !mounted) {
      return;
    }
    final DateTime to = picked.end.isAfter(now)
        ? now
        : ReportPeriod.endOfDay(picked.end);
    _safeSetState(() {
      _historyPeriod = 'custom';
      _historyFrom = ReportPeriod.startOfDay(picked.start);
      _historyTo = to;
      _historyLoaded = false;
      _historyEmptyDialogDismissed = false;
      _prepareForHistoryReload();
      _historyLoadSeq++;
    });
    _loadHistory(force: true);
  }

  String _historyPeriodLabel() {
    switch (_historyPeriod) {
      case '1h':
        return context.tr('1 Hour');
      case 'yesterday':
        return context.tr('Yesterday');
      case 'week':
        return context.tr('Week');
      case 'month':
        return context.tr('Month');
      case 'custom':
        return context.tr('Custom');
      case 'today':
      default:
        return context.tr('Today');
    }
  }

  Duration _historyPlaybackTotalDuration() {
    final List<HistoryPoint> points = _historyRoute.points;
    if (points.length < 2) {
      return Duration.zero;
    }
    final DateTime? start = points.first.time;
    final DateTime? end = points.last.time;
    if (start == null || end == null || !end.isAfter(start)) {
      return Duration(seconds: points.length);
    }
    return end.difference(start);
  }

  Duration _historyPlaybackElapsed() {
    final Duration total = _historyPlaybackTotalDuration();
    if (total == Duration.zero) {
      return Duration.zero;
    }
    return Duration(
      milliseconds: (total.inMilliseconds * _historySliderValue.value).round(),
    );
  }

  void _stopHistoryPlayback() {
    _historyPlaybackTimer?.cancel();
    _historyPlaybackTimer = null;
    _historyPlayWallClockStart = null;
    _isHistoryPlaying.value = false;
  }

  void _toggleHistoryPlayback() {
    if (_historyLoading) {
      return;
    }
    if (_historyRoute.points.length < 2) {
      if (_historyLoaded && !_screenDisposed && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.tr('No history route for playback. Try another period.'),
            ),
          ),
        );
        if (_historyError != null || _historyRoute.isEmpty) {
          _historyLoadSeq++;
          _loadHistory(force: true);
        }
      }
      return;
    }
    if (_isHistoryPlaying.value) {
      _stopHistoryPlayback();
      return;
    }
    if (_historySliderValue.value >= 1.0) {
      _historySliderValue.value = 0;
    }
    _isHistoryPlaying.value = true;
    _historyPlayRouteFractionStart = _historySliderValue.value;
    _historyPlayWallClockStart = DateTime.now();
    _historyPlaybackTimer?.cancel();
    _historyPlaybackTimer = Timer.periodic(
      const Duration(milliseconds: 80),
      (_) => _tickHistoryPlayback(),
    );
    _safeSetState(() {});
  }

  void _tickHistoryPlayback() {
    if (_screenDisposed || !mounted) {
      _historyPlaybackTimer?.cancel();
      _historyPlaybackTimer = null;
      return;
    }
    final List<HistoryPoint> points = _historyRoute.points;
    if (points.length < 2) {
      _stopHistoryPlayback();
      return;
    }
    final DateTime wallStart = _historyPlayWallClockStart ?? DateTime.now();
    final Duration total = _historyPlaybackTotalDuration();
    final double fraction = HistoryRouteUtils.playbackFractionFromClock(
      wallStart: wallStart,
      startFraction: _historyPlayRouteFractionStart,
      speed: _historyPlaybackSpeed,
      routeTotal: total,
      pointCount: points.length,
    );
    _historySliderValue.value = fraction;
    if (fraction >= 1.0) {
      _stopHistoryPlayback();
    }
  }

  void _setHistoryPlaybackSpeed(double speed) {
    final double parsed = speed.clamp(0.5, 10.0);
    if (_isHistoryPlaying.value) {
      _historyPlayRouteFractionStart = _historySliderValue.value;
      _historyPlayWallClockStart = DateTime.now();
    }
    _safeSetState(() => _historyPlaybackSpeed = parsed);
  }

  void _restartHistoryPlayback() {
    _stopHistoryPlayback();
    _historySliderValue.value = 0;
  }

  void _onStopSelected(HistoryStopSession session) {
    _seekToStopSession(session);
    _safeSetState(() => _selectedStop = session);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _historyMapKey.currentState?.refreshStopPopupAnchor();
    });
  }

  Widget _buildMapStopPopup({
    required Color accentColor,
  }) {
    return ValueListenableBuilder<Offset?>(
      valueListenable: _stopPopupScreen,
      builder: (BuildContext context, Offset? anchor, _) {
        final HistoryStopSession? session = _selectedStop;
        if (session == null || anchor == null) {
          return const SizedBox.shrink();
        }
        final Size screen = MediaQuery.sizeOf(context);
        final double topInset = MediaQuery.paddingOf(context).top;
        const double cardWidth = 300;
        const double cardHeight = 172;
        final double left = (anchor.dx - cardWidth / 2).clamp(
          10.0,
          screen.width - cardWidth - 10,
        );
        final double maxTop = (screen.height * 0.64) - cardHeight;
        final double top = (anchor.dy - cardHeight - 12).clamp(
          topInset + 88,
          maxTop > topInset + 88 ? maxTop : topInset + 88,
        );
        return Positioned(
          left: left,
          top: top,
          width: cardWidth,
          child: IgnorePointer(
            ignoring: false,
            child: Material(
              type: MaterialType.transparency,
              elevation: 16,
              shadowColor: Colors.black45,
              borderRadius: BorderRadius.circular(14),
              child: HistoryStopInfoCard(
                session: session,
                accentColor: accentColor,
                fallbackAddress: widget.fallbackLocation,
                onClose: _dismissStopPopup,
              ),
            ),
          ),
        );
      },
    );
  }

  void _seekToStopSession(HistoryStopSession session) {
    final List<HistoryPoint> points = _historyRoute.points;
    if (points.isEmpty) {
      return;
    }
    final DateTime? routeStart = points.first.time;
    final DateTime? routeEnd = points.last.time;
    if (routeStart == null || routeEnd == null) {
      return;
    }
    final Duration total = routeEnd.difference(routeStart);
    if (total.inMilliseconds <= 0) {
      return;
    }
    final Duration offset = session.arrival.difference(routeStart);
    _stopHistoryPlayback();
    _historySliderValue.value =
        (offset.inMilliseconds / total.inMilliseconds).clamp(0.0, 1.0);
  }

  Future<void> _openHistorySettings() async {
    final result = await showHistoryPlaybackSettingsDialog(
      context: context,
      accentColor: widget.accentColor,
      initialStoppageMinutes: _stoppageMinutes,
      initialOverspeedKmph: _overspeedLimitKmph,
    );
    if (result == null || _screenDisposed || !mounted) {
      return;
    }
    await context
        .read<GeneralSettingsController>()
        .setHistoryStoppageMinutes(result.stoppageMinutes);
    _safeSetState(() {
      _stoppageMinutes = result.stoppageMinutes;
      _overspeedLimitKmph = result.overspeedKmph;
    });
    _rebuildDerivedHistoryDataFor(_historyRoute);
    _safeSetState(() {});

    final int? deviceId = widget.deviceId;
    if (deviceId != null && result.overspeedKmph > 0) {
      try {
        await VehicleDeviceEditService.updateSpeedLimit(
          deviceId: deviceId,
          limitKmph: result.overspeedKmph.toDouble(),
        );
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString())),
          );
        }
      }
    }
  }

  double _speedAtPlaybackFraction(double fraction) {
    final List<HistoryPoint> points = _historyRoute.points;
    if (points.isEmpty) {
      return 0;
    }
    final HistoryPoint? point = HistoryRouteUtils.pointAtFraction(
      points,
      fraction,
    );
    return point?.speed ?? _historyRoute.avgSpeed ?? 0;
  }

  void _seekToSegment(HistoryTimelineSegment segment) {
    final List<HistoryPoint> points = _historyRoute.points;
    if (points.isEmpty || !segment.start.isBefore(segment.end)) {
      return;
    }
    final DateTime? routeStart = points.first.time;
    final DateTime? routeEnd = points.last.time;
    if (routeStart == null || routeEnd == null) {
      return;
    }
    final Duration total = routeEnd.difference(routeStart);
    if (total.inMilliseconds <= 0) {
      return;
    }
    final Duration offset = segment.start.difference(routeStart);
    _stopHistoryPlayback();
    _historySliderValue.value =
        (offset.inMilliseconds / total.inMilliseconds).clamp(0.0, 1.0);
  }

  String _historyPanelDate(DateTime value) {
    return DateFormat('dd MMM yyyy').format(value);
  }

  Color _historySegmentCardColor({required bool isTrip}) {
    final Color base = isTrip
        ? const Color(0xFFE8F5E9)
        : const Color(0xFFFFEBEE);
    return base.withValues(alpha: 0.86);
  }

  String _historyDurationDisplay() {
    final String raw =
        _historyRoute.moveDurationLabel ??
        _historyRoute.durationLabel ??
        '00:00:00';
    return raw
        .replaceAll(RegExp(r'\s*Hrs\s*$', caseSensitive: false), '')
        .trim();
  }

  String _historyLocationDisplay() {
    if (_historyRoute.points.isEmpty) {
      return widget.fallbackLocation.trim();
    }
    for (final HistoryPoint p in _historyRoute.points.reversed) {
      final String? addr = p.address?.trim();
      if (addr != null && addr.isNotEmpty && addr != '-') {
        return addr;
      }
    }
    return widget.fallbackLocation.trim();
  }

  String _shortVehicleBadgeLabel(String label) {
    final String trimmed = label.trim();
    if (trimmed.length <= 8) {
      return trimmed;
    }
    return '${trimmed.substring(0, 8)}..';
  }

  String _locationAtPlaybackFraction(double fraction) {
    final List<HistoryPoint> points = _historyRoute.points;
    if (points.isEmpty) {
      return widget.fallbackLocation.trim();
    }
    final HistoryPoint? point = HistoryRouteUtils.pointAtFraction(
      points,
      fraction,
    );
    final String? addr = point?.address?.trim();
    if (addr != null && addr.isNotEmpty && addr != '-') {
      return addr;
    }
    return _historyLocationDisplay();
  }

  Widget _playbackCardDivider() {
    return Divider(
      height: 1,
      thickness: 1,
      color: Colors.grey.shade400.withValues(alpha: 0.5),
    );
  }

  String _playbackTimeLabel() {
    final Duration total = _historyPlaybackTotalDuration();
    if (total == Duration.zero) {
      return '00:00:00 / 00:00:00';
    }
    final Duration elapsed = Duration(
      milliseconds: (total.inMilliseconds * _historySliderValue.value).round(),
    );
    String fmt(Duration d) {
      final int h = d.inHours;
      final int m = d.inMinutes.remainder(60);
      final int s = d.inSeconds.remainder(60);
      return '${h.toString().padLeft(2, '0')}:'
          '${m.toString().padLeft(2, '0')}:'
          '${s.toString().padLeft(2, '0')}';
    }

    return '${fmt(elapsed)} / ${fmt(total)}';
  }

  @override
  Widget build(BuildContext context) {
    final Color accentColor = widget.accentColor;
    final Color textColor = context.textColor;
    final GeneralSettingsController generalSettings = context
        .watch<GeneralSettingsController>();
    final Color historyRouteColor = generalSettings.historyRouteColor(
      accentColor,
    );
    final String vehicleLabel = widget.name.isNotEmpty
        ? widget.name
        : (widget.deviceId?.toString() ?? '—');
    final String fallbackSpeedStat = _historyRoute.points.isEmpty
        ? '0 ${context.tr('kmph')}'
        : '${(_historyRoute.avgSpeed ?? _historyRoute.topSpeedKmph ?? 0).toStringAsFixed(0)} ${context.tr('kmph')}';
    final String distanceStat = _historyRoute.points.isEmpty
        ? '0.0 km'
        : '${(_historyRoute.distanceKm ?? 0).toStringAsFixed(1)} km';
    final String speedLabel =
        _historyPlaybackSpeed == _historyPlaybackSpeed.roundToDouble()
        ? '${_historyPlaybackSpeed.toInt()}x'
        : '${_historyPlaybackSpeed.toStringAsFixed(1)}x';

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: context.containerColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: accentColor, size: 22),
          onPressed: () {
            if (widget.onClose != null) {
              widget.onClose!();
            } else {
              Navigator.maybePop(context);
            }
          },
        ),
        titleSpacing: 0,
        title: Text(
          vehicleLabel,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            position: PopupMenuPosition.over,
            offset: const Offset(0, -310),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
            constraints: const BoxConstraints(
              minWidth: 100,
              maxWidth: 100,
              minHeight: 300,
              maxHeight: 300,
            ),
            onSelected: _applyHistoryPeriod,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: context.containerColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Text(
                    _historyPeriodLabel(),
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.keyboard_arrow_down, color: accentColor, size: 20),
                ],
              ),
            ),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: "1h",
                height: 60,
                child: Center(
                  child: Text(
                    context.tr("1 Hour"),
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ),
              PopupMenuItem(
                value: "today",
                height: 60,
                child: Center(
                  child: Text(
                    context.tr("Today"),
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ),
              PopupMenuItem(
                value: "yesterday",
                height: 60,
                child: Center(
                  child: Text(
                    context.tr("Yesterday"),
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ),
              PopupMenuItem(
                value: "week",
                height: 60,
                child: Center(
                  child: Text(
                    context.tr("Week"),
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ),
              PopupMenuItem(
                value: "month",
                height: 60,
                child: Center(
                  child: Text(
                    context.tr("Month"),
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ),
              PopupMenuItem(
                value: "custom",
                height: 60,
                child: Center(
                  child: Text(
                    context.tr("Custom"),
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: Icon(Icons.filter_alt_outlined, color: accentColor, size: 26),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const NotificationFilterScreen(),
              ),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: RepaintBoundary(
              child: HistoryMap(
                key: _historyMapKey,
                route: _historyRoute,
                fractionListenable: _historySliderValue,
                playingListenable: _isHistoryPlaying,
                isActive: widget.isTabActive,
                playbackSpeed: _historyPlaybackSpeed,
                playWallClockStart: _historyPlayWallClockStart,
                playFractionStart: _historyPlayRouteFractionStart,
                playbackTotal: _historyPlaybackTotalDuration(),
                arrowColor: widget.accentColor,
                routeColor: historyRouteColor,
                stopSessions: _stopSessions,
                onStopSelected: _onStopSelected,
                selectedStopPosition: _selectedStop?.position,
                stopPopupScreenNotifier: _stopPopupScreen,
              ),
            ),
          ),
          if (_historyLoading)
            const Positioned.fill(
              child: ColoredBox(
                color: Color(0x55000000),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
          Positioned(
            top: 130,
            left: 16,
            child: Column(
              children: [
                _floatingMapButton(
                  Icons.map_outlined,
                  context.textColor,
                  () {},
                ),
                const SizedBox(height: 12),
                _floatingMapButton(
                  Icons.settings_outlined,
                  context.textColor,
                  _openHistorySettings,
                ),
              ],
            ),
          ),
          Positioned(
            top: 320,
            right: 16,
            child: Column(
              children: [
                _floatingMapButton(Icons.anchor, context.textColor, () {}),
                const SizedBox(height: 12),
                _floatingMapButton(Icons.local_parking, accentColor, () {}),
                const SizedBox(height: 12),
                _floatingMapButton(Icons.my_location, context.textColor, () {}),
                const SizedBox(height: 12),
                Container(
                  width: 38,
                  decoration: BoxDecoration(
                    color: context.containerColor,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: const [
                      BoxShadow(color: Colors.black12, blurRadius: 4),
                    ],
                  ),
                  child: Column(
                    children: [
                      SizedBox(
                        height: 38,
                        width: 38,
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          icon: Icon(
                            Icons.add,
                            size: 22,
                            color: context.textColor,
                          ),
                          onPressed: () {},
                        ),
                      ),
                      Container(
                        width: 25,
                        height: 1,
                        color: Colors.grey.withValues(alpha: 0.2),
                      ),
                      SizedBox(
                        height: 38,
                        width: 38,
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          icon: Icon(
                            Icons.remove,
                            size: 22,
                            color: context.textColor,
                          ),
                          onPressed: () {},
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (_selectedStop != null)
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: _dismissStopPopup,
              ),
            ),
          _buildMapStopPopup(accentColor: accentColor),
          DraggableScrollableSheet(
            initialChildSize: 0.36,
            minChildSize: 0.24,
            maxChildSize: 0.9,
            snap: true,
            snapSizes: const <double>[0.36, 0.55, 0.9],
            builder: (
              BuildContext context,
              ScrollController scrollController,
            ) {
              return ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: CustomScrollView(
                    controller: scrollController,
                    slivers: <Widget>[
                    SliverToBoxAdapter(
                      child: Column(
                        children: [
                          const SizedBox(height: 10),
                          Container(
                            width: 44,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade400,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(height: 6),
                        ],
                      ),
                    ),
                    SliverPersistentHeader(
                      pinned: true,
                      delegate: _HistoryPlaybackHeaderDelegate(
                        height: 234,
                        backgroundColor: Colors.transparent,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
                          child: _buildPlaybackControlCard(
                            accentColor: accentColor,
                            vehicleLabel: vehicleLabel,
                            fallbackSpeedStat: fallbackSpeedStat,
                            distanceStat: distanceStat,
                            speedLabel: speedLabel,
                          ),
                        ),
                      ),
                    ),
                    if (_historyRoute.isEmpty &&
                        _historyLoaded &&
                        !_historyLoading)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 32),
                          child: Center(
                            child: Text(
                              context.tr('No history for this period'),
                              style: TextStyle(
                                color: context.mutedTextColor,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(10, 6, 10, 40),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (BuildContext context, int index) {
                              return _historyTimelineCard(
                                _timelineSegments[index],
                                accentColor,
                                textColor,
                              );
                            },
                            childCount: _timelineSegments.length,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPlaybackControlCard({
    required Color accentColor,
    required String vehicleLabel,
    required String fallbackSpeedStat,
    required String distanceStat,
    required String speedLabel,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: _historyDateLabel(
                  context.tr('From :'),
                  _historyPanelDate(
                    _historyRoute.startTime ?? _historyFrom,
                  ),
                  accentColor,
                  alignStart: true,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  _shortVehicleBadgeLabel(vehicleLabel),
                  maxLines: 1,
                  overflow: TextOverflow.clip,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
              Expanded(
                child: _historyDateLabel(
                  context.tr('To :'),
                  _historyPanelDate(_historyRoute.endTime ?? _historyTo),
                  accentColor,
                  alignStart: false,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _playbackCardDivider(),
          const SizedBox(height: 10),
          ValueListenableBuilder<double>(
            valueListenable: _historySliderValue,
            builder: (BuildContext context, double fraction, _) {
              final String speedStat = _historyRoute.points.isEmpty
                  ? fallbackSpeedStat
                  : '${_speedAtPlaybackFraction(fraction).toStringAsFixed(0)} ${context.tr('kmph')}';
              return Row(
                children: [
                  Expanded(
                    child: _historyStatItem(
                      Icons.speed,
                      speedStat,
                      accentColor,
                    ),
                  ),
                  Expanded(
                    child: _historyStatItem(
                      Icons.access_time_filled_outlined,
                      _historyDurationDisplay(),
                      accentColor,
                    ),
                  ),
                  Expanded(
                    child: _historyStatItem(
                      Icons.route_outlined,
                      distanceStat,
                      accentColor,
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 10),
          _playbackCardDivider(),
          const SizedBox(height: 10),
          ValueListenableBuilder<double>(
            valueListenable: _historySliderValue,
            builder: (BuildContext context, double fraction, _) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.location_on, color: accentColor, size: 18),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _locationAtPlaybackFraction(fraction),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: context.mutedTextColor,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 10),
          _playbackCardDivider(),
          const SizedBox(height: 10),
          Row(
            children: [
              ValueListenableBuilder<bool>(
                valueListenable: _isHistoryPlaying,
                builder: (BuildContext context, bool playing, _) {
                  return _historyCircleControl(
                    accentColor,
                    size: 46,
                    onTap: _toggleHistoryPlayback,
                    child: Icon(
                      playing ? Icons.pause : Icons.play_arrow,
                      color: Colors.white,
                      size: 30,
                    ),
                  );
                },
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 4,
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 8,
                    ),
                    overlayShape: SliderComponentShape.noOverlay,
                    activeTrackColor: accentColor,
                    inactiveTrackColor:
                        Colors.grey.shade400.withValues(alpha: 0.5),
                  ),
                  child: ValueListenableBuilder<double>(
                    valueListenable: _historySliderValue,
                    builder: (BuildContext context, double sliderValue, _) {
                      return Slider(
                        value: sliderValue,
                        onChangeStart: (_) => _stopHistoryPlayback(),
                        onChanged: (double v) => _historySliderValue.value = v,
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(width: 4),
              PopupMenuButton<String>(
                offset: const Offset(0, -180),
                onSelected: (String v) {
                  final double parsed =
                      double.tryParse(v.replaceAll('x', '')) ?? 1.0;
                  _setHistoryPlaybackSpeed(parsed);
                },
                itemBuilder: (context) => <String>[
                  '0.5x',
                  '1.0x',
                  '1.5x',
                  '2.0x',
                  '3.0x',
                  '6.0x',
                  '10.0x',
                ]
                    .map(
                      (String s) => PopupMenuItem<String>(
                        value: s,
                        child: Text(s),
                      ),
                    )
                    .toList(),
                child: _historyCircleControl(
                  accentColor,
                  child: Text(
                    speedLabel,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              _historyCircleControl(
                accentColor,
                onTap: _restartHistoryPlayback,
                child: const Icon(
                  Icons.replay,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 6),
              _historyCircleControl(
                accentColor,
                onTap: () {
                  _historySliderValue.value = 0;
                  _stopHistoryPlayback();
                },
                child: const Icon(
                  Icons.route,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _playbackCardDivider(),
        ],
      ),
    );
  }

  Widget _historyDateLabel(
    String label,
    String date,
    Color color, {
    required bool alignStart,
  }) {
    return Column(
      crossAxisAlignment: alignStart
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.end,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: Colors.grey,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.calendar_today, size: 14, color: color),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                date,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _historyCircleControl(
    Color accentColor, {
    required Widget child,
    VoidCallback? onTap,
    double size = 36,
  }) {
    return Material(
      color: accentColor,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: size,
          height: size,
          child: Center(child: child),
        ),
      ),
    );
  }

  Widget _historyTimelineCard(
    HistoryTimelineSegment segment,
    Color accentColor,
    Color textColor,
  ) {
    final bool isTrip = segment.kind == HistoryTimelineKind.trip;
    final Color bg = _historySegmentCardColor(isTrip: isTrip);
    final Color badgeBg = isTrip
        ? const Color(0xFF43A047)
        : const Color(0xFFE53935);
    final String badgeLabel =
        isTrip ? context.tr('Trip') : context.tr('Stop');
    final String durationLabel =
        HistoryRouteUtils.formatHumanDuration(segment.duration);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.55),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => _seekToSegment(segment),
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (isTrip)
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.directions_run, size: 18, color: badgeBg),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              '${context.tr('Distance')}: ${segment.distanceKm.toStringAsFixed(2)} km',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                                color: textColor,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: badgeBg,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              badgeLabel,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${context.tr('Max speed')}: ${segment.maxSpeedKmph.toStringAsFixed(0)} ${context.tr('kmph')}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade800,
                        ),
                      ),
                    ],
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: badgeBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        badgeLabel,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              _timelineDetailRow(
                Icons.play_circle_outline,
                context.tr('Start'),
                HistoryRouteUtils.formatTimelineCardTime(segment.start),
              ),
              _timelineDetailRow(
                Icons.access_time,
                context.tr('Duration'),
                durationLabel,
              ),
              _timelineDetailRow(
                Icons.stop_circle_outlined,
                context.tr('End'),
                HistoryRouteUtils.formatTimelineCardTime(segment.end),
                showDivider: false,
              ),
            ],
          ),
        ),
        ),
      ),
    );
  }

  Widget _timelineDetailRow(
    IconData icon,
    String label,
    String value, {
    bool showDivider = true,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 20, color: Colors.grey.shade600),
              const SizedBox(width: 10),
              Text(
                '$label: ',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
              Expanded(
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: context.textColor,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            thickness: 1,
            indent: 12,
            endIndent: 12,
            color: Colors.grey.shade400.withValues(alpha: 0.45),
          ),
      ],
    );
  }

  Widget _historyStatItem(IconData icon, String value, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: context.textColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _floatingMapButton(
    IconData icon,
    Color iconColor,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 38,
        width: 38,
        decoration: BoxDecoration(
          color: context.containerColor,
          borderRadius: BorderRadius.circular(8),
          border: context.appTokens.containerBorderColor == null
              ? null
              : Border.all(color: context.appTokens.containerBorderColor!),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
    );
  }
}

class _HistoryPlaybackHeaderDelegate extends SliverPersistentHeaderDelegate {
  _HistoryPlaybackHeaderDelegate({
    required this.height,
    required this.child,
    required this.backgroundColor,
  });

  final double height;
  final Widget child;
  final Color backgroundColor;

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Material(
      color: backgroundColor,
      elevation: 0,
      shadowColor: Colors.transparent,
      child: SizedBox(height: height, child: child),
    );
  }

  @override
  bool shouldRebuild(covariant _HistoryPlaybackHeaderDelegate oldDelegate) {
    return oldDelegate.height != height ||
        oldDelegate.backgroundColor != backgroundColor;
  }
}
