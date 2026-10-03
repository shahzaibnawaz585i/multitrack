import 'dart:async';
import 'dart:math' as math;

import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:multitrack/l10n/app_l10n.dart';
import 'package:multitrack/screens/report_screens/main_screen.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/expense_local_store.dart';
import '../data/vehicle_data.dart';
import '../models/daily_report_day.dart';
import '../utils/report_period.dart';
import '../models/expense_model.dart';
import '../models/vehicle_model.dart';
import '../services/daily_report_service.dart';
import '../services/dashboard_chart_service.dart';
import '../services/vehicle_detail_api_service.dart';
import '../services/pakistan_fuel_rate_service.dart';
import '../services/tracking_api_service.dart';
import '../services/general_settings_controller.dart';
import '../services/vehicle_service.dart';
import '../services/voice_alert_service.dart';
import '../theme/app_theme_tokens.dart';
import '../widgets/select_vehicle_dialog.dart';
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

    // Pre-warm TTS engine immediately — covers the case where the user is
    // already logged in and skips the login screen (prewarm in bootstrap
    // is only called after a fresh login).
    unawaited(VoiceAlertService.instance.prewarm());

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      if (_selectedIndex != _listIndex) {
        setState(() {
          _selectedIndex = _listIndex;
          _loadedTabs.add(_listIndex);
        });
      }
    });

  }

  @override
  void dispose() {
    super.dispose();
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

  Widget _buildNavigationItem({required IconData icon, required int index}) {
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
      child: Icon(icon, size: 26, color: Theme.of(context).colorScheme.primary),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: Stack(
          children: <Widget>[
            // ── Main tab content ──────────────────────────────────────
            PageStorage(
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
                  _loadedTabs.contains(_listIndex)
                      ? ListScreen(
                          key: const PageStorageKey<String>(
                            'vehicle_list_screen',
                          ),
                          initialFilter: _vehicleFilter,
                          isVisible: _selectedIndex == _listIndex,
                        )
                      : const SizedBox.shrink(),
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
          ],
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
            _buildNavigationItem(icon: Icons.dashboard, index: _dashboardIndex),
            _buildNavigationItem(
              icon: Icons.location_on_rounded,
              index: _mapIndex,
            ),
            _buildNavigationItem(icon: Icons.local_shipping, index: _listIndex),
            _buildNavigationItem(icon: Icons.person, index: _reportIndex),
            _buildNavigationItem(icon: Icons.settings, index: _settingsIndex),
          ],
          onTap: _onNavigationTap,
        ),
    );
  }
}

class MainDashboardContent extends StatefulWidget {
  final ValueChanged<String> onStatusTap;

  const MainDashboardContent({super.key, required this.onStatusTap});

  @override
  State<MainDashboardContent> createState() => _MainDashboardContentState();
}

class _MainDashboardContentState extends State<MainDashboardContent> {
  List<VehicleModel> _vehicles = <VehicleModel>[];
  VehicleModel? _selectedVehicle;
  bool _isLoadingVehicles = false;
  bool _isLoadingCharts = false;

  List<String> _chartDates = <String>[];
  List<FlSpot> _engineHourSpots = <FlSpot>[];

  List<String> _travelDistanceDates = <String>[];
  List<double> _travelDistanceValues = <double>[];

  int _chartLoadGeneration = 0;

  @override
  void initState() {
    super.initState();
    _initDefaultDates();
    _loadVehicles();
  }

  void _initDefaultDates() {
    final DateTime now = DateTime.now();
    final List<String> dates = <String>[];
    final List<FlSpot> spots = <FlSpot>[];
    final List<double> distances = <double>[];

    for (int i = 6; i >= 0; i--) {
      final DateTime day = now.subtract(Duration(days: i));
      dates.add('${day.day}/${day.month}');
      spots.add(FlSpot((6 - i).toDouble(), 0));
      distances.add(0.0);
    }

    _chartDates = dates;
    _travelDistanceDates = List<String>.from(dates);
    _engineHourSpots = spots;
    _travelDistanceValues = distances;
  }

