import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import 'dart:async';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/app_l10n.dart';
import '../models/vehicle_model.dart';
import '../services/history_service.dart';
import 'vehicle_history_screen.dart';
import '../services/live_route_service.dart';
import '../services/tracking_api_service.dart';
import '../services/vehicle_service.dart';
import '../services/vehicle_detail_api_service.dart';
import '../services/vehicle_detail_fast_api_service.dart';
import '../services/vehicle_detail_telemetry_service.dart';
import '../services/live_device_socket_service.dart';
import '../utils/report_period.dart';
import '../data/vehicle_data.dart';
import '../controllers/vehicle_track_controller.dart';
import '../services/road_route_service.dart';
import '../utils/live_location_text.dart';
import '../theme/tracking_map_style.dart';
import '../utils/map_car_icon.dart';
import '../utils/vehicle_status_colors.dart';
import '../utils/vehicle_speed_utils.dart';
import '../utils/vehicle_category_map_icon.dart';
import '../services/vehicle_icon_service.dart';
import '../widgets/update_vehicle_icon_dialog.dart';
import '../widgets/update_odometer_dialog.dart';
import '../widgets/call_driver_dialog.dart';
import '../widgets/update_engine_number_dialog.dart';
import '../widgets/add_group_device_dialog.dart';
import '../widgets/update_device_value_dialog.dart';
import '../widgets/share_live_location_dialog.dart';
import '../services/live_location_share_service.dart';
import '../services/geofence_service.dart';
import '../screens/settings_screen/add_geofence_screen.dart';
import '../screens/settings_screen/add_reminder_picker_screen.dart';
import '../screens/settings_screen/add_new_reminder_screen.dart';
import '../screens/vehicle_documents_screen.dart';
import '../models/device_group_model.dart';
import '../services/vehicle_device_edit_service.dart';
import '../services/vehicle_driver_phone_service.dart';
import '../services/vehicle_group_service.dart';
import '../theme/app_theme_tokens.dart';
import 'notifications_screen.dart';
import 'notification_filter_screen.dart';
import 'send_command_screen.dart';

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
  final String? deviceTime;
  final String? serverTime;
  final String? runningDuration;
  final String? stopDuration;
  final String? idleDuration;
  final String? inactiveDuration;
  final String? fuelMileage;
  final String? fuelConsumption;
  final String? fuelCost;
  final String? avgSpeed;
  final String? maxSpeed;
  final String? devBattery;
  final String? engineHours;
  final String? carBattery;
  final String? satellites;
  final String? fuelLevel;
  final String? accuracy;
  final String? temperature;
  final String? movement;
  final VehicleModel? vehicle;

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
    this.deviceTime,
    this.serverTime,
    this.runningDuration,
    this.stopDuration,
    this.idleDuration,
    this.inactiveDuration,
    this.fuelMileage,
    this.fuelConsumption,
    this.fuelCost,
    this.avgSpeed,
    this.maxSpeed,
    this.devBattery,
    this.engineHours,
    this.carBattery,
    this.satellites,
    this.fuelLevel,
    this.accuracy,
    this.temperature,
    this.movement,
    this.vehicle,
  });

  @override
  State<VehicleDetailScreen> createState() => _VehicleDetailScreenState();
}

