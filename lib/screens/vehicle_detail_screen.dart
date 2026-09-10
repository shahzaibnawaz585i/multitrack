import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:async';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../l10n/app_l10n.dart';
import '../models/vehicle_model.dart';
import '../services/history_service.dart';
import '../services/live_route_service.dart';
import '../services/tracking_api_service.dart';
import '../services/vehicle_service.dart';
import '../data/vehicle_data.dart';
import '../controllers/vehicle_track_controller.dart';
import '../services/road_route_service.dart';
import '../utils/map_arrow_icon.dart';
import '../theme/app_theme_tokens.dart';
import 'notifications_screen.dart'; 
import 'notification_filter_screen.dart';

class VehicleDetailScreen extends StatefulWidget {
  final int? deviceId;
  final String name;
  final String status;
  final Color color;
  final String speed;
  final String distance;
  final String odometer;
  final String time;
  final String livetime;
  final String location;
  final String date;
  final double? latitude;
  final double? longitude;
  final List<VehicleTrackPoint> initialTail;

  const VehicleDetailScreen({
    super.key,
    this.deviceId,
    required this.name,
    required this.status,
    required this.color,
    required this.speed,
    required this.distance,
    required this.odometer,
    required this.time,
    required this.livetime,
    required this.location,
    required this.date,
    this.latitude,
    this.longitude,
    this.initialTail = const <VehicleTrackPoint>[],
  });

  @override
  State<VehicleDetailScreen> createState() => _VehicleDetailScreenState();
}

