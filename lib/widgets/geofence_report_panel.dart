import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/vehicle_data.dart';
import '../l10n/app_l10n.dart';
import '../models/geofence_report_event.dart';
import '../models/vehicle_model.dart';
import '../screens/report_screens/geofence_report_map_screen.dart';
import '../screens/report_screens/report_content_widgets.dart';
import '../services/geofence_report_service.dart';
import '../services/vehicle_service.dart';
import '../theme/app_theme_tokens.dart';
import '../utils/report_date_picker.dart';
import '../utils/report_period.dart';
import '../widgets/select_vehicle_dialog.dart';

/// Over-speed-style geofence report: search, filters, auto load, event cards.
class GeofenceReportPanel extends StatefulWidget {
  const GeofenceReportPanel({super.key});

  @override
  State<GeofenceReportPanel> createState() => _GeofenceReportPanelState();
}

class _GeofenceReportPanelState extends State<GeofenceReportPanel> {
  static const Color _accent = Color(0xFFF53D6B);
  static const Color _filterUnselectedBg = Color(0xFFFFF0F3);
  static const Color _fromDateColor = Color.fromARGB(255, 46, 125, 50);

  VehicleModel? _selectedVehicle;
  int _selectedIndex = 3;
  DateTime _fromDate = DateTime.now();
  DateTime _endDate = DateTime.now();

  bool _isLoading = false;
  String? _loadError;
  List<GeofenceReportEvent> _events = <GeofenceReportEvent>[];
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
        _events = <GeofenceReportEvent>[];
      });
      await _loadReport();
    }
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
      _events = <GeofenceReportEvent>[];
    });
    if (_selectedVehicle != null) {
      await _loadReport();
    }
  }

  Future<void> _pickFromDate() async {
    final DateTime? picked = await ReportDatePicker.pickDateTime(
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
    if (_selectedVehicle != null) {
      await _loadReport();
    }
  }

  Future<void> _pickEndDate() async {
    final DateTime? picked = await ReportDatePicker.pickDateTime(
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
    if (_selectedVehicle != null) {
      await _loadReport();
    }
  }

  Future<void> _loadReport() async {
    final VehicleModel? vehicle = _selectedVehicle;
    if (vehicle == null) {
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

      final List<GeofenceReportEvent> events =
          await GeofenceReportService.loadEvents(
        vehicle: vehicle,
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
        _events = <GeofenceReportEvent>[];
      });
    }
  }

  void _openEventOnMap(GeofenceReportEvent event) {
    Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (BuildContext context) =>
            GeofenceReportMapScreen(event: event),
      ),
    );
  }

  Widget _buildBodyContent({
    required Color accentColor,
    required Color mutedColor,
    required Color contentBg,
  }) {
    if (_selectedVehicle == null) {
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
          context.tr('No geofence events in this period'),
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
        itemCount: _events.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (BuildContext context, int index) {
          final GeofenceReportEvent event = _events[index];
          return GeofenceReportCard(
            vehicleName: event.vehicleName,
            timeLabel: event.timeLabel,
            statusLabel: event.statusLabel,
            isEnter: event.isEnter,
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
    final Color surfaceColor = context.containerColor;
    final Color contentBg =
        isHacking ? Colors.transparent : const Color(0xFFF3F3F3);
    final Color unselectedFilterBg =
        isHacking ? accentColor.withValues(alpha: 0.10) : _filterUnselectedBg;
    final Color fromValueColor =
        isHacking ? const Color(0xFF00E676) : _fromDateColor;

    return Column(
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
                            _selectedVehicle?.name ??
                                context.tr('Search Vehicle'),
                            style: TextStyle(
                              color: mutedColor,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        if (_selectedVehicle != null)
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedVehicle = null;
                                _events = <GeofenceReportEvent>[];
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
                          color: selected ? accentColor : unselectedFilterBg,
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
                      child: _GeofenceReportDateCard(
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
                      child: _GeofenceReportDateCard(
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
    );
  }
}

class _GeofenceReportDateCard extends StatelessWidget {
  const _GeofenceReportDateCard({
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
            child: Icon(Icons.calendar_month, color: accentColor, size: 34),
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
