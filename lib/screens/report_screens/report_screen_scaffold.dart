import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../l10n/app_l10n.dart';
import '../../theme/app_theme_tokens.dart';

import '../../data/vehicle_data.dart';
import '../../models/vehicle_model.dart';
import '../../services/tracking_api_service.dart';
import '../../services/vehicle_service.dart';
import '../../utils/live_location_text.dart';
import '../../utils/report_date_picker.dart';
import '../../utils/report_response_parser.dart';
import '../../widgets/report_export_dialog.dart';
import '../../widgets/select_vehicle_dialog.dart';

class ReportScreenScaffold extends StatefulWidget {
  final String title;
  final IconData? emptyIcon;
  final String emptyTitle;
  final String emptySubtitle;
  final String generatedSnackMessage;
  final String? detailsTitle;
  final String? foundLabel;
  final bool showResultsHeader;
  final int reportId;
  /// Shown when a vehicle is selected but the API returned no rows.
  final String? noDataMessage;
  final Map<String, dynamic>? reportExtra;
  final Widget Function(
    BuildContext context,
    VehicleModel vehicle,
    Map<String, dynamic>? reportData,
  ) buildGeneratedContent;

  const ReportScreenScaffold({
    super.key,
    required this.title,
    this.emptyIcon,
    required this.emptyTitle,
    this.emptySubtitle = '',
    required this.generatedSnackMessage,
    this.detailsTitle,
    this.foundLabel,
    this.showResultsHeader = true,
    required this.reportId,
    this.reportExtra,
    this.noDataMessage,
    required this.buildGeneratedContent,
  });

  @override
  State<ReportScreenScaffold> createState() => _ReportScreenScaffoldState();
}

class _ReportScreenScaffoldState extends State<ReportScreenScaffold> {
  static const Color _pinkColor = Color(0xfff53d6b);
  static const Color _lightPinkColor = Color(0xffff7a9c);
  static const Color _filterUnselectedBg = Color(0xFFFFF0F3);
  static const Color _fromDateColor = Color.fromARGB(255, 46, 125, 50);
    
  int selectedIndex = 0;
  DateTime fromDate = DateTime.now();
  DateTime endDate = DateTime.now();
  VehicleModel? selectedVehicle;
  bool reportGenerated = false;
  bool isGenerating = false;
  Map<String, dynamic>? reportData;
  String? reportError;
  List<VehicleModel> vehicles = VehicleData.vehicles;

  final List<String> filters = const [
    'Today',
    'Yesterday',
    'Week',
    'Month',
  ];

  @override
  void initState() {
    super.initState();
    _setFilterDates(0);
    _loadVehicles();
  }

  Future<void> _loadVehicles() async {
    final List<VehicleModel> fetched =
        await VehicleService.getDevices(forceRefresh: false);
    if (!mounted) {
      return;
    }
    setState(() {
      vehicles = fetched.isNotEmpty ? fetched : VehicleData.vehicles;
    });
  }

  Future<void> _generateReport() async {
    if (selectedVehicle == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.tr('Please search and select a vehicle first!'),
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (selectedVehicle!.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr('Selected vehicle has no device ID')),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() {
      isGenerating = true;
      reportError = null;
    });

    final dynamic response = await TrackingApiService.generateReport(
      reportId: widget.reportId,
      deviceId: selectedVehicle!.id!,
      from: _formatApiDate(fromDate),
      to: _formatApiDate(endDate),
      extra: widget.reportExtra,
    );

    if (!mounted) {
      return;
    }

    if (response == null) {
      setState(() {
        isGenerating = false;
        reportGenerated = false;
        reportData = null;
        reportError = context.tr('Could not load report');
      });
      return;
    }

    setState(() {
      isGenerating = false;
      reportGenerated = true;
      reportData = ReportResponseParser.asReportMap(response);
      reportError = null;
    });
  }

  String _formatApiDate(DateTime date) {
    return DateFormat('yyyy-MM-dd HH:mm:ss').format(date);
  }

  Future<void> _pickFromDate() async {
    final DateTime? picked = await ReportDatePicker.pickDateTime(
      context,
      initialDate: fromDate,
    );

    if (picked == null || !mounted) {
      return;
    }

    setState(() {
      fromDate = picked;
      selectedIndex = -1;
      reportGenerated = false;
      reportData = null;
      reportError = null;
    });
    if (selectedVehicle != null) {
      await _generateReport();
    }
  }

