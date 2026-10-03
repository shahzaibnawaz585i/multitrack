import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

import '../l10n/app_l10n.dart';
import '../services/general_settings_controller.dart';
import '../data/vehicle_data.dart';
import '../models/vehicle_model.dart';
import '../services/alert_service.dart';
import '../services/app_bootstrap_service.dart';
import '../services/location_service.dart';
import '../theme/app_theme_tokens.dart';
import '../utils/map_car_icon.dart';
import '../utils/vehicle_category_map_icon.dart';
import 'notification_filter_screen.dart';
import 'notifications_screen.dart';

class MapScreen extends StatefulWidget {
  final bool isVisible;

  const MapScreen({
    super.key,
    this.isVisible = true,
  });

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  static const double _panScrollPixels = 120;

  double _carRotation = 90.0;
  GoogleMapController? _mapController;

  static const LatLng _defaultCenter = LatLng(31.5204, 74.3587);
  LatLng _cameraTarget = _defaultCenter;
  LatLng? _currentUserLocation;
  int _focusedVehicleIndex = 0;

  double _zoom = 16;

  bool _trafficEnabled = false;
  bool _isLiveLocationActive = false;
  bool _locationPermissionGranted = false;
  bool _isFetchingLocation = false;
  List<VehicleModel> _vehicles = VehicleData.vehicles;
  Timer? _vehicleRefreshTimer;
  bool _vehicleLoadInFlight = false;
  DateTime _lastUserCameraMove = DateTime.fromMillisecondsSinceEpoch(0);
  static const Duration _userCameraThrottle = Duration(milliseconds: 600);
  final Map<String, LatLng> _lastVehiclePositions = <String, LatLng>{};
  int _markerSyncGeneration = 0;

  MapType _mapType = MapType.normal;
  GeneralSettingsController? _generalSettings;

  StreamSubscription<Position>? _positionSubscription;
  final ValueNotifier<Set<Marker>> _markers = ValueNotifier<Set<Marker>>(
    <Marker>{},
  );

