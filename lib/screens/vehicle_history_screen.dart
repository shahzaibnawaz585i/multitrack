import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../l10n/app_l10n.dart';
import '../services/general_settings_controller.dart';
import '../services/history_service.dart';
import '../services/vehicle_detail_api_service.dart';
import '../theme/app_theme_tokens.dart';
import '../utils/history_route_utils.dart';
import '../utils/report_period.dart';
import '../widgets/history_map.dart';
import 'notification_filter_screen.dart';

class VehicleHistoryScreen extends StatefulWidget {
  const VehicleHistoryScreen({
    super.key,
    this.deviceId,
    required this.name,
    required this.accentColor,
    required this.fallbackLocation,
    this.onClose,
  });

  final int? deviceId;
  final String name;
  final Color accentColor;
  final String fallbackLocation;

  /// When embedded in vehicle detail tabs, returns to Track instead of popping route.
  final VoidCallback? onClose;

  @override
  State<VehicleHistoryScreen> createState() => _VehicleHistoryScreenState();
}

class _VehicleHistoryScreenState extends State<VehicleHistoryScreen> {
  bool _historyLoading = false;
  bool _historyLoaded = false;
  bool _historyEmptyDialogDismissed = false;
  final ValueNotifier<double> _historyPanelTop = ValueNotifier<double>(0);
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      final double h = MediaQuery.sizeOf(context).height;
      _historyPanelTop.value = h * 0.65;
      _loadHistory();
    });
  }

  @override
  void dispose() {
    _stopHistoryPlayback();
    _historyPanelTop.dispose();
    _historySliderValue.dispose();
    _isHistoryPlaying.dispose();
    super.dispose();
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

  void _applyHistoryRoute(HistoryRoute route, {required bool stillLoading}) {
    if (!mounted) {
      return;
    }
    final HistoryRoute displayRoute = _historyRouteForDisplay(route);
    setState(() {
      _historyLoading = stillLoading;
      _historyLoaded = true;
      _historyRoute = displayRoute;
      _historyError = route.errorMessage;
      if (!stillLoading) {
        _historySliderValue.value = 0;
      }
    });
  }

  Future<void> _loadHistory({bool force = false}) async {
    final int? deviceId = widget.deviceId;
    if (deviceId == null) {
      setState(() {
        _historyError = context.tr('No device selected');
        _historyLoaded = true;
        _historyRoute = const HistoryRoute(points: <HistoryPoint>[]);
        _historyLoading = false;
      });
      return;
    }

    if (!force &&
        _historyLoaded &&
        _historyError == null &&
        !_historyRoute.isEmpty) {
      return;
    }

    if (!force) {
      try {
        final HistoryRoute cached = await VehicleDetailApiService.loadHistory(
          deviceId: deviceId,
          from: _historyFrom,
          to: _historyTo,
          forceRefresh: false,
        );
        if (!mounted) {
          return;
        }
        if (!cached.isEmpty) {
          _stopHistoryPlayback();
          _applyHistoryRoute(cached, stillLoading: false);
          return;
        }
      } catch (_) {
        if (!mounted) {
          return;
        }
      }
    }

    if (_historyLoading) {
      return;
    }

    _stopHistoryPlayback();
    setState(() {
      _historyLoading = true;
      _historyError = null;
      _historyLoaded = true;
    });

    await _fetchHistoryFromNetwork(deviceId: deviceId, force: force);
  }

  Future<void> _fetchHistoryFromNetwork({
    required int deviceId,
    required bool force,
  }) async {
    try {
      final HistoryRoute route = await VehicleDetailApiService.loadHistory(
        deviceId: deviceId,
        from: _historyFrom,
        to: _historyTo,
        forceRefresh: force,
      ).timeout(const Duration(seconds: 25));
      if (!mounted) {
        return;
      }
      _applyHistoryRoute(route, stillLoading: false);
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _historyLoading = false;
        _historyLoaded = true;
        if (_historyRoute.isEmpty) {
          _historyRoute = const HistoryRoute(points: <HistoryPoint>[]);
        }
        _historyError = e.toString();
      });
    }
  }

  void _applyHistoryPeriod(String period) {
    if (period == _historyPeriod && _historyLoaded && !_historyLoading) {
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
    setState(() {
      _historyPeriod = period;
      _historyFrom = range.from;
      _historyTo = range.to;
      _historyLoaded = false;
      _historyError = null;
      _historyEmptyDialogDismissed = false;
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
    if (picked == null || !mounted) {
      return;
    }
    final DateTime to = picked.end.isAfter(now)
        ? now
        : ReportPeriod.endOfDay(picked.end);
    setState(() {
      _historyPeriod = 'custom';
      _historyFrom = ReportPeriod.startOfDay(picked.start);
      _historyTo = to;
      _historyLoaded = false;
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
    if (mounted) {
      setState(() {});
    }
  }

  void _toggleHistoryPlayback() {
    if (_historyRoute.points.length < 2) {
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
      const Duration(milliseconds: 33),
      (_) => _tickHistoryPlayback(),
    );
    setState(() {});
  }

  void _tickHistoryPlayback() {
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
    setState(() => _historyPlaybackSpeed = parsed);
  }

  void _restartHistoryPlayback() {
    _stopHistoryPlayback();
    _historySliderValue.value = 0;
  }

  String _historyPanelDate(DateTime value) {
    return DateFormat('dd MMM yyyy').format(value);
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
    final double screenHeight = MediaQuery.sizeOf(context).height;
    const double maxTopLimit = 120.0;
    final double bottomLimit = screenHeight * 0.8;
    final String vehicleLabel = widget.name.isNotEmpty
        ? widget.name
        : (widget.deviceId?.toString() ?? '—');
    final String speedStat = _historyRoute.points.isEmpty
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
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
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
                key: const ValueKey<String>('vehicle_history_map'),
                route: _historyRoute,
                fractionListenable: _historySliderValue,
                playingListenable: _isHistoryPlaying,
                isActive: true,
                playbackSpeed: _historyPlaybackSpeed,
                playWallClockStart: _historyPlayWallClockStart,
                playFractionStart: _historyPlayRouteFractionStart,
                playbackTotal: _historyPlaybackTotalDuration(),
                arrowColor: widget.accentColor,
                routeColor: historyRouteColor,
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
                  () {},
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
          ValueListenableBuilder<double>(
            valueListenable: _historyPanelTop,
            builder: (BuildContext context, double top, Widget? child) {
              return Positioned(top: top, left: 0, right: 0, child: child!);
            },
            child: GestureDetector(
              onVerticalDragUpdate: (DragUpdateDetails details) {
                _historyPanelTop.value =
                    (_historyPanelTop.value + details.delta.dy).clamp(
                      maxTopLimit,
                      bottomLimit,
                    );
              },
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.12),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                padding: EdgeInsets.fromLTRB(10, screenHeight * 0.05, 10, 20),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: context.containerColor,
                    borderRadius: BorderRadius.circular(26),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 15,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _historyDateLabel(
                            context.tr('From :'),
                            _historyPanelDate(
                              _historyRoute.startTime ?? _historyFrom,
                            ),
                            accentColor,
                            alignStart: true,
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: accentColor,
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Text(
                              vehicleLabel,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ),
                          _historyDateLabel(
                            context.tr('To :'),
                            _historyPanelDate(
                              _historyRoute.endTime ?? _historyTo,
                            ),
                            accentColor,
                            alignStart: false,
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Divider(
                        height: 1,
                        thickness: 0.8,
                        color: context.mutedTextColor.withValues(alpha: 0.3),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _historyStatItem(Icons.speed, speedStat, accentColor),
                          _historyStatItem(
                            Icons.access_time_filled_outlined,
                            _historyRoute.durationLabel ??
                                _historyDurationDisplay(),
                            accentColor,
                          ),
                          _historyStatItem(
                            Icons.route_outlined,
                            distanceStat,
                            accentColor,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Stack(
                        children: [
                          Container(
                            height: 40,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: context.mutedTextColor.withValues(
                                alpha: 0.1,
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          ValueListenableBuilder<double>(
                            valueListenable: _historySliderValue,
                            builder:
                                (BuildContext context, double sliderValue, _) {
                                  return SliderTheme(
                                    data: SliderTheme.of(context).copyWith(
                                      trackHeight: 40,
                                      thumbShape: SliderComponentShape.noThumb,
                                      overlayShape:
                                          SliderComponentShape.noOverlay,
                                      activeTrackColor: accentColor.withValues(
                                        alpha: 0.15,
                                      ),
                                      inactiveTrackColor: Colors.transparent,
                                    ),
                                    child: Slider(
                                      value: sliderValue,
                                      onChangeStart: (_) =>
                                          _stopHistoryPlayback(),
                                      onChanged: (double v) =>
                                          _historySliderValue.value = v,
                                    ),
                                  );
                                },
                          ),
                          Positioned.fill(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: Row(
                                children: [
                                  ValueListenableBuilder<bool>(
                                    valueListenable: _isHistoryPlaying,
                                    builder:
                                        (
                                          BuildContext context,
                                          bool playing,
                                          _,
                                        ) {
                                          return GestureDetector(
                                            onTap: _toggleHistoryPlayback,
                                            child: Icon(
                                              playing
                                                  ? Icons.pause_circle_filled
                                                  : Icons.play_circle_fill,
                                              color: accentColor,
                                              size: 30,
                                            ),
                                          );
                                        },
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: ValueListenableBuilder<double>(
                                      valueListenable: _historySliderValue,
                                      builder:
                                          (BuildContext context, double _, __) {
                                            return Text(
                                              _playbackTimeLabel(),
                                              style: TextStyle(
                                                color: context.mutedTextColor,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            );
                                          },
                                    ),
                                  ),
                                  PopupMenuButton<String>(
                                    offset: const Offset(0, -180),
                                    onSelected: (String v) {
                                      final double parsed =
                                          double.tryParse(
                                            v.replaceAll('x', ''),
                                          ) ??
                                          1.0;
                                      _setHistoryPlaybackSpeed(parsed);
                                    },
                                    itemBuilder: (context) =>
                                        [
                                              '0.5x',
                                              '1.0x',
                                              '1.5x',
                                              '2.0x',
                                              '3.0x',
                                              '6.0x',
                                              '10.0x',
                                            ]
                                            .map(
                                              (String s) =>
                                                  PopupMenuItem<String>(
                                                    value: s,
                                                    child: Text(s),
                                                  ),
                                            )
                                            .toList(),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: accentColor,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
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
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
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
        Text(
          date,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: color,
          ),
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
        Flexible(
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