  Future<void> _pickEndDate() async {
    final DateTime? picked = await ReportDatePicker.pickDateTime(
      context,
      initialDate: endDate,
    );

    if (picked == null || !mounted) {
      return;
    }

    setState(() {
      endDate = picked;
      selectedIndex = -1;
      reportGenerated = false;
      reportData = null;
      reportError = null;
    });
    if (selectedVehicle != null) {
      await _generateReport();
    }
  }

  void _setFilterDates(int index) {
    selectedIndex = index;
    final DateTime now = DateTime.now();

    switch (index) {
      case 0:
        fromDate = DateTime(now.year, now.month, now.day);
        endDate = now;
        break;
      case 1:
        final DateTime yesterday = now.subtract(const Duration(days: 1));
        fromDate = DateTime(yesterday.year, yesterday.month, yesterday.day);
        endDate = DateTime(
          yesterday.year,
          yesterday.month,
          yesterday.day,
          23,
          59,
        );
        break;
      case 2:
        final DateTime weekAgo = now.subtract(const Duration(days: 7));
        fromDate = DateTime(weekAgo.year, weekAgo.month, weekAgo.day);
        endDate = now;
        break;
      case 3:
        fromDate = DateTime(now.year, now.month, 1);
        endDate = now;
        break;
    }
  }

  Future<void> _changeFilter(int index) async {
    setState(() {
      _setFilterDates(index);
      reportGenerated = false;
      reportData = null;
      reportError = null;
    });
    if (selectedVehicle != null) {
      await _generateReport();
    }
  }

  String formatDate(DateTime date) {
    return DateFormat('dd MMM yyyy hh:mm a').format(date);
  }

