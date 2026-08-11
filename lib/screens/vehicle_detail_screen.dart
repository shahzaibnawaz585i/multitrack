import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:async';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../theme/app_theme_tokens.dart';
import '../theme/hacking_map_style.dart';
import 'notifications_screen.dart'; 
import 'notification_filter_screen.dart';

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
  int _currentBottomIndex = 0; 
  double _sheetProgress = 0.0;
  double _historySliderValue = 0.0;
  bool _isHistoryPlaying = false;
  String _selectedStatFilter = "Today";
  
  double? _historyPanelTop;

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
        if (_currentBottomIndex == 0) {
          _mapController?.animateCamera(CameraUpdate.newLatLng(_carLocation));
        }
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color accentColor = Theme.of(context).colorScheme.primary;
    final Color mutedColor = context.mutedTextColor;
    final double screenHeight = MediaQuery.of(context).size.height;

    final double maxTopLimit = 120.0;
    final double bottomLimit = screenHeight * 0.8;
    _historyPanelTop ??= screenHeight * 0.65;

    return Scaffold(
      body: IndexedStack(
        index: _currentBottomIndex,
        children: [
          _buildTrackView(), 
          _buildHistoryView(maxTopLimit, bottomLimit, screenHeight, accentColor), 
          const NotificationsScreen(showAlertsOnly: true),
          _buildStatisticsView(accentColor), 
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10)],
        ),
        child: BottomNavigationBar(
          backgroundColor: context.containerColor,
          currentIndex: _currentBottomIndex,
          onTap: (index) => setState(() => _currentBottomIndex = index),
          selectedItemColor: accentColor,
          unselectedItemColor: mutedColor,
          type: BottomNavigationBarType.fixed,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
          unselectedLabelStyle: const TextStyle(fontSize: 11),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.location_on), label: "Track"),
            BottomNavigationBarItem(icon: Icon(Icons.history), label: "History"),
            BottomNavigationBarItem(icon: Icon(Icons.notifications), label: "Alerts"),
            BottomNavigationBarItem(icon: Icon(Icons.analytics), label: "Statistics"),
          ],
        ),
      ),
    );
  }

  /// --- STATISTICS VIEW ---
  Widget _buildStatisticsView(Color accentColor) {
    final Color textColor = context.textColor;
    return Scaffold(
      backgroundColor: context.isHackingTheme ? Colors.black : const Color(0xFFF9F9F9),
      appBar: AppBar(
        backgroundColor: context.containerColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: accentColor, size: 20),
          onPressed: () => setState(() => _currentBottomIndex = 0),
        ),
        title: Text(
          "${widget.name} Statistics",
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 12),
            _buildStatFiltersGrid(accentColor),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.6, 
                children: [
                  _buildStatCard("Route length", "0.0 km", "assets/route_length.png"),
                  _buildStatCard("Move duration", "00:00:00", "assets/move_duration.png"),
                  _buildStatCard("Stop duration", "00:00:00", "assets/stop_duration.png"),
                  _buildStatCard("Idle duration", "00:00:00", "assets/engine_work.png"),
                  _buildStatCard("Top speed", "0.00 kmph", "assets/top-speed.png"),
                  _buildStatCard("Average speed", "0.00 kmph", "assets/top-speed.png"),
                  _buildStatCard("Overspeed count", "0", "assets/over_speed.png"),
                  _buildStatCard("Stop count", "0", "assets/stop_count.png"),
                  _buildStatCard("Avg.fuel cons.", "0.00 km/Ltr", "assets/fuel_consum.png"),
                  _buildStatCard("Fuel cost", "INR 0.00", "assets/fuel_cost.png"),
                  _buildStatCard("Engine work", "INR 0.00", "assets/engine_work.png"),
                  _buildStatCard("Fuel consumption", "0.0 Liter", "assets/fuel_consum.png"),
                  _buildStatCard("Odometer", "28152.79 km", "assets/odometer.png"),
                  _buildStatCard("Engine hours", "00:00:00", "assets/engine_work.png"),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
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
                filter,
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
                  title,
                  style: TextStyle(
                    color: context.mutedTextColor, 
                    fontSize: 15.0, 
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Image.asset(imagePath, height: 26, width: 26, errorBuilder: (c, e, s) => Icon(Icons.bar_chart, color: Theme.of(context).colorScheme.primary, size: 24)),
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

        NotificationListener<DraggableScrollableNotification>(
          onNotification: (notification) {
            final double delta = notification.maxExtent - notification.minExtent;
            if (mounted) {
              setState(() {
                if (delta > 0) {
                  _sheetProgress = ((notification.extent - notification.minExtent) / delta).clamp(0.0, 1.0);
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
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.directions_car, color: widget.color, size: 22),
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
                    child: Opacity(
                      opacity: (1.0 - (_sheetProgress * 2.5)).clamp(0.0, 1.0),
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
                                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textColor, height: 1.0),
                                  ),
                                  Text(
                                    "kmph",
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
          onPressed: () => setState(() => _currentBottomIndex = 0),
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
                  Text("Today", style: TextStyle(color: Colors.grey.shade700, fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(width: 4),
                  Icon(Icons.keyboard_arrow_down, color: accentColor, size: 20),
                ],
              ),
            ),
            itemBuilder: (context) => [
              const PopupMenuItem(value: "1h", height: 60, child: Center(child: Text("1 Hour", style: TextStyle(fontSize: 12)))),
              const PopupMenuItem(value: "today", height: 60, child: Center(child: Text("Today", style: TextStyle(fontSize: 12)))),
              const PopupMenuItem(value: "yesterday", height: 60, child: Center(child: Text("Yesterday", style: TextStyle(fontSize: 12)))),
              const PopupMenuItem(value: "week", height: 60, child: Center(child: Text("Week", style: TextStyle(fontSize: 12)))),
              const PopupMenuItem(value: "custom", height: 60, child: Center(child: Text("Custom", style: TextStyle(fontSize: 12)))),
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
          Positioned.fill(child: GoogleMap(initialCameraPosition: const CameraPosition(target: LatLng(31.5204, 74.3587), zoom: 14.0), style: context.isHackingTheme ? hackingMapStyle : null, zoomControlsEnabled: false, myLocationEnabled: false)),
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
          Positioned(
            top: _historyPanelTop, left: 0, right: 0,
            child: GestureDetector(
              onVerticalDragUpdate: (details) => setState(() => _historyPanelTop = (_historyPanelTop! + details.delta.dy).clamp(maxTop, bottomLimit)),
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
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [_historyDateLabel("From :", widget.date.isNotEmpty ? widget.date : "29 Jul 2026", accentColor), Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: accentColor, borderRadius: BorderRadius.circular(15)), child: Text(widget.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11))), _historyDateLabel("To :", widget.date.isNotEmpty ? widget.date : "29 Jul 2026", accentColor)]),
                      const SizedBox(height: 14), Divider(height: 1, thickness: 0.8, color: context.mutedTextColor.withOpacity(0.3)), const SizedBox(height: 14),
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [_historyStatItem(Icons.speed, "${widget.speed} kmph", accentColor), _historyStatItem(Icons.access_time_filled_outlined, "01:20 Hrs", accentColor), _historyStatItem(Icons.route_outlined, "${widget.distance} km", accentColor)]),
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
  Widget _historyDateLabel(String label, String date, Color color) {
    return Column(
      crossAxisAlignment: label == "From :" ? CrossAxisAlignment.start : CrossAxisAlignment.end,
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
                  "Device Time",
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
                  "Server Time",
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
        SizedBox(width: 70, child: Text(stateLabel, style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal, color: context.mutedTextColor))),
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
        SizedBox(width: 95, child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.normal, color: context.mutedTextColor))),
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
                  label,
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
                _buildActionButton(Icons.location_on, Colors.redAccent, "Share\nLocation"),
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

  Widget _buildActionButton(IconData icon, Color color, String label, {bool hasBg = false}) {
    return SizedBox(
      width: 80,
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
            label,
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
