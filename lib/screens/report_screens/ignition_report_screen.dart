import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../data/vehicle_data.dart';
import '../../l10n/app_l10n.dart';
import '../../models/ignition_report_event.dart';
import '../../models/vehicle_model.dart';
import '../../services/ignition_report_service.dart';
import '../../services/vehicle_service.dart';
import '../../theme/app_theme_tokens.dart';
import '../../utils/coordinate_parser.dart';
import '../../utils/report_date_picker.dart';
import '../../utils/report_period.dart';
import '../../widgets/select_vehicle_dialog.dart';
import 'ignition_report_map_screen.dart';
import 'report_content_widgets.dart';

class IgnitionReportScreen extends StatefulWidget {
  const IgnitionReportScreen({super.key});

  @override
  State<IgnitionReportScreen> createState() => _IgnitionReportScreenState();
}

class _IgnitionReportScreenState extends State<IgnitionReportScreen> {
  static const Color _accent = Color(0xFFF53D6B);
  static const Color _filterUnselectedBg = Color(0xFFFFF0F3);
  static const Color _fromDateColor = Color.fromARGB(255, 46, 125, 50);

  VehicleModel? _selectedVehicle;
  bool _loadAllVehicles = false;
  int _selectedIndex = 3;
  DateTime _fromDate = DateTime.now();
  DateTime _endDate = DateTime.now();

  bool _isLoading = false;
  String? _loadError;
  List<IgnitionReportEvent> _events = <IgnitionReportEvent>[];
  List<VehicleModel> _vehicles = VehicleData.vehicles;

  final List<String> _filters = <String>[
    'Today',
    'Yesterday',
    'Week',
    'Month',
  ];

  @override
  void initState() {
    super.initState();
    _applyPeriod(3);
    _loadVehicles();
  }

  Future<void> _loadVehicles() async {
    final List<VehicleModel> fetched =
        await VehicleService.getDevices(forceRefresh: false);
    if (!mounted) {
      return;
    }
    setState(() {
      _vehicles = fetched.isNotEmpty ? fetched : VehicleData.vehicles;
    });
  }

  Future<void> _showSelectVehicleDialog() async {
    final VehicleModel? result = await showDialog<VehicleModel>(
      context: context,
      builder: (BuildContext context) {
        return SelectVehicleDialog(
          initialSelected: _selectedVehicle,
          vehicles: _vehicles,
        );
      },
    );

    if (result != null && mounted) {
      setState(() {
        _selectedVehicle = result;
        _loadAllVehicles = false;
      });
      await _loadReport();
    }
  }

  String _searchFieldLabel(BuildContext context) {
    if (_loadAllVehicles) {
      final List<String> names = _vehicles
          .map((VehicleModel v) => v.name)
          .where((String n) => n.trim().isNotEmpty)
          .take(4)
          .toList();
      if (names.isEmpty) {
        return context.tr('All vehicles');
      }
      final String joined = names.join(', ');
      if (_vehicles.length > names.length) {
        return '$joined, …';
      }
      return joined;
    }
    return _selectedVehicle?.name ?? context.tr('Search Vehicle');
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd MMM yyyy hh:mm a').format(date);
  }

  void _applyPeriod(int index) {
    final ({DateTime from, DateTime to}) period =
        ReportPeriod.rangeForChip(index, DateTime.now());
    _fromDate = period.from;
    _endDate = period.to;
    _selectedIndex = index;
  }

  Future<void> _changeFilter(int index) async {
    setState(() {
      _applyPeriod(index);
      _events = <IgnitionReportEvent>[];
    });
    if (_selectedVehicle != null || _loadAllVehicles) {
      await _loadReport();
    }
  }

  Future<void> _pickFromDate() async {
    final DateTime? picked = await AppDateTimePicker.pickDateTime(
      context,
      initialDate: _fromDate,
    );
    if (picked == null || !mounted) {
      return;
    }
    setState(() {
      _fromDate = picked;
      _selectedIndex = -1;
    });
    if (_selectedVehicle != null || _loadAllVehicles) {
      await _loadReport();
    }
  }