  Future<void> _showExportDialog() async {
    final ReportExportType? exportType = await ReportExportDialog.show(context);

    if (exportType == null || !mounted) {
      return;
    }

    final String label =
        exportType == ReportExportType.excel ? 'Excel' : 'PDF';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          context.trp('Exporting {title} to {label}...', {
            'title': context.tr(widget.title),
            'label': label,
          }),
        ),
        backgroundColor: _pinkColor,
      ),
    );
  }

  Widget _buildFilterChips() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: List.generate(filters.length, (index) {
          final bool selected = selectedIndex == index;

          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                right: index < filters.length - 1 ? 8 : 0,
              ),
              child: GestureDetector(
                onTap: () => _changeFilter(index),
                child: Container(
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selected ? _pinkColor : _filterUnselectedBg,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        blurRadius: 8,
                        color: Colors.black.withValues(alpha: 0.08),
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Text(
                    context.tr(filters[index]),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight:
                          selected ? FontWeight.w700 : FontWeight.w400,
                      color: selected
                          ? Colors.white
                          : _pinkColor.withValues(alpha: 0.85),
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Future<void> _showSelectVehicleDialog() async {
    final VehicleModel? result = await showDialog<VehicleModel>(
      context: context,
      builder: (BuildContext context) {
        return SelectVehicleDialog(
          initialSelected: selectedVehicle,
          vehicles: vehicles,
        );
      },
    );

    if (result != null && mounted) {
      setState(() {
        selectedVehicle = result;
        reportGenerated = false;
        reportData = null;
        reportError = null;
      });
      await _generateReport();
    }
  }

  Widget _buildBodyContent() {
    final Color accentColor = _pinkColor;
    final Color mutedColor = context.mutedTextColor;

    if (selectedVehicle == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            context.tr('Search and select a vehicle to view report'),
            textAlign: TextAlign.center,
            style: TextStyle(color: mutedColor, fontSize: 14),
          ),
        ),
      );
    }

    if (isGenerating) {
      return Center(
        child: CircularProgressIndicator(color: accentColor),
      );
    }

    if (reportError != null) {
      return Center(
        child: Text(
          reportError!,
          style: TextStyle(color: Colors.red.shade700),
        ),
      );
    }

    if (!reportGenerated) {
      return Center(
        child: CircularProgressIndicator(color: accentColor),
      );
    }

    final bool hasApiItems =
        ReportResponseParser.rowsFromResponse(reportData).isNotEmpty;
    if (!hasApiItems && widget.noDataMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            context.tr(widget.noDataMessage!),
            textAlign: TextAlign.center,
            style: TextStyle(color: mutedColor, fontSize: 14),
          ),
        ),
      );
    }

    return _buildGeneratedResults();
  }

  Widget _buildEmptyContent() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (widget.emptyIcon != null) ...[
              Icon(
                widget.emptyIcon,
                size: 70,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 15),
            ],
            Text(
              context.tr(widget.emptyTitle),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
            ),
            if (widget.emptySubtitle.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                context.tr(widget.emptySubtitle),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 13,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildGeneratedResults() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.showResultsHeader &&
              widget.detailsTitle != null &&
              widget.foundLabel != null) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  context.tr(widget.detailsTitle!),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: context.textColor,
                  ),
                ),
                Text(
                  '${ReportResponseParser.itemCount(reportData)} ${context.tr(widget.foundLabel!)}',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
          ],
          widget.buildGeneratedContent(context, selectedVehicle!, reportData),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isHacking = context.isHackingTheme;
    final Color surfaceColor = context.containerColor;
    final Color contentBg = isHacking
        ? Colors.transparent
        : const Color(0xFFF3F3F3);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: isHacking ? Colors.transparent : Colors.white,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: _pinkColor,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          context.tr(widget.title),
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.more_vert,
              color: _pinkColor,
            ),
            onPressed: _showExportDialog,
          ),
        ],
      ),
      body: Column(
        children: [
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
              children: [
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
                                  _pinkColor.withValues(alpha: 0.45))
                              : const Color(0xFF555555),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.search_rounded,
                            color: _pinkColor,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              selectedVehicle?.name ?? context.tr('Search Vehicle'),
                              style: TextStyle(
                                color: context.mutedTextColor,
                                fontSize: 12,
                                fontWeight: FontWeight.normal,
                              ),
                            ),
                          ),
                          if (selectedVehicle != null)
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  selectedVehicle = null;
                                  reportGenerated = false;
                                  reportData = null;
                                  reportError = null;
                                  isGenerating = false;
                                });
                              },
                              child: Icon(
                                Icons.clear,
                                color: Colors.grey,
                                size: 16,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                _buildFilterChips(),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: _DatePickerCard(
                          label: context.tr('From Date'),
                          labelFontSize: 12,
                          value: formatDate(fromDate),
                          valueColor: isHacking
                              ? const Color(0xFF00E676)
                              : _fromDateColor,
                          onTap: _pickFromDate,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _DatePickerCard(
                          label: context.tr('End Date'),
                          labelFontSize: 12,
                          value: formatDate(endDate),
                          valueColor: _pinkColor,
                          onTap: _pickEndDate,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Bottom dark-grey blur under the white top container
          IgnorePointer(
            child: Container(
              height: 12,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF5A5A5A).withValues(alpha: 0.28),
                    const Color(0xFF5A5A5A).withValues(alpha: 0.10),
                    const Color(0xFF5A5A5A).withValues(alpha: 0.0),
                  ],
                  stops: const [0.0, 0.45, 1.0],
                ),
              ),
            ),
          ),
          Expanded(
            child: ColoredBox(
              color: contentBg,
              child: _buildBodyContent(),
            ),
          ),
        ],
      ),
    );
  }
}

class _SelectedVehicleCard extends StatelessWidget {
  final VehicleModel vehicle;

  const _SelectedVehicleCard({required this.vehicle});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.containerColor,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xffffd8df), width: 1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xfff53d6b).withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.directions_car_rounded,
                    color: vehicle.color,
                    size: 30,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    vehicle.name,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: context.textColor,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: vehicle.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  vehicle.status,
                  style: TextStyle(
                    color: vehicle.color,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.speed, size: 16, color: Colors.grey),
              const SizedBox(width: 4),
              Text(
                '${context.tr('Speed')}: ${vehicle.speed} km/h',
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(width: 16),
              Icon(Icons.route, size: 16, color: Colors.grey),
              const SizedBox(width: 4),
              Text(
                '${context.tr('Today')}: ${vehicle.distance}',
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.location_on, size: 16, color: Colors.grey),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  LiveLocationText.forVehicle(vehicle),
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DatePickerCard extends StatelessWidget {
  final String label;
  final double labelFontSize;
  final String value;
  final Color valueColor;
  final VoidCallback onTap;

  const _DatePickerCard({
    required this.label,
    required this.labelFontSize,
    required this.value,
    required this.valueColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 4),
              child: Icon(
                Icons.calendar_month,
                color: Color(0xfff53d6b),
                size: 34,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: labelFontSize,
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
      ),
    );
  }
}