class _VehicleDetailScreenState extends State<VehicleDetailScreen>
    with TickerProviderStateMixin {
  // ─── UI state ─────────────────────────────────────────────────────────────
  int _currentBottomIndex = 0;
  final Set<int> _loadedDetailTabs = <int>{0};

  final ValueNotifier<double> _sheetProgress = ValueNotifier<double>(0.0);
  final ValueNotifier<double> _historyPanelTop = ValueNotifier<double>(0.0);
  final GlobalKey<_LiveVehicleMapState> _liveMapKey =
      GlobalKey<_LiveVehicleMapState>();

  bool _historyLoading = false;
  bool _historyLoaded = false;
  HistoryRoute _historyRoute = const HistoryRoute(points: <HistoryPoint>[]);
  final DateTime _historyFrom =
      DateTime.now().subtract(const Duration(hours: 1));
  final DateTime _historyTo = DateTime.now();

  // ─── Map / camera ─────────────────────────────────────────────────────────
  GoogleMapController? _mapController;
  bool _userDraggingMap = false;
  DateTime _programmaticCameraUntil = DateTime.fromMillisecondsSinceEpoch(0);
  bool _followEnabled = true;
  static const double _followZoom = 17.5;

  // ─── Car render state ─────────────────────────────────────────────────────
  late LatLng _carLocation;
  double _carRotation = 0.0;
  LatLng _renderPos = const LatLng(0, 0);
  double _renderBearing = 0.0;

  // ─── Tracking controller (GPS → filter → route → animation) ───────────────
  late VehicleTrackController _trackController;

  // ─── API polling ──────────────────────────────────────────────────────────
  Timer? _pollTimer;
  final ValueNotifier<double> _historySliderValue = ValueNotifier<double>(0.0);
  final ValueNotifier<bool> _isHistoryPlaying = ValueNotifier<bool>(false);

  // ─── Cached arrow marker ──────────────────────────────────────────────────
  BitmapDescriptor? _arrowIcon;
  int _arrowColorKey = 0;
  final ValueNotifier<String> _liveStatus = ValueNotifier<String>('');
  final ValueNotifier<String> _liveSpeed = ValueNotifier<String>('00');
  final ValueNotifier<String> _liveOdometer = ValueNotifier<String>('0 km');
  bool _forceNextRefresh = true;
  bool _disposed = false;
  bool _pollInFlight = false;
  static const Duration _pollInterval = Duration(seconds: 2);
  bool _trailDirty = true;

  double _initialSheetFraction(double screenHeight) {
    return 0.20;
  }

  double _minSheetFraction(double screenHeight) {
    return 0.16;
  }

  double _sheetHeightPx(double screenHeight) =>
      screenHeight * _initialSheetFraction(screenHeight);

  EdgeInsets _mapPadding(double screenHeight) {
    final double sheetPx = _sheetHeightPx(screenHeight);
    final double visible = screenHeight - sheetPx - 60;
    final double bottomPad = sheetPx + visible * 0.38;
    return EdgeInsets.only(top: 60, bottom: bottomPad);
  }

  void _recenterOnCar({double? zoom, bool animated = true}) {
    if (_mapController == null) return;
    try {
      _followEnabled = true;
      _userDraggingMap = false;
      _markProgrammaticCamera();
      final CameraUpdate update = CameraUpdate.newCameraPosition(
        CameraPosition(
          target: _renderPos,
          zoom: zoom ?? _followZoom,
          bearing: 0,
          tilt: 0,
        ),
      );
      if (animated) {
        _mapController!.animateCamera(update);
      } else {
        _mapController!.moveCamera(update);
      }
    } catch (_) {
      _mapController = null;
    }
  }

  void _markProgrammaticCamera() {
    _programmaticCameraUntil =
        DateTime.now().add(const Duration(milliseconds: 120));
  }

  List<LatLng> _trailForMap() => _trackController.animator.trailSnapshot();

  // ─── Helpers ──────────────────────────────────────────────────────────────

  IconData _statusIconFor(String status) {
    switch (status.trim().toLowerCase()) {
      case 'running':
        return Icons.directions_car_filled;
      case 'stopped':
        return Icons.local_parking_rounded;
      case 'idle':
        return Icons.pause_circle_outline;
      case 'not reporting':
        return Icons.signal_wifi_off;
      case 'expired':
        return Icons.event_busy;
      default:
        return Icons.directions_car_outlined;
    }
  }

  Color _statusIconColorFor(String status) {
    switch (status.trim().toLowerCase()) {
      case 'running':
        return const Color(0xFF00C853);
      case 'stopped':
        return const Color(0xFFD50000);
      case 'idle':
        return const Color(0xFFFFA000);
      case 'expired':
        return const Color(0xFFF43A6B);
      default:
        return const Color(0xFF757575);
    }
  }

  List<String> _odometerDigits(String raw) {
    final String numeric = raw.replaceAll(RegExp(r'[^0-9.]'), '');
    final double value = double.tryParse(numeric) ?? 0.0;
    final String padded = value.round().toString().padLeft(8, '0');
    return padded.split('');
  }

  String _formatOdometerLabel(String raw) {
    final String numeric = raw.replaceAll(RegExp(r'[^0-9.]'), '');
    final double value = double.tryParse(numeric) ?? 0.0;
    return '${value.toStringAsFixed(2)} km';
  }

  static LatLng _resolveInitialPosition(
    double? lat,
    double? lng,
    String locationText,
  ) {
    if (lat != null && lng != null && (lat != 0.0 || lng != 0.0)) {
      return LatLng(lat, lng);
    }
    final RegExp regex = RegExp(r'(-?\d+\.\d+)');
    final List<RegExpMatch> matches = regex.allMatches(locationText).toList();
    if (matches.length >= 2) {
      final double? pLat = double.tryParse(matches[0].group(1) ?? '');
      final double? pLng = double.tryParse(matches[1].group(1) ?? '');
      if (pLat != null && pLng != null && (pLat != 0.0 || pLng != 0.0)) {
        return LatLng(pLat, pLng);
      }
    }
    return const LatLng(31.5204, 74.3587);
  }

  @override
  void initState() {
    super.initState();
    final LatLng initial = _resolveInitialPosition(
      widget.latitude,
      widget.longitude,
      widget.location,
    );
    _carLocation = initial;
    _renderPos = initial;
    _liveStatus.value = widget.status;
    _liveSpeed.value = widget.speed;
    _liveOdometer.value = widget.odometer;

    _trackController = VehicleTrackController(
      vsync: this,
      deviceId: widget.deviceId,
    )..onFrame = _onSegmentFrame;

    _seedFromWidgetData(initial);

    // Show arrow + green trail immediately, then refresh in background.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _disposed) return;
      final double screenHeight = MediaQuery.sizeOf(context).height;
      _historyPanelTop.value = screenHeight * 0.65;
      _primeMapVisuals();
      _loadArrowIcon();
      _bootstrapLiveRoute();
      _startLiveTracking();
    });
  }

  /// Seeds position, bearing and green trail from the vehicle card data — no wait.
  void _seedFromWidgetData(LatLng fallback) {
    List<LatLng> tailPoints = widget.initialTail
        .map((VehicleTrackPoint p) => LatLng(p.latitude, p.longitude))
        .toList();
    tailPoints = LiveRouteService.dedupe(tailPoints);

    double bearing = 0;
    LatLng position = fallback;

    if (tailPoints.length >= 2) {
      position = tailPoints.last;
      bearing = _bearingFromTail(tailPoints);
      _trackController.seed(position, bearing: bearing);
      _trackController.animator.seedTrailFromPoints(tailPoints);
    } else {
      _trackController.seed(position, bearing: bearing);
    }

    _carLocation = position;
    _renderPos = position;
    _renderBearing = bearing;
    _carRotation = bearing;
    _trailDirty = true;
  }

  Future<void> _loadArrowIcon() async {
    final Color color = _arrowColorForLive();
    final int colorKey = color.toARGB32();
    if (_arrowIcon != null && _arrowColorKey == colorKey) return;

    try {
      final BitmapDescriptor icon = await MapArrowIcon.forColor(color);
      if (!mounted || _disposed) return;
      _arrowIcon = icon;
      _arrowColorKey = colorKey;
      _liveMapKey.currentState?.updateMarker(
        position: _renderPos,
        bearing: _renderBearing,
        arrowIcon: _arrowIcon,
        force: true,
      );
    } catch (_) {
      if (!mounted || _disposed) return;
      _arrowIcon = BitmapDescriptor.defaultMarkerWithHue(
        BitmapDescriptor.hueGreen,
      );
      _liveMapKey.currentState?.updateMarker(
        position: _renderPos,
        bearing: _renderBearing,
        arrowIcon: _arrowIcon,
        force: true,
      );
    }
  }

  void _primeMapVisuals() {
    if (_disposed || !mounted) return;
    _liveMapKey.currentState?.updateMarker(
      position: _renderPos,
      bearing: _renderBearing,
      arrowIcon: _arrowIcon,
      force: true,
    );
    _pushTrailToMap(force: true);
    if (_followEnabled) {
      _followCameraSmooth(force: true);
    }
  }

  void _onSegmentFrame(LatLng position, double bearing) {
    if (_disposed || !mounted) return;
    _renderPos = position;
    _renderBearing = bearing;
    _carLocation = _renderPos;
    _carRotation = _renderBearing;
    _trailDirty = true;

    _liveMapKey.currentState?.updateMarker(
      position: _renderPos,
      bearing: _renderBearing,
      arrowIcon: _arrowIcon,
      fromAnimation: true,
    );
    _pushTrailToMap();

    if (_followEnabled && !_userDraggingMap) {
      _followCameraSmooth(fromAnimation: true);
    }
  }

  void _pushTrailToMap({bool force = false}) {
    final List<LatLng> trail = _trailForMap();
    if (trail.length < 2) return;
    _trailDirty = false;
    _liveMapKey.currentState?.updateTrail(trail, force: force);
  }

  void _readAnimatorState() {
    _renderPos = _trackController.animator.displayPosition;
    _renderBearing = _trackController.animator.displayBearing;
    _carLocation = _renderPos;
    _carRotation = _renderBearing;
  }

  Future<void> _bootstrapLiveRoute() async {
    List<VehicleTrackPoint> tail = widget.initialTail;
    if (tail.isEmpty && widget.deviceId != null) {
      final VehicleModel? cached =
          VehicleService.findCachedDevice(widget.deviceId!);
      if (cached != null && cached.id == widget.deviceId) {
        tail = cached.tail;
      } else {
        for (final VehicleModel vehicle in VehicleData.vehicles) {
          if (vehicle.id == widget.deviceId) {
            tail = vehicle.tail;
            break;
          }
        }
      }
    }

    List<LatLng> points = tail
        .map((VehicleTrackPoint p) => LatLng(p.latitude, p.longitude))
        .toList();
    points = LiveRouteService.dedupe(points);

    if (widget.deviceId != null && points.length < 4) {
      final List<LatLng> bootstrap = await LiveRouteService.bootstrapRoute(
        deviceId: widget.deviceId!,
        tail: tail,
      );
      if (bootstrap.length >= 2) {
        points = bootstrap;
      }
    }

    if (!mounted || _disposed || points.isEmpty) return;

    if (points.length >= 2) {
      final List<LatLng> roadPath = await RoadRouteService.routeBetween(
        from: points.first,
        to: points.last,
        tailHint: points,
      );
      if (roadPath.length >= 2) {
        points = roadPath;
      }
    }

    // Only refresh trail if we are far — never jump the visible car position.
    final LatLng latest = points.last;
    final double bearing = points.length >= 2
        ? _bearingFromTail(points)
        : _renderBearing;
    final double driftMeters =
        LiveRouteService.haversineMeters(_renderPos, latest);

    if (driftMeters >= 50.0) {
      _trackController.seed(latest, bearing: bearing);
      _readAnimatorState();
    }

    if (points.length >= 2) {
      _trackController.animator.seedTrailFromPoints(points);
    }
    _primeMapVisuals();
  }

  Color _arrowColorForLive() {
    final double speed = double.tryParse(_liveSpeed.value) ?? 0.0;
    if (speed > 0) return const Color(0xFF00C853);
    switch (_liveStatus.value.trim().toLowerCase()) {
      case 'running':
        return const Color(0xFF00C853);
      case 'stopped':
        return const Color(0xFFD50000);
      case 'idle':
        return const Color(0xFFFFA000);
      case 'not reporting':
        return const Color(0xFF757575);
      default:
        return const Color(0xFF757575);
    }
  }

  void _onUserMapGesture() {
    if (DateTime.now().isBefore(_programmaticCameraUntil)) return;
    _userDraggingMap = true;
    _followEnabled = false;
  }

  void _onMapCameraIdle() {
    if (_disposed || DateTime.now().isBefore(_programmaticCameraUntil)) return;
    _userDraggingMap = false;
  }

  void _startLiveTracking() {
    _pollTimer?.cancel();

    if (widget.deviceId == null) return;

    _refreshLivePosition();
    _pollTimer = Timer.periodic(_pollInterval, (_) {
      if (!_disposed && mounted) {
        _refreshLivePosition();
      }
    });
  }

  void _stopLiveTracking() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  void _syncVisuals({bool forceTrail = false}) {
    if (_disposed || !mounted) return;
    if (forceTrail || _trailDirty) {
      _pushTrailToMap(force: true);
    }
  }

  /// Camera pans to keep the road arrow marker in view — north-up, marker shows direction.
  void _followCameraSmooth({
    bool force = false,
    bool fromAnimation = false,
  }) {
    if (!_followEnabled ||
        _userDraggingMap ||
        _mapController == null ||
        _disposed) {
      return;
    }

    try {
      _markProgrammaticCamera();
      _mapController!.moveCamera(
        CameraUpdate.newLatLng(_renderPos),
      );
    } catch (_) {
      _mapController = null;
    }
  }

  Future<void> _refreshLivePosition() async {
    if (widget.deviceId == null || !mounted || _disposed || _pollInFlight) {
      return;
    }
    _pollInFlight = true;

    try {
      final List<VehicleModel> devices = await VehicleService.getDevices(
        forceRefresh: _forceNextRefresh,
      );
      _forceNextRefresh = false;
      if (!mounted || _disposed) return;

      VehicleModel? match = VehicleService.findCachedDevice(widget.deviceId!);
      if (match == null) {
        for (final VehicleModel d in devices) {
          if (d.id == widget.deviceId) {
            match = d;
            break;
          }
        }
      }

      if (match == null || match.id != widget.deviceId) return;

      final bool statusChanged = match.status != _liveStatus.value;
      final bool speedChanged = match.speed != _liveSpeed.value;
      final String previousSpeed = _liveSpeed.value;
      if (statusChanged || speedChanged) {
        if (statusChanged) {
          _liveStatus.value = match.status;
        }
        if (speedChanged) {
          _liveSpeed.value = match.speed;
        }
        final double oldSpd = double.tryParse(previousSpeed) ?? 0.0;
        final double newSpd = double.tryParse(match.speed) ?? 0.0;
        if (statusChanged || (oldSpd == 0) != (newSpd == 0)) {
          await _loadArrowIcon();
        }
      }

      if (match.odometer != _liveOdometer.value) {
        _liveOdometer.value = match.odometer;
      }

      if (match.latitude == null || match.longitude == null) return;

      final LatLng serverPos = LatLng(match.latitude!, match.longitude!);
      final LatLng posBefore = _trackController.animator.displayPosition;
      final GpsIngestResult ingestResult =
          await _trackController.ingestVehicleModel(match);
      if (!mounted || _disposed) return;

      if (ingestResult == GpsIngestResult.wrongDevice) return;

      final LatLng posAfter = _trackController.animator.displayPosition;
      final double driftMeters =
          LiveRouteService.haversineMeters(posAfter, serverPos);

      if (ingestResult == GpsIngestResult.rejected && driftMeters >= 12.0) {
        final List<LatLng> tail = match.tail
            .map((VehicleTrackPoint p) => LatLng(p.latitude, p.longitude))
            .toList();
        final double bearing = tail.length >= 2
            ? _bearingFromTail(tail)
            : _trackController.animator.displayBearing;
        _trackController.forceSnapTo(serverPos, bearing: bearing);
      }

      _readAnimatorState();
      final bool moved = posBefore.latitude != posAfter.latitude ||
          posBefore.longitude != posAfter.longitude ||
          ingestResult == GpsIngestResult.snapped ||
          ingestResult == GpsIngestResult.animated;

      if (moved || statusChanged || speedChanged || driftMeters >= 1.0) {
        _trailDirty = moved || driftMeters >= 1.0;
        _liveMapKey.currentState?.updateMarker(
          position: _renderPos,
          bearing: _renderBearing,
          arrowIcon: _arrowIcon,
          force: true,
        );
        _syncVisuals(forceTrail: _trailDirty);
        if (_followEnabled && !_userDraggingMap && moved) {
          _followCameraSmooth(force: true);
        }
      }
    } finally {
      _pollInFlight = false;
    }
  }

  static double _bearingFromTail(List<LatLng> tail) {
    if (tail.length < 2) return 0;
    final LatLng from = tail[tail.length - 2];
    final LatLng to = tail.last;
    final double lat1 = from.latitude * math.pi / 180;
    final double lat2 = to.latitude * math.pi / 180;
    final double dLng = (to.longitude - from.longitude) * math.pi / 180;
    final double y = math.sin(dLng) * math.cos(lat2);
    final double x = math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLng);
    return (math.atan2(y, x) * 180 / math.pi + 360) % 360;
  }

  // ─── Tab management ────────────────────────────────────────────────────────
  void _selectTab(int index) {
    if (_currentBottomIndex == index) return;
    setState(() {
      _currentBottomIndex = index;
      _loadedDetailTabs.add(index);
    });
    if (index == 0) {
      _startLiveTracking();
    } else {
      _stopLiveTracking();
      if (index == 1 && !_historyLoaded) {
        _loadHistory();
      }
    }
  }

  // ─── History ──────────────────────────────────────────────────────────────
  Future<void> _loadHistory({bool force = false}) async {
    if (widget.deviceId == null) return;
    if (!force && _historyLoaded) return;
    setState(() => _historyLoading = true);
    final HistoryRoute route = await HistoryService.getRoute(
      deviceId: widget.deviceId!,
      from: _historyFrom,
      to: _historyTo,
    );
    if (!mounted) return;
    setState(() {
      _historyLoading = false;
      _historyLoaded = true;
      _historyRoute   = route;
      if (route.points.isNotEmpty) _historySliderValue.value = 0;
    });
  }

  Future<void> _shareLocation() async {
    if (widget.deviceId == null) return;
    final Map<String, dynamic>? response = await TrackingApiService.sharing(
      <String, dynamic>{
        'device_id': widget.deviceId.toString(),
        'lat': widget.latitude?.toString() ?? _carLocation.latitude.toString(),
        'lng': widget.longitude?.toString() ?? _carLocation.longitude.toString(),
      },
    );
    if (!mounted) return;
    final String message = response?['url']?.toString() ??
        response?['message']?.toString() ??
        context.tr('Location shared');
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  // ─── Lifecycle ────────────────────────────────────────────────────────────
  @override
  void dispose() {
    _disposed = true;
    _stopLiveTracking();
    _trackController.dispose();
    _mapController?.dispose();
    _mapController = null;
    _sheetProgress.dispose();
    _historyPanelTop.dispose();
    _liveStatus.dispose();
    _liveSpeed.dispose();
    _liveOdometer.dispose();
    _historySliderValue.dispose();
    _isHistoryPlaying.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    final Color accentColor = Theme.of(context).colorScheme.primary;
    final Color mutedColor = context.mutedTextColor;
    final double screenHeight = MediaQuery.of(context).size.height;

    final double maxTopLimit = 120.0;
    final double bottomLimit = screenHeight * 0.8;

    return Scaffold(
      body: IndexedStack(
        index: _currentBottomIndex,
        children: <Widget>[
          Offstage(
            offstage: _currentBottomIndex != 0,
            child: _buildTrackView(),
          ),
          _loadedDetailTabs.contains(1)
              ? _buildHistoryView(
                  maxTopLimit,
                  bottomLimit,
                  screenHeight,
                  accentColor,
                )
              : const SizedBox.shrink(),
          _loadedDetailTabs.contains(2)
              ? NotificationsScreen(
                  key: const ValueKey<String>('vehicle_detail_alerts'),
                  showAlertsOnly: true,
                  vehicleName: widget.name,
                  deviceId: widget.deviceId,
                )
              : const SizedBox.shrink(),
          _loadedDetailTabs.contains(3)
              ? _VehicleStatisticsTab(
                  key: const ValueKey<String>('vehicle_detail_statistics'),
                  vehicleName: widget.name,
                  onBack: () => _selectTab(0),
                )
              : const SizedBox.shrink(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10)],
        ),
        child: BottomNavigationBar(
          backgroundColor: context.containerColor,
          currentIndex: _currentBottomIndex,
          onTap: _selectTab,
          selectedItemColor: accentColor,
          unselectedItemColor: mutedColor,
          type: BottomNavigationBarType.fixed,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
          unselectedLabelStyle: const TextStyle(fontSize: 11),
          items: [
            BottomNavigationBarItem(icon: const Icon(Icons.location_on), label: context.tr('Track')),
            BottomNavigationBarItem(icon: const Icon(Icons.history), label: context.tr('History')),
            BottomNavigationBarItem(icon: const Icon(Icons.notifications), label: context.tr('Alerts')),
            BottomNavigationBarItem(icon: const Icon(Icons.analytics), label: context.tr('Statistics')),
          ],
        ),
      ),
    );
  }

  /// --- TRACK VIEW ---
  Widget _buildTrackView() {
    final double mediaHeight = MediaQuery.of(context).size.height;
    final double initialSheetSize = _initialSheetFraction(mediaHeight);
    final double minSheetSize = _minSheetFraction(mediaHeight);
    final double sheetHeightPx = _sheetHeightPx(mediaHeight);
    final EdgeInsets mapPadding = _mapPadding(mediaHeight);
    final Color textColor = context.textColor;
    final Color mutedColor = context.mutedTextColor;
    final Color accentColor = Theme.of(context).colorScheme.primary;

    return Stack(
      children: [
        Positioned.fill(
          child: RepaintBoundary(
            child: _LiveVehicleMap(
              key: _liveMapKey,
              deviceId: widget.deviceId,
              padding: mapPadding,
              initialTarget: _carLocation,
              initialBearing: _carRotation,
              mapStyle: context.themedMapStyle,
              arrowIcon: _arrowIcon,
              onMapCreated: (GoogleMapController controller) {
                _mapController = controller;
                _primeMapVisuals();
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted && !_disposed) {
                    _primeMapVisuals();
                    _recenterOnCar(animated: false);
                  }
                });
              },
              onCameraMoveStarted: _onUserMapGesture,
              onCameraIdle: _onMapCameraIdle,
            ),
          ),
        ),

        Positioned(
          top: 55,
          left: 16,
          child: _floatingMapButton(
            Icons.arrow_back_ios_new,
            textColor,
            () => Navigator.pop(context),
          ),
        ),
        Positioned(
          top: 55,
          right: 16,
          child: Column(
            children: [
              _floatingMapButton(
                Icons.my_location,
                accentColor,
                () {
                  _followEnabled = true;
                  _userDraggingMap = false;
                  _recenterOnCar(zoom: 17.0);
                },
              ),
              const SizedBox(height: 12),
              _floatingMapButton(Icons.lock, Colors.green, () {}),
              const SizedBox(height: 12),
              _floatingMapButton(Icons.local_parking, Colors.red, () {}),
            ],
          ),
        ),
        Positioned(
          bottom: sheetHeightPx + 20,
          left: 16,
          child: _floatingMapButton(
            Icons.route_outlined,
            Colors.redAccent,
            () => _recenterOnCar(zoom: 17.0),
          ),
        ),

        NotificationListener<DraggableScrollableNotification>(
          onNotification: (DraggableScrollableNotification notification) {
            final double delta =
                notification.maxExtent - notification.minExtent;
            final double next = delta > 0
                ? ((notification.extent - notification.minExtent) / delta)
                    .clamp(0.0, 1.0)
                : 0.0;
            if ((next - _sheetProgress.value).abs() >= 0.02) {
              _sheetProgress.value = next;
            }
            return true;
          },
          child: DraggableScrollableSheet(
            initialChildSize: initialSheetSize,
            minChildSize: minSheetSize,
            maxChildSize: 0.88,
            snap: true,
            snapSizes: <double>[initialSheetSize, 0.88],
            builder: (BuildContext context, ScrollController scrollController) {
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: context.containerColor,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(24),
                        topRight: Radius.circular(24),
                      ),
                      border: context.appTokens.containerBorderColor == null
                          ? null
                          : Border.all(color: context.appTokens.containerBorderColor!),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        const SizedBox(height: 10),
                        Container(
                          height: 4,
                          width: 40,
                          decoration: BoxDecoration(
                            color: mutedColor.withOpacity(0.4),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                          child: ListView(
                            controller: scrollController,
                            physics: const ClampingScrollPhysics(
                              parent: AlwaysScrollableScrollPhysics(),
                            ),
                            cacheExtent: 120,
                            addAutomaticKeepAlives: false,
                            addRepaintBoundaries: true,
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                            children: [
                              ValueListenableBuilder<String>(
                                valueListenable: _liveStatus,
                                builder: (BuildContext context, String status, _) {
                                  return Row(
                                    children: [
                                      Icon(
                                        _statusIconFor(status),
                                        size: 20,
                                        color: _statusIconColorFor(status),
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          widget.name,
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: textColor,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 1,
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                              const SizedBox(height: 10),
                              _buildOdometerRow(context, accentColor, mutedColor),
                              const SizedBox(height: 14),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(top: 2),
                                    child: Icon(Icons.location_on, color: accentColor, size: 16),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      widget.location,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: mutedColor,
                                        fontWeight: FontWeight.w500,
                                        height: 1.3,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Container(
                                height: 90,
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: context.containerColor,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: context.appTokens.containerBorderColor ?? mutedColor.withOpacity(0.25),
                                  ),
                                ),
                                child: ListView(
                                  scrollDirection: Axis.horizontal,
                                  physics: const BouncingScrollPhysics(),
                                  padding: const EdgeInsets.symmetric(horizontal: 10),
                                  children: [
                                    _buildScrollableGridItem(context, Icons.battery_std, "0%", "Dev Battery"),
                                    _buildScrollableGridItem(context, Icons.schedule, "00:00", "Hours"),
                                    _buildScrollableGridItem(context, Icons.battery_saver, "0 V", "Car Battery"),
                                    _buildScrollableGridItem(context, Icons.satellite_alt, "0", "Satellite"),
                                    _buildScrollableGridItem(context, Icons.local_gas_station, "N/A", "Fuel"),
                                    _buildScrollableGridItem(context, Icons.gps_fixed, "N/A", "Accuracy"),
                                    _buildScrollableGridItem(context, Icons.thermostat, "N/A", "Temp"),
                                    _buildScrollableGridItem(context, Icons.route, "false", "Movement"),
                                    _buildScrollableGridItem(context, Icons.directions_car, "N/A", "Movement"),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 14),
                              _buildDeviceServerTimeRow(context, mutedColor, accentColor),
                              const SizedBox(height: 14),
                              SizedBox(
                                height: 120,
                                child: PageView(
                                  physics: const BouncingScrollPhysics(),
                                  children: [
                                    _buildRunningStopCard(textColor, mutedColor, accentColor),
                                    _buildFuelCard(textColor, mutedColor),
                                    _buildSpeedLimitCard(textColor, mutedColor),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 14),
                              _buildQuickActionsCard(textColor, mutedColor),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  Positioned(
                    top: -48,
                    left: 0,
                    right: 0,
                    child: ValueListenableBuilder<double>(
                      valueListenable: _sheetProgress,
                      builder: (BuildContext context, double progress, Widget? child) {
                        return Opacity(
                          opacity: (1.0 - (progress * 2.5)).clamp(0.0, 1.0),
                          child: child,
                        );
                      },
                      child: ValueListenableBuilder<String>(
                        valueListenable: _liveSpeed,
                        builder: (BuildContext context, String speedText, _) {
                          final double currentSpeed =
                              double.tryParse(speedText) ?? 0.0;
                          return Center(
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Container(
                                  height: 96,
                                  width: 96,
                                  decoration: BoxDecoration(
                                    color: context.containerColor,
                                    shape: BoxShape.circle,
                                    border: context.appTokens.containerBorderColor == null
                                        ? null
                                        : Border.all(
                                            color: context.appTokens.containerBorderColor!,
                                          ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.08),
                                        blurRadius: 10,
                                        spreadRadius: 1,
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(
                                  height: 88,
                                  width: 88,
                                  child: RepaintBoundary(
                                    child: CustomPaint(
                                      painter: FullCircularSpeedoPainter(
                                        speedValue: currentSpeed,
                                        scaleTextColor: textColor,
                                      ),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  bottom: 16,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        speedText,
                                        style: TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.bold,
                                          color: textColor,
                                          height: 1.0,
                                        ),
                                      ),
                                      Text(
                                        context.tr("kmph"),
                                        style: TextStyle(
                                          fontSize: 8,
                                          fontWeight: FontWeight.w600,
                                          color: mutedColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  /// --- HISTORY VIEW ---
  Widget _buildHistoryView(double maxTop, double bottomLimit, double screenHeight, Color accentColor) {
    final Color textColor = context.textColor;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: context.containerColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: accentColor, size: 22),
          onPressed: () => _selectTab(0),
        ),
        titleSpacing: 0,
        title: Text(
          widget.name.isNotEmpty ? widget.name : "KL45Q8460",
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textColor),
        ),
        actions: [
          PopupMenuButton<String>(
            position: PopupMenuPosition.over,
            offset: const Offset(0, -310),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            constraints: const BoxConstraints(minWidth: 100, maxWidth: 100, minHeight: 300, maxHeight: 300),
            onSelected: (value) {},
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(color: context.containerColor, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))]),
              child: Row(
                children: [
                  Text(context.tr("Today"), style: TextStyle(color: Colors.grey.shade700, fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(width: 4),
                  Icon(Icons.keyboard_arrow_down, color: accentColor, size: 20),
                ],
              ),
            ),
            itemBuilder: (context) => [
              PopupMenuItem(value: "1h", height: 60, child: Center(child: Text(context.tr("1 Hour"), style: const TextStyle(fontSize: 12)))),
              PopupMenuItem(value: "today", height: 60, child: Center(child: Text(context.tr("Today"), style: const TextStyle(fontSize: 12)))),
              PopupMenuItem(value: "yesterday", height: 60, child: Center(child: Text(context.tr("Yesterday"), style: const TextStyle(fontSize: 12)))),
              PopupMenuItem(value: "week", height: 60, child: Center(child: Text(context.tr("Week"), style: const TextStyle(fontSize: 12)))),
              PopupMenuItem(value: "custom", height: 60, child: Center(child: Text(context.tr("Custom"), style: const TextStyle(fontSize: 12)))),
            ],
          ),
          const SizedBox(width: 12),
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: Icon(Icons.filter_alt_outlined, color: accentColor, size: 26),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const NotificationFilterScreen())),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: RepaintBoundary(
              child: _HistoryMap(route: _historyRoute),
            ),
          ),
          if (_historyLoading)
            const Positioned.fill(
              child: ColoredBox(
                color: Color(0x55000000),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
          Positioned(top: 130, left: 16, child: Column(children: [_floatingMapButton(Icons.map_outlined, context.textColor, () {}), const SizedBox(height: 12), _floatingMapButton(Icons.settings_outlined, context.textColor, () {})])),
          Positioned(
            top: 320, right: 16,
            child: Column(
              children: [
                _floatingMapButton(Icons.anchor, context.textColor, () {}), const SizedBox(height: 12),
                _floatingMapButton(Icons.local_parking, accentColor, () {}), const SizedBox(height: 12),
                _floatingMapButton(Icons.my_location, context.textColor, () {}), const SizedBox(height: 12),
                Container(
                  width: 38,
                  decoration: BoxDecoration(color: context.containerColor, borderRadius: BorderRadius.circular(8), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)]),
                  child: Column(children: [SizedBox(height: 38, width: 38, child: IconButton(padding: EdgeInsets.zero, icon: Icon(Icons.add, size: 22, color: context.textColor), onPressed: () {})), Container(width: 25, height: 1, color: Colors.grey.withOpacity(0.2)), SizedBox(height: 38, width: 38, child: IconButton(padding: EdgeInsets.zero, icon: Icon(Icons.remove, size: 22, color: context.textColor), onPressed: () {}))]),
                ),
              ],
            ),
          ),
          ValueListenableBuilder<double>(
            valueListenable: _historyPanelTop,
            builder: (BuildContext context, double top, Widget? child) {
              return Positioned(
                top: top,
                left: 0,
                right: 0,
                child: child!,
              );
            },
            child: GestureDetector(
              onVerticalDragUpdate: (DragUpdateDetails details) {
                _historyPanelTop.value =
                    (_historyPanelTop.value + details.delta.dy)
                        .clamp(maxTop, bottomLimit);
              },
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(color: Colors.black.withOpacity(0.12), borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16))),
                padding: EdgeInsets.fromLTRB(10, screenHeight * 0.05, 10, 20),
                child: Container(
                  width: double.infinity, padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(color: context.containerColor, borderRadius: BorderRadius.circular(26), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 15, offset: const Offset(0, -4))]),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [_historyDateLabel(context.tr("From :"), widget.date.isNotEmpty ? widget.date : "29 Jul 2026", accentColor, alignStart: true), Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: accentColor, borderRadius: BorderRadius.circular(15)), child: Text(widget.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11))), _historyDateLabel(context.tr("To :"), widget.date.isNotEmpty ? widget.date : "29 Jul 2026", accentColor, alignStart: false)]),
                      const SizedBox(height: 14), Divider(height: 1, thickness: 0.8, color: context.mutedTextColor.withOpacity(0.3)), const SizedBox(height: 14),
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [_historyStatItem(Icons.speed, "${_historyRoute.avgSpeed?.toStringAsFixed(0) ?? widget.speed} ${context.tr('kmph')}", accentColor), _historyStatItem(Icons.access_time_filled_outlined, _historyRoute.durationLabel ?? "00:00 Hrs", accentColor), _historyStatItem(Icons.route_outlined, "${_historyRoute.distanceKm?.toStringAsFixed(1) ?? widget.distance} km", accentColor)]),
                      const SizedBox(height: 16),
                      Stack(
                        children: [
                          Container(height: 40, width: double.infinity, decoration: BoxDecoration(color: context.mutedTextColor.withOpacity(0.1), borderRadius: BorderRadius.circular(20))),
                          ValueListenableBuilder<double>(
                            valueListenable: _historySliderValue,
                            builder: (BuildContext context, double sliderValue, _) {
                              return SliderTheme(
                                data: SliderTheme.of(context).copyWith(trackHeight: 40, thumbShape: SliderComponentShape.noThumb, overlayShape: SliderComponentShape.noOverlay, activeTrackColor: accentColor.withOpacity(0.15), inactiveTrackColor: Colors.transparent),
                                child: Slider(
                                  value: sliderValue,
                                  onChanged: (double v) => _historySliderValue.value = v,
                                ),
                              );
                            },
                          ),
                          Positioned.fill(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Row(
                                children: [
                                  ValueListenableBuilder<bool>(
                                    valueListenable: _isHistoryPlaying,
                                    builder: (BuildContext context, bool playing, _) {
                                      return GestureDetector(
                                        onTap: () => _isHistoryPlaying.value = !playing,
                                        child: Icon(
                                          playing ? Icons.pause_circle_filled : Icons.play_circle_fill,
                                          color: accentColor,
                                          size: 30,
                                        ),
                                      );
                                    },
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(child: Text("00:00:00 / 01:20:00", style: TextStyle(color: context.mutedTextColor, fontSize: 12, fontWeight: FontWeight.w600))),
                                  PopupMenuButton<String>(
                                    offset: const Offset(0, -180),
                                    onSelected: (v) {},
                                    child: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: accentColor, borderRadius: BorderRadius.circular(12)), child: const Text("1.0x", style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold))),
                                    itemBuilder: (context) => ["0.5x", "1.0x", "1.5x", "2.0x"].map((s) => PopupMenuItem(value: s, child: Text(s))).toList(),
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

  /// --- HELPER WIDGETS ---
  Widget _historyDateLabel(String label, String date, Color color, {required bool alignStart}) {
    return Column(
      crossAxisAlignment: alignStart ? CrossAxisAlignment.start : CrossAxisAlignment.end,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
        Text(date, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  Widget _historyStatItem(IconData icon, String value, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 4),
        Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: context.textColor)),
      ],
    );
  }

  Widget _floatingMapButton(IconData icon, Color iconColor, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 38, width: 38,
        decoration: BoxDecoration(color: context.containerColor, borderRadius: BorderRadius.circular(8), border: context.appTokens.containerBorderColor == null ? null : Border.all(color: context.appTokens.containerBorderColor!), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))]),
        child: Icon(icon, color: iconColor, size: 20),
      ),
    );
  }

  Widget _buildOdometerRow(
    BuildContext context,
    Color accentColor,
    Color mutedColor,
  ) {
    return ValueListenableBuilder<String>(
      valueListenable: _liveOdometer,
      builder: (BuildContext context, String odometerValue, _) {
        final List<String> digits = _odometerDigits(odometerValue);
        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(Icons.speed_outlined, color: accentColor, size: 18),
            const SizedBox(width: 6),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  context.tr('Odometer'),
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: mutedColor,
                  ),
                ),
                Text(
                  _formatOdometerLabel(odometerValue),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: context.textColor,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 8),
            ...digits.map(
              (String digit) => _buildOdometerDigit(context, digit),
            ),
            const Spacer(),
            _miniIconBadge(Icons.severe_cold, Colors.pink),
            _miniIconBadge(Icons.satellite_alt, Colors.green),
            _miniIconBadge(Icons.power_settings_new, Colors.green),
            _miniIconBadge(Icons.vpn_key, Colors.green),
            _miniIconBadge(Icons.battery_charging_full, Colors.green),
          ],
        );
      },
    );
  }

  Widget _buildOdometerDigit(BuildContext context, String digit) {
    return Container(
      margin: const EdgeInsets.only(right: 2),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
      decoration: BoxDecoration(
        color: context.containerColor,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: context.appTokens.containerBorderColor ??
              context.mutedTextColor.withOpacity(0.35),
        ),
      ),
      child: Text(
        digit,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: context.textColor,
        ),
      ),
    );
  }

  Widget _miniIconBadge(IconData icon, Color color) {
    return Container(margin: const EdgeInsets.only(left: 4), padding: const EdgeInsets.all(5), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(5)), child: Icon(icon, color: color, size: 13));
  }

  Widget _buildScrollableGridItem(BuildContext context, IconData icon, String value, String label) {
    return SizedBox(
      width: 85,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: context.textColor, size: 22),
          const SizedBox(height: 5),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: context.textColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            context.tr(label),
            style: TextStyle(
              fontSize: 10,
              color: context.mutedTextColor,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceServerTimeRow(BuildContext context, Color mutedColor, Color accentColor) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: context.containerColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: context.appTokens.containerBorderColor ?? mutedColor.withOpacity(0.25),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                Text(
                  widget.livetime,
                  style: TextStyle(fontSize: 12, color: accentColor, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Text(
                  context.tr("Device Time"),
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: mutedColor),
                ),
              ],
            ),
          ),
          Container(width: 1, height: 28, color: mutedColor.withOpacity(0.3)),
          Expanded(
            child: Column(
              children: [
                Text(
                  widget.livetime,
                  style: TextStyle(fontSize: 12, color: accentColor, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Text(
                  context.tr("Server Time"),
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: mutedColor),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(BuildContext context, Color color, String stateLabel, String durationValue) {
    return Row(
      children: [
        Container(height: 18, width: 18, decoration: BoxDecoration(color: color.withOpacity(0.12), shape: BoxShape.circle, border: Border.all(color: color, width: 2)), padding: const EdgeInsets.all(3), child: Container(decoration: BoxDecoration(color: color, shape: BoxShape.circle))),
        const SizedBox(width: 12),
        SizedBox(width: 70, child: Text(context.tr(stateLabel), style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal, color: context.mutedTextColor))),
        Text(durationValue, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: context.mutedTextColor)),
      ],
    );
  }

  Widget _buildRunningStopCard(
    Color textColor,
    Color mutedColor,
    Color accentColor,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(color: context.containerColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: context.appTokens.containerBorderColor ?? mutedColor.withValues(alpha: 0.25)), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))]),
      child: Row(
        children: [
          SizedBox(
            width: 65,
            child: ValueListenableBuilder<String>(
              valueListenable: _liveOdometer,
              builder: (BuildContext context, String odometerValue, _) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.speed_outlined, color: accentColor, size: 22),
                    const SizedBox(height: 4),
                    Text(
                      _formatOdometerLabel(odometerValue),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                    ),
                  ],
                );
              },
            ),
          ),
          Container(width: 1, height: 75, color: Colors.black.withValues(alpha: 0.06), margin: const EdgeInsets.symmetric(horizontal: 10)),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [_buildSummaryRow(context, const Color(0xff55b985), "Running :", "00:00:00 Hrs"), const SizedBox(height: 6), _buildSummaryRow(context, const Color(0xfff53d6b), "Stop :", "00:00:00 Hrs"), const SizedBox(height: 6), _buildSummaryRow(context, const Color(0xffe2ab2f), "Idle :", "00:00:00 Hrs"), const SizedBox(height: 6), _buildSummaryRow(context, const Color(0xff2aa1ca), "Inactive :", "00:00:00 Hrs")])),
        ],
      ),
    );
  }

  Widget _buildFuelCard(Color textColor, Color mutedColor) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(color: context.containerColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: context.appTokens.containerBorderColor ?? mutedColor.withValues(alpha: 0.25)), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))]),
      child: Row(
        children: [
          const SizedBox(width: 70, child: Center(child: Icon(Icons.local_gas_station_rounded, size: 32, color: Colors.orange))),
          Container(width: 1, height: 75, color: Colors.black.withValues(alpha: 0.06), margin: const EdgeInsets.symmetric(horizontal: 10)),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [_buildFuelRow(context, Icons.speed, Colors.teal, "Fuel Mileage :", "10 km/ltr"), const SizedBox(height: 6), _buildFuelRow(context, Icons.local_gas_station_rounded, Colors.orange.shade600, "Fuel Consumption :", "0.00 ltr"), const SizedBox(height: 6), _buildFuelRow(context, Icons.payments_rounded, Colors.green.shade600, "Fuel Cost :", "0.00 INR")])),
        ],
      ),
    );
  }

  Widget _buildFuelRow(BuildContext context, IconData icon, Color iconColor, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 18),
        const SizedBox(width: 8),
        SizedBox(width: 95, child: Text(context.tr(label), style: TextStyle(fontSize: 11, fontWeight: FontWeight.normal, color: context.mutedTextColor))),
        Text(value, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: context.textColor)),
      ],
    );
  }

  Widget _buildSpeedLimitCard(Color textColor, Color mutedColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.containerColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.appTokens.containerBorderColor ?? mutedColor.withValues(alpha: 0.25)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildSpeedBox(
              context: context,
              color: const Color(0xFFBCE9FF),
              icon: Icons.speed_outlined,
              label: "Avg Speed",
              value: "0",
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _buildSpeedBox(
              context: context,
              color: const Color(0xFFFFB8B8),
              icon: Icons.speed_rounded,
              label: "Max Speed",
              value: "0",
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpeedBox({
    required BuildContext context,
    required Color color,
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, color: const Color(0xFF1F2937), size: 22),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  context.tr(label),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsCard(Color textColor, Color mutedColor) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: context.containerColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: context.appTokens.containerBorderColor ?? mutedColor.withValues(alpha: 0.25),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildActionButton(Icons.directions_car, Colors.red, "Update\nIcon"),
                _buildActionButton(Icons.speed, Colors.green, "Update\nOdometer"),
                _buildActionButton(Icons.phone, Colors.cyan.shade600, "Call\nDriver", hasBg: true),
                _buildActionButton(Icons.engineering, Colors.orange, "Update\nEngine"),
                _buildActionButton(Icons.group_add, Colors.purple, "Add\nGroup"),
                _buildActionButton(Icons.speed, Colors.redAccent, "overspeed\nLimit"),
                _buildActionButton(Icons.streetview, Colors.blueAccent, "Street\nView"),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildActionButton(Icons.local_gas_station, Colors.teal, "Fuel Cost\nPer Liter"),
                _buildActionButton(Icons.av_timer, Colors.brown, "Mileage\nPer Liter"),
                _buildActionButton(Icons.location_on, Colors.redAccent, "Share\nLocation", onTap: _shareLocation),
                _buildActionButton(Icons.map, Colors.orange.shade700, "Add\nGeofence"),
                _buildActionButton(Icons.notifications_active, Colors.amber, "Add\nReminder"),
                _buildActionButton(Icons.build_circle, Colors.deepOrange, "Engine\ncost"),
                _buildActionButton(Icons.assignment, Colors.blueGrey, "Upload\nDocs"),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
    IconData icon,
    Color color,
    String label, {
    bool hasBg = false,
    VoidCallback? onTap,
  }) {
    return SizedBox(
      width: 80,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: hasBg ? color : color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: hasBg ? Colors.white : color,
              size: 24,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            context.tr(label),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: context.textColor.withValues(alpha: 0.8),
              height: 1.2,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
        ),
      ),
    );
  }
}

