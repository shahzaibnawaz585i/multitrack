import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../services/history_service.dart';
import '../services/live_route_service.dart';
import '../theme/app_theme_tokens.dart';
import '../utils/history_numbered_stop_icon.dart';
import '../utils/history_route_utils.dart';
import '../utils/map_arrow_icon.dart';

class HistoryMap extends StatefulWidget {
  const HistoryMap({
    super.key,
    required this.route,
    required this.fractionListenable,
    required this.playingListenable,
    required this.isActive,
    required this.playbackSpeed,
    required this.playWallClockStart,
    required this.playFractionStart,
    required this.playbackTotal,
    required this.arrowColor,
    required this.routeColor,
    this.stopSessions = const <HistoryStopSession>[],
    this.onStopSelected,
    this.selectedStopPosition,
    this.stopPopupScreenNotifier,
  });

  final HistoryRoute route;
  final List<HistoryStopSession> stopSessions;
  final ValueChanged<HistoryStopSession>? onStopSelected;
  final LatLng? selectedStopPosition;
  final ValueNotifier<Offset?>? stopPopupScreenNotifier;
  final ValueListenable<double> fractionListenable;
  final ValueListenable<bool> playingListenable;
  final bool isActive;
  final double playbackSpeed;
  final DateTime? playWallClockStart;
  final double playFractionStart;
  final Duration playbackTotal;
  final Color arrowColor;
  final Color routeColor;

  @override
  State<HistoryMap> createState() => HistoryMapState();
}