class _VehicleDetailScreenState extends State<VehicleDetailScreen>
    with TickerProviderStateMixin {
  // ─── UI state ─────────────────────────────────────────────────────────────
  int _currentBottomIndex = 0;
  final ValueNotifier<double> _sheetProgress = ValueNotifier<double>(0.0);
  final GlobalKey<_LiveVehicleMapState> _liveMapKey =
      GlobalKey<_LiveVehicleMapState>();

  // ─── Map / camera ─────────────────────────────────────────────────────────
  GoogleMapController? _mapController;
  bool _userDraggingMap = false;
  DateTime _programmaticCameraUntil = DateTime.fromMillisecondsSinceEpoch(0);
  bool _followEnabled = true;
  static const double _followZoom = liveTrackInitialZoom;
  MapType _mapType = MapType.normal;
  bool _trafficEnabled = false;
  bool _showTrail = true;
  bool _mapToolsMenuOpen = false;

  static const Color _mapToolsPink = Color(0xFFFF2F68);
  static const String _supportPhoneDisplay = '9893311111';

  // ─── Car render state ─────────────────────────────────────────────────────
  late LatLng _carLocation;
  double _carRotation = 0.0;
  LatLng _renderPos = const LatLng(0, 0);
  double _renderBearing = 0.0;

  // ─── Tracking controller (GPS → filter → route → animation) ───────────────
  late VehicleTrackController _trackController;

  // ─── API polling ──────────────────────────────────────────────────────────
  Timer? _pollTimer;
  StreamSubscription<VehicleModel>? _liveDeviceSub;
  bool _liveNetworkInFlight = false;

  // ─── Cached map marker (category icon or arrow) ───────────────────────────
  BitmapDescriptor? _arrowIcon;
  int _arrowColorKey = 0;
  Offset _markerAnchor = MapCarIcon.markerAnchor;
  bool _markerUsesCategoryIcon = false;
  final ValueNotifier<String> _liveStatus = ValueNotifier<String>('');
  final ValueNotifier<String> _liveSpeed = ValueNotifier<String>('00');
  final ValueNotifier<String> _liveOdometer = ValueNotifier<String>('0 km');
  final ValueNotifier<String> _liveLocation = ValueNotifier<String>('');
  late final ValueNotifier<VehicleModel> _liveTelemetry;
  bool _locationResolveInFlight = false;
  bool _forceNextRefresh = true;
  bool _disposed = false;
  int _historyWarmGeneration = 0;
  static const Duration _pollInterval = Duration(seconds: 2);
  bool _trailDirty = true;
  int _lastFollowCameraMs = 0;
  int _lastTrailPushMs = 0;

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

  VehicleModel _vehicleSnapshotFromWidget() {
    if (widget.vehicle != null) {
      return widget.vehicle!;
    }
    return VehicleModel(
      id: widget.deviceId,
      name: widget.name,
      status: widget.status,
      color: widget.color,
      speed: widget.speed,
      distance: widget.distance,
      odometer: widget.odometer,
      time: widget.time,
      liveTime: widget.livetime,
      location: widget.location,
      date: widget.date,
      latitude: widget.latitude,
      longitude: widget.longitude,
      tail: widget.initialTail,
      deviceTime: widget.deviceTime ?? 'N/A',
      serverTime: widget.serverTime ?? 'N/A',
      runningDuration: widget.runningDuration ?? '00:00:00 Hrs',
      stopDuration: widget.stopDuration ?? '00:00:00 Hrs',
      idleDuration: widget.idleDuration ?? '00:00:00 Hrs',
      inactiveDuration: widget.inactiveDuration ?? '00:00:00 Hrs',
      fuelMileage: widget.fuelMileage ?? '—',
      fuelConsumption: widget.fuelConsumption ?? '0.00 ltr',
      fuelCost: widget.fuelCost ?? '0.00',
      avgSpeed: widget.avgSpeed ?? '0',
      maxSpeed: widget.maxSpeed ?? '0',
      devBattery: widget.devBattery ?? '0%',
      engineHours: widget.engineHours ?? '00:00',
      carBattery: widget.carBattery ?? '0 V',
      satellites: widget.satellites ?? '0',
      fuelLevel: widget.fuelLevel ?? 'N/A',
      accuracy: widget.accuracy ?? 'N/A',
      temperature: widget.temperature ?? 'N/A',
      movement: widget.movement ?? 'false',
    );
  }

  String _formatMovementLabel(String raw) {
    final String lower = raw.trim().toLowerCase();
    if (lower == 'true' ||
        lower == '1' ||
        lower == 'yes' ||
        lower == 'on' ||
        lower == 'moving') {
      return 'Yes';
    }
    if (lower == 'false' ||
        lower == '0' ||
        lower == 'no' ||
        lower == 'off' ||
        lower == 'stopped') {
      return 'No';
    }
    return raw.trim().isEmpty ? '—' : raw.trim();
  }

  String _speedWithUnit(String raw) {
    final String trimmed = raw.trim();
    if (trimmed.isEmpty || trimmed == '—') {
      return '0 kmph';
    }
    if (trimmed.toLowerCase().contains('kmph') ||
        trimmed.toLowerCase().contains('km/h')) {
      return trimmed;
    }
    return '$trimmed kmph';
  }

  /// Splits fleet name into two sheet lines, e.g. `0612-FMY/BSC-838 Multan`.
  ({String line1, String line2}) _vehicleNameLines(String raw) {
    final String name = raw.trim();
    if (name.isEmpty) {
      return (line1: '', line2: '');
    }
    final int slash = name.indexOf('/');
    if (slash >= 0) {
      final String line1 = name.substring(0, slash + 1).trim();
      final String line2 = name.substring(slash + 1).trim();
      if (line2.isNotEmpty) {
        return (line1: line1, line2: line2);
      }
      return (line1: line1, line2: '');
    }
    return (line1: name, line2: '');
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
    _liveTelemetry = ValueNotifier<VehicleModel>(_vehicleSnapshotFromWidget());
    _liveStatus.value = widget.status;
    _liveSpeed.value = widget.speed;
    _liveOdometer.value = widget.odometer;
    if (LiveLocationText.isUsableAddress(widget.location)) {
      _liveLocation.value = widget.location.trim();
    } else if (widget.latitude != null &&
        widget.longitude != null &&
        (widget.latitude != 0.0 || widget.longitude != 0.0)) {
      _liveLocation.value = LiveLocationText.formatCoordinates(
        widget.latitude!,
        widget.longitude!,
      );
    } else {
      _liveLocation.value = LiveLocationText.unavailable;
    }

    _trackController = VehicleTrackController(
      vsync: this,
      deviceId: widget.deviceId,
    )..onFrame = _onSegmentFrame;

    _seedFromWidgetData(initial);
    unawaited(MapCarIcon.preloadStatusIcons());

    // Show arrow + green trail immediately, then refresh in background.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _disposed) return;
      final double screenHeight = MediaQuery.sizeOf(context).height;
      _primeMapVisuals();
      _refreshTrackMarkerIcon();
      _bootstrapLiveRoute();
      _startLiveTracking();
      final int? deviceId = widget.deviceId ?? widget.vehicle?.id;
      if (deviceId != null) {
        unawaited(_refreshTelemetryFromServer(deviceId));
        final int warmGen = ++_historyWarmGeneration;
        unawaited(
          Future<void>.delayed(const Duration(seconds: 3), () {
            if (!mounted ||
                _disposed ||
                warmGen != _historyWarmGeneration ||
                _currentBottomIndex != 0) {
              return;
            }
            VehicleDetailApiService.warmHistoryCache(deviceId);
          }),
        );
      }
    });
  }

  Future<void> _refreshTelemetryFromServer(int deviceId) async {
    final VehicleModel? fresh =
        await VehicleDetailTelemetryService.loadLive(deviceId);
    if (!mounted || _disposed || fresh == null) {
      return;
    }
    _liveTelemetry.value = fresh;
    if (fresh.odometer != _liveOdometer.value) {
      _liveOdometer.value = fresh.odometer;
    }
    if (fresh.status != _liveStatus.value) {
      _liveStatus.value = fresh.status;
    }
    final String freshSpeed =
        VehicleSpeed.formatLabel(VehicleSpeed.effectiveKmh(fresh));
    if (freshSpeed != _liveSpeed.value) {
      _liveSpeed.value = freshSpeed;
    }
    unawaited(_syncLiveLocation(fresh));
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

  String _resolvedMapIconSlug() {
    final int? deviceId = widget.deviceId ?? widget.vehicle?.id;
    if (deviceId != null) {
      final String? slug = VehicleService.mapIconSlugForDevice(deviceId);
      if (slug != null && slug.isNotEmpty) {
        return slug;
      }
    }
    return widget.vehicle?.mapIcon ?? '';
  }

  ({String status, String speed}) _normalizedLiveTelemetry(VehicleModel match) {
    final double kmh = VehicleSpeed.effectiveKmh(match);
    final String speedLabel = VehicleSpeed.formatLabel(kmh);
    return (status: match.status, speed: speedLabel);
  }

  void _applyMarkerColorInstant(String status, String speed) {
    final Color color = VehicleStatusColors.markerColor(
      status: status,
      speed: speed,
    );
    final int colorKey = color.toARGB32();
    if (_arrowColorKey == colorKey && _arrowIcon != null) {
      return;
    }
    final BitmapDescriptor? cached = MapCarIcon.cachedForColor(color);
    if (cached == null) {
      unawaited(_refreshTrackMarkerIcon());
      return;
    }
    _markerUsesCategoryIcon = false;
    _markerAnchor = MapCarIcon.markerAnchor;
    _arrowIcon = cached;
    _arrowColorKey = colorKey;
    if (_currentBottomIndex == 0) {
      _liveMapKey.currentState?.updateMarker(
        position: _renderPos,
        bearing: _renderBearing,
        arrowIcon: cached,
        force: true,
      );
    }
  }

  Future<void> _refreshTrackMarkerIcon() async {
    final Color color = VehicleStatusColors.markerColor(
      status: _liveStatus.value,
      speed: _liveSpeed.value,
    );
    final int colorKey = color.toARGB32();

    if (_arrowIcon != null && _arrowColorKey == colorKey) {
      return;
    }

    _markerUsesCategoryIcon = false;
    _markerAnchor = MapCarIcon.markerAnchor;
    try {
      final BitmapDescriptor icon = await MapCarIcon.forColor(color);
      if (!mounted || _disposed) {
        return;
      }
      _arrowIcon = icon;
      _arrowColorKey = colorKey;
      _applyMarkerIconToMap(force: true);
    } catch (_) {
      if (!mounted || _disposed) {
        return;
      }
      _arrowIcon = BitmapDescriptor.defaultMarkerWithHue(
        BitmapDescriptor.hueGreen,
      );
      _applyMarkerIconToMap(force: true);
    }
  }

  void _applyMarkerIconToMap({required bool force}) {
    _liveMapKey.currentState?.updateMarker(
      position: _renderPos,
      bearing: _renderBearing,
      arrowIcon: _arrowIcon,
      markerAnchor: _markerAnchor,
      force: force,
    );
  }

  void _primeMapVisuals() {
    if (_disposed || !mounted || _currentBottomIndex != 0) return;
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
    if (_disposed || !mounted || _currentBottomIndex != 0) return;
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
      force: true,
    );
    final int nowMs = DateTime.now().millisecondsSinceEpoch;
    if (nowMs - _lastTrailPushMs >= 66) {
      _lastTrailPushMs = nowMs;
      _pushTrailToMap();
    }

    if (_followEnabled && !_userDraggingMap) {
      _followCameraSmooth(fromAnimation: true);
    }
  }

  void _pushTrailToMap({bool force = false}) {
    if (_currentBottomIndex != 0) return;
    if (!_showTrail) {
      _liveMapKey.currentState?.clearTrailOverlay();
      return;
    }
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

    if (!mounted || _disposed || points.isEmpty) return;

    if (points.length >= 2) {
      _trackController.animator.seedTrailFromPoints(points);
    }
    _primeMapVisuals();

    unawaited(_bootstrapLiveRouteFromNetwork(tail));
  }

  Future<void> _bootstrapLiveRouteFromNetwork(
    List<VehicleTrackPoint> tail,
  ) async {
    if (widget.deviceId == null || !mounted || _disposed) return;

    List<LatLng> points = tail
        .map((VehicleTrackPoint p) => LatLng(p.latitude, p.longitude))
        .toList();
    points = LiveRouteService.dedupe(points);

    if (points.length < 4) {
      final List<LatLng> bootstrap = await LiveRouteService.bootstrapRoute(
        deviceId: widget.deviceId!,
        tail: tail,
      );
      if (bootstrap.length >= 2) {
        points = bootstrap;
      }
    }

    if (!mounted || _disposed || points.length < 2) return;

    final List<LatLng> roadPath = await RoadRouteService.routeBetween(
      from: points.first,
      to: points.last,
      tailHint: points,
    );
    if (roadPath.length >= 2) {
      points = roadPath;
    }

    final LatLng latest = points.last;
    final double driftMeters =
        LiveRouteService.haversineMeters(_renderPos, latest);
    if (driftMeters >= 50.0) {
      final double bearing = _bearingFromTail(points);
      _trackController.seed(latest, bearing: bearing);
      _readAnimatorState();
    }

    if (points.length >= 2) {
      _trackController.animator.seedTrailFromPoints(points);
    }
    _primeMapVisuals();
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
    _liveDeviceSub?.cancel();

    if (widget.deviceId == null) return;
    final int deviceId = widget.deviceId!;

    unawaited(LiveDeviceSocketService.instance.startTracking(deviceId));
    _liveDeviceSub = LiveDeviceSocketService.instance
        .streamForDevice(deviceId)
        .listen(_onLiveDeviceStreamUpdate);

    LiveDeviceSocketService.instance.emitCachedDevice(deviceId);
  }

  void _onLiveDeviceStreamUpdate(VehicleModel match) {
    if (_disposed || !mounted || _currentBottomIndex != 0) {
      return;
    }
    if (match.id != widget.deviceId) {
      return;
    }
    final ({String status, String speed}) live = _normalizedLiveTelemetry(match);
    _applyMarkerColorInstant(live.status, live.speed);
    unawaited(_applyLiveVehicleModel(match, fromStream: true));
  }

  void _stopLiveTracking() {
    _pollTimer?.cancel();
    _pollTimer = null;
    _liveDeviceSub?.cancel();
    _liveDeviceSub = null;
    if (widget.deviceId != null) {
      LiveDeviceSocketService.instance.stopTracking(deviceId: widget.deviceId);
    }
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

    final int nowMs = DateTime.now().millisecondsSinceEpoch;
    if (!force && !fromAnimation && nowMs - _lastFollowCameraMs < 50) {
      return;
    }
    _lastFollowCameraMs = nowMs;

    try {
      if (force) {
        _trackController.navCamera.reset(_renderPos, _renderBearing);
      }
      final CameraPosition cam = _trackController.navCamera.cameraFor(
        _renderPos,
        _renderBearing,
        snapToMarker: fromAnimation || force,
      );
      _markProgrammaticCamera();
      _mapController!.moveCamera(CameraUpdate.newCameraPosition(cam));
    } catch (_) {
      _mapController = null;
    }
  }

  Future<void> _syncLiveLocation(VehicleModel match) async {
    if (!mounted || _disposed) {
      return;
    }

    String next = match.location.trim();
    if (LiveLocationText.isUsableAddress(next)) {
      if (next != _liveLocation.value) {
        _liveLocation.value = next;
      }
      return;
    }

    final bool hasCoords = match.latitude != null &&
        match.longitude != null &&
        (match.latitude != 0.0 || match.longitude != 0.0);

    if (hasCoords) {
      if (_locationResolveInFlight) {
        return;
      }
      _locationResolveInFlight = true;
      try {
        final String? resolved = await VehicleService.resolveAddressFor(match);
        if (resolved != null && LiveLocationText.isUsableAddress(resolved)) {
          next = resolved;
          VehicleService.patchCachedDevice(match.copyWith(location: resolved));
        } else {
          next = LiveLocationText.formatCoordinates(
            match.latitude!,
            match.longitude!,
          );
        }
      } finally {
        _locationResolveInFlight = false;
      }
    }

    if (LiveLocationText.isPlaceholder(next)) {
      return;
    }

    if (next != _liveLocation.value) {
      _liveLocation.value = next;
    }
  }

  Future<void> _fetchLiveVehicleFromNetwork(int deviceId) async {
    try {
      final bool resolveAddressThisPoll = _forceNextRefresh;
      _forceNextRefresh = false;

      final VehicleModel? match =
          await VehicleDetailFastApiService.refreshLiveDevice(
        deviceId,
        allowNetwork: true,
        resolveAddress: resolveAddressThisPoll,
        aggressiveNetwork: true,
      );

      if (!mounted || _disposed || match == null || match.id != deviceId) {
        return;
      }
      await _applyLiveVehicleModel(match);
    } finally {
      _liveNetworkInFlight = false;
    }
  }

  Future<void> _applyLiveVehicleModel(
    VehicleModel match, {
    bool fromStream = false,
  }) async {
    if (!mounted || _disposed || match.id != widget.deviceId) return;

    final ({String status, String speed}) live = _normalizedLiveTelemetry(match);
    final bool statusChanged = live.status != _liveStatus.value;
    final bool speedChanged = live.speed != _liveSpeed.value;
    if (statusChanged) {
      _liveStatus.value = live.status;
    }
    if (speedChanged) {
      _liveSpeed.value = live.speed;
    }
    if (statusChanged || speedChanged) {
      _applyMarkerColorInstant(live.status, live.speed);
    }

    if (match.odometer != _liveOdometer.value) {
      _liveOdometer.value = match.odometer;
    }

    _liveTelemetry.value = match;
    unawaited(_syncLiveLocation(match));

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
    final double markerLagMeters =
        LiveRouteService.haversineMeters(_renderPos, serverPos);
    final double speedKmh = VehicleSpeed.effectiveKmh(match);
    final List<LatLng> tail = match.tail
        .map((VehicleTrackPoint p) => LatLng(p.latitude, p.longitude))
        .toList();

    if (markerLagMeters >= 35 ||
        (markerLagMeters >= 12 && speedKmh > 2)) {
      _trackController.catchUpToServer(
        serverPos,
        speedKmh: speedKmh,
        tailHint: tail,
      );
    } else if (ingestResult == GpsIngestResult.rejected &&
        driftMeters >= 25.0) {
      final double bearing = tail.length >= 2
          ? _bearingFromTail(tail)
          : _trackController.animator.displayBearing;
      _trackController.forceSnapTo(serverPos, bearing: bearing);
    }

    _readAnimatorState();
    final bool animating = _trackController.animator.isAnimating;
    final bool moved = posBefore.latitude != posAfter.latitude ||
        posBefore.longitude != posAfter.longitude ||
        ingestResult == GpsIngestResult.snapped ||
        ingestResult == GpsIngestResult.animated;

    if (moved || statusChanged || speedChanged || driftMeters >= 1.0) {
      _trailDirty = moved || driftMeters >= 1.0;
      if (!animating || ingestResult == GpsIngestResult.snapped) {
        _liveMapKey.currentState?.updateMarker(
          position: _renderPos,
          bearing: _renderBearing,
          arrowIcon: _arrowIcon,
          force: ingestResult == GpsIngestResult.snapped,
          fromAnimation: animating && !fromStream,
        );
      }
      _syncVisuals(forceTrail: _trailDirty);
      if (_followEnabled &&
          !_userDraggingMap &&
          moved &&
          !animating &&
          ingestResult != GpsIngestResult.animated) {
        _followCameraSmooth(force: true);
      }
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
    setState(() => _currentBottomIndex = index);
    if (index == 0) {
      _trackController.onFrame = _onSegmentFrame;
      _readAnimatorState();
      _trackController.navCamera.reset(_renderPos, _renderBearing);
      _startLiveTracking();
      _primeMapVisuals();
    } else {
      _stopLiveTracking();
    }
  }

  Widget _buildDetailBody(Color accentColor) {
    final int? historyDeviceId = widget.deviceId ?? widget.vehicle?.id;
    switch (_currentBottomIndex) {
      case 1:
        return VehicleHistoryScreen(
          key: const ValueKey<String>('vehicle_detail_history_tab'),
          deviceId: historyDeviceId,
          name: widget.name,
          accentColor: widget.color,
          fallbackLocation: widget.location,
          speedLimitKmph: double.tryParse(
            widget.vehicle?.speedLimitKmph.trim() ?? '',
          ),
          onClose: () => _selectTab(0),
          isTabActive: true,
        );
      case 2:
        return NotificationsScreen(
          key: const ValueKey<String>('vehicle_detail_alerts'),
          showAlertsOnly: true,
          vehicleName: widget.name,
          deviceId: widget.deviceId,
        );
      case 3:
        return _VehicleStatisticsTab(
          key: const ValueKey<String>('vehicle_detail_statistics'),
          deviceId: historyDeviceId,
          vehicleName: widget.name,
          onBack: () => _selectTab(0),
        );
      case 0:
      default:
        return _buildTrackView();
    }
  }

  LatLng _nearbyAnchor() {
    if (_renderPos.latitude != 0 || _renderPos.longitude != 0) {
      return _renderPos;
    }
    final double? lat = widget.latitude;
    final double? lng = widget.longitude;
    if (lat != null && lng != null) {
      return LatLng(lat, lng);
    }
    return _carLocation;
  }

  void _toggleMapToolsMenu() {
    setState(() {
      _mapToolsMenuOpen = !_mapToolsMenuOpen;
    });
  }

  void _closeMapToolsMenu() {
    if (!_mapToolsMenuOpen) return;
    setState(() {
      _mapToolsMenuOpen = false;
    });
  }

  Future<void> _launchExternalUri(Uri uri) async {
    try {
      if (!await canLaunchUrl(uri)) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr('Could not open maps'))),
        );
        return;
      }
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('Could not open maps'))),
      );
    }
  }

  Future<void> _dialSupportPhone() async {
    final Uri uri = Uri(scheme: 'tel', path: _supportPhoneDisplay);
    await _launchExternalUri(uri);
  }

  Future<void> _openSupportWhatsApp() async {
    final Uri uri = Uri.parse('https://wa.me/91$_supportPhoneDisplay');
    await _launchExternalUri(uri);
  }

  void _showSupportAndHelpsDialog() {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black54,
      builder: (BuildContext dialogContext) {
        return Dialog(
          backgroundColor: context.containerColor,
          insetPadding: const EdgeInsets.symmetric(horizontal: 28),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(
                  context.tr('Support & Helps'),
                  style: TextStyle(
                    color: context.textColor,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                Divider(
                  color: context.mutedTextColor.withValues(alpha: 0.35),
                  height: 1,
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            Navigator.pop(dialogContext);
                            _dialSupportPhone();
                          },
                          child: Text(
                            'Phone($_supportPhoneDisplay)',
                            style: TextStyle(
                              color: context.textColor,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () {
                          Navigator.pop(dialogContext);
                          _dialSupportPhone();
                        },
                        child: Icon(Icons.phone, color: _mapToolsPink, size: 22),
                      ),
                      const SizedBox(width: 10),
                      InkWell(
                        onTap: () {
                          Navigator.pop(dialogContext);
                          _openSupportWhatsApp();
                        },
                        child: Icon(Icons.chat, color: Colors.green.shade600, size: 22),
                      ),
                    ],
                  ),
                ),
                InkWell(
                  onTap: () {
                    Navigator.pop(dialogContext);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(context.tr('Opening email...'))),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            context.tr('Email id()'),
                            style: TextStyle(
                              color: context.textColor,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Icon(Icons.email_outlined, color: _mapToolsPink, size: 22),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showNearbyPlacesDialog() {
    showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return Dialog(
          backgroundColor: context.containerColor,
          insetPadding: const EdgeInsets.symmetric(horizontal: 32),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                child: Center(
                  child: Text(
                    context.tr('Nearby'),
                    style: TextStyle(
                      color: context.textColor,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              Divider(
                height: 1,
                color: context.mutedTextColor.withValues(alpha: 0.35),
              ),
              _nearbyDialogTile(
                dialogContext,
                Icons.account_balance,
                context.tr('ATMS'),
                'ATM',
              ),
              _nearbyDialogTile(
                dialogContext,
                Icons.local_gas_station,
                context.tr('Petrol pumps'),
                'Petrol pump',
              ),
              _nearbyDialogTile(
                dialogContext,
                Icons.local_hospital,
                context.tr('Hospitals'),
                'Hospital',
              ),
              _nearbyDialogTile(
                dialogContext,
                Icons.local_police,
                context.tr('Police Stations'),
                'Police station',
              ),
              _nearbyDialogTile(
                dialogContext,
                Icons.support_agent,
                context.tr('Service Points'),
                'Car service',
              ),
              _nearbyDialogTile(
                dialogContext,
                Icons.restaurant,
                context.tr('Restaurants'),
                'Restaurant',
              ),
              _nearbyDialogTile(
                dialogContext,
                Icons.local_parking,
                context.tr('Parking'),
                'Parking',
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Widget _nearbyDialogTile(
    BuildContext dialogContext,
    IconData icon,
    String label,
    String mapsQuery,
  ) {
    return InkWell(
      onTap: () {
        Navigator.pop(dialogContext);
        _openNearbyOnMaps(mapsQuery);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        child: Row(
          children: <Widget>[
            Icon(icon, color: context.textColor.withValues(alpha: 0.85), size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: context.textColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddPoiDialog() {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController addressController =
        TextEditingController(text: _liveLocation.value);

    showDialog<void>(context: context, builder: (BuildContext dialogContext) {
      return Dialog(
        backgroundColor: context.containerColor,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                context.tr('Add POI'),
                style: TextStyle(
                  color: context.textColor,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Divider(
                color: context.mutedTextColor.withValues(alpha: 0.35),
                height: 1,
              ),
              const SizedBox(height: 14),
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  hintText: context.tr('Name*'),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: _mapToolsPink),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: _mapToolsPink, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: addressController,
                maxLines: 2,
                decoration: InputDecoration(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: _mapToolsPink),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: _mapToolsPink, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: <Widget>[
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      style: TextButton.styleFrom(
                        backgroundColor: _mapToolsPink,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      child: Text(
                        context.tr('CANCEL'),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextButton(
                      onPressed: () {
                        final String name = nameController.text.trim();
                        Navigator.pop(dialogContext);
                        if (name.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(context.tr('Name*'))),
                          );
                          return;
                        }
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '${context.tr('Add POI')}: $name',
                            ),
                          ),
                        );
                      },
                      style: TextButton.styleFrom(
                        backgroundColor: _mapToolsPink,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      child: Text(
                        context.tr('Add POI'),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }).then((_) {
      nameController.dispose();
      addressController.dispose();
    });
  }

  Future<void> _openTrafficOnMaps() async {
    final LatLng pos = _nearbyAnchor();
    if (pos.latitude == 0 && pos.longitude == 0) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('Location not available'))),
      );
      return;
    }
    final Uri uri = Uri.parse(
      'https://www.google.com/maps/@${pos.latitude},${pos.longitude},14z/data=!5m1!1e1',
    );
    await _launchExternalUri(uri);
  }

  Future<void> _openNavigationOnMaps() async {
    final LatLng pos = _nearbyAnchor();
    if (pos.latitude == 0 && pos.longitude == 0) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('Location not available'))),
      );
      return;
    }
    final Uri uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=${pos.latitude},${pos.longitude}',
    );
    await _launchExternalUri(uri);
  }

  Widget _mapToolsPinkCircleVisual({
    required IconData icon,
    Color iconColor = Colors.white,
    double size = 40,
  }) {
    return Container(
      height: size,
      width: size,
      decoration: const BoxDecoration(
        color: _mapToolsPink,
        shape: BoxShape.circle,
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black26,
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Icon(icon, color: iconColor, size: 22),
    );
  }

  Widget _mapToolsPinkCircleButton({
    required IconData icon,
    required VoidCallback onTap,
    Color iconColor = Colors.white,
    double size = 40,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: _mapToolsPinkCircleVisual(
          icon: icon,
          iconColor: iconColor,
          size: size,
        ),
      ),
    );
  }

  Widget _mapToolMenuEntry({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            _mapToolsPinkCircleVisual(icon: icon),
            if (label.isNotEmpty) ...<Widget>[
              const SizedBox(width: 10),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  shadows: <Shadow>[
                    Shadow(color: Colors.black54, blurRadius: 4),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _openNearbyOnMaps(String placeQuery) async {
    final LatLng pos = _nearbyAnchor();
    if (pos.latitude == 0 && pos.longitude == 0) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('Location not available'))),
      );
      return;
    }
    final String encoded = Uri.encodeComponent(placeQuery);
    final Uri uri = Uri.parse(
      'https://www.google.com/maps/search/$encoded/@${pos.latitude},${pos.longitude},15z',
    );
    try {
      if (!await canLaunchUrl(uri)) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr('Could not open maps'))),
        );
        return;
      }
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('Could not open maps'))),
      );
    }
  }

  int? get _commandDeviceId => widget.deviceId ?? widget.vehicle?.id;

  void _openEngineCommands() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => SendCommandScreen(
          vehicleName: widget.name,
          deviceId: _commandDeviceId,
        ),
      ),
    );
  }

  void _cycleMapType() {
    setState(() {
      if (_mapType == MapType.normal) {
        _mapType = MapType.satellite;
      } else if (_mapType == MapType.satellite) {
        _mapType = MapType.hybrid;
      } else {
        _mapType = MapType.normal;
      }
    });
  }

  /// Same Google Maps styling as the main fleet [MapScreen] (native look by default).
  String? _googleMapStyle(BuildContext context) {
    if (_mapType != MapType.normal) {
      return null;
    }
    return context.themedMapStyle;
  }

  void _toggleInMapTraffic() {
    setState(() => _trafficEnabled = !_trafficEnabled);
  }

  Future<void> _zoomMapBy(double delta) async {
    final GoogleMapController? controller = _mapController;
    if (controller == null) {
      return;
    }
    try {
      final double zoom = await controller.getZoomLevel();
      await controller.animateCamera(
        CameraUpdate.zoomTo((zoom + delta).clamp(3.0, 21.0)),
      );
    } catch (_) {}
  }

  void _toggleTrailVisibility() {
    setState(() {
      _showTrail = !_showTrail;
    });
    if (_showTrail) {
      _pushTrailToMap(force: true);
    } else {
      _liveMapKey.currentState?.clearTrailOverlay();
    }
  }

  Future<void> _refreshMapAndVehicle() async {
    if (widget.deviceId != null) {
      _forceNextRefresh = true;
      await _fetchLiveVehicleFromNetwork(widget.deviceId!);
    }
    if (!mounted) {
      return;
    }
    _followEnabled = true;
    _userDraggingMap = false;
    _recenterOnCar(zoom: _followZoom);
  }

  void _openTripHistory() {
    if (widget.deviceId == null) {
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => VehicleHistoryScreen(
          deviceId: widget.deviceId,
          name: widget.name,
          accentColor: Theme.of(context).colorScheme.primary,
          fallbackLocation: widget.location,
        ),
      ),
    );
  }

  Future<void> _confirmEngineCommand(String commandType, String actionTitle) async {
    if (_commandDeviceId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('Device not available'))),
      );
      return;
    }
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            actionTitle,
            style: const TextStyle(
              color: Color(0xFFFF5364),
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          content: Text(
            ctx.tr('Do you want to Stop/Resume Engine?'),
            style: TextStyle(fontSize: 14, color: ctx.textColor),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(
                context.tr('CANCEL'),
                style: const TextStyle(
                  color: Color(0xFF1F2937),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(
                context.tr('OK'),
                style: const TextStyle(
                  color: Color(0xFF1F2937),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !mounted) return;
    try {
      await TrackingApiService.sendCommandData(<String, dynamic>{
        'device_id': _commandDeviceId,
        'type': commandType,
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$actionTitle ${context.tr('command sent successfully')}'),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr('Failed to send command')),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _showUpdateOdometerDialog() async {
    final int? deviceId = widget.deviceId ?? widget.vehicle?.id;
    if (deviceId == null) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('Vehicle not linked to a device'))),
      );
      return;
    }

    final double? km = await UpdateOdometerDialog.show(
      context,
      initialOdometerKm: _liveOdometer.value,
    );
    if (km == null || !mounted) {
      return;
    }

    try {
      await VehicleDeviceEditService.updateOdometer(
        deviceId: deviceId,
        kilometers: km,
      );
      if (!mounted) {
        return;
      }
      final String label = '${km.toStringAsFixed(2)} km';
      _liveOdometer.value = label;
      _liveTelemetry.value =
          _liveTelemetry.value.copyWith(odometer: label);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr('Odometer updated successfully')),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _showCallDriverDialog() async {
    final int? deviceId = widget.deviceId ?? widget.vehicle?.id;
    if (deviceId == null) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('Vehicle not linked to a device'))),
      );
      return;
    }

    showDialog<void>(
      context: context,
      useRootNavigator: true,
      barrierDismissible: false,
      builder: (BuildContext ctx) {
        return PopScope(
          canPop: false,
          child: Center(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(context.tr('Loading driver phone…')),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );

    String phone = '';
    try {
      phone = await VehicleDriverPhoneService.phoneForDevice(deviceId);
    } catch (_) {}

    if (!mounted) {
      return;
    }
    Navigator.pop(context);

    await CallDriverDialog.show(context, phone: phone);
  }

  Future<void> _showUpdateEngineDialog() async {
    final int? deviceId = widget.deviceId ?? widget.vehicle?.id;
    if (deviceId == null) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('Vehicle not linked to a device'))),
      );
      return;
    }

    final VehicleModel? cached = VehicleService.findCachedDevice(deviceId);
    String initial = cached?.engineNumber.trim() ?? '';
    if (initial.isEmpty) {
      initial = cached?.name.trim() ?? widget.vehicle?.name.trim() ?? '';
    }

    final String? engineNumber = await UpdateEngineNumberDialog.show(
      context,
      initialEngineNumber: initial,
    );
    if (engineNumber == null || !mounted) {
      return;
    }

    try {
      await VehicleDeviceEditService.updateEngineNumber(
        deviceId: deviceId,
        engineNumber: engineNumber,
      );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr('Engine number updated successfully')),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _showAddGroupDialog() async {
    final int? deviceId = widget.deviceId ?? widget.vehicle?.id;
    if (deviceId == null) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('Vehicle not linked to a device'))),
      );
      return;
    }

    showDialog<void>(
      context: context,
      useRootNavigator: true,
      barrierDismissible: false,
      builder: (BuildContext ctx) {
        return PopScope(
          canPop: false,
          child: Center(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(context.tr('Loading groups…')),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );

    List<DeviceGroupModel> groups = <DeviceGroupModel>[];
    try {
      await VehicleService.getDevices(forceRefresh: false);
      groups = await VehicleGroupService.fetchGroups();
    } catch (_) {}

    if (!mounted) {
      return;
    }
    Navigator.pop(context);

    final VehicleModel? cached = VehicleService.findCachedDevice(deviceId);
    final DeviceGroupModel? picked = await AddGroupDeviceDialog.show(
      context,
      groups: groups,
      initialGroupId: cached?.groupId,
    );
    if (picked == null || !mounted) {
      return;
    }

    try {
      await VehicleDeviceEditService.assignDeviceGroup(
        deviceId: deviceId,
        groupId: picked.id,
        groupName: picked.name,
      );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr('Device group updated successfully')),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _showUpdateIconDialog() async {
    final int? deviceId = widget.deviceId ?? widget.vehicle?.id;
    if (deviceId == null) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('Vehicle not linked to a device'))),
      );
      return;
    }

    final VehicleIconCategory initial =
        VehicleIconService.initialCategoryForDevice(deviceId);

    final VehicleIconCategory? picked = await UpdateVehicleIconDialog.show(
      context,
      initialCategory: initial,
    );
    if (picked == null || !mounted) {
      return;
    }

    showDialog<void>(
      context: context,
      useRootNavigator: true,
      barrierDismissible: false,
      builder: (BuildContext ctx) {
        return PopScope(
          canPop: false,
          child: Center(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    CircularProgressIndicator(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(context.tr('Updating…')),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );

    try {
      await VehicleIconService.updateDeviceIcon(
        deviceId: deviceId,
        category: picked,
      );
      if (!mounted) {
        return;
      }
      Navigator.pop(context);
      VehicleCategoryMapIcon.clearCache();
      _arrowColorKey = 0;
      await _refreshTrackMarkerIcon();
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr('Icon updated successfully')),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }
      Navigator.pop(context);
      VehicleCategoryMapIcon.clearCache();
      _arrowColorKey = 0;
      await _refreshTrackMarkerIcon();
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  int? get _detailDeviceId => widget.deviceId ?? widget.vehicle?.id;

  String _digitsFromTelemetry(String raw) {
    final String digits = raw.replaceAll(RegExp(r'[^0-9.]'), '');
    return digits.isEmpty ? '0' : digits;
  }

  void _showDeviceNotLinkedSnack() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.tr('Vehicle not linked to a device'))),
    );
  }

  Future<void> _openStreetViewOnMaps() async {
    final LatLng pos = _nearbyAnchor();
    if (pos.latitude == 0 && pos.longitude == 0) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('Location not available'))),
      );
      return;
    }
    final Uri uri = Uri.parse(
      'https://www.google.com/maps/@?api=1&map_action=pano&viewpoint=${pos.latitude},${pos.longitude}',
    );
    await _launchExternalUri(uri);
  }

  Future<void> _showUpdateSpeedLimitDialog() async {
    final int? deviceId = _detailDeviceId;
    if (deviceId == null) {
      if (!mounted) {
        return;
      }
      _showDeviceNotLinkedSnack();
      return;
    }

    final VehicleModel? cached = VehicleService.findCachedDevice(deviceId);
    String initial = cached?.speedLimitKmph.trim() ?? '';
    if (initial.isEmpty) {
      initial = '80';
    }

    final String? raw = await UpdateDeviceValueDialog.show(
      context,
      title: 'Update Speed Limit',
      initialValue: _digitsFromTelemetry(initial),
      decimal: false,
    );
    if (raw == null || !mounted) {
      return;
    }
    final double? kmph = double.tryParse(raw);
    if (kmph == null || kmph <= 0) {
      return;
    }

    try {
      await VehicleDeviceEditService.updateSpeedLimit(
        deviceId: deviceId,
        limitKmph: kmph,
      );
      if (!mounted) {
        return;
      }
      final String label = kmph.truncateToDouble() == kmph
          ? kmph.toInt().toString()
          : kmph.toStringAsFixed(1);
      _liveTelemetry.value =
          _liveTelemetry.value.copyWith(speedLimitKmph: label);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr('Speed limit updated successfully')),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _showUpdateFuelCostDialog() async {
    final int? deviceId = _detailDeviceId;
    if (deviceId == null) {
      if (!mounted) {
        return;
      }
      _showDeviceNotLinkedSnack();
      return;
    }

    final VehicleModel? cached = VehicleService.findCachedDevice(deviceId);
    String initial = cached?.fuelPricePerLiter.trim() ?? '';
    if (initial.isEmpty && cached != null) {
      initial = _digitsFromTelemetry(cached.fuelCost);
    }
    if (initial.isEmpty) {
      initial = '0';
    }

    final String? raw = await UpdateDeviceValueDialog.show(
      context,
      title: 'Update Cost',
      initialValue: _digitsFromTelemetry(initial),
      submitLabel: 'UPDATE',
    );
    if (raw == null || !mounted) {
      return;
    }
    final double? price = double.tryParse(raw);
    if (price == null || price < 0) {
      return;
    }

    try {
      await VehicleDeviceEditService.updateFuelPricePerLiter(
        deviceId: deviceId,
        price: price,
      );
      if (!mounted) {
        return;
      }
      final String label = price.toStringAsFixed(2);
      _liveTelemetry.value = _liveTelemetry.value.copyWith(
        fuelPricePerLiter: label,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr('Fuel cost updated successfully')),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _showUpdateMileageDialog() async {
    final int? deviceId = _detailDeviceId;
    if (deviceId == null) {
      if (!mounted) {
        return;
      }
      _showDeviceNotLinkedSnack();
      return;
    }

    final VehicleModel? cached = VehicleService.findCachedDevice(deviceId);
    String initial = _digitsFromTelemetry(cached?.fuelMileage ?? '');
    if (initial == '0' || initial.isEmpty) {
      initial = '15';
    }

    final String? raw = await UpdateDeviceValueDialog.show(
      context,
      title: 'Update Mileage',
      initialValue: initial,
    );
    if (raw == null || !mounted) {
      return;
    }
    final double? kmPerLiter = double.tryParse(raw);
    if (kmPerLiter == null || kmPerLiter <= 0) {
      return;
    }

    try {
      await VehicleDeviceEditService.updateFuelMileage(
        deviceId: deviceId,
        kmPerLiter: kmPerLiter,
      );
      if (!mounted) {
        return;
      }
      final String label = kmPerLiter.truncateToDouble() == kmPerLiter
          ? '${kmPerLiter.toInt()} km/ltr'
          : '${kmPerLiter.toStringAsFixed(2)} km/ltr';
      _liveTelemetry.value =
          _liveTelemetry.value.copyWith(fuelMileage: label);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr('Mileage updated successfully')),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _openVehicleDocuments() {
    final int? deviceId = _detailDeviceId;
    if (deviceId == null) {
      _showDeviceNotLinkedSnack();
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => VehicleDocumentsScreen(
          deviceId: deviceId,
          vehicleName: widget.name,
        ),
      ),
    );
  }

  Future<void> _openAddGeofenceFlow() async {
    LatLng? initialCenter;
    final LatLng pos = _nearbyAnchor();
    if (pos.latitude != 0 || pos.longitude != 0) {
      initialCenter = pos;
    }

    final AddGeofenceResult? result = await Navigator.push<AddGeofenceResult>(
      context,
      MaterialPageRoute<AddGeofenceResult>(
        builder: (_) => AddGeofenceScreen(initialMapCenter: initialCenter),
      ),
    );
    if (result == null || !mounted) {
      return;
    }

    final bool saved = await GeofenceService.addGeofence(
      name: result.name,
      position: result.location.position,
      radiusMeters: result.location.radiusMeters,
      isCircular: result.isCircular,
      address: result.location.address,
    );
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          saved
              ? context.tr('Geofence saved successfully')
              : context.tr('Could not save geofence'),
        ),
        backgroundColor: saved ? const Color(0xFF10B981) : const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _openAddReminderFlow() async {
    final int? deviceId = _detailDeviceId;
    if (deviceId == null) {
      if (!mounted) {
        return;
      }
      _showDeviceNotLinkedSnack();
      return;
    }

    final List<String>? types = await AddReminderPickerScreen.open(context);
    if (types == null || types.isEmpty || !mounted) {
      return;
    }

    final bool? saved = await AddNewReminderScreen.open(
      context,
      initialType: types.first,
      deviceId: deviceId,
    );
    if (!mounted || saved != true) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.tr('Reminder saved successfully')),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _showUpdateEngineCostDialog() async {
    final int? deviceId = _detailDeviceId;
    if (deviceId == null) {
      if (!mounted) {
        return;
      }
      _showDeviceNotLinkedSnack();
      return;
    }

    final VehicleModel? cached = VehicleService.findCachedDevice(deviceId);
    String initial = cached?.engineWorkCost.trim() ?? '';
    if (initial.isEmpty) {
      initial = '0';
    }

    final String? raw = await UpdateDeviceValueDialog.show(
      context,
      title: 'Update Engine cost',
      initialValue: _digitsFromTelemetry(initial),
    );
    if (raw == null || !mounted) {
      return;
    }
    final double? cost = double.tryParse(raw);
    if (cost == null || cost < 0) {
      return;
    }

    try {
      await VehicleDeviceEditService.updateEngineWorkCost(
        deviceId: deviceId,
        cost: cost,
      );
      if (!mounted) {
        return;
      }
      final String label = cost.toStringAsFixed(2);
      _liveTelemetry.value =
          _liveTelemetry.value.copyWith(engineWorkCost: label);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr('Engine cost updated successfully')),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _shareLocation() async {
    final int? deviceId = _detailDeviceId;
    if (deviceId == null) {
      if (!mounted) {
        return;
      }
      _showDeviceNotLinkedSnack();
      return;
    }

    final ShareLiveLocationChoice? choice =
        await ShareLiveLocationDialog.show(
      context,
      vehicleName: widget.name,
    );
    if (choice == null || !mounted) {
      return;
    }

    final LatLng pos = _nearbyAnchor();
    if (pos.latitude == 0 && pos.longitude == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('Location not available'))),
      );
      return;
    }

    showDialog<void>(
      context: context,
      useRootNavigator: true,
      barrierDismissible: false,
      builder: (BuildContext ctx) {
        return PopScope(
          canPop: false,
          child: Center(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(context.tr('Sharing location…')),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );

    try {
      final LiveLocationShareResult result =
          await LiveLocationShareService.share(
        deviceId: deviceId,
        latitude: pos.latitude,
        longitude: pos.longitude,
        choice: choice,
        vehicleName: widget.name,
      );
      if (!mounted) {
        return;
      }
      Navigator.pop(context);

      await Clipboard.setData(ClipboardData(text: result.shareUrl));
      final bool whatsAppOpened =
          await LiveLocationShareService.openWhatsApp(result);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            whatsAppOpened
                ? context.tr('Opening WhatsApp with live location link')
                : context.tr(
                    'Live link copied. Install WhatsApp or paste the link to share.',
                  ),
          ),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ─── Lifecycle ────────────────────────────────────────────────────────────
  @override
  void dispose() {
    _disposed = true;
    _historyWarmGeneration++;
    _stopLiveTracking();
    _trackController.onFrame = null;
    _trackController.dispose();
    _mapController = null;
    _sheetProgress.dispose();
    _liveStatus.dispose();
    _liveSpeed.dispose();
    _liveOdometer.dispose();
    _liveLocation.dispose();
    _liveTelemetry.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    final Color accentColor = Theme.of(context).colorScheme.primary;
    final Color mutedColor = context.mutedTextColor;
    return Scaffold(
      body: _buildDetailBody(accentColor),
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
    final double mapControlsBottom = sheetHeightPx + 20;
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
              mapType: _mapType,
              mapStyle: _googleMapStyle(context),
              trafficEnabled: _trafficEnabled,
              initialZoom: _followZoom,
              arrowIcon: _arrowIcon,
              markerAnchor: _markerAnchor,
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

        if (_mapToolsMenuOpen)
          Positioned.fill(
            child: GestureDetector(
              onTap: _closeMapToolsMenu,
              child: Container(color: Colors.black54),
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
          bottom: mapControlsBottom,
          left: 16,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _floatingMapButton(Icons.refresh, mutedColor, _refreshMapAndVehicle),
              const SizedBox(height: 10),
              _floatingMapButton(
                Icons.route_outlined,
                const Color(0xFF43A047),
                _openTripHistory,
              ),
              const SizedBox(height: 10),
              _floatingMapButton(
                _showTrail ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                mutedColor,
                _toggleTrailVisibility,
              ),
              const SizedBox(height: 10),
              _floatingMapButton(
                Icons.support_agent,
                mutedColor,
                _showSupportAndHelpsDialog,
              ),
              const SizedBox(height: 10),
              Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.bottomLeft,
                children: <Widget>[
                  if (_mapToolsMenuOpen)
                    Positioned(
                      left: 0,
                      bottom: 50,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          _mapToolMenuEntry(
                            icon: Icons.location_city,
                            label: context.tr('Nearby'),
                            onTap: () {
                              _closeMapToolsMenu();
                              _showNearbyPlacesDialog();
                            },
                          ),
                          _mapToolMenuEntry(
                            icon: Icons.add_location_alt,
                            label: context.tr('Add POI'),
                            onTap: () {
                              _closeMapToolsMenu();
                              _showAddPoiDialog();
                            },
                          ),
                          _mapToolMenuEntry(
                            icon: Icons.traffic,
                            label: context.tr('Traffic'),
                            onTap: () {
                              _closeMapToolsMenu();
                              _toggleInMapTraffic();
                            },
                          ),
                          _mapToolMenuEntry(
                            icon: Icons.navigation,
                            label: context.tr('Navigation'),
                            onTap: () {
                              _closeMapToolsMenu();
                              _openNavigationOnMaps();
                            },
                          ),
                        ],
                      ),
                    ),
                  if (_mapToolsMenuOpen)
                    _mapToolsPinkCircleButton(
                      icon: Icons.close,
                      iconColor: const Color(0xFF1A1A1A),
                      onTap: _closeMapToolsMenu,
                    )
                  else
                    _floatingMapButton(Icons.add, mutedColor, _toggleMapToolsMenu),
                ],
              ),
            ],
          ),
        ),
        Positioned(
          bottom: mapControlsBottom,
          right: 16,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              _floatingMapButton(Icons.layers_outlined, mutedColor, _cycleMapType),
              const SizedBox(height: 10),
              _floatingMapButton(Icons.lock, Colors.green, _openEngineCommands),
              const SizedBox(height: 10),
              _floatingMapButton(Icons.local_parking, Colors.grey, () {}),
              const SizedBox(height: 10),
              _floatingMapButton(Icons.person_outline, mutedColor, () {}),
              const SizedBox(height: 10),
              _floatingMapButton(
                Icons.my_location,
                accentColor,
                () {
                  _followEnabled = true;
                  _userDraggingMap = false;
                  _recenterOnCar(zoom: _followZoom);
                },
              ),
              const SizedBox(height: 10),
              _floatingMapZoomControls(),
            ],
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
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                          child: _buildSheetTopHeader(
                            textColor,
                            mutedColor,
                            accentColor,
                          ),
                        ),
                        Container(
                          height: 4,
                          width: 40,
                          decoration: BoxDecoration(
                            color: mutedColor.withOpacity(0.4),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        const SizedBox(height: 10),
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
                              _buildOdometerRow(context),
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
                                    child: ValueListenableBuilder<String>(
                                      valueListenable: _liveLocation,
                                      builder: (
                                        BuildContext context,
                                        String locationText,
                                        _,
                                      ) {
                                        return Text(
                                          locationText,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: mutedColor,
                                            fontWeight: FontWeight.w500,
                                            height: 1.3,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              _sheetGreyDivider(mutedColor),
                              ValueListenableBuilder<VehicleModel>(
                                valueListenable: _liveTelemetry,
                                builder: (
                                  BuildContext context,
                                  VehicleModel telemetry,
                                  _,
                                ) {
                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: <Widget>[
                                      Container(
                                        height: 90,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 10,
                                        ),
                                        decoration: BoxDecoration(
                                          color: context.containerColor,
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color: context.appTokens
                                                    .containerBorderColor ??
                                                mutedColor.withOpacity(0.25),
                                          ),
                                        ),
                                        child: ListView(
                                          scrollDirection: Axis.horizontal,
                                          physics: const BouncingScrollPhysics(),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                          ),
                                          children: <Widget>[
                                            _buildScrollableGridItem(
                                              context,
                                              Icons.battery_std,
                                              telemetry.devBattery,
                                              'Dev Battery',
                                            ),
                                            _buildScrollableGridItem(
                                              context,
                                              Icons.schedule,
                                              telemetry.engineHours,
                                              'Hours',
                                            ),
                                            _buildScrollableGridItem(
                                              context,
                                              Icons.battery_saver,
                                              telemetry.carBattery,
                                              'Car Battery',
                                            ),
                                            _buildScrollableGridItem(
                                              context,
                                              Icons.satellite_alt,
                                              telemetry.satellites,
                                              'Satellite',
                                            ),
                                            _buildScrollableGridItem(
                                              context,
                                              Icons.local_gas_station,
                                              telemetry.fuelLevel,
                                              'Fuel',
                                            ),
                                            _buildScrollableGridItem(
                                              context,
                                              Icons.gps_fixed,
                                              telemetry.accuracy,
                                              'Accuracy',
                                            ),
                                            _buildScrollableGridItem(
                                              context,
                                              Icons.thermostat,
                                              telemetry.temperature,
                                              'Temp',
                                            ),
                                            _buildScrollableGridItem(
                                              context,
                                              Icons.route,
                                              _formatMovementLabel(
                                                telemetry.movement,
                                              ),
                                              'Movement',
                                            ),
                                          ],
                                        ),
                                      ),
                                      _sheetGreyDivider(mutedColor),
                                      _buildDeviceServerTimeRow(
                                        context,
                                        mutedColor,
                                        accentColor,
                                        telemetry,
                                      ),
                                      _sheetGreyDivider(mutedColor),
                                      SizedBox(
                                        height: 120,
                                        child: PageView(
                                          physics: const BouncingScrollPhysics(),
                                          children: <Widget>[
                                            _buildRunningStopCard(
                                              textColor,
                                              mutedColor,
                                              accentColor,
                                              telemetry,
                                            ),
                                            _buildFuelCard(
                                              textColor,
                                              mutedColor,
                                              telemetry,
                                            ),
                                            _buildSpeedLimitCard(
                                              textColor,
                                              mutedColor,
                                              telemetry,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                              _sheetGreyDivider(mutedColor),
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
                              VehicleModel.parseSpeedKmh(speedText);
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


  Widget _floatingMapButton(IconData icon, Color iconColor, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          height: 40,
          width: 40,
          decoration: BoxDecoration(
            color: context.containerColor,
            borderRadius: BorderRadius.circular(10),
            border: context.appTokens.containerBorderColor == null
                ? null
                : Border.all(color: context.appTokens.containerBorderColor!),
            boxShadow: const <BoxShadow>[
              BoxShadow(
                color: Colors.black12,
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Icon(icon, color: iconColor, size: 21),
        ),
      ),
    );
  }

  Widget _floatingMapZoomControls() {
    return Container(
      width: 40,
      decoration: BoxDecoration(
        color: context.containerColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const <BoxShadow>[
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          InkWell(
            onTap: () => _zoomMapBy(1),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: const SizedBox(
              height: 36,
              width: 40,
              child: Icon(Icons.add, size: 20),
            ),
          ),
          Container(height: 1, color: Colors.black12),
          InkWell(
            onTap: () => _zoomMapBy(-1),
            borderRadius:
                const BorderRadius.vertical(bottom: Radius.circular(20)),
            child: const SizedBox(
              height: 36,
              width: 40,
              child: Icon(Icons.remove, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSheetTopHeader(
    Color textColor,
    Color mutedColor,
    Color accentColor,
  ) {
    return ValueListenableBuilder<String>(
      valueListenable: _liveStatus,
      builder: (BuildContext context, String status, _) {
        return ValueListenableBuilder<String>(
          valueListenable: _liveOdometer,
          builder: (BuildContext context, String odometerValue, _) {
            final double screenWidth = MediaQuery.sizeOf(context).width;
            final double nameMaxWidth =
                (screenWidth * 0.42).clamp(130.0, 190.0);
            final ({String line1, String line2}) nameLines =
                _vehicleNameLines(widget.name);
            final TextStyle nameStyle = TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: textColor,
              height: 1.15,
            );
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 1),
                  child: Icon(
                    _statusIconFor(status),
                    size: 16,
                    color: _statusIconColorFor(status),
                  ),
                ),
                const SizedBox(width: 6),
                SizedBox(
                  width: nameMaxWidth,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        nameLines.line1,
                        style: nameStyle,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      if (nameLines.line2.isNotEmpty)
                        Text(
                          nameLines.line2,
                          style: nameStyle.copyWith(fontSize: 10),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                    ],
                  ),
                ),
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
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
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.speed_outlined, color: accentColor, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          _formatOdometerLabel(odometerValue),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _sheetGreyDivider(Color mutedColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Divider(
        height: 1,
        thickness: 1,
        color: mutedColor.withValues(alpha: 0.38),
      ),
    );
  }

  Widget _buildOdometerRow(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: _liveOdometer,
      builder: (BuildContext context, String odometerValue, _) {
        final List<String> digits = _odometerDigits(odometerValue);
        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: digits
                        .map(
                          (String digit) =>
                              _buildOdometerDigit(context, digit),
                        )
                        .toList(),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            _buildOdometerStatusIcons(),
          ],
        );
      },
    );
  }

  Widget _buildOdometerStatusIcons() {
    const List<(IconData, Color)> items = <(IconData, Color)>[
      (Icons.severe_cold, Colors.pink),
      (Icons.satellite_alt, Colors.green),
      (Icons.power_settings_new, Colors.green),
      (Icons.vpn_key, Colors.green),
      (Icons.battery_charging_full, Colors.green),
    ];
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (int i = 0; i < items.length; i++) ...<Widget>[
          if (i > 0) const SizedBox(width: 8),
          _miniIconBadge(items[i].$1, items[i].$2),
        ],
      ],
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
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Icon(icon, color: color, size: 13),
    );
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

  Widget _buildDeviceServerTimeRow(
    BuildContext context,
    Color mutedColor,
    Color accentColor,
    VehicleModel telemetry,
  ) {
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
                  telemetry.deviceTime,
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
                  telemetry.serverTime,
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
    VehicleModel telemetry,
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
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [_buildSummaryRow(context, const Color(0xff55b985), "Running :", telemetry.runningDuration), const SizedBox(height: 6), _buildSummaryRow(context, const Color(0xfff53d6b), "Stop :", telemetry.stopDuration), const SizedBox(height: 6), _buildSummaryRow(context, const Color(0xffe2ab2f), "Idle :", telemetry.idleDuration), const SizedBox(height: 6), _buildSummaryRow(context, const Color(0xff2aa1ca), "Inactive :", telemetry.inactiveDuration)])),
        ],
      ),
    );
  }

  Widget _buildFuelCard(
    Color textColor,
    Color mutedColor,
    VehicleModel telemetry,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(color: context.containerColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: context.appTokens.containerBorderColor ?? mutedColor.withValues(alpha: 0.25)), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))]),
      child: Row(
        children: [
          const SizedBox(width: 70, child: Center(child: Icon(Icons.local_gas_station_rounded, size: 32, color: Colors.orange))),
          Container(width: 1, height: 75, color: Colors.black.withValues(alpha: 0.06), margin: const EdgeInsets.symmetric(horizontal: 10)),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [_buildFuelRow(context, Icons.speed, Colors.teal, "Fuel Mileage :", telemetry.fuelMileage), const SizedBox(height: 6), _buildFuelRow(context, Icons.local_gas_station_rounded, Colors.orange.shade600, "Fuel Consumption :", telemetry.fuelConsumption), const SizedBox(height: 6), _buildFuelRow(context, Icons.payments_rounded, Colors.green.shade600, "Fuel Cost :", telemetry.fuelCost)])),
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

  Widget _buildSpeedLimitCard(
    Color textColor,
    Color mutedColor,
    VehicleModel telemetry,
  ) {
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
              value: _speedWithUnit(telemetry.avgSpeed),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _buildSpeedBox(
              context: context,
              color: const Color(0xFFFFB8B8),
              icon: Icons.speed_rounded,
              label: "Max Speed",
              value: _speedWithUnit(telemetry.maxSpeed),
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
                _buildActionButton(
                  Icons.directions_car,
                  Colors.red,
                  "Update\nIcon",
                  onTap: _showUpdateIconDialog,
                ),
                _buildActionButton(
                  Icons.speed,
                  Colors.green,
                  "Update\nOdometer",
                  onTap: _showUpdateOdometerDialog,
                ),
                _buildActionButton(
                  Icons.phone,
                  Colors.cyan.shade600,
                  "Call\nDriver",
                  hasBg: true,
                  onTap: _showCallDriverDialog,
                ),
                _buildActionButton(
                  Icons.engineering,
                  Colors.orange,
                  "Update\nEngine",
                  onTap: _showUpdateEngineDialog,
                ),
                _buildActionButton(
                  Icons.group_add,
                  Colors.purple,
                  "Add\nGroup",
                  onTap: _showAddGroupDialog,
                ),
                _buildActionButton(
                  Icons.speed,
                  Colors.redAccent,
                  "overspeed\nLimit",
                  onTap: _showUpdateSpeedLimitDialog,
                ),
                _buildActionButton(
                  Icons.streetview,
                  Colors.blueAccent,
                  "Street\nView",
                  onTap: _openStreetViewOnMaps,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildActionButton(
                  Icons.local_gas_station,
                  Colors.teal,
                  "Fuel Cost\nPer Liter",
                  onTap: _showUpdateFuelCostDialog,
                ),
                _buildActionButton(
                  Icons.av_timer,
                  Colors.brown,
                  "Mileage\nPer Liter",
                  onTap: _showUpdateMileageDialog,
                ),
                _buildActionButton(Icons.location_on, Colors.redAccent, "Share\nLocation", onTap: _shareLocation),
                _buildActionButton(
                  Icons.map,
                  Colors.orange.shade700,
                  "Add\nGeofence",
                  onTap: _openAddGeofenceFlow,
                ),
                _buildActionButton(
                  Icons.notifications_active,
                  Colors.amber,
                  "Add\nReminder",
                  onTap: _openAddReminderFlow,
                ),
                _buildActionButton(
                  Icons.build_circle,
                  Colors.deepOrange,
                  "Engine\ncost",
                  onTap: _showUpdateEngineCostDialog,
                ),
                _buildActionButton(
                  Icons.assignment,
                  Colors.blueGrey,
                  "Upload\nDocs",
                  onTap: _openVehicleDocuments,
                ),
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
      child: Material(
        color: Colors.transparent,
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
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: context.textColor.withValues(alpha: 0.8),
              height: 1.2,
            ),
          ),
        ],
          ),
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

List<_StatItem> _statItemsFromPeriod(VehiclePeriodStats stats) {
  return <_StatItem>[
    _StatItem('Route length', stats.routeLengthKm, 'assets/route_length.png'),
    _StatItem('Move duration', stats.moveDuration, 'assets/move_duration.png'),
    _StatItem('Stop duration', stats.stopDuration, 'assets/stop_duration.png'),
    _StatItem('Idle duration', stats.idleDuration, 'assets/engine_work.png'),
    _StatItem('Top speed', stats.topSpeedKmph, 'assets/top-speed.png'),
    _StatItem('Average speed', stats.avgSpeedKmph, 'assets/top-speed.png'),
    _StatItem('Overspeed count', stats.overspeedCount, 'assets/over_speed.png'),
    _StatItem('Stop count', stats.stopCount, 'assets/stop_count.png'),
    _StatItem('Avg.fuel cons.', stats.avgFuelCons, 'assets/fuel_consum.png'),
    _StatItem('Fuel cost', stats.fuelCostPkr, 'assets/fuel_cost.png'),
    _StatItem('Engine work', stats.engineWorkPkr, 'assets/engine_work.png'),
    _StatItem(
      'Fuel consumption',
      stats.fuelConsumption,
      'assets/fuel_consum.png',
    ),
    _StatItem('Odometer', stats.odometer, 'assets/odometer.png'),
    _StatItem('Engine hours', stats.engineHours, 'assets/engine_work.png'),
  ];
}

class _VehicleStatisticsTab extends StatefulWidget {
  const _VehicleStatisticsTab({
    super.key,
    required this.deviceId,
    required this.vehicleName,
    required this.onBack,
  });

  final int? deviceId;
  final String vehicleName;
  final VoidCallback onBack;

  @override
  State<_VehicleStatisticsTab> createState() => _VehicleStatisticsTabState();
}

class _VehicleStatisticsTabState extends State<_VehicleStatisticsTab> {
  String _selectedStatFilter = 'Today';
  VehiclePeriodStats? _stats;
  bool _isLoading = false;
  String? _loadError;
  int _loadGeneration = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadForFilter('Today'));
  }

  Future<void> _loadForFilter(String filter, {bool forceRefresh = false}) async {
    final int? deviceId = widget.deviceId;
    if (deviceId == null) {
      setState(() {
        _loadError = 'Vehicle not linked to a device';
        _stats = null;
        _isLoading = false;
      });
      return;
    }

    final DateTime now = DateTime.now();
    final ({DateTime from, DateTime to}) range =
        ReportPeriod.statisticsRangeFor(filter, now);

    final VehiclePeriodStats? cached = forceRefresh
        ? null
        : VehicleDetailApiService.peekStatistics(
            deviceId: deviceId,
            from: range.from,
            to: range.to,
          );

    final int generation = ++_loadGeneration;
    setState(() {
      _selectedStatFilter = filter;
      _loadError = null;
      if (cached != null) {
        _stats = cached;
        _isLoading = false;
      } else {
        _isLoading = true;
      }
    });

    try {
      final VehiclePeriodStats loaded =
          await VehicleDetailApiService.loadStatistics(
        deviceId: deviceId,
        from: range.from,
        to: range.to,
        forceRefresh: forceRefresh,
      );
      if (!mounted || generation != _loadGeneration) {
        return;
      }
      setState(() {
        _stats = loaded;
        _isLoading = false;
        _loadError = loaded.hasError ? loaded.errorMessage : null;
      });
    } catch (e) {
      if (!mounted || generation != _loadGeneration) {
        return;
      }
      setState(() {
        _isLoading = false;
        _loadError = e.toString();
      });
    }
  }

  void _onFilterTap(String filter) {
    if (filter == _selectedStatFilter && _stats != null && !_isLoading) {
      _loadForFilter(filter, forceRefresh: true);
      return;
    }
    _loadForFilter(filter);
  }

  @override
  Widget build(BuildContext context) {
    final Color accentColor = Theme.of(context).colorScheme.primary;
    final Color textColor = context.textColor;
    final List<_StatItem> statItems = _stats != null
        ? _statItemsFromPeriod(_stats!)
        : const <_StatItem>[];

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
          if (_isLoading)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Center(
                  child: CircularProgressIndicator(color: accentColor),
                ),
              ),
            ),
          if (_loadError != null && !_isLoading)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Text(
                  _loadError!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.red.shade700, fontSize: 13),
                ),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 12)),
          if (statItems.isNotEmpty)
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
                    final _StatItem item = statItems[index];
                    return _buildStatCard(
                      item.title,
                      item.value,
                      item.imagePath,
                    );
                  },
                  childCount: statItems.length,
                  addAutomaticKeepAlives: false,
                  addRepaintBoundaries: true,
                ),
              ),
            )
          else if (!_isLoading && widget.deviceId == null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  context.tr('Vehicle not linked to a device'),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: context.mutedTextColor),
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
            onTap: () => _onFilterTap(filter),
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
    required this.mapType,
    required this.mapStyle,
    required this.trafficEnabled,
    required this.initialZoom,
    required this.arrowIcon,
    required this.markerAnchor,
    required this.onMapCreated,
    required this.onCameraMoveStarted,
    required this.onCameraIdle,
  });

  final int? deviceId;
  final EdgeInsets padding;
  final LatLng initialTarget;
  final double initialBearing;
  final MapType mapType;
  final String? mapStyle;
  final bool trafficEnabled;
  final double initialZoom;
  final BitmapDescriptor? arrowIcon;
  final Offset markerAnchor;
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
    Offset? markerAnchor,
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
      anchor: markerAnchor ?? widget.markerAnchor,
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
      key: const ValueKey<String>('vehicle_track_google_map'),
      padding: widget.padding,
      initialCameraPosition: CameraPosition(
        target: widget.initialTarget,
        zoom: widget.initialZoom,
        bearing: widget.initialBearing,
      ),
      style: widget.mapStyle,
      mapType: widget.mapType,
      trafficEnabled: widget.trafficEnabled,
      onMapCreated: widget.onMapCreated,
      onCameraMoveStarted: widget.onCameraMoveStarted,
      onCameraIdle: widget.onCameraIdle,
      gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
        Factory<EagerGestureRecognizer>(() => EagerGestureRecognizer()),
      },
      myLocationEnabled: false,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      mapToolbarEnabled: false,
      compassEnabled: false,
      rotateGesturesEnabled: true,
      liteModeEnabled: false,
      buildingsEnabled: true,
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
