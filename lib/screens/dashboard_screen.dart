import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:multitrack/screens/report_screens/main_screen.dart';

import '../../theme/app_theme_tokens.dart';
import 'lists_screen.dart';
import 'map_screen.dart';
 import 'settings_screen/setting_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  static const int _dashboardIndex = 0;
  static const int _mapIndex = 1;
  static const int _listIndex = 2;
  static const int _reportIndex = 3;
  static const int _settingsIndex = 4;

  int _selectedIndex = _listIndex;

  String _vehicleFilter = 'all';

  final PageStorageBucket _pageStorageBucket = PageStorageBucket();

  void _onNavigationTap(int index) {
    if (_selectedIndex == index) {
      return;
    }

    setState(() {
      _selectedIndex = index;

      // Bottom navigation se List open ho to All Vehicles show hon.
      if (index == _listIndex) {
        _vehicleFilter = 'all';
      }
    });
  }

  void _openVehicleList(String filter) {
    final String normalizedFilter = filter.trim().toLowerCase();

    setState(() {
      _vehicleFilter = normalizedFilter;
      _selectedIndex = _listIndex;
    });
  }

  Widget _buildCurrentScreen() {
    switch (_selectedIndex) {
      case _dashboardIndex:
        return MainDashboardContent(
          key: const PageStorageKey<String>('dashboard_screen'),
          onStatusTap: _openVehicleList,
        );

      case _mapIndex:
      // Map sirf Map tab selected hone par widget tree mein hogi.
      // Tab change hone par MapScreen dispose ho sakti hai.
        return const MapScreen(
          key: ValueKey<String>('map_screen'),
        );

      case _listIndex:
        return ListScreen(
          key: const PageStorageKey<String>('vehicle_list_screen'),
          initialFilter: _vehicleFilter,
        );

      case _reportIndex:
        return   MainScreen(
          key: PageStorageKey<String>('report_screen'),
        );

      case _settingsIndex:
        return const SettingScreen(
          key: PageStorageKey<String>('settings_screen'),
        );

      default:
        return ListScreen(
          initialFilter: _vehicleFilter,
        );
    }
  }

  Widget _buildNavigationItem({
    required IconData icon,
    required int index,
  }) {
    final bool isSelected = _selectedIndex == index;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isSelected
            ? (Theme.of(context).brightness == Brightness.dark
                ? Colors.white.withValues(alpha: 0.14)
                : Colors.black)
            : Colors.transparent,
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        size: 26,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: PageStorage(
        bucket: _pageStorageBucket,
        child: _buildCurrentScreen(),
      ),
      bottomNavigationBar: CurvedNavigationBar(
        index: _selectedIndex,
        height: 65,
        backgroundColor: Colors.transparent,
        color: theme.cardColor,
        buttonBackgroundColor: theme.cardColor,

        // Curved selected button slow aur smoothly move karega.
        animationDuration: const Duration(milliseconds: 1000),
        animationCurve: Curves.easeInOutCubic,

        items: <Widget>[
          _buildNavigationItem(
            icon: Icons.dashboard,
            index: _dashboardIndex,
          ),
          _buildNavigationItem(
            icon: Icons.location_on_rounded,
            index: _mapIndex,
          ),
          _buildNavigationItem(
            icon: Icons.local_shipping,
            index: _listIndex,
          ),
          _buildNavigationItem(
            icon: Icons.person,
            index: _reportIndex,
          ),
          _buildNavigationItem(
            icon: Icons.settings,
            index: _settingsIndex,
          ),
        ],

        // Screen yahan foran change hogi.
        onTap: _onNavigationTap,
      ),    );
  }
}

class MainDashboardContent extends StatelessWidget {
  final ValueChanged<String> onStatusTap;

  const MainDashboardContent({
    super.key,
    required this.onStatusTap,
  });

  static const Color _primaryColor = Color(0xFFF43A6B);

  static const List<String> _chartDates = <String>[
    '21/6',
    '22/6',
    '23/6',
    '24/6',
    '25/6',
    '26/6',
    '27/6',
    '28/6',
  ];

  static const List<FlSpot> _engineHourSpots = <FlSpot>[
    FlSpot(0, 2),
    FlSpot(1, 2.5),
    FlSpot(2, 3),
    FlSpot(3, 0.5),
    FlSpot(4, 5),
    FlSpot(5, 1),
    FlSpot(6, 0.5),
    FlSpot(7, 1.5),
  ];

  @override
  Widget build(BuildContext context) {
    final Color textColor = Theme.of(context).colorScheme.onSurface;
    final Color mutedColor = textColor.withValues(alpha: 0.6);
    final Color accentColor = Theme.of(context).colorScheme.primary;

    return SafeArea(
      child: SingleChildScrollView(
        key: const PageStorageKey<String>('dashboard_scroll'),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),

            _buildHeader(accentColor),

            const SizedBox(height: 10),

            _buildDashboardTitle(textColor, accentColor),

            const SizedBox(height: 20),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Fleet Status',
                style: TextStyle(
                  fontSize: 16,
                  fontFamily: 'NormalBold',
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
            ),

            _buildFleetStatusCard(context, mutedColor),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Engine Hours',
                style: TextStyle(
                  fontFamily: 'NormalBold',
                  fontSize: 16,
                  color: textColor,
                ),
              ),
            ),

