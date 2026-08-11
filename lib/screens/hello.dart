import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:async';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../theme/app_theme_tokens.dart';
import '../theme/hacking_map_style.dart';

class VehicleDetailScreen extends StatefulWidget {
  final String name;
  final String status;
  final Color color;
  final String speed;
  final String distance;
  final String time;
  final String livetime;
  final String location;
  final String date;

  const VehicleDetailScreen({
    super.key,
    required this.name,
    required this.status,
    required this.color,
    required this.speed,
    required this.distance,
    required this.time,
    required this.livetime,
    required this.location,
    required this.date,
  });

  @override
  State<VehicleDetailScreen> createState() => _VehicleDetailScreenState();
}

class _VehicleDetailScreenState extends State<VehicleDetailScreen> {
  // int _selectindex = 0;

  // اسکرینز کی لسٹ - آپ کا ڈیزائن انڈیکس 0 پر ہے
  // final List<Widget> _screens = [
  //   const Center(child: Text("Profile Screen")),
  //   const Center(child: Text("Profile Screen")),
  //   const Center(child: Text("Settings Screen")),
  // ];
  int _currentBottomIndex = 0;
  double _sheetProgress = 0.0;

  GoogleMapController? _mapController;
  LatLng _carLocation = const LatLng(31.5204, 74.3587);
  double _carRotation = 90.0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startFakeTracking();
  }

  void _startFakeTracking() {
    _timer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (mounted) {
        setState(() {
          _carLocation = LatLng(
            _carLocation.latitude + 0.0001,
            _carLocation.longitude + 0.0001,
          );
          _carRotation += 1.5;
        });
        _mapController?.animateCamera(CameraUpdate.newLatLng(_carLocation));
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    // GoogleMapController managed internally, no dispose() method exists.
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double currentSpeed = double.tryParse(widget.speed) ?? 0.0;
    final double mediaHeight = MediaQuery.of(context).size.height;
    final Color textColor = context.textColor;
    final Color mutedColor = context.mutedTextColor;
    final Color accentColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      body: Stack(
        children: [
          /// 1️⃣ GOOGLE MAP BACKGROUND
          Positioned.fill(
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _carLocation,
                zoom: 16.0,
              ),
              style: context.isHackingTheme ? hackingMapStyle : null,
              onMapCreated: (controller) => _mapController = controller,
              myLocationEnabled: false,
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
              markers: {
                Marker(
                  markerId: const MarkerId("car"),
                  position: _carLocation,
                  rotation: _carRotation,
                  flat: true,
                  anchor: const Offset(0.5, 0.5),
                  icon: BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueAzure,
                  ),
                ),
              },
            ),
          ),

          /// Floating Buttons Overlay
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
                _floatingMapButton(Icons.map_outlined, textColor, () {}),
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
                  () {},
            ),
          ),

          /// 2️⃣ SCROLLABLE SHEET
          NotificationListener<DraggableScrollableNotification>(
            onNotification: (notification) {
              final double delta =
                  notification.maxExtent - notification.minExtent;
              if (mounted) {
                setState(() {
                  if (delta > 0) {
                    _sheetProgress =
                        ((notification.extent - notification.minExtent) / delta)
                            .clamp(0.0, 1.0);
                  } else {
                    _sheetProgress = 0.0;
                  }
                });
              }
              return true;
            },
            child: DraggableScrollableSheet(
              initialChildSize: 0.47,
              minChildSize: 0.47,
              maxChildSize: 0.85,
              builder:
                  (BuildContext context, ScrollController scrollController) {
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
                        border: context.appTokens.containerBorderColor ==
                            null
                            ? null
                            : Border.all(
                          color: context
                              .appTokens.containerBorderColor!,
                        ),
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
                              color: mutedColor.withValues(alpha: 0.4),
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          const SizedBox(height: 40),
                          Expanded(
                            child: ListView(
                              controller: scrollController,
                              physics: const BouncingScrollPhysics(),
                              padding: const EdgeInsets.fromLTRB(
                                16,
                                0,
                                16,
                                20,
                              ),
                              children: [
                                Row(
                                  mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.directions_car,
                                          color: widget.color,
                                          size: 22,
                                        ),
                                        const SizedBox(width: 3),
                                        Text(
                                          widget.name,
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                            color: textColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.speed,
                                          color: accentColor,
                                          size: 18,
                                        ),
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
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    _buildOdometerDigit(context, "0"),
                                    _buildOdometerDigit(context, "2"),
                                    _buildOdometerDigit(context, "6"),
                                    _buildOdometerDigit(context, "9"),
                                    _buildOdometerDigit(context, "3"),
                                    _buildOdometerDigit(context, "1"),
                                    _buildOdometerDigit(context, "1"),
                                    _buildOdometerDigit(context, "1"),
                                    const Spacer(),
                                    _miniIconBadge(
                                      Icons.severe_cold,
                                      Colors.pink,
                                    ),
                                    _miniIconBadge(
                                      Icons.satellite_alt,
                                      Colors.green,
                                    ),
                                    _miniIconBadge(
                                      Icons.power_settings_new,
                                      Colors.green,
                                    ),
                                    _miniIconBadge(
                                      Icons.vpn_key,
                                      Colors.green,
                                    ),
                                    _miniIconBadge(
                                      Icons.battery_charging_full,
                                      Colors.green,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                Row(
                                  crossAxisAlignment:
                                  CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding:
                                      const EdgeInsets.only(top: 2),
                                      child: Icon(
                                        Icons.location_on,
                                        color: accentColor,
                                        size: 16,
                                      ),
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
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: context.containerColor,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: context.appTokens
                                          .containerBorderColor ??
                                          mutedColor
                                              .withValues(alpha: 0.25),
                                    ),
                                  ),
                                  child: ListView(
                                    scrollDirection: Axis.horizontal,
                                    physics: const BouncingScrollPhysics(),
                                    padding: const EdgeInsets.symmetric(horizontal: 10),
                                    children: [
                                      _buildScrollableGridItem(
                                        context,
                                        Icons.battery_std,
                                        "0%",
                                        "Dev Battery",
                                      ),
                                      _buildScrollableGridItem(
                                        context,
                                        Icons.schedule,
                                        "00:00",
                                        "Hours",
                                      ),
                                      _buildScrollableGridItem(
                                        context,
                                        Icons.battery_saver,
                                        "0 V",
                                        "Car Battery",
                                      ),
                                      _buildScrollableGridItem(
                                        context,
                                        Icons.satellite_alt,
                                        "0",
                                        "Satellite",
                                      ),
                                      _buildScrollableGridItem(
                                        context,
                                        Icons.local_gas_station,
                                        "N/A",
                                        "Fuel",
                                      ),
                                      _buildScrollableGridItem(
                                        context,
                                        Icons.gps_fixed,
                                        "N/A",
                                        "Accuracy",
                                      ),
                                      _buildScrollableGridItem(
                                        context,
                                        Icons.thermostat,
                                        "N/A",
                                        "Temp",
                                      ),
                                      _buildScrollableGridItem(
                                        context,
                                        Icons.route,
                                        "false",
                                        "Movement",
                                      ),
                                      _buildScrollableGridItem(
                                        context,
                                        Icons.directions_car,
                                        "N/A",
                                        "Movement",
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 14),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 10,
                                    horizontal: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: context.containerColor,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: context.appTokens
                                          .containerBorderColor ??
                                          mutedColor
                                              .withValues(alpha: 0.25),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          children: [
                                            Text(
                                              widget.livetime,
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: accentColor,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              "Device Time",
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: mutedColor,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        width: 1,
                                        height: 28,
                                        color:
                                        mutedColor.withValues(alpha: 0.3),
                                      ),
                                      Expanded(
                                        child: Column(
                                          children: [
                                            Text(
                                              widget.livetime,
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: accentColor,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              "Server Time",
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: mutedColor,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 14),
                                SizedBox(
                                  height: 150,
                                  child: PageView(
                                    physics: const BouncingScrollPhysics(),
                                    children: [
                                      _buildRunningStopCard(textColor, mutedColor),
                                      _buildFuelCard(textColor, mutedColor),
                                    ],
                                  ),
                                ),
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
                      child: Opacity(
                        opacity: (1.0 - (_sheetProgress * 2.5)).clamp(
                          0.0,
                          1.0,
                        ),
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
                                  border: context.appTokens
                                      .containerBorderColor ==
                                      null
                                      ? null
                                      : Border.all(
                                    color: context.appTokens
                                        .containerBorderColor!,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.08),
                                      blurRadius: 14,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(
                                height: 130,
                                width: 130,
                                child: CustomPaint(
                                  painter: FullCircularSpeedoPainter(
                                    speedValue: currentSpeed,
                                    scaleTextColor: textColor,
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
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: textColor,
                                        height: 1.0,
                                      ),
                                    ),
                                    Text(
                                      "kmph",
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: mutedColor,
                                      ),
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
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10),
          ],
        ),
        child: BottomNavigationBar(
          backgroundColor: context.containerColor,
          currentIndex: _currentBottomIndex,
          onTap: (index) => setState(() => _currentBottomIndex = index),
          selectedItemColor: accentColor,
          unselectedItemColor: mutedColor,
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.my_location),
              label: "Track",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.history_toggle_off),
              label: "History",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.notifications_none),
              label: "Alerts",
            ),
          ],
        ),
      ),
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

  Widget _buildOdometerDigit(BuildContext context, String digit) {
    return Container(
      margin: const EdgeInsets.only(right: 3),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: context.containerColor,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: context.appTokens.containerBorderColor ??
              context.mutedTextColor.withValues(alpha: 0.35),
        ),
      ),
      child: Text(
        digit,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: context.textColor,
        ),
      ),
    );
  }

  Widget _miniIconBadge(IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(left: 4),
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Icon(icon, color: color, size: 13),
    );
  }

  Widget _buildScrollableGridItem(
      BuildContext context,
      IconData icon,
      String value,
      String label,
      ) {
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
            label,
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

  Widget _buildSummaryRow(
      BuildContext context,
      Color color,
      String stateLabel,
      String durationValue,
      ) {
    return Row(
      children: [
        Container(
          height: 18,
          width: 18,
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 2),
          ),
          padding: const EdgeInsets.all(3),
          child: Container(
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 70,
          child: Text(
            stateLabel,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.normal,
              color: context.mutedTextColor,
            ),
          ),
        ),
        Text(
          durationValue,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: context.mutedTextColor,
          ),
        ),
      ],
    );
  }

  Widget _buildRunningStopCard(Color textColor, Color mutedColor) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: 16,
        horizontal: 16,
      ),
      decoration: BoxDecoration(
        color: context.containerColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: context.appTokens.containerBorderColor ??
              mutedColor.withValues(alpha: 0.25),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Left side: Distance & Location Pin (shifted closer with fixed width)
          SizedBox(
            width: 70,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.location_on,
                  color: Color(0xfff53d6b),
                  size: 36,
                ),
                const SizedBox(height: 8),
                Text(
                  widget.distance.isNotEmpty ? widget.distance : "0 km",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          // Separator line (reduced margins)
          Container(
            width: 1,
            height: 110,
            color: Colors.black.withOpacity(0.06),
            margin: const EdgeInsets.symmetric(horizontal: 12),
          ),
          // Right side: Status Summaries - takes all remaining space
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildSummaryRow(
                  context,
                  const Color(0xff55b985), // Green
                  "Running :",
                  "00:00:00 Hrs",
                ),
                const SizedBox(height: 10),
                _buildSummaryRow(
                  context,
                  const Color(0xfff53d6b), // Red/Pink
                  "Stop :",
                  "00:00:00 Hrs",
                ),
                const SizedBox(height: 10),
                _buildSummaryRow(
                  context,
                  const Color(0xffe2ab2f), // Orange/Yellow
                  "Idle :",
                  "00:00:00 Hrs",
                ),
                const SizedBox(height: 10),
                _buildSummaryRow(
                  context,
                  const Color(0xff2aa1ca), // Light Blue
                  "Inactive :",
                  "00:00:00 Hrs",
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFuelCard(Color textColor, Color mutedColor) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: 16,
        horizontal: 16,
      ),
      decoration: BoxDecoration(
        color: context.containerColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: context.appTokens.containerBorderColor ??
              mutedColor.withValues(alpha: 0.25),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Left side: Animated Car & Fuel Pump (width set to 80 to fit layout)
          const SizedBox(
            width: 80,
            child: Center(
              child: RefuelingAnimationWidget(),
            ),
          ),
          // Separator line
          Container(
            width: 1,
            height: 110,
            color: Colors.black.withOpacity(0.06),
            margin: const EdgeInsets.symmetric(horizontal: 12),
          ),
          // Right side: Fuel stats
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildFuelRow(
                  context,
                  Icons.speed,
                  Colors.teal,
                  "Fuel Mileage :",
                  "10 km/ltr",
                ),
                const SizedBox(height: 10),
                _buildFuelRow(
                  context,
                  Icons.local_gas_station_rounded,
                  Colors.orange.shade600,
                  "Fuel Consumption :",
                  "0.00 ltr",
                ),
                const SizedBox(height: 10),
                _buildFuelRow(
                  context,
                  Icons.payments_rounded,
                  Colors.green.shade600,
                  "Fuel Cost :",
                  "0.00 INR",
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFuelRow(
      BuildContext context,
      IconData icon,
      Color iconColor,
      String label,
      String value,
      ) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 18),
        const SizedBox(width: 8),
        SizedBox(
          width: 95,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.normal,
              color: context.mutedTextColor,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: context.textColor,
          ),
        ),
      ],
    );
  }
}

