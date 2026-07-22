import 'package:flutter/material.dart';

import '../constants/app_theme.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../data/vehicle_data.dart';
import '../models/vehicle_model.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _mapController;
  final LatLng _defaultCenter = const LatLng(31.5204, 74.3587);

  double _zoom = 12;
  bool _trafficEnabled = false;
  MapType _mapType = MapType.normal;
  Set<Marker> _markers = {};
  bool _mapReady = false;

  @override
  void initState() {
    super.initState();
    _markers = _buildVehicleMarkers();
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  Set<Marker> _buildVehicleMarkers() {
    return VehicleData.vehicles.map((vehicle) {
      return Marker(
        markerId: MarkerId(vehicle.name),
        position: LatLng(vehicle.latitude, vehicle.longitude),
        icon: BitmapDescriptor.defaultMarkerWithHue(_markerHue(vehicle)),
        infoWindow: InfoWindow(
          title: vehicle.name,
          snippet: '${vehicle.status} • ${vehicle.speed} km/h',
        ),
      );
    }).toSet();
  }

  double _markerHue(VehicleModel vehicle) {
    switch (vehicle.status.toLowerCase()) {
      case 'running':
        return BitmapDescriptor.hueGreen;
      case 'stopped':
        return BitmapDescriptor.hueRed;
      case 'idle':
      case 'idel':
        return BitmapDescriptor.hueOrange;
      default:
        return BitmapDescriptor.hueAzure;
    }
  }

  Future<void> _fitAllVehicles() async {
    final controller = _mapController;
    if (controller == null || VehicleData.vehicles.isEmpty) {
      return;
    }

    if (VehicleData.vehicles.length == 1) {
      final vehicle = VehicleData.vehicles.first;
      await controller.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(vehicle.latitude, vehicle.longitude),
          14,
        ),
      );
      return;
    }

    double minLat = VehicleData.vehicles.first.latitude;
    double maxLat = VehicleData.vehicles.first.latitude;
    double minLng = VehicleData.vehicles.first.longitude;
    double maxLng = VehicleData.vehicles.first.longitude;

    for (final vehicle in VehicleData.vehicles) {
      minLat = minLat < vehicle.latitude ? minLat : vehicle.latitude;
      maxLat = maxLat > vehicle.latitude ? maxLat : vehicle.latitude;
      minLng = minLng < vehicle.longitude ? minLng : vehicle.longitude;
      maxLng = maxLng > vehicle.longitude ? maxLng : vehicle.longitude;
    }

    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );

    await controller.animateCamera(CameraUpdate.newLatLngBounds(bounds, 80));
  }

  Future<void> _goToMyLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showMessage('Location services are turned off.');
      return;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      _showMessage('Location permission denied.');
      return;
    }

    if (permission == LocationPermission.deniedForever) {
      _showMessage('Enable location permission from app settings.');
      return;
    }

    final position = await Geolocator.getCurrentPosition();
    final target = LatLng(position.latitude, position.longitude);

    setState(() => _zoom = 16);
    await _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: target, zoom: _zoom),
      ),
    );
  }

  void _toggleMapType() {
    setState(() {
      _mapType = switch (_mapType) {
        MapType.normal => MapType.satellite,
        MapType.satellite => MapType.hybrid,
        MapType.hybrid => MapType.normal,
        _ => MapType.normal,
      };
    });
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Widget _buildMapButton(
    IconData icon,
    VoidCallback onTap, {
    Color? color,
    Color? iconColor,
    bool isActive = false,
  }) {
    final Color buttonColor = color ?? context.appSurface;
    final Color buttonIconColor = iconColor ?? context.appTextColor;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 50,
        width: 50,
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFF43A6B) : buttonColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              blurRadius: 8,
              offset: Offset(0, 4),
              color: Colors.black12,
            ),
          ],
        ),
        child: Icon(icon, color: isActive ? Colors.white : buttonIconColor),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appBackground,
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _defaultCenter,
              zoom: _zoom,
            ),
            mapType: _mapType,
            trafficEnabled: _trafficEnabled,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            markers: _markers,
            onMapCreated: (GoogleMapController controller) async {
              _mapController = controller;
              setState(() => _mapReady = true);
              await _fitAllVehicles();
            },
          ),

          if (!_mapReady)
            const Center(
              child: CircularProgressIndicator(color: Color(0xFFF43A6B)),
            ),

          Positioned(
            bottom: 15,
            right: 15,
            child: Column(
              children: [
                _buildMapButton(Icons.add, () {
                  setState(() => _zoom = (_zoom + 1).clamp(3, 20));
                  _mapController?.animateCamera(CameraUpdate.zoomTo(_zoom));
                }),
                const SizedBox(height: 1),
                _buildMapButton(Icons.remove, () {
                  setState(() => _zoom = (_zoom - 1).clamp(3, 20));
                  _mapController?.animateCamera(CameraUpdate.zoomTo(_zoom));
                }),
              ],
            ),
          ),

          Positioned(
            top: 30,
            right: 15,
            child: Column(
              children: [
                _buildMapButton(Icons.filter_alt_outlined, () {
                  _fitAllVehicles();
                }),
                const SizedBox(height: 10),
                _buildMapButton(
                  Icons.layers_outlined,
                  _toggleMapType,
                  isActive: _mapType != MapType.normal,
                ),
                const SizedBox(height: 10),
                _buildMapButton(
                  Icons.traffic,
                  () => setState(() => _trafficEnabled = !_trafficEnabled),
                  isActive: _trafficEnabled,
                ),
              ],
            ),
          ),

          Positioned(
            top: 30,
            left: 15,
            child: GestureDetector(
              onTap: _fitAllVehicles,
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: context.appSurface,
                  boxShadow: const [
                    BoxShadow(
                      blurRadius: 8,
                      offset: Offset(0, 4),
                      color: Colors.black12,
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Image.asset('assets/map_fold.png'),
                ),
              ),
            ),
          ),

          Positioned(
            bottom: 130,
            right: 15,
            child: _buildMapButton(
              Icons.my_location,
              _goToMyLocation,
              isActive: true,
            ),
          ),
        ],
      ),
    );
  }
}