  @override
  void initState() {
    super.initState();
    MapCarIcon.clearCache();
    if (VehicleData.vehicles.isNotEmpty) {
      _applyFirstVehicle(VehicleData.vehicles);
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _loadVehicles(forceRefresh: true);
        }
      });
    }
    _syncMarkers();
    if (widget.isVisible) {
      _startVehicleRefresh();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final GeneralSettingsController gs =
        context.read<GeneralSettingsController>();
    if (!identical(_generalSettings, gs)) {
      _generalSettings?.removeListener(_onGeneralSettingsChanged);
      _generalSettings = gs;
      _generalSettings!.addListener(_onGeneralSettingsChanged);
      _applyGeneralSettings(gs);
    }
  }

  void _onGeneralSettingsChanged() {
    if (_generalSettings != null) {
      _applyGeneralSettings(_generalSettings!);
    }
  }

  void _applyGeneralSettings(GeneralSettingsController gs) {
    if (!mounted) {
      return;
    }
    setState(() {
      _mapType = gs.googleMapType;
      _zoom = gs.zoomLevel;
    });
  }

  void _applyFirstVehicle(List<VehicleModel> fetched) {
    _vehicles = fetched;
    _focusedVehicleIndex = 0;
    _cameraTarget = _resolveCameraTarget();
  }

  LatLng _resolveCameraTarget() {
    if (_isLiveLocationActive && _currentUserLocation != null) {
      return _currentUserLocation!;
    }
    final List<VehicleModel> mapped = _mappedVehicles;
    if (mapped.isEmpty) {
      return _defaultCenter;
    }
    final int index = _focusedVehicleIndex.clamp(0, mapped.length - 1);
    final VehicleModel vehicle = mapped[index];
    return LatLng(vehicle.latitude!, vehicle.longitude!);
  }

  static String _markerIdFor(VehicleModel vehicle) {
    if (vehicle.id != null) {
      return 'fleet_vehicle_${vehicle.id}';
    }
    return 'fleet_vehicle_name_${vehicle.name.hashCode}';
  }

  static double _bearingForVehicle(VehicleModel vehicle) {
    if (vehicle.tail.length >= 2) {
      final VehicleTrackPoint from = vehicle.tail[vehicle.tail.length - 2];
      final VehicleTrackPoint to = vehicle.tail.last;
      final double lat1 = from.latitude * math.pi / 180;
      final double lat2 = to.latitude * math.pi / 180;
      final double dLng = (to.longitude - from.longitude) * math.pi / 180;
      final double y = math.sin(dLng) * math.cos(lat2);
      final double x = math.cos(lat1) * math.sin(lat2) -
          math.sin(lat1) * math.cos(lat2) * math.cos(dLng);
      return (math.atan2(y, x) * 180 / math.pi + 360) % 360;
    }
    return 0;
  }

  Future<void> _loadVehicles({bool forceRefresh = false}) async {
    if (_vehicleLoadInFlight) {
      return;
    }
    _vehicleLoadInFlight = true;
    try {
      final List<VehicleModel> fetched =
          await AppBootstrapService.refreshVehicles(forceRefresh: forceRefresh);
      if (!mounted || fetched.isEmpty) {
        return;
      }

      _vehicles = fetched;
      _focusedVehicleIndex = _focusedVehicleIndex.clamp(0, fetched.length - 1);
      _cameraTarget = _resolveCameraTarget();
      await _syncMarkers();
    } finally {
      _vehicleLoadInFlight = false;
    }
  }

  void _startVehicleRefresh() {
    _vehicleRefreshTimer?.cancel();
    _vehicleRefreshTimer = Timer.periodic(const Duration(seconds: 12), (_) {
      _loadVehicles(forceRefresh: false);
    });
  }

  void _stopVehicleRefresh() {
    _vehicleRefreshTimer?.cancel();
    _vehicleRefreshTimer = null;
  }

  @override
  void didUpdateWidget(covariant MapScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isVisible == widget.isVisible) {
      return;
    }
    if (widget.isVisible) {
      _startVehicleRefresh();
      unawaited(_loadVehicles(forceRefresh: true));
      if (_locationPermissionGranted) {
        _startLocationStream();
      }
    } else {
      _stopVehicleRefresh();
      _positionSubscription?.cancel();
      _positionSubscription = null;
    }
  }

  @override
  void dispose() {
    _generalSettings?.removeListener(_onGeneralSettingsChanged);
    _stopVehicleRefresh();
    _positionSubscription?.cancel();
    _mapController = null;
    _markers.dispose();
    super.dispose();
  }

  Future<void> _initCurrentLocation({bool requestOnStart = false}) async {
    if (_isFetchingLocation) {
      return;
    }

    setState(() {
      _isFetchingLocation = true;
    });

    if (requestOnStart) {
      final bool serviceEnabled = await LocationService.isServiceEnabled();
      if (!serviceEnabled && mounted) {
        _showLocationMessage(
          context.tr('Location services are off. Please enable GPS.'),
          actionLabel: context.tr('Settings'),
          onAction: LocationService.openLocationSettings,
        );
        setState(() {
          _isFetchingLocation = false;
        });
        return;
      }

      final bool granted = await LocationService.requestForegroundPermission();
      if (!granted && mounted) {
        _showLocationMessage(
          context.tr('Location permission is required to show your current position.'),
          actionLabel: context.tr('Allow'),
          onAction: () async {
            final bool retry =
                await LocationService.requestForegroundPermission();
            if (!mounted) return;
            if (retry) {
              await _initCurrentLocation();
            } else {
              await LocationService.openAppSettings();
            }
          },
        );
        setState(() {
          _isFetchingLocation = false;
        });
        return;
      }
    }

    final Position? position = await LocationService.getCurrentPosition();
    if (!mounted) {
      return;
    }

    if (position == null) {
      setState(() {
        _isFetchingLocation = false;
      });
      _showLocationMessage(context.tr('Unable to get current location. Try again.'));
      return;
    }

    _applyUserLocation(position, moveCamera: !_isLiveLocationActive);
    _startLocationStream();

    setState(() {
      _locationPermissionGranted = true;
      _isFetchingLocation = false;
    });
  }

  void _startLocationStream() {
    _positionSubscription?.cancel();
    _positionSubscription = LocationService.positionStream().listen(
      (Position position) {
        if (!mounted) {
          return;
        }

        _applyUserLocation(
          position,
          moveCamera: _isLiveLocationActive,
        );
      },
    );
  }

  void _applyUserLocation(Position position, {required bool moveCamera}) {
    final LatLng userLocation = LatLng(position.latitude, position.longitude);

    _currentUserLocation = userLocation;
    if (_isLiveLocationActive) {
      _cameraTarget = userLocation;
      if (position.heading >= 0) {
        _carRotation = position.heading;
      }
      _syncMarkers();
    }

    if (moveCamera) {
      final DateTime now = DateTime.now();
      if (now.difference(_lastUserCameraMove) >= _userCameraThrottle) {
        _lastUserCameraMove = now;
        _mapController?.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: userLocation,
              zoom: _zoom,
              bearing: _carRotation,
            ),
          ),
        );
      }
    }
  }

  List<VehicleModel> get _mappedVehicles => _vehicles
      .where(
        (VehicleModel v) =>
            v.latitude != null &&
            v.longitude != null &&
            (v.latitude != 0.0 || v.longitude != 0.0),
      )
      .toList();

  Future<void> _syncMarkers({bool force = false}) async {
    final int generation = ++_markerSyncGeneration;
    final Set<Marker> nextMarkers = <Marker>{};
    bool changed = force;

    for (final VehicleModel vehicle in _mappedVehicles) {
      final String markerKey = _markerIdFor(vehicle);
      final LatLng position = LatLng(vehicle.latitude!, vehicle.longitude!);
      final LatLng? previous = _lastVehiclePositions[markerKey];

      if (previous == null ||
          previous.latitude != position.latitude ||
          previous.longitude != position.longitude) {
        changed = true;
      }

      _lastVehiclePositions[markerKey] = position;
    }

    if (!changed && _markers.value.isNotEmpty) {
      return;
    }

    for (final VehicleModel vehicle in _mappedVehicles) {
      final String markerKey = _markerIdFor(vehicle);
      final LatLng position = LatLng(vehicle.latitude!, vehicle.longitude!);
      final BitmapDescriptor icon = vehicle.mapIcon.trim().isNotEmpty
          ? await VehicleCategoryMapIcon.forSlug(
              vehicle.mapIcon,
              tint: vehicle.color,
            )
          : await MapCarIcon.forStatus(vehicle.status);
      if (!mounted || generation != _markerSyncGeneration) {
        return;
      }

      nextMarkers.add(
        Marker(
          markerId: MarkerId(markerKey),
          position: position,
          icon: icon,
          anchor: MapCarIcon.markerAnchor,
          flat: true,
          rotation: _bearingForVehicle(vehicle),
          infoWindow: InfoWindow(title: vehicle.name, snippet: vehicle.status),
        ),
      );
    }

    if (nextMarkers.isEmpty) {
      final BitmapDescriptor fallbackIcon =
          await MapCarIcon.forStatus('inactive');
      if (!mounted || generation != _markerSyncGeneration) {
        return;
      }
      nextMarkers.add(
        Marker(
          markerId: const MarkerId('fleet_fallback'),
          position: _cameraTarget,
          icon: fallbackIcon,
          anchor: MapCarIcon.markerAnchor,
          flat: true,
          rotation: _carRotation,
        ),
      );
      changed = true;
    }

    if (!changed && nextMarkers.length == _markers.value.length) {
      return;
    }

    _cameraTarget = _resolveCameraTarget();
    _markers.value = nextMarkers;
  }

  void _showLocationMessage(
    String message, {
    String? actionLabel,
    Future<void> Function()? onAction,
  }) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        action: actionLabel == null
            ? null
            : SnackBarAction(
                label: actionLabel,
                onPressed: () {
                  onAction?.call();
                },
              ),
      ),
    );
  }

  Future<void> _openFilter() async {
    await Navigator.push<NotificationFilterResult>(
      context,
      MaterialPageRoute<NotificationFilterResult>(
        builder: (_) => const NotificationFilterScreen(vehicleOnly: true),
      ),
    );
  }

  void _openNotifications() {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => const NotificationsScreen(),
      ),
    );
  }

  void _toggleTraffic() {
    setState(() {
      _trafficEnabled = !_trafficEnabled;
    });
  }

  Future<void> _recenterMap() async {
    setState(() {
      _isLiveLocationActive = true;
    });

    if (_currentUserLocation != null) {
      await _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: _currentUserLocation!,
            zoom: _zoom,
            bearing: _carRotation,
          ),
        ),
      );
      return;
    }

    await _initCurrentLocation();
  }

  Future<void> _panMapHorizontal(double dx) async {
    await _mapController?.animateCamera(
      CameraUpdate.scrollBy(dx, 0),
    );
  }

  Future<void> _moveLiveLocation(int direction) async {
    if (direction == 0) {
      return;
    }

    setState(() {
      _isLiveLocationActive = false;
    });

    final List<VehicleModel> mapped = _mappedVehicles;
    if (mapped.isEmpty) {
      await _panMapHorizontal(direction * _panScrollPixels);
      return;
    }

    final int nextIndex = _focusedVehicleIndex + direction;
    if (nextIndex < 0 || nextIndex >= mapped.length) {
      await _panMapHorizontal(direction * _panScrollPixels);
      return;
    }

    _focusedVehicleIndex = nextIndex;
    final VehicleModel nextVehicle = mapped[nextIndex];
    final LatLng nextLocation =
        LatLng(nextVehicle.latitude!, nextVehicle.longitude!);

    setState(() {
      _cameraTarget = nextLocation;
      _carRotation = _bearingForVehicle(nextVehicle);
    });

    await _mapController?.animateCamera(
      CameraUpdate.newLatLng(nextLocation),
    );
  }

  Widget _buildSidePanButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.35),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 30,
        ),
      ),
    );
  }

  void _cycleMapType() {
    final GeneralSettingsController gs =
        context.read<GeneralSettingsController>();
    setState(() {
      _mapType = gs.nextMapType(_mapType);
    });
    gs.setSetting('Map Type', gs.mapTypeLabelFor(_mapType));
  }

  Future<void> _showLoadingPopup() async {
    final Color textColor = context.textColor;
    final Color accentColor = Theme.of(context).colorScheme.primary;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return Dialog(
          backgroundColor: context.containerColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 36,
                  height: 36,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: accentColor,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  context.tr('Loading...'),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    await _initCurrentLocation(requestOnStart: true);

    if (mounted && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  Widget _buildTopIconButton({
    required Widget child,
    required VoidCallback onTap,
    bool isActive = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 50,
        width: 50,
        decoration: BoxDecoration(
          color: isActive
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.15)
              : context.containerColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              blurRadius: 8,
              offset: const Offset(0, 4),
              color: Colors.black.withValues(alpha: 0.12),
            ),
          ],
        ),
        child: child,
      ),
    );
  }

  Widget _buildMapButton(
    IconData icon,
    VoidCallback onTap, {
    Color? color,
    Color? iconColor,
  }) {
    final Color buttonColor = color ?? context.containerColor;
    final Color resolvedIconColor =
        iconColor ?? Theme.of(context).colorScheme.onSurface;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 50,
        width: 50,
        decoration: BoxDecoration(
          color: buttonColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              blurRadius: 8,
              offset: const Offset(0, 4),
              color: Colors.black.withValues(alpha: 0.12),
            ),
          ],
        ),
        child: Icon(icon, color: resolvedIconColor),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color accentColor = Theme.of(context).colorScheme.primary;
    final Color iconColor = context.textColor;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          RepaintBoundary(
            child: ValueListenableBuilder<Set<Marker>>(
              valueListenable: _markers,
              builder: (BuildContext context, Set<Marker> markers, _) {
                return GoogleMap(
                  key: const ValueKey<String>('live_google_map'),
                  initialCameraPosition: CameraPosition(
                    target: _cameraTarget,
                    zoom: _zoom,
                  ),
                  style: _mapType == MapType.normal
                      ? context.themedMapStyle
                      : null,
                  mapType: _mapType,
                  trafficEnabled: _trafficEnabled,
                  myLocationEnabled: _locationPermissionGranted,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  compassEnabled: false,
                  mapToolbarEnabled: false,
                  markers: markers,
                  onMapCreated: (GoogleMapController controller) {
                    _mapController = controller;
                  },
                );
              },
            ),
          ),

          if (_isFetchingLocation)
            Center(
              child: CircularProgressIndicator(color: accentColor),
            ),

          Positioned(
            bottom: 15,
            right: 15,
            child: Column(
              children: [
                _buildMapButton(Icons.add, () {
                  _zoom++;
                  _mapController?.animateCamera(CameraUpdate.zoomTo(_zoom));
                }),
                const SizedBox(height: 1),
                _buildMapButton(Icons.remove, () {
                  _zoom--;
                  _mapController?.animateCamera(CameraUpdate.zoomTo(_zoom));
                }),
                const SizedBox(height: 10),
              ],
            ),
          ),

          Positioned(
            top: 30,
            right: 15,
            child: Column(
              children: [
                _buildTopIconButton(
                  onTap: _openFilter,
                  child: Icon(
                    Icons.filter_alt_outlined,
                    color: accentColor,
                  ),
                ),
                const SizedBox(height: 10),
                _buildTopIconButton(
                  onTap: _openNotifications,
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Image.asset(
                      'assets/radio.png',
                      cacheWidth: 48,
                      cacheHeight: 48,
                      filterQuality: FilterQuality.low,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                _buildTopIconButton(
                  onTap: _toggleTraffic,
                  isActive: _trafficEnabled,
                  child: Icon(
                    Icons.traffic,
                    color: _trafficEnabled ? accentColor : iconColor,
                  ),
                ),
                const SizedBox(height: 10),
                _buildTopIconButton(
                  onTap: _showLoadingPopup,
                  child: Icon(
                    Icons.refresh,
                    color: iconColor,
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
          Positioned(
            top: 30,
            left: 15,
            child: _buildTopIconButton(
              onTap: _cycleMapType,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Image.asset(
                  'assets/map_fold.png',
                  cacheWidth: 48,
                  cacheHeight: 48,
                  filterQuality: FilterQuality.low,
                ),
              ),
            ),
          ),

          Positioned(
            left: 8,
            top: 0,
            bottom: 0,
            child: Center(
              child: _buildSidePanButton(
                icon: Icons.chevron_left,
                onTap: () => _moveLiveLocation(-1),
              ),
            ),
          ),
          Positioned(
            right: 8,
            top: 0,
            bottom: 0,
            child: Center(
              child: _buildSidePanButton(
                icon: Icons.chevron_right,
                onTap: () => _moveLiveLocation(1),
              ),
            ),
          ),

          Positioned(
            bottom: 130,
            right: 15,
            child: Container(
              height: 50,
              width: 50,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(100),
                color: _isLiveLocationActive
                    ? accentColor.withValues(alpha: 0.12)
                    : context.containerColor,
                boxShadow: const [
                  BoxShadow(
                    blurRadius: 8,
                    offset: Offset(0, 4),
                    color: Colors.black12,
                  ),
                ],
              ),
              child: IconButton(
                onPressed: _recenterMap,
                icon: Icon(Icons.my_location, color: accentColor),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
