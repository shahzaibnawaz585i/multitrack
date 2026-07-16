// import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:geolocator/geolocator.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  // 1. میپ اور ٹریکنگ کے متغیرات (Variables)
  double _carRotation = 90.0;
  GoogleMapController? _mapController;

  LatLng _carLocation = const LatLng(31.5204, 74.3587);

  double _zoom = 16;

  bool _trafficEnabled = false;

  MapType _mapType = MapType.normal;
  Widget _buildMapButton(
    IconData icon,
    VoidCallback onTap, {
    Color color = Colors.white,
    Color iconColor = Colors.black,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 50,
        width: 50,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              blurRadius: 8,
              offset: Offset(0, 4),
              color: Colors.black12,
            ),
          ],
        ),
        child: Icon(icon, color: iconColor),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // 🌏 حصہ 1: لائیو نقشہ
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _carLocation,
              zoom: _zoom,
            ),
            mapType: _mapType,
            trafficEnabled: _trafficEnabled,
            myLocationEnabled: false,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            markers: {
              Marker(
                markerId: const MarkerId('car'),
                position: _carLocation,
                rotation: _carRotation,
              ),
            },
            onMapCreated: (GoogleMapController controller) {
              _mapController = controller;
            },
          ),

          // 🛰️ حصہ 3: اوپر والا اسٹیٹس بار (Container)

          // ➕➖ حصہ 4: سائیڈ کے کنٹرول بٹنز
          Positioned(
            bottom: 15,
            right: 15,

            child: Column(
              children: [
                _buildMapButton(Icons.add, () {
                  setState(() {
                    _zoom++;
                  });

                  _mapController?.animateCamera(CameraUpdate.zoomTo(_zoom));
                }),
                SizedBox(height: 1),

                _buildMapButton(Icons.remove, () {
                  setState(() {
                    _zoom--;
                  });

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
                Container(
                  height: 50,
                  width: 50,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    onPressed: () {},
                    icon: Icon(Icons.filter_alt_outlined),
                  ),
                ),
                SizedBox(height: 10),
                Container(
                  height: 50,
                  width: 50,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(8),
                    child: Image.asset('assets/radio.png'),
                  ),
                ),
                SizedBox(height: 10),
                Container(
                  height: 50,
                  width: 50,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    onPressed: () {},
                    icon: Icon(Icons.traffic),
                  ),
                ),

                const SizedBox(height: 10),
              ],
            ),
          ),
          Positioned(
            top: 30,
            left: 15,
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: Colors.white,
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Image.asset('assets/map_fold.png'),
              ),
            ),
          ),

          // 🔘 حصہ 5: لوکیشن ری سیٹ بٹن (پنک بٹن)
          Positioned(
            bottom: 130,
            right: 15,
            child: Container(
              height: 50,
              width: 50,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(100),
                color: Colors.white,
              ),
              child: IconButton(
                onPressed: () {},
                icon: Icon(Icons.my_location),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
