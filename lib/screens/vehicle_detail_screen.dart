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
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                        horizontal: 6,
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
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceAround,
                                        children: [
                                          _buildGridItem(
                                            context,
                                            Icons.battery_alert,
                                            "0 V",
                                            "Car Battery",
                                          ),
                                          _buildGridItem(
                                            context,
                                            Icons.satellite_alt_sharp,
                                            "15",
                                            "Satellite",
                                          ),
                                          _buildGridItem(
                                            context,
                                            Icons.local_gas_station,
                                            "N/A",
                                            "Fuel",
                                          ),
                                          _buildGridItem(
                                            context,
                                            Icons.grain,
                                            "0.0",
                                            "Accuracy",
                                          ),
                                          _buildGridItem(
                                            context,
                                            Icons.device_thermostat,
                                            "N/A",
                                            "Temp",
                                          ),
                                          _buildGridItem(
                                            context,
                                            Icons.alt_route,
                                            "true",
                                            "Movement",
                                          ),
                                          _buildGridItem(
                                            context,
                                            Icons.sensor_door,
                                            "N/A",
                                            "Door",
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
                                    Container(
                                      padding: const EdgeInsets.all(14),
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
                                      child: Column(
                                        children: [
                                          _buildStateSummaryRow(
                                            context,
                                            Colors.green,
                                            "Running :",
                                            "01:12 Hrs",
                                          ),
                                          const Divider(
                                            height: 16,
                                            thickness: 0.5,
                                          ),
                                          _buildStateSummaryRow(
                                            context,
                                            Colors.red,
                                            "Stop :",
                                            "00:04 Hrs",
                                          ),
                                          const Divider(
                                            height: 16,
                                            thickness: 0.5,
                                          ),
                                          _buildStateSummaryRow(
                                            context,
                                            Colors.orange,
                                            "Idle :",
                                            "00:20 Hrs",
                                          ),
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

  Widget _buildGridItem(BuildContext context, IconData icon, String value, String label) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: context.mutedTextColor, size: 18),
          const SizedBox(height: 5),
          Text(
            value,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: context.textColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 8,
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

  Widget _buildStateSummaryRow(
    BuildContext context,
    Color color,
    String stateLabel,
    String durationValue,
  ) {
    return Row(
      children: [
        Container(
          height: 12,
          width: 12,
          decoration: BoxDecoration(
            color: color.withOpacity(0.18),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Container(
              height: 6,
              width: 6,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          stateLabel,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: context.textColor,
          ),
        ),
        const Spacer(),
        Text(
          durationValue,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: context.textColor,
          ),
        ),
      ],
    );
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
