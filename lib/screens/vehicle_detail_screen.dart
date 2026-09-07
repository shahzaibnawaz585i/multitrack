import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:async';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../l10n/app_l10n.dart';
import '../models/vehicle_model.dart';
import '../services/history_service.dart';
import '../services/tracking_api_service.dart';
import '../services/vehicle_service.dart';
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
  final String time;
  final String livetime;
  final String location;
  final String date;
  final double? latitude;
  final double? longitude;

  const VehicleDetailScreen({
    super.key,
    this.deviceId,
    required this.name,
    required this.status,
    required this.color,
    required this.speed,
    required this.distance,
    required this.time,
    required this.livetime,
    required this.location,
    required this.date,
    this.latitude,
    this.longitude,
  });

  @override
  State<VehicleDetailScreen> createState() => _VehicleDetailScreenState();
}

class _VehicleDetailScreenState extends State<VehicleDetailScreen>
    with SingleTickerProviderStateMixin {
  // ─── UI state ─────────────────────────────────────────────────────────────
  int _currentBottomIndex = 0;
  double _historySliderValue = 0.0;
  bool _isHistoryPlaying = false;
  String _selectedStatFilter = "Today";

  final ValueNotifier<double> _sheetProgress = ValueNotifier<double>(0.0);
  final ValueNotifier<double> _historyPanelTop = ValueNotifier<double>(0.0);
  late final ValueNotifier<Set<Marker>> _trackMarkers;
  final ValueNotifier<Set<Polyline>> _trackPolylines =
      ValueNotifier<Set<Polyline>>(<Polyline>{});

  bool _historyPanelReady = false;
  bool _historyLoading = false;
  HistoryRoute _historyRoute = const HistoryRoute(points: <HistoryPoint>[]);
  final DateTime _historyFrom =
      DateTime.now().subtract(const Duration(hours: 1));
  final DateTime _historyTo = DateTime.now();

  // ─── Map / camera ─────────────────────────────────────────────────────────
  GoogleMapController? _mapController;
  bool _userDraggingMap = false;       // suppress camera follow while user pans
  Timer? _dragIdleTimer;               // re-engage follow after 2.5 s idle

  // ─── Car render state (what is actually drawn on screen) ──────────────────
  late LatLng _carLocation;            // alias kept for UI reads
  double _carRotation = 0.0;
  LatLng _renderPos = const LatLng(0, 0);
  double _renderBearing = 0.0;

  // ─── Kinematic engine ─────────────────────────────────────────────────────
  // Vsync AnimationController drives the 60-fps tick
  late AnimationController _animCtrl;

  // Catmull-Rom waypoint ring buffer (last 4 confirmed GPS fixes)
  final List<LatLng> _waypoints = <LatLng>[];

  // Animation progress 0→1 between _fromPos and _toPos
  LatLng _fromPos = const LatLng(0, 0);
  LatLng _toPos   = const LatLng(0, 0);
  double _fromBearing = 0.0;
  double _toBearing   = 0.0;

  // Dead-reckoning: velocity in deg/s (lat & lng components separately)
  double _velLatDegPerSec = 0.0;
  double _velLngDegPerSec = 0.0;

  // Timestamp / duration of current animation segment
  DateTime _segmentStart = DateTime.now();
  double   _segmentDurMs = 500.0;      // initial guess — refined on each fix

  // Kalman-like GPS smoothing (exponential filter on incoming lat/lng)
  LatLng? _filteredGps;
  static const double _gpsAlpha = 0.72;

  // ─── Trail polyline points ─────────────────────────────────────────────────
  final List<LatLng> _trailPoints = <LatLng>[];

  // ─── API polling ──────────────────────────────────────────────────────────
  Timer? _pollTimer;
  DateTime _lastFixTime = DateTime.now();
  LatLng  _lastFixPos   = const LatLng(0, 0);

  // ─── Cached marker icon ───────────────────────────────────────────────────
  BitmapDescriptor? _carIcon;

  // ─── Helpers ──────────────────────────────────────────────────────────────
  bool get _isRunning =>
      widget.status.trim().toLowerCase() == 'running' ||
      (double.tryParse(widget.speed) ?? 0.0) > 0;

  String get _carIconAsset => 'assets/caricon.png';

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
    _carLocation   = initial;
    _renderPos     = initial;
    _fromPos       = initial;
    _toPos         = initial;
    _lastFixPos    = initial;
    _filteredGps   = initial;
    _waypoints.add(initial);
    _trailPoints.add(initial);

    _trackMarkers = ValueNotifier<Set<Marker>>(<Marker>{
      Marker(
        markerId: const MarkerId('car'),
        position: initial,
        rotation: _carRotation,
        flat: true,
        anchor: const Offset(0.5, 0.5),
        icon: BitmapDescriptor.defaultMarker,
      ),
    });

    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(days: 999),
    )..addListener(_onAnimationTick);

    _loadCarIcon();
    _startLiveTracking();
  }

  Future<void> _loadCarIcon() async {
    final BitmapDescriptor icon = await BitmapDescriptor.asset(
      const ImageConfiguration(size: Size(60, 60)),
      _carIconAsset,
    );
    if (!mounted) return;
    _carIcon = icon;
    _syncMarker();
  }

  void _startLiveTracking() {
    _pollTimer?.cancel();
    _animCtrl.stop();

    if (widget.deviceId == null) {
      if (_isRunning) _startSimulatedTracking();
      return;
    }

    _animCtrl.repeat();
    _refreshLivePosition();
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _refreshLivePosition();
    });
  }

  void _onAnimationTick() {
    if (!mounted) return;

    final double elapsedMs =
        DateTime.now().difference(_segmentStart).inMicroseconds / 1000.0;
    final double rawT = _segmentDurMs > 0 ? elapsedMs / _segmentDurMs : 1.0;

    LatLng target;
    double targetBearing;

    if (rawT <= 1.0) {
      final double t = _easeInOutCubic(rawT);
      target = _catmullRomLatLng(t);
      targetBearing = _lerpAngle(_fromBearing, _toBearing, t);
    } else {
      final double extraMs = elapsedMs - _segmentDurMs;
      final double extraSec = (extraMs / 1000.0).clamp(0.0, 30.0);
      target = LatLng(
        _toPos.latitude  + _velLatDegPerSec * extraSec,
        _toPos.longitude + _velLngDegPerSec * extraSec,
      );
      targetBearing = _toBearing;
    }

    const double bearingDamp = 0.12;
    _renderBearing = _lerpAngle(_renderBearing, targetBearing, bearingDamp);

    _renderPos   = target;
    _carLocation = _renderPos;
    _carRotation = _renderBearing;
    _syncMarker();

    if (_currentBottomIndex == 0 && !_userDraggingMap) {
      _followCamera();
    }
  }

  void _followCamera() {
    try {
      _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: _renderPos,
            zoom: 17.5,
            bearing: _renderBearing,
            tilt: _isRunning ? 45.0 : 0.0,
          ),
        ),
      );
    } catch (_) {
      _mapController = null;
    }
  }

  Future<void> _refreshLivePosition() async {
    if (widget.deviceId == null || !mounted) return;

    final List<VehicleModel> devices =
        await VehicleService.getDevices(forceRefresh: true);
    VehicleModel? match;
    for (final VehicleModel d in devices) {
      if (d.id == widget.deviceId) { match = d; break; }
    }

    if (match == null || match.latitude == null ||
        match.longitude == null || !mounted) return;

    final LatLng raw = LatLng(match.latitude!, match.longitude!);

    final LatLng prev = _filteredGps ?? raw;
    final LatLng filtered = LatLng(
      prev.latitude  + _gpsAlpha * (raw.latitude  - prev.latitude),
      prev.longitude + _gpsAlpha * (raw.longitude - prev.longitude),
    );
    _filteredGps = filtered;

    final double dist = _haversineMeters(_lastFixPos, filtered);
    if (dist < 4.0) return;

    final double secsSinceFix =
        DateTime.now().difference(_lastFixTime).inMilliseconds / 1000.0;
    final double newBearing = dist > 1.0
        ? _calculateBearing(_lastFixPos, filtered)
        : _toBearing;

    if (secsSinceFix > 0.3 && dist > 2.0) {
      const double mPerDegLat = 111319.5;
      final double mPerDegLng =
          mPerDegLat * math.cos(filtered.latitude * math.pi / 180);
      _velLatDegPerSec =
          (filtered.latitude  - _lastFixPos.latitude)  / secsSinceFix;
      _velLngDegPerSec =
          (filtered.longitude - _lastFixPos.longitude) / secsSinceFix;
      final double maxLatDeg = 200.0 / 3.6 / mPerDegLat;
      final double maxLngDeg = 200.0 / 3.6 / mPerDegLng;
      _velLatDegPerSec = _velLatDegPerSec.clamp(-maxLatDeg, maxLatDeg);
      _velLngDegPerSec = _velLngDegPerSec.clamp(-maxLngDeg, maxLngDeg);
    } else {
      _velLatDegPerSec = 0;
      _velLngDegPerSec = 0;
    }

    _waypoints.add(filtered);
    if (_waypoints.length > 4) _waypoints.removeAt(0);

    _fromPos      = _renderPos;
    _toPos        = filtered;
    _fromBearing  = _renderBearing;
    _toBearing    = newBearing;
    _segmentStart = DateTime.now();
    _segmentDurMs = (secsSinceFix * 1000).clamp(300.0, 8000.0);

    _lastFixPos  = filtered;
    _lastFixTime = DateTime.now();

    _trailPoints.add(filtered);
    if (_trailPoints.length > 200) _trailPoints.removeAt(0);
    _syncTrailPolyline();
  }

  void _startSimulatedTracking() {
    final double kmh = double.tryParse(widget.speed) ?? 30.0;
    final double mps = kmh / 3.6;
    const double mPerDegLat = 111319.5;
    final double refLat = _carLocation.latitude;
    final double mPerDegLng = mPerDegLat * math.cos(refLat * math.pi / 180);

    _carRotation   = 45.0;
    _renderBearing = 45.0;

    double simBearing = 45.0;
    int frame = 0;
    final math.Random rng = math.Random();

    _animCtrl.addListener(() {
      if (!mounted || widget.deviceId != null) return;
      frame++;

      if (frame % 240 == 0) {
        simBearing = (simBearing + (rng.nextDouble() - 0.5) * 28 + 360) % 360;
      }

      _renderBearing = _lerpAngle(_renderBearing, simBearing, 0.025);
      _carRotation   = _renderBearing;

      const double dtMs = 1000.0 / 60.0;
      final double rad  = _renderBearing * math.pi / 180.0;
      final double dLat = mps * math.cos(rad) / mPerDegLat * (dtMs / 1000.0);
      final double dLng = mps * math.sin(rad) / mPerDegLng * (dtMs / 1000.0);

      _carLocation = LatLng(_carLocation.latitude + dLat,
                            _carLocation.longitude + dLng);
      _renderPos   = _carLocation;

      if (frame % 30 == 0) {
        _trailPoints.add(_carLocation);
        if (_trailPoints.length > 200) _trailPoints.removeAt(0);
        _syncTrailPolyline();
      }

      _syncMarker();

      if (_currentBottomIndex == 0 && !_userDraggingMap) {
        _followCamera();
      }
    });

    _animCtrl.repeat();
  }

  LatLng _catmullRomLatLng(double t) {
    if (_waypoints.length < 2) return _toPos;
    if (_waypoints.length < 4) {
      return LatLng(
        _fromPos.latitude  + (_toPos.latitude  - _fromPos.latitude)  * t,
        _fromPos.longitude + (_toPos.longitude - _fromPos.longitude) * t,
      );
    }
    final LatLng p0 = _waypoints[_waypoints.length - 4];
    final LatLng p1 = _waypoints[_waypoints.length - 3];
    final LatLng p2 = _waypoints[_waypoints.length - 2];
    final LatLng p3 = _waypoints[_waypoints.length - 1];
    final double t2 = t * t, t3 = t2 * t;
    final double lat =
        0.5 * ((2.0 * p1.latitude) +
        (-p0.latitude + p2.latitude) * t +
        (2.0 * p0.latitude - 5.0 * p1.latitude + 4.0 * p2.latitude - p3.latitude) * t2 +
        (-p0.latitude + 3.0 * p1.latitude - 3.0 * p2.latitude + p3.latitude) * t3);
    final double lng =
        0.5 * ((2.0 * p1.longitude) +
        (-p0.longitude + p2.longitude) * t +
        (2.0 * p0.longitude - 5.0 * p1.longitude + 4.0 * p2.longitude - p3.longitude) * t2 +
        (-p0.longitude + 3.0 * p1.longitude - 3.0 * p2.longitude + p3.longitude) * t3);
    return LatLng(lat, lng);
  }

  static double _easeInOutCubic(double t) =>
      t < 0.5 ? 4.0 * t * t * t : 1.0 - math.pow(-2.0 * t + 2.0, 3) / 2.0;

  static double _haversineMeters(LatLng a, LatLng b) {
    const double r = 6371000;
    final double lat1 = a.latitude  * math.pi / 180;
    final double lat2 = b.latitude  * math.pi / 180;
    final double dLat = (b.latitude  - a.latitude)  * math.pi / 180;
    final double dLng = (b.longitude - a.longitude) * math.pi / 180;
    final double s = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1) * math.cos(lat2) *
        math.sin(dLng / 2) * math.sin(dLng / 2);
    return r * 2 * math.atan2(math.sqrt(s), math.sqrt(1 - s));
  }

  static double _lerpAngle(double from, double to, double t) {
    final double diff = (to - from + 540) % 360 - 180;
    return (from + diff * t + 360) % 360;
  }

  /// Calculates the compass bearing from [start] to [end].
  static double _calculateBearing(LatLng start, LatLng end) {
    final double lat1 = start.latitude * math.pi / 180;
    final double lat2 = end.latitude * math.pi / 180;
    final double dLng = (end.longitude - start.longitude) * math.pi / 180;
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
      _startLiveTracking();
    } else {
      _pollTimer?.cancel();
      _animCtrl.stop();
      if (index == 1) _loadHistory();
    }
  }

  // ─── Marker + polyline sync ────────────────────────────────────────────────
  void _syncMarker() {
    final BitmapDescriptor icon = _carIcon ?? BitmapDescriptor.defaultMarker;
    _trackMarkers.value = <Marker>{
      Marker(
        markerId: const MarkerId('car'),
        position: _carLocation,
        rotation: _carRotation,
        flat: true,
        anchor: const Offset(0.5, 0.5),
        icon: icon,
        zIndexInt: 10,
      ),
    };
  }

  // Alias for backward compatibility (history screen calls this)
  void _syncTrackMarkers() => _syncMarker();

  void _syncTrailPolyline() {
    if (_trailPoints.length < 2) return;
    _trackPolylines.value = <Polyline>{
      Polyline(
        polylineId: const PolylineId('vehicle_trail'),
        points: List<LatLng>.from(_trailPoints),
        color: _isRunning
            ? const Color(0xFF00E676)
            : Theme.of(context).colorScheme.primary,
        width: 6,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
        jointType: JointType.round,
      ),
    };
  }

  void _syncTrackPolyline() => _syncTrailPolyline();

  // ─── History ──────────────────────────────────────────────────────────────
  Future<void> _loadHistory() async {
    if (widget.deviceId == null) return;
    setState(() => _historyLoading = true);
    final HistoryRoute route = await HistoryService.getRoute(
      deviceId: widget.deviceId!,
      from: _historyFrom,
      to: _historyTo,
    );
    if (!mounted) return;
    setState(() {
      _historyLoading = false;
      _historyRoute   = route;
      if (route.points.isNotEmpty) _historySliderValue = 0;
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
    _pollTimer?.cancel();
    _dragIdleTimer?.cancel();
    _animCtrl.dispose();
    _mapController = null;
    _sheetProgress.dispose();
    _historyPanelTop.dispose();
    _trackMarkers.dispose();
    _trackPolylines.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    final Color accentColor = Theme.of(context).colorScheme.primary;
    final Color mutedColor = context.mutedTextColor;
    final double screenHeight = MediaQuery.of(context).size.height;

    final double maxTopLimit = 120.0;
    final double bottomLimit = screenHeight * 0.8;
    if (!_historyPanelReady) {
      _historyPanelTop.value = screenHeight * 0.65;
      _historyPanelReady = true;
    }

    return Scaffold(
      body: _buildSelectedTab(
        maxTopLimit,
        bottomLimit,
        screenHeight,
        accentColor,
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

  Widget _buildSelectedTab(
    double maxTopLimit,
    double bottomLimit,
    double screenHeight,
    Color accentColor,
  ) {
    switch (_currentBottomIndex) {
      case 1:
        return _buildHistoryView(
          maxTopLimit,
          bottomLimit,
          screenHeight,
          accentColor,
        );
      case 2:
        return NotificationsScreen(
          showAlertsOnly: true,
          vehicleName: widget.name,
          deviceId: widget.deviceId,
        );
      case 3:
        return _buildStatisticsView(accentColor);
      default:
        return _buildTrackView();
    }
  }

  /// --- STATISTICS VIEW ---
  Widget _buildStatisticsView(Color accentColor) {
    final Color textColor = context.textColor;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: context.containerColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: accentColor, size: 20),
          onPressed: () => _selectTab(0),
        ),
        title: Text(
          '${widget.name} ${context.tr('Statistics')}',
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
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
    final filters = ["Today", "Yesterday", "2 Days", "3 Days", "This Week", "Last Week", "This Month", "Last Month"];
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
        itemBuilder: (context, index) {
          final filter = filters[index];
          bool isSelected = _selectedStatFilter == filter;
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
        border: context.appTokens.containerBorderColor == null ? null : Border.all(color: context.appTokens.containerBorderColor!),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
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

  /// --- TRACK VIEW ---
  Widget _buildTrackView() {
    final double currentSpeed = double.tryParse(widget.speed) ?? 0.0;
    final double mediaHeight = MediaQuery.of(context).size.height;
    final Color textColor = context.textColor;
    final Color mutedColor = context.mutedTextColor;
    final Color accentColor = Theme.of(context).colorScheme.primary;

    return Stack(
      children: [
        Positioned.fill(
          child: RepaintBoundary(
            child: ValueListenableBuilder<Set<Marker>>(
              valueListenable: _trackMarkers,
              builder: (BuildContext context, Set<Marker> markers, _) {
                return ValueListenableBuilder<Set<Polyline>>(
                  valueListenable: _trackPolylines,
                  builder: (BuildContext context, Set<Polyline> polylines, _) {
                    return GoogleMap(
                      key: const ValueKey<String>('vehicle_track_map'),
                      initialCameraPosition: CameraPosition(
                        target: _carLocation,
                        zoom: 16.5,
                        bearing: _carRotation,
                      ),
                      style: context.themedMapStyle,
                      onMapCreated: (GoogleMapController controller) =>
                          _mapController = controller,
                      myLocationEnabled: false,
                      zoomControlsEnabled: false,
                      mapToolbarEnabled: false,
                      compassEnabled: false,
                      markers: markers,
                      polylines: polylines,
                    );
                  },
                );
              },
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
                  _mapController?.animateCamera(
                    CameraUpdate.newCameraPosition(
                      CameraPosition(
                        target: _carLocation,
                        zoom: 17.0,
                        bearing: _carRotation,
                      ),
                    ),
                  );
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
          bottom: (mediaHeight * 0.47) + 20,
          left: 16,
          child: _floatingMapButton(
            Icons.route_outlined,
            Colors.redAccent,
            () {
              _mapController?.animateCamera(
                CameraUpdate.newCameraPosition(
                  CameraPosition(
                    target: _carLocation,
                    zoom: 17.0,
                    bearing: _carRotation,
                  ),
                ),
              );
            },
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
            initialChildSize: 0.47,
            minChildSize: 0.47,
            maxChildSize: 0.85,
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
                        const SizedBox(height: 40),
                        Expanded(
                            child: ListView(
                            controller: scrollController,
                            physics: const BouncingScrollPhysics(),
                            cacheExtent: 250,
                            addAutomaticKeepAlives: false,
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                            children: [
                              Row(
                                children: [
                                  Image.asset(
                                    'assets/caricon.png',
                                    height: 26,
                                    width: 26,
                                    color: widget.color,
                                    colorBlendMode: BlendMode.srcIn,
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      widget.name,
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: textColor,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Icon(Icons.speed, color: accentColor, size: 18),
                                  const SizedBox(width: 4),
                                  Text(
                                    widget.distance,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: textColor,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
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
                                    _buildRunningStopCard(textColor, mutedColor),
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
                    top: -70,
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
                      child: Center(
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              height: 140,
                              width: 140,
                              decoration: BoxDecoration(
                                color: context.containerColor,
                                shape: BoxShape.circle,
                                border: context.appTokens.containerBorderColor == null
                                    ? null
                                    : Border.all(color: context.appTokens.containerBorderColor!),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.08),
                                    blurRadius: 14,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(
                              height: 130,
                              width: 130,
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
                              bottom: 24,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    widget.speed,
                                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textColor, height: 1.0),
                                  ),
                                  Text(
                                    context.tr("kmph"),
                                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: mutedColor),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
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
                          SliderTheme(
                            data: SliderTheme.of(context).copyWith(trackHeight: 40, thumbShape: SliderComponentShape.noThumb, overlayShape: SliderComponentShape.noOverlay, activeTrackColor: accentColor.withOpacity(0.15), inactiveTrackColor: Colors.transparent),
                            child: Slider(value: _historySliderValue, onChanged: (v) => setState(() => _historySliderValue = v)),
                          ),
                          Positioned.fill(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Row(
                                children: [
                                  GestureDetector(onTap: () => setState(() => _isHistoryPlaying = !_isHistoryPlaying), child: Icon(_isHistoryPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill, color: accentColor, size: 30)),
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

  Widget _buildOdometerRow(BuildContext context) {
    return Row(
      children: [
        _buildOdometerDigit(context, "0"), _buildOdometerDigit(context, "2"), _buildOdometerDigit(context, "6"), _buildOdometerDigit(context, "9"), _buildOdometerDigit(context, "3"), _buildOdometerDigit(context, "1"), _buildOdometerDigit(context, "1"), _buildOdometerDigit(context, "1"),
        const Spacer(),
        _miniIconBadge(Icons.severe_cold, Colors.pink), _miniIconBadge(Icons.satellite_alt, Colors.green), _miniIconBadge(Icons.power_settings_new, Colors.green), _miniIconBadge(Icons.vpn_key, Colors.green), _miniIconBadge(Icons.battery_charging_full, Colors.green),
      ],
    );
  }

  Widget _buildOdometerDigit(BuildContext context, String digit) {
    return Container(margin: const EdgeInsets.only(right: 3), padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4), decoration: BoxDecoration(color: context.containerColor, borderRadius: BorderRadius.circular(4), border: Border.all(color: context.appTokens.containerBorderColor ?? context.mutedTextColor.withOpacity(0.35))), child: Text(digit, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: context.textColor)));
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

  Widget _buildRunningStopCard(Color textColor, Color mutedColor) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(color: context.containerColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: context.appTokens.containerBorderColor ?? mutedColor.withValues(alpha: 0.25)), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))]),
      child: Row(
        children: [
          SizedBox(width: 65, child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.location_on, color: Color(0xfff53d6b), size: 28), const SizedBox(height: 4), Text(widget.distance.isNotEmpty ? widget.distance : "0 km", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textColor), textAlign: TextAlign.center)])),
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

class _HistoryMap extends StatelessWidget {
  const _HistoryMap({required this.route});

  final HistoryRoute route;

  @override
  Widget build(BuildContext context) {
    final List<LatLng> points =
        route.points.map((HistoryPoint p) => p.position).toList();
    final LatLng target = points.isNotEmpty
        ? points.first
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
      polylines: points.length >= 2
          ? <Polyline>{
              Polyline(
                polylineId: const PolylineId('history_route'),
                points: points,
                color: const Color(0xFFF53D6B),
                width: 4,
              ),
            }
          : const <Polyline>{},
      markers: points.isNotEmpty
          ? <Marker>{
              Marker(
                markerId: const MarkerId('history_start'),
                position: points.first,
              ),
              if (points.length > 1)
                Marker(
                  markerId: const MarkerId('history_end'),
                  position: points.last,
                ),
            }
          : const <Marker>{},
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
    final circlePaint = Paint()..style = PaintingStyle.stroke..strokeWidth = 2.5..shader = const SweepGradient(colors: [Colors.green, Colors.yellow, Colors.orange, Colors.red, Colors.green]).createShader(rect);
    canvas.drawCircle(center, radius - 2, circlePaint);
    const double startAngle = math.pi * 0.75;
    const double maxSweepAngle = math.pi * 1.5;
    final List<String> scale = ["0", "_", "50", "_", "100", "_", "150", "_", "200"];
    for (int i = 0; i < scale.length; i++) {
      final angle = startAngle + (i * maxSweepAngle / (scale.length - 1));
      final tickPaint = Paint()..color = scale[i] == "_" ? scaleTextColor.withOpacity(0.35) : scaleTextColor..strokeWidth = scale[i] == "_" ? 1.5 : 2;
      final tickStart = Offset(center.dx + (radius - 5) * math.cos(angle), center.dy + (radius - 5) * math.sin(angle));
      final tickEnd = Offset(center.dx + (radius - 15) * math.cos(angle), center.dy + (radius - 15) * math.sin(angle));
      canvas.drawLine(tickStart, tickEnd, tickPaint);
      if (scale[i] != "_") _drawScaleText(canvas, center, scale[i], angle, radius - 28);
    }
    final needleAngle = startAngle + ((speedValue / 200).clamp(0.0, 1.0) * maxSweepAngle);
    final tip = Offset(center.dx + (radius - 18) * math.cos(needleAngle), center.dy + (radius - 18) * math.sin(needleAngle));
    canvas.drawLine(center, tip, Paint()..color = Colors.red..strokeWidth = 3);
    canvas.drawCircle(center, 7, Paint()..color = Colors.black87);
    canvas.drawCircle(center, 4, Paint()..color = Colors.red);
  }

  void _drawScaleText(Canvas canvas, Offset center, String text, double angle, double distance) {
    final tp = TextPainter(text: TextSpan(text: text, style: TextStyle(color: scaleTextColor, fontSize: 10, fontWeight: FontWeight.bold)), textDirection: TextDirection.ltr)..layout();
    canvas.save();
    canvas.translate(center.dx + distance * math.cos(angle) - tp.width / 2, center.dy + distance * math.sin(angle) - tp.height / 2);
    tp.paint(canvas, Offset.zero);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant FullCircularSpeedoPainter oldDelegate) => oldDelegate.speedValue != speedValue || oldDelegate.scaleTextColor != scaleTextColor;
}