class _StatItem {
  final String title;
  final String value;
  final String imagePath;

  const _StatItem(this.title, this.value, this.imagePath);
}

const List<_StatItem> _statItems = <_StatItem>[
  _StatItem('Route length', '0.0 km', 'assets/route_length.png'),
  _StatItem('Move duration', '00:00:00', 'assets/move_duration.png'),
  _StatItem('Stop duration', '00:00:00', 'assets/stop_duration.png'),
  _StatItem('Idle duration', '00:00:00', 'assets/engine_work.png'),
  _StatItem('Top speed', '0.00 kmph', 'assets/top-speed.png'),
  _StatItem('Average speed', '0.00 kmph', 'assets/top-speed.png'),
  _StatItem('Overspeed count', '0', 'assets/over_speed.png'),
  _StatItem('Stop count', '0', 'assets/stop_count.png'),
  _StatItem('Avg.fuel cons.', '0.00 km/Ltr', 'assets/fuel_consum.png'),
  _StatItem('Fuel cost', 'INR 0.00', 'assets/fuel_cost.png'),
  _StatItem('Engine work', 'INR 0.00', 'assets/engine_work.png'),
  _StatItem('Fuel consumption', '0.0 Liter', 'assets/fuel_consum.png'),
  _StatItem('Odometer', '28152.79 km', 'assets/odometer.png'),
  _StatItem('Engine hours', '00:00:00', 'assets/engine_work.png'),
];

