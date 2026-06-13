import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart'; // نقشے کے لیے
import 'package:latlong2/latlong.dart'; // لوکیشن کے لیے

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  // 1. میپ اور ٹریکنگ کے متغیرات (Variables)
  LatLng _carLocation = const LatLng(31.5204, 74.3587); // ابتدائی لوکیشن (لاہور)
  final MapController _mapController = MapController();
  Timer? _timer;
  double _carRotation = 90.0; // گاڑی کا رخ

  @override
  void initState() {
    super.initState();
    _startFakeTracking(); // ایپ لوڈ ہوتے ہی ٹریکنگ شروع
  }

  // 2. گاڑی کو حرکت دینے والا فنکشن
  void _startFakeTracking() {
    _timer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (mounted) {
        setState(() {
          // گاڑی کی لوکیشن میں معمولی اضافہ (شمال مشرق کی طرف)
          _carLocation = LatLng(
            _carLocation.latitude + 0.0002,
            _carLocation.longitude + 0.0002,
          );
          _carRotation += 2.0; // گاڑی کو تھوڑا سا گھمانا
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel(); // میموری بچانے کے لیے ٹائمر بند کرنا
    super.dispose();
  }

  // 3. کسٹم بٹن بنانے والا فنکشن (Helper UI)
  Widget _buildMapButton(IconData icon, VoidCallback onTap, {Color color = Colors.white, Color iconColor = Colors.black}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 50,
        width: 50,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
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
      body:
      Stack(
        children: [
          // 🌏 حصہ 1: لائیو نقشہ
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _carLocation,
              initialZoom: 16.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.multitrack',
              ),

              // 🚗 حصہ 2: گاڑی کا مارکر
              MarkerLayer(
                markers: [
                  Marker(
                    point: _carLocation,
                    width: 50,
                    height: 50,
                    child: Transform.rotate(
                      angle: _carRotation * (3.14159 / 180),
                      child: Image.asset(
                        'assets/caricon.png', // آپ کی گاڑی کی تصویر
                        errorBuilder: (context, error, stackTrace) {
                          // اگر تصویر نہ ملے تو یہ آئیکن دکھائے گا
                          return const Icon(
                            Icons.directions_car_filled,
                            color: Colors.red,
                            size: 50,
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          // 🛰️ حصہ 3: اوپر والا اسٹیٹس بار (Container)


          // ➕➖ حصہ 4: سائیڈ کے کنٹرول بٹنز
          Positioned(
            bottom: 15,
            left: 300,


            child: Column(
              children: [
                _buildMapButton(Icons.add, () {
                  _mapController.move(_mapController.camera.center, _mapController.camera.zoom + 1);
                }),
                SizedBox(
                  height: 1,
                ),

                _buildMapButton(Icons.remove, () {
                  _mapController.move(_mapController.camera.center, _mapController.camera.zoom - 1);
                }),
                const SizedBox(height: 10),

              ],
            ),
          ),

          Positioned(
            top: 30,
            left: 300,


            child: Column(
              children: [
                Container(
                  height: 50,
                  width: 50,
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12)
                  ),
                  child:IconButton(onPressed: (){}, 
                      icon: Icon(Icons.filter_alt_outlined)) ,
                ),
                SizedBox(
                  height: 10,
                ),
                Container(
                  height: 50,
                  width: 50,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12)
                  ),
                  child:Padding(
                    padding:  EdgeInsets.all(8),
                    child: Image.asset('assets/radio.png'),
                  ) ,
                ),
                 SizedBox(height: 10),
                Container(
                  height: 50,
                  width: 50,
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12)
                  ),
                  child:IconButton(onPressed: (){},
                      icon: Icon(Icons.traffic)) ,
                ),

                const SizedBox(height: 10),

              ],
            ),
          ),
          Positioned(
            top: 30,
            right: 300,
            child:Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                borderRadius:BorderRadius.circular(10),
                color: Colors.white
              ),
              child: Padding(
                padding: const EdgeInsets.all(14
                ),
                child: Image.asset('assets/map_fold.png'),
              ),
            )
          ),

          // 🔘 حصہ 5: لوکیشن ری سیٹ بٹن (پنک بٹن)
          Positioned(
            bottom: 130,
            left: 300,
            child: Container(
              height: 50,
              width: 50,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(100),
                color: Colors.white
                
              ),
              child: IconButton(onPressed: (){},
                  icon: Icon(Icons.my_location)),
            )
            ),

        ],
      ),
    );
  }
}