class HistoryMapState extends State<HistoryMap>
    with SingleTickerProviderStateMixin {
  GoogleMapController? _controller;
  Set<Polyline> _polylines = const <Polyline>{};
  Set<Marker> _markers = const <Marker>{};
  Set<Circle> _circles = const <Circle>{};
  List<LatLng> _fullPoints = const <LatLng>[];
  List<LatLng> _displayLine = const <LatLng>[];
  List<HistoryPoint> _sortedPoints = const <HistoryPoint>[];
  List<double> _timeFractions = const <double>[];
  String _routeKey = '';
  double _displayFraction = 0;
  double _smoothedBearing = 0;
  Ticker? _playbackTicker;
  BitmapDescriptor? _arrowIcon;
  Map<int, BitmapDescriptor> _stopNumberIcons = <int, BitmapDescriptor>{};
  String _stopIconsSessionKey = '';
  int _lastCameraMoveMs = 0;
  LatLng? _lastCameraTarget;
  Duration _lastFrameAt = Duration.zero;
  int _lastUiFrameMs = 0;
  int _popupAnchorUpdateSeq = 0;
  int _lastPopupAnchorPublishMs = 0;
  static const double _playbackFollowZoom = 17.0;
  static const int _followThrottleMs = 320;
  bool _wasPlaying = false;
  bool _followZoomApplied = false;
  bool _mapDisposed = false;

  bool get _isPlaying {
    try {
      return widget.playingListenable.value;
    } catch (_) {
      return false;
    }
  }

  double get _targetFraction {
    try {
      return widget.fractionListenable.value;
    } catch (_) {
      return _displayFraction;
    }
  }

  @override
  void initState() {
    super.initState();
    _displayFraction = _targetFraction;
    _wasPlaying = widget.playingListenable.value;
    widget.fractionListenable.addListener(_onExternalPlaybackTick);
    widget.playingListenable.addListener(_onExternalPlaybackTick);
    _playbackTicker = createTicker(_onPlaybackFrame);
    if (widget.isActive) {
      _playbackTicker!.start();
    }
    _loadArrowIcon();
    _deferApplyRoute(widget.route, _targetFraction);
  }

  @override
  void dispose() {
    _mapDisposed = true;
    try {
      widget.fractionListenable.removeListener(_onExternalPlaybackTick);
    } catch (_) {}
    try {
      widget.playingListenable.removeListener(_onExternalPlaybackTick);
    } catch (_) {}
    _playbackTicker?.stop();
    _playbackTicker?.dispose();
    _playbackTicker = null;
    _controller = null;
    try {
      widget.stopPopupScreenNotifier?.value = null;
    } catch (_) {}
    super.dispose();
  }

  /// Screen position for [widget.selectedStopPosition] (updates when the map pans/zooms).
  Future<void> refreshStopPopupAnchor() async {
    await _publishStopPopupScreen(widget.selectedStopPosition);
  }

  Future<void> _publishStopPopupScreen(LatLng? latLng) async {
    final ValueNotifier<Offset?>? notifier = widget.stopPopupScreenNotifier;
    if (notifier == null) {
      return;
    }
    if (latLng == null) {
      notifier.value = null;
      return;
    }
    final GoogleMapController? controller = _controller;
    if (controller == null || !mounted) {
      return;
    }
    try {
      final ScreenCoordinate screen =
          await controller.getScreenCoordinate(latLng);
      if (!mounted) {
        return;
      }
      notifier.value = Offset(screen.x.toDouble(), screen.y.toDouble());
    } catch (_) {
      notifier.value = null;
    }
  }

  void _scheduleStopPopupAnchorUpdate() {
    if (widget.selectedStopPosition == null) {
      return;
    }
    final int nowMs = DateTime.now().millisecondsSinceEpoch;
    if (nowMs - _lastPopupAnchorPublishMs < 32) {
      return;
    }
    _lastPopupAnchorPublishMs = nowMs;
    final int seq = ++_popupAnchorUpdateSeq;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || seq != _popupAnchorUpdateSeq) {
        return;
      }
      await _publishStopPopupScreen(widget.selectedStopPosition);
    });
  }

  void _onExternalPlaybackTick() {
    if (_mapDisposed || !mounted || !widget.isActive) {
      return;
    }
    try {
      final bool playing = _isPlaying;
      final double target = _targetFraction.clamp(0.0, 1.0);
      if (!playing && (target - _displayFraction).abs() < 0.000001) {
        return;
      }
      _displayFraction = target;
      if (playing && !_wasPlaying) {
        _lastCameraMoveMs = 0;
        _lastCameraTarget = null;
        _followZoomApplied = false;
      } else if (!playing && _wasPlaying) {
        _followZoomApplied = false;
      }
      _wasPlaying = playing;
      _applyPlaybackVisuals(
        _displayFraction,
        followCamera: playing,
        smoothMarker: playing,
      );
    } catch (_) {}
  }

  void _deferApplyRoute(HistoryRoute route, double playbackFraction) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      try {
        _applyRoute(route, playbackFraction);
        setState(() {});
        _scheduleFitBounds();
      } catch (_) {
        _polylines = const <Polyline>{};
        _markers = const <Marker>{};
        _circles = const <Circle>{};
        if (mounted) {
          setState(() {});
        }
      }
    });
  }

  void _syncTickerWithVisibility(bool active) {
    final Ticker? ticker = _playbackTicker;
    if (ticker == null) {
      return;
    }
    if (active && !ticker.isTicking) {
      ticker.start();
    } else if (!active && ticker.isTicking) {
      ticker.stop();
    }
  }

  double _fractionForFrame() {
    if (_isPlaying && widget.playWallClockStart != null) {
      return HistoryRouteUtils.playbackFractionFromClock(
        wallStart: widget.playWallClockStart!,
        startFraction: widget.playFractionStart,
        speed: widget.playbackSpeed,
        routeTotal: widget.playbackTotal,
        pointCount: _sortedPoints.length,
      );
    }
    final double target = _targetFraction;
    final double diff = target - _displayFraction;
    if (diff.abs() < 0.000001) {
      return _displayFraction;
    }
    return _displayFraction + diff * (diff.abs() > 0.06 ? 0.55 : 0.32);
  }

  void _onPlaybackFrame(Duration elapsed) {
    if (_mapDisposed ||
        !mounted ||
        !widget.isActive ||
        _sortedPoints.isEmpty ||
        _isPlaying) {
      return;
    }
    if (_lastFrameAt != Duration.zero &&
        elapsed - _lastFrameAt < const Duration(milliseconds: 33)) {
      return;
    }
    _lastFrameAt = elapsed;

    final double next = _fractionForFrame();
    if ((next - _displayFraction).abs() < 0.000001) {
      return;
    }
    _displayFraction = next;
    _applyPlaybackVisuals(
      _displayFraction,
      followCamera: false,
      smoothMarker: false,
    );
  }

  Future<void> _loadArrowIcon() async {
    try {
      final BitmapDescriptor icon =
          await MapArrowIcon.forColor(widget.arrowColor);
      if (!mounted) {
        return;
      }
      setState(() => _arrowIcon = icon);
    } catch (_) {
      _arrowIcon = BitmapDescriptor.defaultMarkerWithHue(
        BitmapDescriptor.hueGreen,
      );
    }
  }

  @override
  void didUpdateWidget(covariant HistoryMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isActive != widget.isActive) {
      _syncTickerWithVisibility(widget.isActive);
    }
    final String nextKey =
        '${widget.route.points.length}_${widget.route.startTime?.millisecondsSinceEpoch}_'
        '${widget.route.endTime?.millisecondsSinceEpoch}_${widget.stopSessions.length}';
    if (oldWidget.selectedStopPosition != widget.selectedStopPosition) {
      unawaited(refreshStopPopupAnchor());
    }
    if (nextKey != _routeKey) {
      _deferApplyRoute(widget.route, _targetFraction);
    } else {
      if (oldWidget.stopSessions != widget.stopSessions) {
        _loadStopNumberIcons();
      }
      if (oldWidget.playWallClockStart != widget.playWallClockStart ||
          oldWidget.playFractionStart != widget.playFractionStart ||
          oldWidget.playbackSpeed != widget.playbackSpeed ||
          oldWidget.playbackTotal != widget.playbackTotal) {
        _onExternalPlaybackTick();
      }
    }
  }

  void _scheduleFitBounds() {
    WidgetsBinding.instance.addPostFrameCallback((_) => _fitRouteBounds());
  }

  static bool _isValidMapPoint(HistoryPoint point) {
    final double lat = point.position.latitude;
    final double lng = point.position.longitude;
    if (!lat.isFinite || !lng.isFinite) {
      return false;
    }
    if (lat.abs() > 90 || lng.abs() > 180) {
      return false;
    }
    return !(lat == 0 && lng == 0);
  }

  void _applyRoute(HistoryRoute route, double playbackFraction) {
    final List<HistoryPoint> sorted = HistoryRouteUtils.sortByTime(
      route.points.where(_isValidMapPoint).toList(),
    );
    _sortedPoints = sorted.length > 800
        ? HistoryRouteUtils.decimatePoints(sorted, 800)
        : sorted;
    _fullPoints = HistoryRouteUtils.positions(_sortedPoints);
    _displayLine = _fullPoints.length > HistoryRouteUtils.maxPolylineVertices
        ? HistoryRouteUtils.simplifyForMap(_fullPoints)
        : _fullPoints;
    _routeKey =
        '${_fullPoints.length}_${route.startTime?.millisecondsSinceEpoch}_'
        '${route.endTime?.millisecondsSinceEpoch}';
    _timeFractions = HistoryRouteUtils.buildPointTimeFractions(_sortedPoints);
    _displayFraction = playbackFraction;
    _circles = widget.stopSessions.isNotEmpty || _sortedPoints.length > 350
        ? const <Circle>{}
        : HistoryRouteUtils.eventCircles(_sortedPoints);
    _rebuildMarkers(playbackFraction);
    _rebuildPolylines(playbackFraction);
    _loadStopNumberIcons();
  }

  Future<void> _loadStopNumberIcons() async {
    if (widget.stopSessions.isEmpty) {
      if (_stopNumberIcons.isNotEmpty) {
        _stopNumberIcons = <int, BitmapDescriptor>{};
        _stopIconsSessionKey = '';
      }
      return;
    }
    final String key = widget.stopSessions
        .map((HistoryStopSession s) => '${s.index}_${s.arrival.millisecondsSinceEpoch}')
        .join('|');
    if (key == _stopIconsSessionKey && _stopNumberIcons.length == widget.stopSessions.length) {
      return;
    }
    _stopIconsSessionKey = key;
    final List<MapEntry<int, BitmapDescriptor>> entries =
        await Future.wait<MapEntry<int, BitmapDescriptor>>(
      widget.stopSessions.map((HistoryStopSession session) async {
        final BitmapDescriptor icon =
            await HistoryNumberedStopIcon.forNumber(session.index);
        return MapEntry<int, BitmapDescriptor>(session.index, icon);
      }),
    );
    final Map<int, BitmapDescriptor> loaded =
        Map<int, BitmapDescriptor>.fromEntries(entries);
    if (!mounted || key != _stopIconsSessionKey) {
      return;
    }
    _stopNumberIcons = loaded;
    _rebuildMarkers(_displayFraction);
    if (mounted) {
      setState(() {});
    }
  }

  void _applyPlaybackVisuals(
    double playbackFraction, {
    required bool followCamera,
    bool smoothMarker = false,
  }) {
    if (_mapDisposed || !mounted || _sortedPoints.isEmpty) {
      return;
    }
    try {
      final int nowMs = DateTime.now().millisecondsSinceEpoch;
      final bool playing = _isPlaying;
      if (playing) {
        _rebuildArrowMarkerOnly(playbackFraction, smoothMarker: smoothMarker);
      } else {
        _rebuildPolylines(playbackFraction);
        _rebuildMarkers(playbackFraction, smoothMarker: smoothMarker);
      }
      if (followCamera && playing) {
        _maybeFollowPlayback(playbackFraction);
      }
      final int uiThrottleMs = playing ? 200 : 66;
      if (nowMs - _lastUiFrameMs >= uiThrottleMs || !playing) {
        _lastUiFrameMs = nowMs;
        if (!_mapDisposed && mounted && widget.isActive) {
          setState(() {});
        }
      }
    } catch (_) {}
  }

  void _rebuildArrowMarkerOnly(
    double playbackFraction, {
    bool smoothMarker = false,
  }) {
    if (_fullPoints.isEmpty) {
      return;
    }
    final HistoryPlaybackSample sample = HistoryRouteUtils.sampleAtFraction(
      _sortedPoints,
      playbackFraction,
      timeFractions: _timeFractions,
    );
    if (smoothMarker) {
      _smoothedBearing = HistoryRouteUtils.lerpAngleDegrees(
        _smoothedBearing,
        sample.bearing,
        0.35,
      );
    } else {
      _smoothedBearing = sample.bearing;
    }
    final BitmapDescriptor arrow =
        _arrowIcon ??
        BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
    final Set<Marker> next = Set<Marker>.from(_markers);
    next.removeWhere(
      (Marker m) => m.markerId == const MarkerId('history_arrow'),
    );
    next.add(
      Marker(
        markerId: const MarkerId('history_arrow'),
        position: sample.position,
        icon: arrow,
        rotation: _smoothedBearing,
        flat: true,
        anchor: MapArrowIcon.markerAnchor,
        zIndexInt: 3,
        infoWindow: InfoWindow(
          title: 'Playback',
          snippet: sample.point?.time != null
              ? HistoryRouteUtils.formatDateTime(sample.point!.time)
              : '',
        ),
      ),
    );
    _markers = next;
  }

  void _rebuildPolylines(double playbackFraction) {
    if (_fullPoints.isEmpty) {
      _polylines = const <Polyline>{};
      return;
    }

    final List<LatLng> traveled = HistoryRouteUtils.polylineUntilFraction(
      _sortedPoints,
      playbackFraction,
      timeFractions: _timeFractions,
    );

    final Color base = widget.routeColor;
    _polylines = <Polyline>{
      if (_displayLine.length >= 2)
        Polyline(
          polylineId: const PolylineId('history_route_full'),
          points: _displayLine,
          color: base.withValues(alpha: 0.28),
          width: 4,
        ),
      if (traveled.length >= 2)
        Polyline(
          polylineId: const PolylineId('history_route_played'),
          points: traveled,
          color: base,
          width: 6,
          startCap: Cap.roundCap,
          endCap: Cap.roundCap,
          jointType: JointType.round,
        ),
    };
  }

  void _rebuildMarkers(double playbackFraction, {bool smoothMarker = false}) {
    if (_fullPoints.isEmpty) {
      _markers = const <Marker>{};
      return;
    }

    final bool numberedStops = widget.stopSessions.isNotEmpty;
    final Set<Marker> next = <Marker>{
      Marker(
        markerId: const MarkerId('history_start'),
        position: _fullPoints.first,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        zIndexInt: 5,
        infoWindow: const InfoWindow(title: 'Start'),
      ),
      if (_fullPoints.length > 1 && !numberedStops)
        Marker(
          markerId: const MarkerId('history_end'),
          position: _fullPoints.last,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: const InfoWindow(title: 'End'),
        ),
    };

    for (final HistoryStopSession session in widget.stopSessions) {
      final BitmapDescriptor stopIcon = _stopNumberIcons[session.index] ??
          BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
      next.add(
        Marker(
          markerId: MarkerId('history_stop_${session.index}'),
          position: session.position,
          icon: stopIcon,
          anchor: HistoryNumberedStopIcon.markerAnchor,
          zIndexInt: 4,
          infoWindow: InfoWindow.noText,
          onTap: () => widget.onStopSelected?.call(session),
        ),
      );
    }

    final HistoryPlaybackSample sample = HistoryRouteUtils.sampleAtFraction(
      _sortedPoints,
      playbackFraction,
      timeFractions: _timeFractions,
    );
    if (smoothMarker) {
      _smoothedBearing = HistoryRouteUtils.lerpAngleDegrees(
        _smoothedBearing,
        sample.bearing,
        _isPlaying ? 0.35 : 0.5,
      );
    } else {
      _smoothedBearing = sample.bearing;
    }
    final BitmapDescriptor arrow =
        _arrowIcon ??
        BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
    next.add(
      Marker(
        markerId: const MarkerId('history_arrow'),
        position: sample.position,
        icon: arrow,
        rotation: _smoothedBearing,
        flat: true,
        anchor: MapArrowIcon.markerAnchor,
        zIndexInt: 3,
        infoWindow: InfoWindow(
          title: 'Playback',
          snippet: sample.point?.time != null
              ? HistoryRouteUtils.formatDateTime(sample.point!.time)
              : '',
        ),
      ),
    );

    _markers = next;
  }

  bool _isValidLatLng(LatLng p) {
    final double lat = p.latitude;
    final double lng = p.longitude;
    if (!lat.isFinite || !lng.isFinite) {
      return false;
    }
    if (lat.abs() > 90 || lng.abs() > 180) {
      return false;
    }
    return !(lat == 0 && lng == 0);
  }

  void _maybeFollowPlayback(double fraction) {
    if (_mapDisposed || !mounted) {
      return;
    }
    final GoogleMapController? controller = _controller;
    if (controller == null || _sortedPoints.isEmpty) {
      return;
    }
    final HistoryPlaybackSample sample = HistoryRouteUtils.sampleAtFraction(
      _sortedPoints,
      fraction,
      timeFractions: _timeFractions,
    );
    if (!_isValidLatLng(sample.position)) {
      return;
    }
    final int nowMs = DateTime.now().millisecondsSinceEpoch;
    final LatLng? last = _lastCameraTarget;
    if (last != null &&
        nowMs - _lastCameraMoveMs < _followThrottleMs &&
        LiveRouteService.haversineMeters(last, sample.position) < 6) {
      return;
    }
    _lastCameraMoveMs = nowMs;
    _lastCameraTarget = sample.position;
    try {
      // Avoid full CameraPosition+bearing every tick — native map crashes on
      // some MediaTek devices when moveCamera is called too aggressively.
      if (!_followZoomApplied) {
        _followZoomApplied = true;
        unawaited(
          controller.animateCamera(
            CameraUpdate.newLatLngZoom(sample.position, _playbackFollowZoom),
          ),
        );
      } else {
        controller.moveCamera(CameraUpdate.newLatLng(sample.position));
      }
    } catch (_) {}
  }

  Future<void> _fitRouteBounds() async {
    final GoogleMapController? controller = _controller;
    final LatLngBounds? bounds = HistoryRouteUtils.boundsFor(_fullPoints);
    if (!mounted || controller == null || bounds == null) {
      return;
    }
    try {
      await controller.animateCamera(
        CameraUpdate.newLatLngBounds(bounds, 48),
      );
    } catch (_) {
      if (!mounted || _fullPoints.isEmpty) {
        return;
      }
      try {
        await controller.animateCamera(
          CameraUpdate.newLatLngZoom(_fullPoints.first, 14),
        );
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    final LatLng target = _fullPoints.isNotEmpty
        ? _fullPoints.first
        : LatLng(
            widget.route.points.isNotEmpty
                ? widget.route.points.first.position.latitude
                : 31.5204,
            widget.route.points.isNotEmpty
                ? widget.route.points.first.position.longitude
                : 74.3587,
          );

    return GoogleMap(
      initialCameraPosition: CameraPosition(target: target, zoom: 14.0),
      style: context.themedMapStyle,
      zoomControlsEnabled: false,
      myLocationEnabled: false,
      compassEnabled: false,
      mapToolbarEnabled: false,
      polylines: _polylines,
      markers: _markers,
      circles: _circles,
      onTap: (LatLng position) {
        if (widget.onStopSelected == null || widget.stopSessions.isEmpty) {
          return;
        }
        final HistoryStopSession? hit = HistoryRouteUtils.nearestStopSession(
          position,
          widget.stopSessions,
        );
        if (hit != null) {
          widget.onStopSelected!(hit);
        }
      },
      onCameraMove: (_) => _scheduleStopPopupAnchorUpdate(),
      onCameraIdle: () => unawaited(refreshStopPopupAnchor()),
      onMapCreated: (GoogleMapController controller) {
        if (!mounted) {
          return;
        }
        _controller = controller;
        _scheduleFitBounds();
        unawaited(refreshStopPopupAnchor());
      },
    );
  }
}