class _HistoryMap extends StatefulWidget {
  const _HistoryMap({required this.route});

  final HistoryRoute route;

  @override
  State<_HistoryMap> createState() => _HistoryMapState();
}

class _HistoryMapState extends State<_HistoryMap> {
  Set<Polyline> _polylines = const <Polyline>{};
  Set<Marker> _markers = const <Marker>{};
  List<LatLng> _points = const <LatLng>[];

  @override
  void initState() {
    super.initState();
    _applyRoute(widget.route);
  }

  @override
  void didUpdateWidget(covariant _HistoryMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.route != widget.route) {
      _applyRoute(widget.route);
    }
  }

  void _applyRoute(HistoryRoute route) {
    _points = route.points.map((HistoryPoint p) => p.position).toList();
    if (_points.length >= 2) {
      _polylines = <Polyline>{
        Polyline(
          polylineId: const PolylineId('history_route'),
          points: _points,
          color: const Color(0xFFF53D6B),
          width: 4,
        ),
      };
    } else {
      _polylines = const <Polyline>{};
    }

    if (_points.isNotEmpty) {
      _markers = <Marker>{
        Marker(
          markerId: const MarkerId('history_start'),
          position: _points.first,
        ),
        if (_points.length > 1)
          Marker(
            markerId: const MarkerId('history_end'),
            position: _points.last,
          ),
      };
    } else {
      _markers = const <Marker>{};
    }
  }

  @override
  Widget build(BuildContext context) {
    final LatLng target = _points.isNotEmpty
        ? _points.first
        : const LatLng(31.5204, 74.3587);

    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: target,
        zoom: 14.0,
      ),
      style: context.themedMapStyle,
      zoomControlsEnabled: false,
      myLocationEnabled: false,
      compassEnabled: false,
      mapToolbarEnabled: false,
      polylines: _polylines,
      markers: _markers,
    );
  }
}

