import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../data/vehicle_data.dart';
import '../../models/vehicle_model.dart';
import '../../theme/app_theme_tokens.dart';
import '../../utils/report_date_picker.dart';
import '../../widgets/select_vehicle_dialog.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({
    super.key,
    this.title = 'Ignition Report',
  });

  final String title;

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  static const Color _accent = Color(0xFFF53D6B);
  static const Color _lightPinkColor = Color(0xFFFF7A9C);
  static const Color _fromDateColor = Color(0xFF2E7D32);
  static const Color _filterSelectedBg = Color(0xFFFFD6DE);
  static const Color _filterUnselectedBg = Color(0xFFFFF0F3);

  VehicleModel? _selectedVehicle;
  int _selectedIndex = 0;
  DateTime _fromDate = DateTime.now();
  DateTime _endDate = DateTime.now();

  final List<String> _filters = <String>[
    'Today',
    'Yesterday',
    'Week',
    'Month',
  ];

  @override
  void initState() {
    super.initState();
    _changeFilter(0);
  }

  Future<void> _showSelectVehicleDialog() async {
    final VehicleModel? result = await showDialog<VehicleModel>(
      context: context,
      builder: (BuildContext context) {
        return SelectVehicleDialog(
          initialSelected: _selectedVehicle,
          vehicles: VehicleData.vehicles,
        );
      },
    );

    if (result != null && mounted) {
      setState(() {
        _selectedVehicle = result;
      });
    }
  }

  String _formatDate(DateTime date) {
    return DateFormat('hh:mm a, dd MMM yyyy').format(date);
  }

  void _changeFilter(int index) {
    final DateTime now = DateTime.now();

    setState(() {
      _selectedIndex = index;

      switch (index) {
        case 0:
          _fromDate = DateTime(now.year, now.month, now.day);
          _endDate = now;
          break;
        case 1:
          final DateTime yesterday = now.subtract(const Duration(days: 1));
          _fromDate = DateTime(yesterday.year, yesterday.month, yesterday.day);
          _endDate = DateTime(
            yesterday.year,
            yesterday.month,
            yesterday.day,
            23,
            59,
          );
          break;
        case 2:
          _fromDate = now.subtract(const Duration(days: 7));
          _endDate = now;
          break;
        case 3:
          _fromDate = DateTime(now.year, now.month, 1);
          _endDate = now;
          break;
      }
    });
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
    });
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
    });
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

    final Color selectedFilterBg =
        isHacking ? accentColor.withValues(alpha: 0.28) : _lightPinkColor;
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
          widget.title,
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
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'export',
                child: Text('Export'),
              ),
              const PopupMenuItem<String>(
                value: 'share',
                child: Text('Share'),
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
                  : [
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
                              _selectedVehicle?.name ?? 'Search Vehicle',
                              style: TextStyle(
                                color: mutedColor,
                                fontSize: 12,
                                fontWeight: FontWeight.normal,
                              ),
                            ),
                          ),
                          if (_selectedVehicle != null)
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedVehicle = null;
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
                                ? selectedFilterBg
                                : unselectedFilterBg,
                            borderRadius: BorderRadius.circular(22),
                            child: InkWell(
                              onTap: () => _changeFilter(index),
                              borderRadius: BorderRadius.circular(22),
                              child: Container(
                                height: 28,
                                alignment: Alignment.center,
                                child: Text(
                                  _filters[index],
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
                          surfaceColor: surfaceColor,
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
                          surfaceColor: surfaceColor,
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
            child: ColoredBox(
              color: contentBg,
              child: Center(
                child: Text(
                  '${widget.title} is not available',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: accentColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
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
    required this.surfaceColor,
    required this.onTap,
  });

  final String label;
  final String value;
  final Color valueColor;
  final Color accentColor;
  final Color textColor;
  final Color surfaceColor;
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
                  label,
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
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
