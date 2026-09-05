import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:multitrack/l10n/app_l10n.dart';
import 'package:multitrack/screens/report_screens/main_screen.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/vehicle_data.dart';
import '../models/vehicle_model.dart';
import '../services/app_bootstrap_service.dart';
import '../theme/app_theme_tokens.dart';
import 'lists_screen.dart';
import 'map_screen.dart';
import 'settings_screen/add_expense_screen.dart';
import 'settings_screen/reminders_screen.dart';
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

  late final Set<int> _loadedTabs = <int>{_selectedIndex};

  @override
  void initState() {
    super.initState();
    AppBootstrapService.refreshVehicles(forceRefresh: true);
  }

  void _onNavigationTap(int index) {
    if (_selectedIndex == index) {
      return;
    }

    setState(() {
      _selectedIndex = index;
      _loadedTabs.add(index);

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
      _loadedTabs.add(_listIndex);
    });
  }

  Widget _buildNavigationItem({
    required IconData icon,
    required int index,
  }) {
    final bool isSelected = _selectedIndex == index;

    return AnimatedContainer(
      duration: Duration.zero,
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
        child: IndexedStack(
          index: _selectedIndex,
          children: <Widget>[
            _loadedTabs.contains(_dashboardIndex)
                ? MainDashboardContent(
                    key: const PageStorageKey<String>('dashboard_screen'),
                    onStatusTap: _openVehicleList,
                  )
                : const SizedBox.shrink(),
            _loadedTabs.contains(_mapIndex)
                ? MapScreen(
                    key: const ValueKey<String>('map_screen'),
                    isVisible: _selectedIndex == _mapIndex,
                  )
                : const SizedBox.shrink(),
            ListScreen(
              key: const PageStorageKey<String>('vehicle_list_screen'),
              initialFilter: _vehicleFilter,
            ),
            _loadedTabs.contains(_reportIndex)
                ? const MainScreen(
                    key: PageStorageKey<String>('report_screen'),
                  )
                : const SizedBox.shrink(),
            _loadedTabs.contains(_settingsIndex)
                ? const SettingScreen(
                    key: PageStorageKey<String>('settings_screen'),
                  )
                : const SizedBox.shrink(),
          ],
        ),
      ),
      bottomNavigationBar: CurvedNavigationBar(
        index: _selectedIndex,
        height: 65,
        backgroundColor: Colors.transparent,
        color: theme.cardColor,
        buttonBackgroundColor: theme.cardColor,
        animationDuration: Duration.zero,
        animationCurve: Curves.linear,
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
        onTap: _onNavigationTap,
      ),
    );
  }
}

class MainDashboardContent extends StatelessWidget {
  final ValueChanged<String> onStatusTap;

  const MainDashboardContent({
    super.key,
    required this.onStatusTap,
  });

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

  static const List<String> _travelDistanceDates = <String>[
    '20/7',
    '21/7',
    '22/7',
    '27/7',
  ];