class _VehicleStatisticsTab extends StatefulWidget {
  const _VehicleStatisticsTab({
    super.key,
    required this.vehicleName,
    required this.onBack,
  });

  final String vehicleName;
  final VoidCallback onBack;

  @override
  State<_VehicleStatisticsTab> createState() => _VehicleStatisticsTabState();
}

class _VehicleStatisticsTabState extends State<_VehicleStatisticsTab> {
  String _selectedStatFilter = 'Today';

  @override
  Widget build(BuildContext context) {
    final Color accentColor = Theme.of(context).colorScheme.primary;
    final Color textColor = context.textColor;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: context.containerColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: accentColor, size: 20),
          onPressed: widget.onBack,
        ),
        title: Text(
          '${widget.vehicleName} ${context.tr('Statistics')}',
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: <Widget>[
          const SliverToBoxAdapter(child: SizedBox(height: 12)),
          SliverToBoxAdapter(child: _buildStatFiltersGrid(accentColor)),
          const SliverToBoxAdapter(child: SizedBox(height: 12)),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.6,
              ),
              delegate: SliverChildBuilderDelegate(
                (BuildContext context, int index) {
                  final _StatItem item = _statItems[index];
                  return _buildStatCard(item.title, item.value, item.imagePath);
                },
                childCount: _statItems.length,
                addAutomaticKeepAlives: false,
                addRepaintBoundaries: true,
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 20)),
        ],
      ),
    );
  }

  Widget _buildStatFiltersGrid(Color accentColor) {
    const List<String> filters = <String>[
      'Today',
      'Yesterday',
      '2 Days',
      '3 Days',
      'This Week',
      'Last Week',
      'This Month',
      'Last Month',
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: filters.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 2.2,
        ),
        itemBuilder: (BuildContext context, int index) {
          final String filter = filters[index];
          final bool isSelected = _selectedStatFilter == filter;
          return GestureDetector(
            onTap: () => setState(() => _selectedStatFilter = filter),
            child: Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: isSelected ? accentColor : context.containerColor,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: accentColor, width: 1.2),
              ),
              child: Text(
                context.tr(filter),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isSelected ? Colors.white : accentColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 10.5,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatCard(String title, String value, String imagePath) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.containerColor,
        borderRadius: BorderRadius.circular(12),
        border: context.appTokens.containerBorderColor == null
            ? null
            : Border.all(color: context.appTokens.containerBorderColor!),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Expanded(
                child: Text(
                  context.tr(title),
                  style: TextStyle(
                    color: context.mutedTextColor,
                    fontSize: 15.0,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Image.asset(
                imagePath,
                height: 26,
                width: 26,
                cacheWidth: 52,
                cacheHeight: 52,
                filterQuality: FilterQuality.low,
                errorBuilder: (BuildContext c, Object e, StackTrace? s) => Icon(
                  Icons.bar_chart,
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              color: context.textColor,
              fontSize: 18.0,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _LiveVehicleMap extends StatefulWidget {
  const _LiveVehicleMap({
    super.key,
    required this.deviceId,
    required this.padding,
    required this.initialTarget,
    required this.initialBearing,
    required this.mapStyle,
    required this.arrowIcon,
    required this.onMapCreated,
    required this.onCameraMoveStarted,
    required this.onCameraIdle,
  });

  final int? deviceId;
  final EdgeInsets padding;
  final LatLng initialTarget;
  final double initialBearing;
  final String? mapStyle;
  final BitmapDescriptor? arrowIcon;
  final ValueChanged<GoogleMapController> onMapCreated;
  final VoidCallback onCameraMoveStarted;
  final VoidCallback onCameraIdle;

  @override
  State<_LiveVehicleMap> createState() => _LiveVehicleMapState();
}

class _LiveVehicleMapState extends State<_LiveVehicleMap> {
  Marker? _arrowMarker;
  Set<Polyline> _polylines = <Polyline>{};
  LatLng? _appliedPos;
  double _appliedBearing = 0.0;
  int _appliedTrailLen = 0;
  LatLng? _appliedTrailTip;

  String get _markerIdValue =>
      'vehicle_arrow_${widget.deviceId ?? 'unknown'}';

  String get _trailIdValue =>
      'vehicle_trail_${widget.deviceId ?? 'unknown'}';

  Set<Marker> get _markers =>
      _arrowMarker == null ? <Marker>{} : <Marker>{_arrowMarker!};

  @override
  void didUpdateWidget(covariant _LiveVehicleMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.arrowIcon != widget.arrowIcon && _arrowMarker != null) {
      updateMarker(
        position: _arrowMarker!.position,
        bearing: _arrowMarker!.rotation,
        arrowIcon: widget.arrowIcon,
        force: true,
      );
    }
  }

  void updateMarker({
    required LatLng position,
    required double bearing,
    BitmapDescriptor? arrowIcon,
    bool force = false,
    bool fromAnimation = false,
  }) {
    if (!mounted) return;

    final LatLng? prev = _appliedPos;
    final double posDelta = prev == null
        ? 999.0
        : LiveRouteService.haversineMeters(prev, position);
    final double bearingDelta =
        prev == null ? 999.0 : (bearing - _appliedBearing).abs();

    final double posThreshold = fromAnimation ? 0.01 : 0.08;
    final double bearingThreshold = fromAnimation ? 0.3 : 1.0;

    if (!force &&
        posDelta < posThreshold &&
        bearingDelta < bearingThreshold &&
        _arrowMarker != null) {
      return;
    }

    _appliedPos = position;
    _appliedBearing = bearing;

    final BitmapDescriptor icon = arrowIcon ??
        widget.arrowIcon ??
        BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);

    _arrowMarker = Marker(
      markerId: MarkerId(_markerIdValue),
      position: position,
      rotation: bearing,
      flat: true,
      anchor: MapArrowIcon.markerAnchor,
      icon: icon,
      zIndexInt: 10,
    );

    setState(() {});
  }

  void updateTrail(List<LatLng> trail, {bool force = false}) {
    if (!mounted) return;

    if (trail.length < 2) {
      if (_polylines.isEmpty) return;
      _polylines = <Polyline>{};
      _appliedTrailLen = 0;
      _appliedTrailTip = null;
      setState(() {});
      return;
    }

    final LatLng tip = trail.last;
    if (!force &&
        _appliedTrailLen == trail.length &&
        _appliedTrailTip != null &&
        LiveRouteService.haversineMeters(_appliedTrailTip!, tip) < 0.03) {
      return;
    }

    _appliedTrailLen = trail.length;
    _appliedTrailTip = tip;
    _polylines = <Polyline>{
      Polyline(
        polylineId: PolylineId(_trailIdValue),
        points: trail,
        color: const Color(0xFF00E676),
        width: 5,
        geodesic: true,
        zIndex: 1,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
        jointType: JointType.round,
      ),
    };
    setState(() {});
  }

  void clearTrailOverlay() {
    if (!mounted || _polylines.isEmpty) return;
    _polylines = <Polyline>{};
    _appliedTrailLen = 0;
    _appliedTrailTip = null;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return GoogleMap(
      key: const ValueKey<String>('vehicle_track_map'),
      padding: widget.padding,
      initialCameraPosition: CameraPosition(
        target: widget.initialTarget,
        zoom: 17.5,
        bearing: widget.initialBearing,
      ),
      style: widget.mapStyle,
      onMapCreated: widget.onMapCreated,
      onCameraMoveStarted: widget.onCameraMoveStarted,
      onCameraIdle: widget.onCameraIdle,
      gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
        Factory<EagerGestureRecognizer>(() => EagerGestureRecognizer()),
      },
      myLocationEnabled: false,
      zoomControlsEnabled: false,
      mapToolbarEnabled: false,
      compassEnabled: false,
      rotateGesturesEnabled: true,
      markers: _markers,
      polylines: _polylines,
    );
  }
}

class FullCircularSpeedoPainter extends CustomPainter {
  final double speedValue;
  final Color scaleTextColor;
  FullCircularSpeedoPainter({required this.speedValue, this.scaleTextColor = Colors.black87});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final rect = Rect.fromLTWH(2, 2, size.width - 4, size.height - 4);
    final circlePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..shader = const SweepGradient(
        colors: <Color>[Colors.green, Colors.yellow, Colors.orange, Colors.red, Colors.green],
      ).createShader(rect);
    canvas.drawCircle(center, radius - 2, circlePaint);
    const double startAngle = math.pi * 0.75;
    const double maxSweepAngle = math.pi * 1.5;
    final List<String> scale = <String>["0", "_", "50", "_", "100", "_", "150", "_", "200"];
    for (int i = 0; i < scale.length; i++) {
      final double angle = startAngle + (i * maxSweepAngle / (scale.length - 1));
      final Paint tickPaint = Paint()
        ..color = scale[i] == "_" ? scaleTextColor.withOpacity(0.35) : scaleTextColor
        ..strokeWidth = scale[i] == "_" ? 1.2 : 1.6;
      final Offset tickStart = Offset(
        center.dx + (radius - 4) * math.cos(angle),
        center.dy + (radius - 4) * math.sin(angle),
      );
      final Offset tickEnd = Offset(
        center.dx + (radius - 11) * math.cos(angle),
        center.dy + (radius - 11) * math.sin(angle),
      );
      canvas.drawLine(tickStart, tickEnd, tickPaint);
      if (scale[i] != "_") {
        _drawScaleText(canvas, center, scale[i], angle, radius - 20);
      }
    }
    final double needleAngle =
        startAngle + ((speedValue / 200).clamp(0.0, 1.0) * maxSweepAngle);
    final Offset tip = Offset(
      center.dx + (radius - 13) * math.cos(needleAngle),
      center.dy + (radius - 13) * math.sin(needleAngle),
    );
    canvas.drawLine(center, tip, Paint()..color = Colors.red..strokeWidth = 2.2);
    canvas.drawCircle(center, 5, Paint()..color = Colors.black87);
    canvas.drawCircle(center, 3, Paint()..color = Colors.red);
  }

  void _drawScaleText(
    Canvas canvas,
    Offset center,
    String text,
    double angle,
    double distance,
  ) {
    final TextPainter tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: scaleTextColor,
          fontSize: 7,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    canvas.save();
    canvas.translate(center.dx + distance * math.cos(angle) - tp.width / 2, center.dy + distance * math.sin(angle) - tp.height / 2);
    tp.paint(canvas, Offset.zero);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant FullCircularSpeedoPainter oldDelegate) => oldDelegate.speedValue != speedValue || oldDelegate.scaleTextColor != scaleTextColor;
}
