import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';

class TrackScreen extends StatefulWidget {
  const TrackScreen({super.key});

  @override
  State<TrackScreen> createState() => _TrackScreenState();
}

class _TrackScreenState extends State<TrackScreen> {
  final CameraPosition _position = const CameraPosition(
    target: LatLng(26.9124, 75.7873),
    zoom: 14,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          /// MAP
          GoogleMap(
            initialCameraPosition: _position,
            myLocationEnabled: false,
            zoomControlsEnabled: false,
          ),

          /// BACK BUTTON
          Positioned(
            top: 55,
            left: 15,
            child: CircleAvatar(
              radius: 23,
              backgroundColor: Colors.white,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () {},
              ),
            ),
          ),

          /// RIGHT BUTTONS
          Positioned(
            top: 110,
            right: 15,
            child: Column(
              children: [
                _mapButton(Icons.map),
                const SizedBox(height: 10),
                _mapButton(Icons.lock, color: Colors.green),
                const SizedBox(height: 10),
                _mapButton(Icons.local_parking, color: Colors.red),
              ],
            ),
          ),

          /// BOTTOM PANEL
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: MediaQuery.of(context).size.height * .55,
              decoration: const BoxDecoration(
                color: Color(0xfff4f4f4),
                borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    /// VEHICLE HEADER
                    Container(
                      margin: const EdgeInsets.all(12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.directions_car,
                                color: Colors.pink,
                              ),
                              const SizedBox(width: 8),

                              const Text(
                                "RJ14TF1654",
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),

                              const Spacer(),

                              const Icon(Icons.speed, color: Colors.pink),

                              const SizedBox(width: 5),

                              const Text(
                                "175.71 km",
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 20,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 10),

                          Row(
                            children: List.generate(
                              6,
                              (index) => Container(
                                margin: const EdgeInsets.only(right: 5),
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: Text("$index"),
                              ),
                            ),
                          ),

                          const SizedBox(height: 15),

                          SizedBox(
                            height: 170,
                            child: SfRadialGauge(
                              axes: <RadialAxis>[
                                RadialAxis(
                                  minimum: 0,
                                  maximum: 200,
                                  showTicks: true,
                                  showLabels: true,
                                  pointers: const [
                                    NeedlePointer(
                                      value: 17,
                                      needleColor: Colors.red,
                                    ),
                                  ],
                                  annotations: const [
                                    GaugeAnnotation(
                                      widget: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            "17",
                                            style: TextStyle(
                                              fontSize: 30,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text("kmph"),
                                        ],
                                      ),
                                      angle: 90,
                                      positionFactor: 0.5,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          const Row(
                            children: [
                              Icon(Icons.location_on, color: Colors.pink),
                              SizedBox(width: 5),
                              Expanded(
                                child: Text(
                                  "157, Urmila Marg, Gom Defence Colony",
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    /// SENSOR CARD
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 12),
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: const [
                          _InfoWidget(
                            icon: Icons.battery_full,
                            title: "0 V",
                            subtitle: "Battery",
                          ),

                          _InfoWidget(
                            icon: Icons.satellite,
                            title: "15",
                            subtitle: "Satellite",
                          ),

                          _InfoWidget(
                            icon: Icons.local_gas_station,
                            title: "N/A",
                            subtitle: "Fuel",
                          ),

                          _InfoWidget(
                            icon: Icons.thermostat,
                            title: "N/A",
                            subtitle: "Temp",
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    /// TIME CARD
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Row(
                        children: [
                          Expanded(
                            child: Padding(
                              padding: EdgeInsets.all(15),
                              child: Column(
                                children: [
                                  Text(
                                    "Jun 28,2023",
                                    style: TextStyle(
                                      color: Colors.pink,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 5),
                                  Text("Device Time"),
                                ],
                              ),
                            ),
                          ),

                          SizedBox(height: 60, child: VerticalDivider()),

                          Expanded(
                            child: Padding(
                              padding: EdgeInsets.all(15),
                              child: Column(
                                children: [
                                  Text(
                                    "Jun 28,2023",
                                    style: TextStyle(
                                      color: Colors.pink,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 5),
                                  Text("Server Time"),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    /// RUNNING CARD
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 12),
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Column(
                        children: [
                          ListTile(
                            leading: Icon(Icons.circle, color: Colors.green),
                            title: Text("Running"),
                            trailing: Text("01:12 Hrs"),
                          ),

                          ListTile(
                            leading: Icon(Icons.circle, color: Colors.red),
                            title: Text("Stop"),
                            trailing: Text("00:04 Hrs"),
                          ),

                          ListTile(
                            leading: Icon(Icons.circle, color: Colors.orange),
                            title: Text("Idle"),
                            trailing: Text("00:20 Hrs"),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 90),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),

      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: Colors.pink,
        currentIndex: 0,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.location_on),
            label: "Track",
          ),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: "History"),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: "Alerts",
          ),
        ],
      ),
    );
  }

  Widget _mapButton(IconData icon, {Color color = Colors.black}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: color),
    );
  }
}

class _InfoWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _InfoWidget({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon),
        const SizedBox(height: 5),
        Text(title),
        Text(subtitle, style: const TextStyle(fontSize: 11)),
      ],
    );
  }
}