class RefuelingAnimationWidget extends StatefulWidget {
  const RefuelingAnimationWidget({super.key});

  @override
  State<RefuelingAnimationWidget> createState() => _RefuelingAnimationWidgetState();
}

class _RefuelingAnimationWidgetState extends State<RefuelingAnimationWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: const Size(80, 55),
          painter: RefuelingPainter(animationValue: _controller.value),
        );
      },
    );
  }
}

class RefuelingPainter extends CustomPainter {
  final double animationValue;

  RefuelingPainter({required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    // Exact colors and cartoonish lineart style matching the reference screenshot
    final outlinePaint = Paint()
      ..color = const Color(0xff4a3f35) // dark lineart outline
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;

    final carPaint = Paint()
      ..color = const Color(0xfff2b343) // yellow/orange car fill
      ..style = PaintingStyle.fill;

    final pumpPaint = Paint()
      ..color = const Color(0xff408ce8) // blue charger pump fill
      ..style = PaintingStyle.fill;

    final greenPaint = Paint()
      ..color = const Color(0xff48c538) // green lightning/plugs fill
      ..style = PaintingStyle.fill;

    final whitePaint = Paint()
      ..color = Colors.white;

    // --- DRAW CHARGING PUMP (Right Side) ---
    // Pump base
    final pumpBase = RRect.fromRectAndRadius(
      const Rect.fromLTRB(72, 48, 100, 51),
      const Radius.circular(1.5),
    );
    canvas.drawRRect(pumpBase, pumpPaint);
    canvas.drawRRect(pumpBase, outlinePaint);

    // Pump body
    final pumpBody = RRect.fromRectAndCorners(
      const Rect.fromLTRB(76, 8, 96, 48),
      topLeft: const Radius.circular(6),
      topRight: const Radius.circular(6),
      bottomLeft: const Radius.circular(2),
      bottomRight: const Radius.circular(2),
    );
    canvas.drawRRect(pumpBody, pumpPaint);
    canvas.drawRRect(pumpBody, outlinePaint);

    // Lightning Bolt symbol on Pump
    final boltPath = Path();
    boltPath.moveTo(89, 16);
    boltPath.moveTo(w * 0.89, h * 0.30);
    boltPath.lineTo(w * 0.81, h * 0.55);
    boltPath.lineTo(w * 0.87, h * 0.55);
    boltPath.lineTo(w * 0.84, h * 0.75);
    boltPath.lineTo(w * 0.93, h * 0.48);
    boltPath.lineTo(w * 0.87, h * 0.48);
    boltPath.close();

    // Pulse the bolt color intensity
    final double boltPulse = 0.5 + 0.5 * math.sin(animationValue * math.pi * 2);
    final boltFillPaint = Paint()
      ..color = Color.lerp(const Color(0xff48c538), Colors.greenAccent, boltPulse)!
      ..style = PaintingStyle.fill;
    canvas.drawPath(boltPath, boltFillPaint);
    canvas.drawPath(boltPath, outlinePaint);

    // --- DRAW CAR (Left Side) ---
    // Tires (drawn first, under the car body)
    final tirePaint = Paint()..color = const Color(0xff4a3f35);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(w * 0.13, h * 0.82, w * 0.18, h * 0.92),
        const Radius.circular(2),
      ),
      tirePaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(w * 0.42, h * 0.82, w * 0.47, h * 0.92),
        const Radius.circular(2),
      ),
      tirePaint,
    );

    // Side mirrors
    final leftMirror = RRect.fromRectAndRadius(
      Rect.fromLTRB(w * 0.08, h * 0.54, w * 0.11, h * 0.60),
      const Radius.circular(1),
    );
    canvas.drawRRect(leftMirror, carPaint);
    canvas.drawRRect(leftMirror, outlinePaint);

    final rightMirror = RRect.fromRectAndRadius(
      Rect.fromLTRB(w * 0.49, h * 0.54, w * 0.52, h * 0.60),
      const Radius.circular(1),
    );
    canvas.drawRRect(rightMirror, carPaint);
    canvas.drawRRect(rightMirror, outlinePaint);

    // Cabin/Roof
    final cabinPath = Path();
    cabinPath.moveTo(w * 0.18, h * 0.54);
    cabinPath.quadraticBezierTo(w * 0.20, h * 0.30, w * 0.30, h * 0.30);
    cabinPath.quadraticBezierTo(w * 0.40, h * 0.30, w * 0.42, h * 0.54);
    cabinPath.close();
    canvas.drawPath(cabinPath, carPaint);
    canvas.drawPath(cabinPath, outlinePaint);

    // Windshield (transparent/white fill)
    final windshieldPath = Path();
    windshieldPath.moveTo(w * 0.21, h * 0.52);
    windshieldPath.quadraticBezierTo(w * 0.22, h * 0.35, w * 0.30, h * 0.35);
    windshieldPath.quadraticBezierTo(w * 0.38, h * 0.35, w * 0.39, h * 0.52);
    windshieldPath.close();
    canvas.drawPath(windshieldPath, whitePaint);
    canvas.drawPath(windshieldPath, outlinePaint);

    // Main Car Body (Lower part)
    final bodyRect = RRect.fromRectAndRadius(
      Rect.fromLTRB(w * 0.10, h * 0.50, w * 0.50, h * 0.85),
      const Radius.circular(8),
    );
    canvas.drawRRect(bodyRect, carPaint);
    canvas.drawRRect(bodyRect, outlinePaint);

    // Headlights (white outlines)
    final leftHeadlight = RRect.fromRectAndRadius(
      Rect.fromLTRB(w * 0.14, h * 0.61, w * 0.22, h * 0.67),
      const Radius.circular(1.5),
    );
    canvas.drawRRect(leftHeadlight, whitePaint);
    canvas.drawRRect(leftHeadlight, outlinePaint);

    final rightHeadlight = RRect.fromRectAndRadius(
      Rect.fromLTRB(w * 0.38, h * 0.61, w * 0.46, h * 0.67),
      const Radius.circular(1.5),
    );
    canvas.drawRRect(rightHeadlight, whitePaint);
    canvas.drawRRect(rightHeadlight, outlinePaint);

    // Lower Grille outline
    final grille = RRect.fromRectAndRadius(
      Rect.fromLTRB(w * 0.20, h * 0.72, w * 0.40, h * 0.78),
      const Radius.circular(1.5),
    );
    canvas.drawRRect(grille, whitePaint);
    canvas.drawRRect(grille, outlinePaint);

    // --- DRAW CONNECTING CABLE & NOZZLES ---
    final cablePath = Path();
    cablePath.moveTo(w * 0.74, h * 0.47);
    // Draw the U-shaped loop down and then up to connect to car body
    cablePath.cubicTo(
      w * 0.64, h * 0.47,
      w * 0.58, h * 0.95,
      w * 0.50, h * 0.72,
    );

    final cablePaint = Paint()
      ..color = const Color(0xff4a3f35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawPath(cablePath, cablePaint);

    // Green nozzle plug connected to the pump
    final pumpNozzle = RRect.fromRectAndRadius(
      Rect.fromLTRB(w * 0.72, h * 0.42, w * 0.76, h * 0.52),
      const Radius.circular(1.5),
    );
    canvas.drawRRect(pumpNozzle, greenPaint);
    canvas.drawRRect(pumpNozzle, outlinePaint);

    // Green adapter block in the middle of the loop
    final pathMetrics = cablePath.computeMetrics();
    for (final metric in pathMetrics) {
      final double totalLength = metric.length;
      final tangent = metric.getTangentForOffset(totalLength * 0.45);
      if (tangent != null) {
        canvas.save();
        canvas.translate(tangent.position.dx, tangent.position.dy);
        canvas.rotate(-tangent.angle);
        final adapterRect = RRect.fromRectAndRadius(
          const Rect.fromLTRB(-5, -2.5, 5, 2.5),
          const Radius.circular(1.5),
        );
        canvas.drawRRect(adapterRect, greenPaint);
        canvas.drawRRect(adapterRect, outlinePaint);
        canvas.restore();
      }

      // Energy Sparks/Flow particles animation moving along the cable
      for (int i = 0; i < 3; i++) {
        final double dotProgress = (animationValue + i / 3.0) % 1.0;
        final double distance = totalLength * (1.0 - dotProgress);
        final dotTangent = metric.getTangentForOffset(distance);
        if (dotTangent != null) {
          final dotPaint = Paint()
            ..color = const Color(0xff48c538)
            ..style = PaintingStyle.fill
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.2);
          canvas.drawCircle(dotTangent.position, 2.5, dotPaint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant RefuelingPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}

class FullCircularSpeedoPainter extends CustomPainter {
  final double speedValue;
  final Color scaleTextColor;

  FullCircularSpeedoPainter({
    required this.speedValue,
    this.scaleTextColor = Colors.black87,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final rect = Rect.fromLTWH(2, 2, size.width - 4, size.height - 4);

    final circlePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..shader = const SweepGradient(
        colors: [
          Colors.green,
          Colors.yellow,
          Colors.orange,
          Colors.red,
          Colors.green,
        ],
      ).createShader(rect);

    canvas.drawCircle(center, radius - 2, circlePaint);

    const double startAngle = math.pi * 0.75;
    const double maxSweepAngle = math.pi * 1.5;
    final List<String> scale = [
      "0",
      "_",
      "50",
      "_",
      "100",
      "_",
      "150",
      "_",
      "200",
    ];

    for (int i = 0; i < scale.length; i++) {
      final angle = startAngle + (i * maxSweepAngle / (scale.length - 1));
      final tickPaint = Paint()
        ..color = scale[i] == "_"
            ? scaleTextColor.withValues(alpha: 0.35)
            : scaleTextColor
        ..strokeWidth = scale[i] == "_" ? 1.5 : 2;

      final tickStart = Offset(
        center.dx + (radius - 5) * math.cos(angle),
        center.dy + (radius - 5) * math.sin(angle),
      );
      final tickEnd = Offset(
        center.dx + (radius - 15) * math.cos(angle),
        center.dy + (radius - 15) * math.sin(angle),
      );
      canvas.drawLine(tickStart, tickEnd, tickPaint);

      if (scale[i] != "_") {
        _drawScaleText(canvas, center, scale[i], angle, radius - 28);
      }
    }

    final speedRatio = (speedValue / 200).clamp(0.0, 1.0);
    final needleAngle = startAngle + (speedRatio * maxSweepAngle);
    final needleLength = radius - 18;
    const double needleWidth = 5;

    final leftBase = Offset(
      center.dx + needleWidth * math.cos(needleAngle - math.pi / 2),
      center.dy + needleWidth * math.sin(needleAngle - math.pi / 2),
    );
    final rightBase = Offset(
      center.dx + needleWidth * math.cos(needleAngle + math.pi / 2),
      center.dy + needleWidth * math.sin(needleAngle + math.pi / 2),
    );
    final tip = Offset(
      center.dx + needleLength * math.cos(needleAngle),
      center.dy + needleLength * math.sin(needleAngle),
    );

    final needlePath = Path();
    needlePath.moveTo(leftBase.dx, leftBase.dy);
    needlePath.lineTo(tip.dx, tip.dy);
    needlePath.lineTo(rightBase.dx, rightBase.dy);
    needlePath.close();

    final needlePaint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.fill;
    canvas.drawPath(needlePath, needlePaint);
    canvas.drawCircle(center, 7, Paint()..color = Colors.black87);
    canvas.drawCircle(center, 4, Paint()..color = Colors.red);
  }

  void _drawScaleText(
      Canvas canvas,
      Offset center,
      String text,
      double angle,
      double distance,
      ) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: scaleTextColor,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final offset = Offset(
      center.dx + distance * math.cos(angle) - textPainter.width / 2,
      center.dy + distance * math.sin(angle) - textPainter.height / 2,
    );
    textPainter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant FullCircularSpeedoPainter oldDelegate) =>
      oldDelegate.speedValue != speedValue ||
          oldDelegate.scaleTextColor != scaleTextColor;
}