            _buildEngineHoursChart(context),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(Color accentColor) {
    return Padding(
      padding: const EdgeInsets.all(9),
      child: Row(
        children: [
          Image.asset(
            'assets/loginicon.png',
            height: 40,
            width: 40,
            errorBuilder: (
                BuildContext context,
                Object error,
                StackTrace? stackTrace,
                ) {
              return const SizedBox(
                height: 40,
                width: 40,
                child: Icon(Icons.apps),
              );
            },
          ),
          const SizedBox(width: 8),
          Text(
            'multiTrack',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: 'NormalBold',
              color: accentColor,
            ),
          ),
          const Spacer(),
          Image.asset(
            'assets/penicons.png',
            height: 50,
            width: 50,
            errorBuilder: (
                BuildContext context,
                Object error,
                StackTrace? stackTrace,
                ) {
              return const SizedBox(
                height: 50,
                width: 50,
                child: Icon(Icons.edit),
              );
            },
          ),
          const SizedBox(width: 8),
          const Icon(
            Icons.refresh_outlined,
            size: 27,
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardTitle(Color textColor, Color accentColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Text(
            'Dashboard',
            style: TextStyle(
              fontSize: 20,
              fontFamily: 'NormalBold',
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              border: Border.all(color: textColor.withValues(alpha: 0.5)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'RJ14UG839',
                  style: TextStyle(fontSize: 13, color: textColor),
                ),
                Icon(
                  Icons.arrow_drop_down,
                  color: accentColor,
                  size: 18,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFleetStatusCard(BuildContext context, Color mutedColor) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(10),
        decoration: context.containerDecoration(
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 160,
              width: 130,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  RepaintBoundary(
                    child: PieChart(
                      PieChartData(
                        startDegreeOffset: -90,
                        sectionsSpace: 1,
                        centerSpaceRadius: 38,
                        pieTouchData: PieTouchData(
                          enabled: true,
                          touchCallback: (
                              FlTouchEvent event,
                              PieTouchResponse? response,
                              ) {
                            if (!event.isInterestedForInteractions) {
                              return;
                            }

                            final PieTouchedSection? touchedSection =
                                response?.touchedSection;

                            if (touchedSection == null) {
                              return;
                            }

                            final int sectionIndex =
                                touchedSection.touchedSectionIndex;

                            _handlePieSectionTap(sectionIndex);
                          },
                        ),
                        sections: _buildPieSections(),
                      ),
                    ),
                  ),

                  IgnorePointer(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '124',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                            fontFamily: 'NormalBold',
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          'Objects',
                          style: TextStyle(
                            color: mutedColor,
                            fontSize: 13,
                            fontFamily: 'NormalBold',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 30),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  StatusRow(
                    title: 'Running',
                    value: 10,
                    color: Colors.green,
                    onTap: () => onStatusTap('running'),
                  ),
                  StatusRow(
                    title: 'Idle',
                    value: 8,
                    color: Colors.orange,
                    onTap: () => onStatusTap('idle'),
                  ),
                  StatusRow(
                    title: 'Stopped',
                    value: 72,
                    color: Colors.red,
                    onTap: () => onStatusTap('stopped'),
                  ),
                  StatusRow(
                    title: 'Expired',
                    value: 2,
                    color: Colors.pink,
                    onTap: () => onStatusTap('expired'),
                  ),
                  StatusRow(
                    title: 'InActive',
                    value: 34,
                    color: Colors.blue,
                    onTap: () => onStatusTap('inactive'),
                  ),
                  StatusRow(
                    title: 'No Data',
                    value: 0,
                    color: Colors.grey,
                    onTap: null,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handlePieSectionTap(int sectionIndex) {
    switch (sectionIndex) {
      case 0:
        onStatusTap('stopped');
        break;

      case 1:
        onStatusTap('inactive');
        break;

      case 2:
        onStatusTap('running');
        break;

      case 3:
        onStatusTap('idle');
        break;
    }
  }

  List<PieChartSectionData> _buildPieSections() {
    return <PieChartSectionData>[
      PieChartSectionData(
        value: 72,
        color: Colors.red,
        radius: 30,
        showTitle: false,
      ),
      PieChartSectionData(
        value: 34,
        color: Colors.blue,
        radius: 30,
        showTitle: false,
      ),
      PieChartSectionData(
        value: 10,
        color: Colors.green,
        radius: 30,
        showTitle: false,
      ),
      PieChartSectionData(
        value: 8,
        color: Colors.orange,
        radius: 30,
        showTitle: false,
      ),
    ];
  }

  Widget _buildEngineHoursChart(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        height: 220,
        width: double.infinity,
        decoration: context.containerDecoration(
          borderRadius: BorderRadius.circular(16),
        ),
        child: RepaintBoundary(
          child: LineChart(
            LineChartData(
              minX: 0,
              maxX: 7,
              minY: 0,
              borderData: FlBorderData(show: false),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: 4,
              ),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: 4,
                    reservedSize: 30,
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: _buildBottomTitle,
                  ),
                ),
                topTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              lineBarsData: [
                LineChartBarData(
                  isCurved: true,
                  color: Colors.teal,
                  barWidth: 3,
                  spots: _engineHourSpots,
                  dotData: FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      colors: [
                        Colors.green.withValues(alpha: 0.20),
                        Colors.green.withValues(alpha: 0.001),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomTitle(
      double value,
      TitleMeta meta,
      ) {
    final int index = value.toInt();

    if (value != index.toDouble() ||
        index < 0 ||
        index >= _chartDates.length) {
      return const SizedBox.shrink();
    }

    return SideTitleWidget(
      axisSide: meta.axisSide,
      child: Text(
        _chartDates[index],
        style: const TextStyle(fontSize: 10),
      ),
    );
  }
}

class StatusRow extends StatelessWidget {
  final String title;
  final int value;
  final Color color;
  final VoidCallback? onTap;

  const StatusRow({
    super.key,
    required this.title,
    required this.value,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: 4,
            horizontal: 2,
          ),
          child: Row(
            children: [
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Bold',
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),

              Text(
                value.toString(),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}