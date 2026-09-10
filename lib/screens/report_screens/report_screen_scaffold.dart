import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../l10n/app_l10n.dart';
import '../../theme/app_theme_tokens.dart';

import '../../data/vehicle_data.dart';
import '../../models/vehicle_model.dart';
import '../../services/tracking_api_service.dart';
import '../../services/vehicle_service.dart';
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
  final bool showGenerateButton;
  final int reportId;
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
    this.showGenerateButton = false,
    required this.reportId,
    this.reportExtra,
    required this.buildGeneratedContent,
  });

  @override
  State<ReportScreenScaffold> createState() => _ReportScreenScaffoldState();
}

class _ReportScreenScaffoldState extends State<ReportScreenScaffold> {
  static const Color _pinkColor = Color(0xfff53d6b);
  static const Color _lightPinkColor = Color(0xffff7a9c);
    
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

    final Map<String, dynamic>? response = await TrackingApiService.generateReport(
      reportId: widget.reportId,
      deviceId: selectedVehicle!.id!,
      from: _formatApiDate(fromDate),
      to: _formatApiDate(endDate),
      extra: widget.reportExtra,
    );

    if (!mounted) {
      return;
    }

    if (response == null || response.isEmpty) {
      setState(() {
        isGenerating = false;
        reportGenerated = false;
        reportError = context.tr('Could not generate report');
      });
      return;
    }

    setState(() {
      isGenerating = false;
      reportGenerated = true;
      reportData = response;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${widget.generatedSnackMessage} ${selectedVehicle!.name}',
        ),
        backgroundColor: _pinkColor,
      ),
    );
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

    setState(() => fromDate = picked);
  }

  Future<void> _pickEndDate() async {
    final DateTime? picked = await ReportDatePicker.pickDateTime(
      context,
      initialDate: endDate,
    );

    if (picked == null || !mounted) {
      return;
    }

    setState(() => endDate = picked);
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

  void _changeFilter(int index) {
    setState(() => _setFilterDates(index));
  }

  String formatDate(DateTime date) {
    return DateFormat('hh:mm a, dd MMM yyyy').format(date);
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
                    color: selected
                        ? _lightPinkColor
                        : const Color(0xffffd8df),
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

    if (result != null) {
      setState(() {
        selectedVehicle = result;
        reportGenerated = false;
      });
    }
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
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Theme.of(context).cardColor,
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
          Material(
            color: context.containerColor,
            elevation: 0,
            child: Column(
              children: [
                const SizedBox(height: 15),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: GestureDetector(
                    onTap: _showSelectVehicleDialog,
                    child: Container(
                      height: 30,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: context.containerColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: context.textColor, width: 1),
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
                if (selectedVehicle != null) ...[
                  const SizedBox(height: 15),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _SelectedVehicleCard(vehicle: selectedVehicle!),
                  ),
                ],
                const SizedBox(height: 10),
                _buildFilterChips(),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: Row(
                    children: [
                      Expanded(
                        child: _DatePickerCard(
                          label: context.tr('From Date'),
                          labelFontSize: 12,
                          value: formatDate(fromDate),
                          valueColor: Colors.green,
                          onTap: _pickFromDate,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _DatePickerCard(
                          label: context.tr('End Date'),
                          labelFontSize: 12,
                          value: formatDate(endDate),
                          valueColor: Colors.red,
                          onTap: _pickEndDate,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
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
              color: Theme.of(context).scaffoldBackgroundColor,
              child: widget.showGenerateButton
                  ? Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                          child: SizedBox(
                            width: double.infinity,
                            height: 55,
                            child: ElevatedButton.icon(
                              onPressed: isGenerating ? null : _generateReport,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _pinkColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              icon: isGenerating
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.description,
                                      color: Colors.white,
                                    ),
                              label: Text(
                                context.tr(
                                  isGenerating
                                      ? 'Generating...'
                                      : 'Generate Report',
                                ),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: reportError != null
                              ? Center(
                                  child: Text(
                                    reportError!,
                                    style: TextStyle(color: Colors.red.shade700),
                                  ),
                                )
                              : (reportGenerated && selectedVehicle != null
                                  ? _buildGeneratedResults()
                                  : _buildEmptyContent()),
                        ),
                      ],
                    )
                  : (reportGenerated && selectedVehicle != null
                      ? _buildGeneratedResults()
                      : _buildEmptyContent()),
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
                  vehicle.location,
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