  Future<void> _pickEndDate() async {
    final DateTime? picked = await AppDateTimePicker.pickDateTime(
      context,
      initialDate: _endDate,
    );
    if (picked == null || !mounted) {
      return;
    }
    setState(() {
      _endDate = picked;
      _selectedIndex = -1;
    });
    if (_selectedVehicle != null || _loadAllVehicles) {
      await _loadReport();
    }
  }

  Future<void> _loadAllVehiclesReport() async {
    setState(() {
      _loadAllVehicles = true;
      _selectedVehicle = null;
    });
    await _loadReport();
  }

  Future<void> _loadReport() async {
    if (!_loadAllVehicles && _selectedVehicle == null) {
      return;
    }

    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      final DateTime from = ReportPeriod.startOfDay(_fromDate);
      final DateTime to = _endDate.hour == 0 &&
              _endDate.minute == 0 &&
              _endDate.second == 0
          ? ReportPeriod.endOfDay(_endDate)
          : _endDate;

      final List<IgnitionReportEvent> events = _loadAllVehicles
          ? await IgnitionReportService.loadEventsForFleet(
              vehicles: _vehicles,
              from: from,
              to: to,
            )
          : await IgnitionReportService.loadEvents(
              vehicle: _selectedVehicle!,
              from: from,
              to: to,
            );

      if (!mounted) {
        return;
      }

      setState(() {
        _events = events;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoading = false;
        _loadError = context.tr('Could not load report');
        _events = <IgnitionReportEvent>[];
      });
    }
  }

  void _openEventOnMap(IgnitionReportEvent event) {
    final (double lat, double lng)? coords = CoordinateParser.fromMap(
      <String, dynamic>{'lat': event.latitude, 'lng': event.longitude},
    );
    if (coords == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr('Location not available for this event')),
        ),
      );
      return;
    }

    Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (BuildContext context) =>
            IgnitionReportMapScreen(event: event),
      ),
    );
  }

  Widget _buildBodyContent({
    required Color accentColor,
    required Color mutedColor,
    required Color contentBg,
  }) {
    if (_selectedVehicle == null && !_loadAllVehicles) {
      return Center(
        child: Text(
          context.tr('Search and select a vehicle to view report'),
          textAlign: TextAlign.center,
          style: TextStyle(color: mutedColor, fontSize: 14),
        ),
      );
    }

    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(color: accentColor),
      );
    }

    if (_loadError != null) {
      return Center(
        child: Text(
          _loadError!,
          style: TextStyle(color: Colors.red.shade700),
        ),
      );
    }

    if (_events.isEmpty) {
      return Center(
        child: Text(
          context.tr('No ignition events in this period'),
          textAlign: TextAlign.center,
          style: TextStyle(color: mutedColor, fontSize: 14),
        ),
      );
    }

    return ColoredBox(
      color: contentBg,
      child: ListView.separated(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
        itemCount: _events.length + 1,
        separatorBuilder: (BuildContext context, int index) =>
            const SizedBox(height: 10),
        itemBuilder: (BuildContext context, int index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(4, 0, 4, 4),
              child: Text(
                '${_events.length} ${context.tr('Events Found')}',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: accentColor,
                ),
              ),
            );
          }

          final IgnitionReportEvent event = _events[index - 1];
          return IgnitionReportCard(
            vehicleName: event.vehicleName,
            timeLabel: event.timeLabel,
            statusLabel: event.statusLabel,
            isOn: event.isOn,
            address: event.address,
            onTap: () => _openEventOnMap(event),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isHacking = context.isHackingTheme;
    final Color accentColor =
        isHacking ? theme.colorScheme.primary : _accent;
    final Color textColor = context.textColor;
    final Color mutedColor = context.mutedTextColor;
    final Color scaffoldBg = theme.scaffoldBackgroundColor;
    final Color surfaceColor = context.containerColor;
    final Color contentBg = isHacking
        ? Colors.transparent
        : const Color(0xFFF3F3F3);

    final Color unselectedFilterBg =
        isHacking ? accentColor.withValues(alpha: 0.10) : _filterUnselectedBg;
    final Color fromValueColor =
        isHacking ? const Color(0xFF00E676) : _fromDateColor;

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: isHacking ? Colors.transparent : Colors.white,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: accentColor,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          context.tr('Ignition Report'),
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        actions: <Widget>[
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: accentColor),
            color: surfaceColor,
            onSelected: (String value) async {
              if (value == 'all_vehicles') {
                await _loadAllVehiclesReport();
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              PopupMenuItem<String>(
                value: 'all_vehicles',
                child: Text(context.tr('All vehicles')),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: isHacking ? Colors.transparent : Colors.white,
              boxShadow: isHacking
                  ? null
                  : <BoxShadow>[
                      BoxShadow(
                        color: const Color(0xFF4A4A4A).withValues(alpha: 0.40),
                        blurRadius: 14,
                        spreadRadius: 0,
                        offset: const Offset(0, 6),
                      ),
                    ],
            ),
            child: Column(
              children: <Widget>[
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: GestureDetector(
                    onTap: _showSelectVehicleDialog,
                    child: Container(
                      height: 30,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: surfaceColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isHacking
                              ? (context.appTokens.containerBorderColor ??
                                  accentColor.withValues(alpha: 0.45))
                              : const Color(0xFF555555),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: <Widget>[
                          Icon(
                            Icons.search_rounded,
                            color: accentColor,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _searchFieldLabel(context),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: mutedColor,
                                fontSize: 12,
                                fontWeight: FontWeight.normal,
                              ),
                            ),
                          ),
                          if (_selectedVehicle != null || _loadAllVehicles)
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedVehicle = null;
                                  _loadAllVehicles = false;
                                  _events = <IgnitionReportEvent>[];
                                  _loadError = null;
                                });
                              },
                              child: Icon(
                                Icons.clear,
                                color: mutedColor,
                                size: 16,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Row(
                    children: List<Widget>.generate(_filters.length, (int index) {
                      final bool selected = _selectedIndex == index;

                      return Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(
                            right: index == _filters.length - 1 ? 0 : 8,
                          ),
                          child: Material(
                            color: selected
                                ? accentColor
                                : unselectedFilterBg,
                            borderRadius: BorderRadius.circular(22),
                            child: InkWell(
                              onTap: () => _changeFilter(index),
                              borderRadius: BorderRadius.circular(22),
                              child: Container(
                                height: 28,
                                alignment: Alignment.center,
                                child: Text(
                                  context.tr(_filters[index]),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: selected
                                        ? FontWeight.w700
                                        : FontWeight.w400,
                                    color: selected
                                        ? Colors.white
                                        : accentColor.withValues(alpha: 0.85),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: _DateCard(
                          label: 'From Date',
                          value: _formatDate(_fromDate),
                          valueColor: fromValueColor,
                          accentColor: accentColor,
                          textColor: textColor,
                          onTap: _pickFromDate,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _DateCard(
                          label: 'End Date',
                          value: _formatDate(_endDate),
                          valueColor: accentColor,
                          accentColor: accentColor,
                          textColor: textColor,
                          onTap: _pickEndDate,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _buildBodyContent(
              accentColor: accentColor,
              mutedColor: mutedColor,
              contentBg: contentBg,
            ),
          ),
        ],
      ),
    );
  }
}

class _DateCard extends StatelessWidget {
  const _DateCard({
    required this.label,
    required this.value,
    required this.valueColor,
    required this.accentColor,
    required this.textColor,
    required this.onTap,
  });

  final String label;
  final String value;
  final Color valueColor;
  final Color accentColor;
  final Color textColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Icon(
              Icons.calendar_month,
              color: accentColor,
              size: 34,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  context.tr(label),
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: valueColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 10,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