  Future<void> _loadVehicles({bool forceRefresh = false}) async {
    if (!mounted) return;
    setState(() => _isLoadingVehicles = true);

    try {
      final List<VehicleModel> fetched = await VehicleService.getDevices(
        forceRefresh: forceRefresh,
      );
      if (!mounted) return;

      final List<VehicleModel> list = fetched.isNotEmpty
          ? fetched
          : VehicleData.vehicles;

      VehicleModel? nextSelected = _selectedVehicle;
      if (list.isNotEmpty) {
        if (nextSelected == null) {
          nextSelected = list.first;
        } else {
          final int idx = list.indexWhere(
            (VehicleModel v) =>
                (v.id != null && v.id == nextSelected!.id) ||
                v.name == nextSelected!.name,
          );
          if (idx != -1) {
            nextSelected = list[idx];
          }
        }
      }

      setState(() {
        _vehicles = list;
        _selectedVehicle = nextSelected;
        _isLoadingVehicles = false;
      });

      if (nextSelected != null) {
        _loadChartDataForVehicle(_vehicleForCharts(nextSelected));
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingVehicles = false);
      }
    }
  }

  VehicleModel _vehicleForCharts(VehicleModel vehicle) {
    for (final VehicleModel v in _vehicles) {
      if (vehicle.id != null && v.id == vehicle.id) {
        return v;
      }
    }
    for (final VehicleModel v in _vehicles) {
      if (v.name == vehicle.name && v.id != null) {
        return v;
      }
    }
    if (vehicle.id == null) {
      for (final VehicleModel v in VehicleData.vehicles) {
        if (v.name == vehicle.name && v.id != null) {
          return v;
        }
      }
    }
    return vehicle;
  }

  static const int _todayChartIndex = 6;

  ({
    List<String> labels,
    Map<String, int> dateIndexMap,
    List<double> engineHours,
    List<double> distances,
  }) _emptySevenDayChartBuckets(DateTime now) {
    final DateFormat keyFmt = DateFormat('yyyy-MM-dd');
    final List<String> labels = <String>[];
    final Map<String, int> dateIndexMap = <String, int>{};
    final List<double> engineHours = List<double>.filled(7, 0.0);
    final List<double> distances = List<double>.filled(7, 0.0);

    for (int i = 6; i >= 0; i--) {
      final DateTime d = ReportPeriod.startOfDay(
        now.subtract(Duration(days: i)),
      );
      final int bucketIndex = 6 - i;
      labels.add('${d.day}/${d.month}');
      dateIndexMap[keyFmt.format(d)] = bucketIndex;
    }

    return (
      labels: labels,
      dateIndexMap: dateIndexMap,
      engineHours: engineHours,
      distances: distances,
    );
  }

  void _mergeReportDaysIntoBuckets({
    required List<DailyReportDay> reportDays,
    required Map<String, int> dateIndexMap,
    required List<double> engineHours,
    required List<double> distances,
  }) {
    final DateFormat keyFmt = DateFormat('yyyy-MM-dd');
    for (final DailyReportDay day in reportDays) {
      final String bucketKey = keyFmt.format(
        ReportPeriod.startOfDay(day.dayDate),
      );
      final int? idx = dateIndexMap[bucketKey];
      if (idx == null) {
        continue;
      }
      final double km = _parseDistance(day.distanceLabel);
      if (km > distances[idx]) {
        distances[idx] = km;
      }
      final double eng = _parseHours(day.engineHours);
      final double run = _parseHours(day.runningTime);
      final double h = eng > 0 ? eng : run;
      if (h > engineHours[idx]) {
        engineHours[idx] = h;
      }
    }
  }

  void _applyLiveTodayBucket({
    required VehicleModel vehicle,
    required List<double> engineHours,
    required List<double> distances,
  }) {
    final stats = VehicleDetailApiService.statsFromVehicleModel(vehicle);
    final double liveKm = _parseDistance(stats.routeLengthKm);
    final double runHours = _parseHours(stats.moveDuration);
    final double liveHours = _parseHours(stats.engineHours);
    final double hours = liveHours > 0 ? liveHours : runHours;

    if (liveKm > distances[_todayChartIndex]) {
      distances[_todayChartIndex] = liveKm;
    }
    if (hours > engineHours[_todayChartIndex]) {
      engineHours[_todayChartIndex] = hours;
    }
  }

  bool _chartHasAnyMetric(List<double> engineHours, List<double> distances) {
    for (int i = 0; i < 7; i++) {
      if (engineHours[i] > 0 || distances[i] > 0) {
        return true;
      }
    }
    return false;
  }

  void _publishChartSeries({
    required int loadId,
    required List<String> labels,
    required List<double> engineHours,
    required List<double> distances,
    required bool loading,
  }) {
    if (!mounted || loadId != _chartLoadGeneration) {
      return;
    }
    final List<FlSpot> spots = <FlSpot>[];
    for (int i = 0; i < 7; i++) {
      final double h = engineHours[i];
      spots.add(FlSpot(i.toDouble(), double.parse(h.toStringAsFixed(2))));
    }
    setState(() {
      _chartDates = labels;
      _travelDistanceDates = List<String>.from(labels);
      _engineHourSpots = spots;
      _travelDistanceValues = distances;
      _isLoadingCharts = loading;
    });
  }

  Future<void> _loadChartDataForVehicle(VehicleModel vehicle) async {
    if (!mounted) return;

    final VehicleModel chartVehicle = _vehicleForCharts(vehicle);
    final int loadId = ++_chartLoadGeneration;

    final DateTime now = DateTime.now();
    final DateTime from = ReportPeriod.startOfDay(
      now.subtract(const Duration(days: 6)),
    );
    final DateTime to = ReportPeriod.endOfDay(now);

    final ({
      List<String> labels,
      Map<String, int> dateIndexMap,
      List<double> engineHours,
      List<double> distances,
    }) buckets = _emptySevenDayChartBuckets(now);

    List<double> engineHours = List<double>.from(buckets.engineHours);
    List<double> distances = List<double>.from(buckets.distances);
    final List<String> labels = buckets.labels;
    final Map<String, int> dateIndexMap = buckets.dateIndexMap;

    _publishChartSeries(
      loadId: loadId,
      labels: labels,
      engineHours: engineHours,
      distances: distances,
      loading: chartVehicle.id != null,
    );

    if (chartVehicle.id == null) {
      _applyLiveTodayBucket(
        vehicle: chartVehicle,
        engineHours: engineHours,
        distances: distances,
      );
      _publishChartSeries(
        loadId: loadId,
        labels: labels,
        engineHours: engineHours,
        distances: distances,
        loading: false,
      );
      return;
    }

    final List<DailyReportDay>? cachedDays =
        DailyReportService.peekFastChartCache(
      deviceId: chartVehicle.id,
      from: from,
    );
    if (cachedDays != null) {
      _mergeReportDaysIntoBuckets(
        reportDays: cachedDays,
        dateIndexMap: dateIndexMap,
        engineHours: engineHours,
        distances: distances,
      );
    }

    _applyLiveTodayBucket(
      vehicle: chartVehicle,
      engineHours: engineHours,
      distances: distances,
    );

    _publishChartSeries(
      loadId: loadId,
      labels: labels,
      engineHours: engineHours,
      distances: distances,
      loading: !_chartHasAnyMetric(engineHours, distances),
    );

    try {
      final List<List<DailyReportDay>> parallel =
          await Future.wait<List<DailyReportDay>>(
        <Future<List<DailyReportDay>>>[
          DailyReportService.loadDaysFastForCharts(
            vehicle: chartVehicle,
            from: from,
            to: to,
          ).catchError((_) => <DailyReportDay>[]),
          DashboardChartService.loadDaysFromHistoryWeek(
            vehicle: chartVehicle,
            from: from,
            to: to,
          )
              .timeout(
                const Duration(seconds: 18),
                onTimeout: () => <DailyReportDay>[],
              )
              .catchError((_) => <DailyReportDay>[]),
        ],
      );
      if (loadId != _chartLoadGeneration || !mounted) {
        return;
      }
      for (final List<DailyReportDay> days in parallel) {
        if (days.isEmpty) {
          continue;
        }
        _mergeReportDaysIntoBuckets(
          reportDays: days,
          dateIndexMap: dateIndexMap,
          engineHours: engineHours,
          distances: distances,
        );
      }
    } catch (_) {}

    _applyLiveTodayBucket(
      vehicle: chartVehicle,
      engineHours: engineHours,
      distances: distances,
    );

    _publishChartSeries(
      loadId: loadId,
      labels: labels,
      engineHours: engineHours,
      distances: distances,
      loading: false,
    );

    unawaited(
      _enrichChartDataInBackground(
        chartVehicle: chartVehicle,
        loadId: loadId,
        from: from,
        to: to,
        labels: labels,
        dateIndexMap: dateIndexMap,
      ),
    );
  }

  Future<void> _enrichChartDataInBackground({
    required VehicleModel chartVehicle,
    required int loadId,
    required DateTime from,
    required DateTime to,
    required List<String> labels,
    required Map<String, int> dateIndexMap,
  }) async {
    try {
      final List<DailyReportDay> fullDays =
          await DailyReportService.loadDaysForCharts(
        vehicle: chartVehicle,
        from: from,
        to: to,
      );
      if (!mounted || loadId != _chartLoadGeneration || fullDays.isEmpty) {
        return;
      }

      final List<double> engineHours = List<double>.filled(7, 0.0);
      final List<double> distances = List<double>.filled(7, 0.0);
      _mergeReportDaysIntoBuckets(
        reportDays: fullDays,
        dateIndexMap: dateIndexMap,
        engineHours: engineHours,
        distances: distances,
      );
      _applyLiveTodayBucket(
        vehicle: chartVehicle,
        engineHours: engineHours,
        distances: distances,
      );
      _publishChartSeries(
        loadId: loadId,
        labels: labels,
        engineHours: engineHours,
        distances: distances,
        loading: false,
      );
    } catch (_) {}
  }

  static double _parseDistance(dynamic raw) {
    if (raw == null) return 0.0;
    if (raw is num) return raw.toDouble();
    final String s = raw.toString().trim().toLowerCase();
    if (s.isEmpty || s == 'null' || s == '-') return 0.0;

    final RegExp reg = RegExp(r'([0-9]+(?:\.[0-9]+)?)');
    final Match? match = reg.firstMatch(s);
    if (match != null) {
      final double val = double.tryParse(match.group(1) ?? '') ?? 0.0;
      if (s.contains('m') && !s.contains('km') && val > 1000) {
        return double.parse((val / 1000.0).toStringAsFixed(2));
      }
      return double.parse(val.toStringAsFixed(2));
    }
    return 0.0;
  }

  static double _parseHours(dynamic raw) {
    if (raw == null) return 0.0;
    if (raw is num) return raw.toDouble();
    String s = raw.toString().trim().toLowerCase();
    s = s.replaceAll(RegExp(r'\s*hrs\s*$'), '').trim();
    if (s.isEmpty ||
        s == 'null' ||
        s == '-' ||
        s == '00:00' ||
        s == '00:00:00') {
      return 0.0;
    }

    if (s.contains('h') || s.contains('m') || s.contains('d')) {
      double totalHours = 0.0;
      final RegExp dMatch = RegExp(r'(\d+)\s*d');
      final RegExp hMatch = RegExp(r'(\d+)\s*h');
      final RegExp mMatch = RegExp(r'(\d+)\s*m');

      final Match? d = dMatch.firstMatch(s);
      final Match? h = hMatch.firstMatch(s);
      final Match? m = mMatch.firstMatch(s);

      if (d != null) totalHours += (double.tryParse(d.group(1)!) ?? 0) * 24;
      if (h != null) totalHours += (double.tryParse(h.group(1)!) ?? 0);
      if (m != null) totalHours += (double.tryParse(m.group(1)!) ?? 0) / 60.0;

      if (totalHours > 0) {
        return double.parse(totalHours.toStringAsFixed(2));
      }
    }

    if (s.contains(':')) {
      final List<String> parts = s.replaceAll(RegExp(r'[^\d:]'), '').split(':');
      if (parts.length >= 2) {
        final double hrs = double.tryParse(parts[0]) ?? 0.0;
        final double mins = double.tryParse(parts[1]) ?? 0.0;
        final double secs = parts.length >= 3
            ? (double.tryParse(parts[2]) ?? 0.0)
            : 0.0;
        return double.parse(
          (hrs + (mins / 60.0) + (secs / 3600.0)).toStringAsFixed(2),
        );
      }
    }

    final RegExp reg = RegExp(r'([0-9]+(?:\.[0-9]+)?)');
    final Match? match = reg.firstMatch(s);
    if (match != null) {
      return double.tryParse(match.group(1) ?? '') ?? 0.0;
    }
    return 0.0;
  }

  Future<void> _openVehiclePicker() async {
    final List<VehicleModel> currentList = _vehicles.isNotEmpty
        ? _vehicles
        : VehicleData.vehicles;

    if (currentList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr('No vehicles available')),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final VehicleModel? chosen = await showDialog<VehicleModel>(
      context: context,
      barrierColor: Colors.black45,
      builder: (_) => SelectVehicleDialog(
        initialSelected: _selectedVehicle,
        vehicles: currentList,
      ),
    );

    if (chosen != null && mounted) {
      final VehicleModel resolved = _vehicleForCharts(chosen);
      setState(() {
        _selectedVehicle = resolved;
      });
      _loadChartDataForVehicle(resolved);
    }
  }

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

            _buildEngineHoursChart(context),

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

            _buildTravelDistanceChart(context),

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
            errorBuilder:
                (BuildContext context, Object error, StackTrace? stackTrace) {
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
            errorBuilder:
                (BuildContext context, Object error, StackTrace? stackTrace) {
                  return const SizedBox(
                    height: 50,
                    width: 50,
                    child: Icon(Icons.edit),
                  );
                },
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: () => _loadVehicles(forceRefresh: true),
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(4.0),
              child: _isLoadingVehicles
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh_outlined, size: 27),
            ),
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
    final String displayName = _selectedVehicle?.name ?? 'Select Vehicle';

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
          InkWell(
            onTap: _openVehiclePicker,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                border: Border.all(color: textColor.withValues(alpha: 0.4)),
                borderRadius: BorderRadius.circular(8),
                color: Theme.of(context).cardColor,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 140),
                    child: Text(
                      displayName,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.arrow_drop_down, color: accentColor, size: 18),
                ],
              ),
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

    final List<VehicleModel> list = _vehicles.isNotEmpty
        ? _vehicles
        : VehicleData.vehicles;

    for (final VehicleModel v in list) {
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
    final int total = list.length;

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
                          touchCallback:
                              (FlTouchEvent event, PieTouchResponse? response) {
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
                    onTap: () => widget.onStatusTap('running'),
                  ),
                  StatusRow(
                    title: 'Idle',
                    value: idle,
                    color: Colors.orange,
                    onTap: () => widget.onStatusTap('idle'),
                  ),
                  StatusRow(
                    title: 'Stopped',
                    value: stopped,
                    color: Colors.red,
                    onTap: () => widget.onStatusTap('stopped'),
                  ),
                  StatusRow(
                    title: 'Expired',
                    value: expired,
                    color: Colors.pink,
                    onTap: () => widget.onStatusTap('expired'),
                  ),
                  StatusRow(
                    title: 'InActive',
                    value: inactive,
                    color: Colors.blue,
                    onTap: () => widget.onStatusTap('inactive'),
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
        widget.onStatusTap('stopped');
        break;

      case 1:
        widget.onStatusTap('inactive');
        break;

      case 2:
        widget.onStatusTap('running');
        break;

      case 3:
        widget.onStatusTap('idle');
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
      sections.add(
        PieChartSectionData(
          value: stopped.toDouble(),
          color: Colors.red,
          radius: 32,
          title: '$stopped',
          titleStyle: sliceStyle,
        ),
      );
    }
    if (inactive > 0) {
      sections.add(
        PieChartSectionData(
          value: inactive.toDouble(),
          color: Colors.blue,
          radius: 32,
          title: '$inactive',
          titleStyle: sliceStyle,
        ),
      );
    }
    if (running > 0) {
      sections.add(
        PieChartSectionData(
          value: running.toDouble(),
          color: Colors.green,
          radius: 32,
          title: '$running',
          titleStyle: sliceStyle,
        ),
      );
    }
    if (idle > 0) {
      sections.add(
        PieChartSectionData(
          value: idle.toDouble(),
          color: Colors.orange,
          radius: 32,
          title: '$idle',
          titleStyle: sliceStyle,
        ),
      );
    }

    if (sections.isEmpty) {
      sections.add(
        PieChartSectionData(
          value: 1,
          color: Colors.grey,
          radius: 32,
          title: '0',
          titleStyle: sliceStyle,
        ),
      );
    }

    return sections;
  }

  TextStyle _chartLabelStyle(BuildContext context, {double alpha = 0.92}) {
    return TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.w600,
      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: alpha),
    );
  }

  Widget _buildEngineHoursChart(BuildContext context) {
    final Color labelColor = Theme.of(context).colorScheme.onSurface;
    final Color tooltipBg = Theme.of(context).colorScheme.surface;

    double maxSpotY = 0.0;
    for (final FlSpot spot in _engineHourSpots) {
      if (spot.y > maxSpotY) maxSpotY = spot.y;
    }
    final double maxY = maxSpotY <= 0 ? 5.0 : (maxSpotY * 1.15);
    final double interval = maxY / 5.0;

    final double maxX = math.max(1.0, (_chartDates.length - 1).toDouble());

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
        height: 236,
        width: double.infinity,
        decoration: context.containerDecoration(
          borderRadius: BorderRadius.circular(16),
        ),
        child: _isLoadingCharts
            ? const Center(
                child: SizedBox(
                  height: 30,
                  width: 30,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            : RepaintBoundary(
                child: LineChart(
                  LineChartData(
                    minX: 0,
                    maxX: maxX,
                    minY: 0,
                    maxY: maxY,
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
                        sideTitles: SideTitles(
                          showTitles: true,
                          interval: interval,
                          reservedSize: 26,
                          getTitlesWidget: (double value, TitleMeta meta) {
                            final double step = maxY / 5.0;
                            final int level = (value / step).round();
                            if (level < 0 ||
                                level > 5 ||
                                (value - level * step).abs() > (step * 0.20)) {
                              return const SizedBox.shrink();
                            }
                            return SideTitleWidget(
                              axisSide: meta.axisSide,
                              space: 6,
                              child: Text(
                                '$level',
                                style: _chartLabelStyle(context),
                              ),
                            );
                          },
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 26,
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
                        color: const Color(0xFF4CAF50),
                        barWidth: 3,
                        spots: _engineHourSpots.isNotEmpty
                            ? _engineHourSpots
                            : const <FlSpot>[FlSpot(0, 0)],
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
    final Color barGreen = const Color(0xFF4CAF50);
    final Color labelColor = Theme.of(context).colorScheme.onSurface;
    final Color tooltipBg = Theme.of(context).colorScheme.surface;
    final Color trackColor = labelColor.withValues(alpha: 0.12);

    double maxDist = 0.0;
    for (final double d in _travelDistanceValues) {
      if (d > maxDist) maxDist = d;
    }
    final double maxY = maxDist <= 0 ? 5.0 : (maxDist * 1.15);
    final double interval = maxY / 5.0;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
        height: 336,
        width: double.infinity,
        decoration: context.containerDecoration(
          borderRadius: BorderRadius.circular(16),
        ),
        child: _isLoadingCharts
            ? const Center(
                child: SizedBox(
                  height: 30,
                  width: 30,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            : RepaintBoundary(
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
                        getTooltipItem:
                            (
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
                        sideTitles: SideTitles(
                          showTitles: true,
                          interval: interval,
                          reservedSize: 26,
                          getTitlesWidget: (double value, TitleMeta meta) {
                            final double step = maxY / 5.0;
                            final int level = (value / step).round();
                            if (level < 0 ||
                                level > 5 ||
                                (value - level * step).abs() > (step * 0.20)) {
                              return const SizedBox.shrink();
                            }
                            return SideTitleWidget(
                              axisSide: meta.axisSide,
                              space: 6,
                              child: Text(
                                '$level',
                                style: _chartLabelStyle(context, alpha: 0.78),
                              ),
                            );
                          },
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 26,
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
                        final double rawY = _travelDistanceValues[index];
                        final double clampedY = rawY.clamp(0.0, maxY);
                        return BarChartGroupData(
                          x: index,
                          barRods: [
                            BarChartRodData(
                              toY: clampedY,
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

  Widget _buildBottomTitle(BuildContext context, double value, TitleMeta meta) {
    final int index = value.toInt();

    if (value != index.toDouble() || index < 0 || index >= _chartDates.length) {
      return const SizedBox.shrink();
    }

    return SideTitleWidget(
      axisSide: meta.axisSide,
      child: Text(_chartDates[index], style: _chartLabelStyle(context)),
    );
  }
}

class _TodaysFuelRateSection extends StatefulWidget {
  const _TodaysFuelRateSection();

  @override
  State<_TodaysFuelRateSection> createState() => _TodaysFuelRateSectionState();
}

class _TodaysFuelRateSectionState extends State<_TodaysFuelRateSection> {
  static const Color _pinkColor = Color(0xFFF43A6B);

  String _selectedCity = PakistanFuelRateService.defaultCity;
  double? _dieselPkr;
  double? _petrolPkr;
  bool _loadingRates = true;
  String _rateSource = '';

  @override
  void initState() {
    super.initState();
    _loadRates();
  }

  Future<void> _loadRates({bool forceRefresh = false}) async {
    setState(() {
      _loadingRates = true;
    });

    if (forceRefresh) {
      await PakistanFuelRateService.refresh();
    }

    final ({double petrol, double diesel}) rates =
        await PakistanFuelRateService.ratesFor(_selectedCity);

    if (!mounted) {
      return;
    }

    setState(() {
      _petrolPkr = rates.petrol;
      _dieselPkr = rates.diesel;
      _rateSource = 'PSO Euro-5 · $_selectedCity';
      _loadingRates = false;
    });
  }

  Future<void> _openSelectState() async {
    final String? selected = await showDialog<String>(
      context: context,
      barrierColor: Colors.black45,
      builder: (_) => _SelectStateDialog(
        states: PakistanFuelRateService.cities,
        initialSelected: _selectedCity,
      ),
    );

    if (selected == null || !mounted) {
      return;
    }

    setState(() {
      _selectedCity = selected;
    });
    await _loadRates();
  }

  String get _displayState {
    if (_selectedCity.length <= 14) {
      return _selectedCity;
    }
    return '${_selectedCity.substring(0, 13)}…';
  }

  @override
  Widget build(BuildContext context) {
    final Color textColor = Theme.of(context).colorScheme.onSurface;
    final GeneralSettingsController settings =
        context.watch<GeneralSettingsController>();
    final String petrolPrice = _loadingRates || _petrolPkr == null
        ? '…'
        : settings.formatPricePerLiter(_petrolPkr!);
    final String dieselPrice = _loadingRates || _dieselPkr == null
        ? '…'
        : settings.formatPricePerLiter(_dieselPkr!);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      context.tr("Today's Fuel Rate"),
                      style: TextStyle(
                        fontFamily: 'NormalBold',
                        fontSize: 16,
                        color: textColor,
                      ),
                    ),
                    if (_rateSource.isNotEmpty)
                      Text(
                        _rateSource,
                        style: TextStyle(
                          fontSize: 10,
                          color: textColor.withValues(alpha: 0.55),
                        ),
                      ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.refresh, color: _pinkColor, size: 20),
                onPressed: _loadingRates
                    ? null
                    : () => _loadRates(forceRefresh: true),
                tooltip: context.tr('Refresh'),
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
                    style: TextStyle(fontSize: 12, color: textColor),
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
                      label: 'Petrol',
                      subtitle: 'Euro-5 Premier',
                      price: petrolPrice,
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
                      label: 'Diesel',
                      subtitle: 'Hi-Cetane Euro-5',
                      price: dieselPrice,
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
  final String subtitle;
  final String price;
  final Color iconColor;

  const _FuelRateColumn({
    required this.label,
    this.subtitle = '',
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
        if (subtitle.isNotEmpty) ...<Widget>[
          const SizedBox(height: 2),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10,
              color: textColor.withValues(alpha: 0.55),
            ),
          ),
        ],
        const SizedBox(height: 10),
        Icon(Icons.local_gas_station, color: iconColor, size: 34),
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SizedBox(
        width: size.width * 0.86,
        height: size.height * 0.78,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Column(
            children: [
              TextField(
                controller: _searchController,
                style: TextStyle(color: textColor, fontSize: 15),
                decoration: InputDecoration(
                  hintText: context.tr('Search state'),
                  hintStyle: TextStyle(color: mutedColor, fontSize: 15),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: borderColor, width: 1),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: colors.primary, width: 1.2),
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

class _MaintenanceReminderSection extends StatefulWidget {
  const _MaintenanceReminderSection();

  @override
  State<_MaintenanceReminderSection> createState() =>
      _MaintenanceReminderSectionState();
}

class _MaintenanceReminderSectionState extends State<_MaintenanceReminderSection> {
  static const Color _iconBoxBg = Color(0xFFD6E6F0);

  int _pendingCount = 0;
  int _overdueCount = 0;
  String? _overdueVehicle;
  String? _overdueTitle;
  String? _overdueOdometer;
  String? _overdueDueLabel;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    try {
    final List<Map<String, dynamic>> tasks =
        await TrackingApiService.getTasks();
    if (!mounted) {
      return;
    }

    int pending = 0;
    int overdue = 0;
    Map<String, dynamic>? firstOverdue;

    for (final Map<String, dynamic> task in tasks) {
      final DateTime? due = _parseTaskDueDate(task);
      if (due == null) {
        continue;
      }
      if (due.isBefore(DateTime.now())) {
        overdue++;
        firstOverdue ??= task;
      } else {
        pending++;
      }
    }

    String? vehicleName;
    String? title;
    String? odometer;
    String? dueLabel;

    if (firstOverdue != null) {
      title = (firstOverdue['title'] ?? firstOverdue['name'] ?? 'Reminder')
          .toString();
      dueLabel = _formatTaskDue(firstOverdue);
      odometer = (firstOverdue['odometer'] ??
              firstOverdue['value'] ??
              firstOverdue['last_service'])
          ?.toString();
      final dynamic deviceId = firstOverdue['device_id'] ?? firstOverdue['deviceId'];
      vehicleName = (firstOverdue['device_name'] ?? firstOverdue['vehicle'])
          ?.toString();
      if ((vehicleName == null || vehicleName.isEmpty) && deviceId != null) {
        final int? id = int.tryParse(deviceId.toString());
        if (id != null) {
          for (final VehicleModel v in VehicleData.vehicles) {
            if (v.id == id) {
              vehicleName = v.name;
              odometer ??= v.odometer;
              break;
            }
          }
        }
      }
    }

    setState(() {
      _pendingCount = pending;
      _overdueCount = overdue;
      _overdueTitle = title;
      _overdueVehicle = vehicleName;
      _overdueOdometer = odometer;
      _overdueDueLabel = dueLabel;
      _loading = false;
    });
    } catch (_) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  static DateTime? _parseTaskDueDate(Map<String, dynamic> task) {
    const List<String> keys = <String>[
      'expires',
      'expires_at',
      'due_date',
      'date',
      'remind_date',
      'time',
    ];
    for (final String key in keys) {
      final dynamic raw = task[key];
      if (raw == null) {
        continue;
      }
      final DateTime? parsed = DateTime.tryParse(raw.toString());
      if (parsed != null) {
        return parsed;
      }
      try {
        return DateFormat('yyyy-MM-dd HH:mm:ss').parse(raw.toString());
      } catch (_) {}
      try {
        return DateFormat('dd-MM-yyyy HH:mm:ss').parse(raw.toString());
      } catch (_) {}
    }
    return null;
  }

  static String _formatTaskDue(Map<String, dynamic> task) {
    final DateTime? due = _parseTaskDueDate(task);
    if (due == null) {
      return '-';
    }
    return DateFormat('dd MMM yyyy').format(due);
  }

  void _openReminders(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (_) => const RemindersScreen()),
    ).then((_) {
      if (mounted) {
        _loadTasks();
      }
    });
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
                    count: _loading ? '…' : '$_pendingCount',
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
                    count: _loading ? '…' : '$_overdueCount',
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
            if (_overdueCount > 0 && _overdueVehicle != null) ...<Widget>[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                decoration: BoxDecoration(
                  color: context.fieldFillColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            _overdueTitle ?? context.tr('Overdue'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _overdueVehicle!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
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
                        children: <Widget>[
                          Icon(
                            Icons.speed,
                            size: 18,
                            color: textColor.withValues(alpha: 0.7),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              _overdueOdometer ?? '-',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                color: textColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: <Widget>[
                          Text(
                            _overdueDueLabel ?? '-',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: textColor,
                            ),
                          ),
                          Text(
                            context.tr('Date'),
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

class _DashboardExpenseSection extends StatefulWidget {
  const _DashboardExpenseSection();

  @override
  State<_DashboardExpenseSection> createState() =>
      _DashboardExpenseSectionState();
}

class _DashboardExpenseSectionState extends State<_DashboardExpenseSection> {
  static const Color _iconBoxBg = Color(0xFFD6E6F0);

  List<ExpenseModel> _expenses = <ExpenseModel>[];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    final List<ExpenseModel> items = await ExpenseLocalStore.loadAll();
    if (!mounted) {
      return;
    }
    setState(() {
      _expenses = items;
      _loading = false;
    });
  }

  Future<void> _openAddExpense() async {
    await Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (_) => const AddExpenseScreen()),
    );
    if (mounted) {
      await _reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color textColor = Theme.of(context).colorScheme.onSurface;
    final GeneralSettingsController settings =
        context.watch<GeneralSettingsController>();
    final double total = ExpenseLocalStore.totalAmount(_expenses);
    final ExpenseModel? latest = _expenses.isNotEmpty ? _expenses.first : null;
    final String totalLabel =
        _loading ? '…' : settings.formatCurrency(total);

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
                  onTap: _openAddExpense,
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
                      totalLabel,
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
            if (latest != null) ...<Widget>[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                decoration: BoxDecoration(
                  color: context.fieldFillColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            latest.category,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            latest.description,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
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
                        children: <Widget>[
                          Text(
                            latest.date,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: textColor,
                            ),
                          ),
                          Text(
                            context.tr('Date'),
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
                        children: <Widget>[
                          Text(
                            latest.amount.toStringAsFixed(1),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: textColor,
                            ),
                          ),
                          Text(
                            context.tr('Amount'),
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
      url: 'https://echallan.punjab.gov.pk/',
    ),
    _QuickLinkItem(
      title: 'Get License',
      icon: Icons.badge_outlined,
      url: 'https://dlims.punjab.gov.pk/',
    ),
    _QuickLinkItem(
      title: 'M-Tag Recharge',
      icon: Icons.toll_outlined,
      url: 'https://m-tag.com.pk/',
    ),
    _QuickLinkItem(
      title: 'Motorway Info',
      icon: Icons.directions_car_outlined,
      url: 'https://nha.gov.pk/',
    ),
    _QuickLinkItem(
      title: 'Buy Insurance',
      icon: Icons.health_and_safety_outlined,
      url: 'https://www.jubileegeneral.com.pk/motor-insurance/',
    ),
    _QuickLinkItem(
      title: 'Tow Service',
      icon: Icons.car_crash_outlined,
      url: 'https://www.google.com/search?q=car+tow+service+pakistan',
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

      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not open ${item.title}')));
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
            Divider(height: 1, thickness: 1, color: Colors.grey.shade400),
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
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
          child: Row(
            children: [
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
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