  static const List<double> _travelDistanceValues = <double>[
    0.3,
    11,
    0,
    0,
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

            _buildDashboardTitle(context, textColor, accentColor),

            const SizedBox(height: 20),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                context.tr('Fleet Status'),
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
                context.tr('Engine Hours'),
                style: TextStyle(
                  fontFamily: 'NormalBold',
                  fontSize: 16,
                  color: textColor,
                ),
              ),
            ),

            _DeferredChartBox(
              height: 268,
              builder: _buildEngineHoursChart,
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                context.tr('Travel Distance (in KM)'),
                style: TextStyle(
                  fontFamily: 'NormalBold',
                  fontSize: 16,
                  color: textColor,
                ),
              ),
            ),

            _DeferredChartBox(
              height: 368,
              builder: _buildTravelDistanceChart,
            ),

            const _TodaysFuelRateSection(),

            const _MaintenanceReminderSection(),

            const _DashboardExpenseSection(),

            const _QuickLinksSection(),

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
            cacheWidth: 120,
            cacheHeight: 120,
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
            cacheWidth: 150,
            cacheHeight: 150,
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

  Widget _buildDashboardTitle(
    BuildContext context,
    Color textColor,
    Color accentColor,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Text(
            context.tr('Dashboard'),
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
    int running = 0;
    int idle = 0;
    int stopped = 0;
    int expired = 0;
    int inactive = 0;

    for (final VehicleModel v in VehicleData.vehicles) {
      final String s = v.status.trim().toLowerCase();
      if (s == 'running') {
        running++;
      } else if (s == 'idle') {
        idle++;
      } else if (s == 'stopped') {
        stopped++;
      } else if (s == 'expired') {
        expired++;
      } else if (s == 'inactive' || s == 'not reporting') {
        inactive++;
      }
    }
    final int total = VehicleData.vehicles.length;

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
                        sections: _buildPieSections(
                          running: running,
                          idle: idle,
                          stopped: stopped,
                          inactive: inactive,
                          expired: expired,
                        ),
                      ),
                    ),
                  ),

                  IgnorePointer(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          total > 0 ? '$total' : '0',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                            fontFamily: 'NormalBold',
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          context.tr('Objects'),
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
                    value: running,
                    color: Colors.green,
                    onTap: () => onStatusTap('running'),
                  ),
                  StatusRow(
                    title: 'Idle',
                    value: idle,
                    color: Colors.orange,
                    onTap: () => onStatusTap('idle'),
                  ),
                  StatusRow(
                    title: 'Stopped',
                    value: stopped,
                    color: Colors.red,
                    onTap: () => onStatusTap('stopped'),
                  ),
                  StatusRow(
                    title: 'Expired',
                    value: expired,
                    color: Colors.pink,
                    onTap: () => onStatusTap('expired'),
                  ),
                  StatusRow(
                    title: 'InActive',
                    value: inactive,
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

  List<PieChartSectionData> _buildPieSections({
    required int running,
    required int idle,
    required int stopped,
    required int inactive,
    required int expired,
  }) {
    const TextStyle sliceStyle = TextStyle(
      color: Colors.white,
      fontSize: 10,
      fontWeight: FontWeight.w700,
    );

    final List<PieChartSectionData> sections = <PieChartSectionData>[];
    if (stopped > 0) {
      sections.add(PieChartSectionData(
        value: stopped.toDouble(),
        color: Colors.red,
        radius: 32,
        title: '$stopped',
        titleStyle: sliceStyle,
      ));
    }
    if (inactive > 0) {
      sections.add(PieChartSectionData(
        value: inactive.toDouble(),
        color: Colors.blue,
        radius: 32,
        title: '$inactive',
        titleStyle: sliceStyle,
      ));
    }
    if (running > 0) {
      sections.add(PieChartSectionData(
        value: running.toDouble(),
        color: Colors.green,
        radius: 32,
        title: '$running',
        titleStyle: sliceStyle,
      ));
    }
    if (idle > 0) {
      sections.add(PieChartSectionData(
        value: idle.toDouble(),
        color: Colors.orange,
        radius: 32,
        title: '$idle',
        titleStyle: sliceStyle,
      ));
    }

    if (sections.isEmpty) {
      sections.add(PieChartSectionData(
        value: 1,
        color: Colors.grey,
        radius: 32,
        title: '0',
        titleStyle: sliceStyle,
      ));
    }

    return sections;
  }

  TextStyle _chartLabelStyle(BuildContext context, {double alpha = 0.92}) {
    return TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w600,
      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: alpha),
    );
  }

  TextStyle _chartAxisNameStyle(BuildContext context) {
    return TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.w700,
      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.72),
    );
  }

  Widget _buildEngineHoursChart(BuildContext context) {
    final Color labelColor = Theme.of(context).colorScheme.onSurface;
    final Color tooltipBg = Theme.of(context).colorScheme.surface;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.fromLTRB(8, 16, 12, 8),
        height: 236,
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
              maxY: 5,
              borderData: FlBorderData(show: false),
              gridData: const FlGridData(show: false),
              lineTouchData: LineTouchData(
                enabled: true,
                touchTooltipData: LineTouchTooltipData(
                  getTooltipColor: (_) => tooltipBg,
                  getTooltipItems: (List<LineBarSpot> spots) {
                    return spots.map((LineBarSpot spot) {
                      return LineTooltipItem(
                        '${spot.y.toStringAsFixed(1)} hrs',
                        TextStyle(
                          color: labelColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      );
                    }).toList();
                  },
                ),
              ),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  axisNameWidget: Text(
                    context.tr('Hours'),
                    style: _chartAxisNameStyle(context),
                  ),
                  axisNameSize: 18,
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: 1,
                    reservedSize: 28,
                    getTitlesWidget: (double value, TitleMeta meta) {
                      if (value < 0 || value > 5) {
                        return const SizedBox.shrink();
                      }
                      return SideTitleWidget(
                        axisSide: meta.axisSide,
                        child: Text(
                          value.toInt().toString(),
                          style: _chartLabelStyle(context),
                        ),
                      );
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 28,
                    getTitlesWidget: (double value, TitleMeta meta) {
                      return _buildBottomTitle(context, value, meta);
                    },
                  ),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              lineBarsData: [
                LineChartBarData(
                  isCurved: true,
                  color: Colors.teal,
                  barWidth: 3,
                  spots: _engineHourSpots,
                  dotData: const FlDotData(show: true),
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

  Widget _buildTravelDistanceChart(BuildContext context) {
    const double maxY = 13;
    const Color barGreen = Color(0xFF4CAF50);
    final Color labelColor = Theme.of(context).colorScheme.onSurface;
    final Color tooltipBg = Theme.of(context).colorScheme.surface;
    final Color trackColor = labelColor.withValues(alpha: 0.12);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
        height: 336,
        width: double.infinity,
        decoration: context.containerDecoration(
          borderRadius: BorderRadius.circular(16),
        ),
        child: RepaintBoundary(
          child: BarChart(
            BarChartData(
              maxY: maxY,
              minY: 0,
              alignment: BarChartAlignment.spaceAround,
              borderData: FlBorderData(show: false),
              gridData: const FlGridData(show: false),
              barTouchData: BarTouchData(
                enabled: true,
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (_) => tooltipBg,
                  getTooltipItem: (
                    BarChartGroupData group,
                    int groupIndex,
                    BarChartRodData rod,
                    int rodIndex,
                  ) {
                    return BarTooltipItem(
                      '${rod.toY.toStringAsFixed(rod.toY % 1 == 0 ? 0 : 1)} KM',
                      TextStyle(
                        color: labelColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    );
                  },
                ),
              ),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                leftTitles: AxisTitles(
                  axisNameWidget: Text(
                    context.tr('KM'),
                    style: _chartAxisNameStyle(context),
                  ),
                  axisNameSize: 18,
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: 1,
                    reservedSize: 28,
                    getTitlesWidget: (double value, TitleMeta meta) {
                      if (value < 0 || value > maxY) {
                        return const SizedBox.shrink();
                      }
                      return SideTitleWidget(
                        axisSide: meta.axisSide,
                        child: Text(
                          value.toInt().toString(),
                          style: _chartLabelStyle(context, alpha: 0.78),
                        ),
                      );
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 28,
                    getTitlesWidget: (double value, TitleMeta meta) {
                      final int index = value.toInt();
                      if (value != index.toDouble() ||
                          index < 0 ||
                          index >= _travelDistanceDates.length) {
                        return const SizedBox.shrink();
                      }
                      return SideTitleWidget(
                        axisSide: meta.axisSide,
                        child: Text(
                          _travelDistanceDates[index],
                          style: _chartLabelStyle(context),
                        ),
                      );
                    },
                  ),
                ),
              ),
              barGroups: List<BarChartGroupData>.generate(
                _travelDistanceValues.length,
                (int index) {
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: _travelDistanceValues[index],
                        width: 18,
                        borderRadius: BorderRadius.circular(20),
                        color: barGreen,
                        backDrawRodData: BackgroundBarChartRodData(
                          show: true,
                          toY: maxY,
                          color: trackColor,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomTitle(
    BuildContext context,
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
        style: _chartLabelStyle(context),
      ),
    );
  }
}

class _DeferredChartBox extends StatefulWidget {
  final double height;
  final Widget Function(BuildContext context) builder;

  const _DeferredChartBox({
    required this.height,
    required this.builder,
  });

  @override
  State<_DeferredChartBox> createState() => _DeferredChartBoxState();
}

class _DeferredChartBoxState extends State<_DeferredChartBox> {
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _ready = true;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return SizedBox(height: widget.height, width: double.infinity);
    }
    return widget.builder(context);
  }
}

class _TodaysFuelRateSection extends StatefulWidget {
  const _TodaysFuelRateSection();

  @override
  State<_TodaysFuelRateSection> createState() => _TodaysFuelRateSectionState();
}

class _TodaysFuelRateSectionState extends State<_TodaysFuelRateSection> {
  static const Color _pinkColor = Color(0xFFF43A6B);

  static const List<String> _states = <String>[
    'andaman-and-nicobar',
    'andhra-pradesh',
    'arunachal-pradesh',
    'assam',
    'bihar',
    'chandigarh',
    'chhattisgarh',
    'delhi',
    'goa',
    'gujarat',
    'haryana',
    'himachal-pradesh',
    'jammu-and-kashmir',
    'jharkhand',
    'karnataka',
    'kerala',
    'madhya-pradesh',
    'maharashtra',
    'manipur',
    'meghalaya',
    'mizoram',
    'nagaland',
    'odisha',
    'punjab',
    'rajasthan',
    'sikkim',
    'tamil-nadu',
    'telangana',
    'tripura',
    'uttar-pradesh',
    'uttarakhand',
    'west-bengal',
  ];

  String _selectedState = 'andaman-and-nicobar';
  String _dieselRate = 'INR 78.05';
  String _petrolRate = 'INR 82.46';

  Future<void> _openSelectState() async {
    final String? selected = await showDialog<String>(
      context: context,
      barrierColor: Colors.black45,
      builder: (_) => _SelectStateDialog(
        states: _states,
        initialSelected: _selectedState,
      ),
    );

    if (selected == null || !mounted) {
      return;
    }

    setState(() {
      _selectedState = selected;
      // Demo rates change slightly by state selection.
      final int seed = selected.hashCode.abs() % 40;
      _dieselRate = 'INR ${(76 + seed * 0.05).toStringAsFixed(2)}';
      _petrolRate = 'INR ${(80 + seed * 0.06).toStringAsFixed(2)}';
    });
  }

  String get _displayState {
    if (_selectedState.length <= 13) {
      return _selectedState;
    }
    return '${_selectedState.substring(0, 12)}-';
  }

  @override
  Widget build(BuildContext context) {
    final Color textColor = Theme.of(context).colorScheme.onSurface;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  context.tr("Today's Fuel Rate"),
                  style: TextStyle(
                    fontFamily: 'NormalBold',
                    fontSize: 16,
                    color: textColor,
                  ),
                ),
              ),
              InkWell(
                onTap: _openSelectState,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 130),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: context.containerColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: textColor.withValues(alpha: 0.45),
                    ),
                  ),
                  child: Text(
                    _displayState,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: textColor,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
            decoration: context.containerDecoration(
              borderRadius: BorderRadius.circular(16),
            ),
            child: IntrinsicHeight(
              child: Row(
                children: [
                  Expanded(
                    child: _FuelRateColumn(
                      label: 'Diesel',
                      price: _dieselRate,
                      iconColor: _pinkColor,
                    ),
                  ),
                  VerticalDivider(
                    width: 1,
                    thickness: 1,
                    color: Colors.grey.shade300,
                  ),
                  Expanded(
                    child: _FuelRateColumn(
                      label: 'Petrol',
                      price: _petrolRate,
                      iconColor: _pinkColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _FuelRateColumn extends StatelessWidget {
  final String label;
  final String price;
  final Color iconColor;

  const _FuelRateColumn({
    required this.label,
    required this.price,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final Color textColor = Theme.of(context).colorScheme.onSurface;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          context.tr(label),
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: textColor,
          ),
        ),
        const SizedBox(height: 10),
        Icon(
          Icons.local_gas_station,
          color: iconColor,
          size: 34,
        ),
        const SizedBox(height: 10),
        Text(
          price,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: textColor,
          ),
        ),
      ],
    );
  }
}

class _SelectStateDialog extends StatefulWidget {
  final List<String> states;
  final String initialSelected;

  const _SelectStateDialog({
    required this.states,
    required this.initialSelected,
  });

  @override
  State<_SelectStateDialog> createState() => _SelectStateDialogState();
}

class _SelectStateDialogState extends State<_SelectStateDialog> {
  final TextEditingController _searchController = TextEditingController();
  late List<String> _filtered;

  @override
  void initState() {
    super.initState();
    _filtered = widget.states;
    _searchController.addListener(_filter);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filter() {
    final String query = _searchController.text.trim().toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filtered = widget.states;
      } else {
        _filtered = widget.states
            .where((String s) => s.toLowerCase().contains(query))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.sizeOf(context);
    final ColorScheme colors = Theme.of(context).colorScheme;
    final Color textColor = colors.onSurface;
    final Color mutedColor = textColor.withValues(alpha: 0.45);
    final Color borderColor = textColor.withValues(alpha: 0.28);

    return Dialog(
      backgroundColor: Theme.of(context).cardColor,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: SizedBox(
        width: size.width * 0.86,
        height: size.height * 0.78,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Column(
            children: [
              TextField(
                controller: _searchController,
                style: TextStyle(
                  color: textColor,
                  fontSize: 15,
                ),
                decoration: InputDecoration(
                  hintText: context.tr('Search state'),
                  hintStyle: TextStyle(
                    color: mutedColor,
                    fontSize: 15,
                  ),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: borderColor,
                      width: 1,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: colors.primary,
                      width: 1.2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: _filtered.isEmpty
                    ? Center(
                        child: Text(
                          context.tr('No state found'),
                          style: TextStyle(color: mutedColor),
                        ),
                      )
                    : ListView.builder(
                        padding: EdgeInsets.zero,
                        itemCount: _filtered.length,
                        itemBuilder: (BuildContext context, int index) {
                          final String state = _filtered[index];
                          return InkWell(
                            onTap: () => Navigator.pop(context, state),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 12,
                                horizontal: 4,
                              ),
                              child: Text(
                                state,
                                style: TextStyle(
                                  color: textColor,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MaintenanceReminderSection extends StatelessWidget {
  const _MaintenanceReminderSection();

  
  static const Color _iconBoxBg = Color(0xFFD6E6F0);

  void _openReminders(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => const RemindersScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color textColor = Theme.of(context).colorScheme.onSurface;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
        decoration: context.containerDecoration(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.tr('Maintenance Reminder'),
              style: TextStyle(
                fontFamily: 'NormalBold',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _MaintenanceSummaryTile(
                    label: 'Pending',
                    count: '0',
                    background: context.fieldFillColor,
                    iconBoxColor: _iconBoxBg,
                    icon: Icons.access_time_filled,
                    iconColor: const Color(0xFF2196F3),
                    badgeColor: const Color(0xFFFFC107),
                    onTap: () => _openReminders(context),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _MaintenanceSummaryTile(
                    label: 'Overdue',
                    count: '1',
                    background: context.fieldFillColor,
                    iconBoxColor: _iconBoxBg,
                    icon: Icons.access_time_filled,
                    iconColor: const Color(0xFFE53935),
                    badgeColor: const Color(0xFFE53935),
                    onTap: () => _openReminders(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color: context.fieldFillColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.tr('Overdue'),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'TN37BR5099',
                          style: TextStyle(
                            fontSize: 12,
                            color: textColor.withValues(alpha: 0.75),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Row(
                      children: [
                        Icon(
                          Icons.speed,
                          size: 18,
                          color: textColor.withValues(alpha: 0.7),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '366723...',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: textColor,
                                ),
                              ),
                              Text(
                                '125487',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: textColor.withValues(alpha: 0.75),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '29 May 2...',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: textColor,
                          ),
                        ),
                        Text(
                          'Date',
                          style: TextStyle(
                            fontSize: 11,
                            color: textColor.withValues(alpha: 0.6),
                          ),
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
    );
  }
}

class _MaintenanceSummaryTile extends StatelessWidget {
  final String label;
  final String count;
  final Color background;
  final Color iconBoxColor;
  final IconData icon;
  final Color iconColor;
  final Color badgeColor;
  final VoidCallback onTap;

  const _MaintenanceSummaryTile({
    required this.label,
    required this.count,
    required this.background,
    required this.iconBoxColor,
    required this.icon,
    required this.iconColor,
    required this.badgeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color textColor = Theme.of(context).colorScheme.onSurface;

    return Material(
      color: background,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr(label),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      count,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
              ),
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: iconBoxColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: Icon(icon, color: iconColor, size: 24),
                  ),
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: badgeColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1),
                      ),
                      child: const Icon(
                        Icons.priority_high,
                        color: Colors.white,
                        size: 10,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardExpenseSection extends StatelessWidget {
  const _DashboardExpenseSection();

  
  static const Color _iconBoxBg = Color(0xFFD6E6F0);

  @override
  Widget build(BuildContext context) {
    final Color textColor = Theme.of(context).colorScheme.onSurface;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
        decoration: context.containerDecoration(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    context.tr('Expense'),
                    style: TextStyle(
                      fontFamily: 'NormalBold',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                  ),
                ),
                InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => const AddExpenseScreen(),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 2,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 18,
                          height: 18,
                          decoration: const BoxDecoration(
                            color: Colors.black,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.add,
                            color: Colors.white,
                            size: 14,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          context.tr('Add Expense'),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: textColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                color: context.fieldFillColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '200.0 INR',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: textColor,
                      ),
                    ),
                  ),
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: _iconBoxBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.account_balance_wallet,
                      color: Color(0xFFFF9800),
                      size: 26,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color: context.fieldFillColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Food',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Testing',
                          style: TextStyle(
                            fontSize: 12,
                            color: textColor.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '02 Jul 2026',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: textColor,
                          ),
                        ),
                        Text(
                          'Date',
                          style: TextStyle(
                            fontSize: 11,
                            color: textColor.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '200.0',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: textColor,
                          ),
                        ),
                        Text(
                          'Amount',
                          style: TextStyle(
                            fontSize: 11,
                            color: textColor.withValues(alpha: 0.6),
                          ),
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
    );
  }
}

class _QuickLinksSection extends StatelessWidget {
  const _QuickLinksSection();

  

  static const List<_QuickLinkItem> _links = <_QuickLinkItem>[
    _QuickLinkItem(
      title: 'E Challan',
      icon: Icons.assignment_outlined,
      url: 'https://echallan.parivahan.gov.in/',
    ),
    _QuickLinkItem(
      title: 'Get License',
      icon: Icons.badge_outlined,
      url: 'https://sarathi.parivahan.gov.in/',
    ),
    _QuickLinkItem(
      title: 'Recharge Fastag',
      icon: Icons.toll_outlined,
      url: 'https://fastag.npci.org.in/',
    ),
    _QuickLinkItem(
      title: 'Check Tolls',
      icon: Icons.directions_car_outlined,
      url: 'https://tis.nhai.gov.in/',
    ),
    _QuickLinkItem(
      title: 'Buy Insurance',
      icon: Icons.health_and_safety_outlined,
      url: 'https://www.policybazaar.com/motor-insurance/',
    ),
    _QuickLinkItem(
      title: 'Tow Service',
      icon: Icons.car_crash_outlined,
      url: 'https://www.google.com/search?q=tow+service+near+me',
    ),
    _QuickLinkItem(
      title: 'test',
      icon: Icons.link,
      url: 'https://www.google.com',
    ),
    _QuickLinkItem(
      title: 'test2',
      icon: Icons.link,
      url: 'https://www.google.com',
    ),
  ];

  Future<void> _openLink(BuildContext context, _QuickLinkItem item) async {
    final Uri uri = Uri.parse(item.url);
    try {
      final bool canLaunch = await canLaunchUrl(uri);
      if (!canLaunch) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not open ${item.title}')),
          );
        }
        return;
      }

      await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open ${item.title}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color textColor = Theme.of(context).colorScheme.onSurface;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
        decoration: context.containerDecoration(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.tr('Quick Links'),
              style: TextStyle(
                fontFamily: 'NormalBold',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
            ),
            const SizedBox(height: 8),
            Divider(
              height: 1,
              thickness: 1,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                const int columns = 3;
                const double spacing = 8;
                final double itemWidth =
                    (constraints.maxWidth - (spacing * (columns - 1))) /
                        columns;

                return Wrap(
                  spacing: spacing,
                  runSpacing: spacing,
                  children: [
                    for (final _QuickLinkItem item in _links)
                      SizedBox(
                        width: itemWidth,
                        child: Material(
                          color: context.fieldFillColor,
                          borderRadius: BorderRadius.circular(7),
                          child: InkWell(
                            onTap: () => _openLink(context, item),
                            borderRadius: BorderRadius.circular(7),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 10,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    item.icon,
                                    size: 16,
                                    color: textColor.withValues(alpha: 0.85),
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      context.tr(item.title),
                                      softWrap: true,
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w600,
                                        color: textColor,
                                        height: 1.2,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickLinkItem {
  final String title;
  final IconData icon;
  final String url;

  const _QuickLinkItem({
    required this.title,
    required this.icon,
    required this.url,
  });
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
                  context.tr(title),
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