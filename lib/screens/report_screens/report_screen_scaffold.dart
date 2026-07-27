import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../data/vehicle_data.dart';
import '../../models/vehicle_model.dart';
import '../../utils/report_date_picker.dart';
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
  final Widget Function(BuildContext context, VehicleModel vehicle)
      buildGeneratedContent;

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
    required this.buildGeneratedContent,
  });

  @override
  State<ReportScreenScaffold> createState() => _ReportScreenScaffoldState();
}

class _ReportScreenScaffoldState extends State<ReportScreenScaffold> {
  static const Color _pinkColor = Color(0xfff53d6b);
  static const Color _topSectionColor = Colors.white;
  static const Color _bottomSectionColor = Color(0xFFF0F0F0);

  int selectedIndex = 0;
  DateTime fromDate = DateTime.now();
  DateTime endDate = DateTime.now();
  VehicleModel? selectedVehicle;
  bool reportGenerated = false;

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
    return DateFormat('dd MMM yyyy  hh:mm a').format(date);
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
        content: Text('Exporting ${widget.title} to $label...'),
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
                  height: 35,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selected ? _pinkColor : const Color(0xffffd8df),
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
                    filters[index],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: selected ? Colors.white : _pinkColor,
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
          vehicles: VehicleData.vehicles,
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
              widget.emptyTitle,
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
                widget.emptySubtitle,
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
                  widget.detailsTitle!,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF292B32),
                  ),
                ),
                Text(
                  widget.foundLabel!,
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
          widget.buildGeneratedContent(context, selectedVehicle!),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bottomSectionColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: _topSectionColor,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: _pinkColor,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.title,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(
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
              color: _topSectionColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.22),
                  blurRadius: 20,
                  spreadRadius: 0,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.10),
                  blurRadius: 8,
                  spreadRadius: 0,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              children: [
                const SizedBox(height: 15),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: GestureDetector(
                    onTap: _showSelectVehicleDialog,
                    child: Container(
                      height: 35,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: _topSectionColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.black, width: 1),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.search_rounded,
                            color: _pinkColor,
                            size: 25,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              selectedVehicle?.name ?? 'Search Vehicle',
                              style: const TextStyle(
                                color: Colors.black54,
                                fontSize: 14,
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
                              child: const Icon(
                                Icons.clear,
                                color: Colors.grey,
                                size: 22,
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
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: Row(
                    children: [
                      Expanded(
                        child: _DatePickerCard(
                          label: 'From Date',
                          labelFontSize: 12,
                          value: formatDate(fromDate),
                          valueColor: Colors.green,
                          onTap: _pickFromDate,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _DatePickerCard(
                          label: 'End Date',
                          labelFontSize: 13,
                          value: formatDate(endDate),
                          valueColor: Colors.red,
                          onTap: _pickEndDate,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
          Expanded(
            child: ColoredBox(
              color: _bottomSectionColor,
              child: widget.showGenerateButton
                  ? Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                          child: SizedBox(
                            width: double.infinity,
                            height: 55,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                if (selectedVehicle == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Please search and select a vehicle first!',
                                      ),
                                      backgroundColor: Colors.redAccent,
                                    ),
                                  );
                                  return;
                                }

                                setState(() => reportGenerated = true);

                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      '${widget.generatedSnackMessage} ${selectedVehicle!.name}',
                                    ),
                                    backgroundColor: _pinkColor,
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _pinkColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              icon: const Icon(
                                Icons.description,
                                color: Colors.white,
                              ),
                              label: const Text(
                                'Generate Report',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: reportGenerated && selectedVehicle != null
                              ? _buildGeneratedResults()
                              : _buildEmptyContent(),
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
        color: _ReportScreenScaffoldState._topSectionColor,
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
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF292B32),
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
              const Icon(Icons.speed, size: 16, color: Colors.grey),
              const SizedBox(width: 4),
              Text(
                'Speed: ${vehicle.speed} km/h',
                style: const TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(width: 16),
              const Icon(Icons.route, size: 16, color: Colors.grey),
              const SizedBox(width: 4),
              Text(
                'Today: ${vehicle.distance}',
                style: const TextStyle(color: Colors.grey, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.location_on, size: 16, color: Colors.grey),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  vehicle.location,
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
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
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            const Icon(
              Icons.calendar_month,
              color: Color(0xfff53d6b),
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: labelFontSize,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    value,
                    style: TextStyle(
                      color: valueColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 9,
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
