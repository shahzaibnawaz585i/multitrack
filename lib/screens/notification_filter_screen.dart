import 'package:flutter/material.dart';

import '../../theme/app_theme_tokens.dart';

class NotificationFilterResult {
  final Set<String> eventTypes;
  final Set<String> vehicles;
  final String datePreset;
  final DateTime startDate;
  final DateTime endDate;

  const NotificationFilterResult({
    required this.eventTypes,
    required this.vehicles,
    required this.datePreset,
    required this.startDate,
    required this.endDate,
  });
}

class NotificationFilterScreen extends StatefulWidget {
  final bool vehicleOnly;

  const NotificationFilterScreen({
    super.key,
    this.vehicleOnly = false,
  });

  @override
  State<NotificationFilterScreen> createState() =>
      _NotificationFilterScreenState();
}

class _NotificationFilterScreenState extends State<NotificationFilterScreen> {
  static const Color _accent = Color(0xFFF53259);
  static const Color _lightBlueHeader = Color(0xFFEAF4FB);
  static const Color _checkboxEmpty = Color(0xFFEBEBEB);
  static const Color _checkboxBorder = Color(0xFFE0E0E0);
  static const double _sidebarWidth = 96;
  static const double _bottomBarHeight = 60;

  static const List<String> _eventTypes = <String>[
    'All Event',
    'Command Result',
    'Device Online',
    'Device Unknown',
    'Device Offline',
    'Device Inactive',
    'Device Moving',
    'Device Stopped',
    'Device OverSpeed',
    'Device FuelDrop',
    'Device FuelIncrease',
    'Geofence Enter',
    'Geofence Exit',
    'Alarm',
    'Ignition On',
    'Ignition Off',
    'Maintenance',
    'Over StopLimit',
    'Over IdleLimit',
    'Text Message',
    'Driver Changed',
    'Media',
    'AC On',
    'AC Off',
    'Device Document Expired',
  ];

  static const List<String> _vehicleIds = <String>[
    'BR09GB6140',
    'KL45Q8460',
    'PB11DD9661',
    'MH12RK8741',
    'TN37BR5099',
    '5612',
    '68080',
  ];

  static const List<String> _datePresets = <String>[
    'Today',
    'Yesterday',
    'Week',
    'Month',
  ];

  int _selectedTab = 0;
  String _vehicleQuery = '';
  String _selectedDatePreset = 'Today';
  bool _isHeaderBlue = false;
  late DateTime _startDate;
  late DateTime _endDate;

  late final Set<String> _selectedEvents;
  late final Set<String> _selectedVehicles;
  late final ScrollController _eventScrollController;
  late final ScrollController _vehicleScrollController;
  late final ScrollController _dateScrollController;

  @override
  void initState() {
    super.initState();
    _selectedEvents = <String>{'All Event'};
    _selectedVehicles = <String>{};
    _eventScrollController = ScrollController()..addListener(_handleScroll);
    _vehicleScrollController = ScrollController()..addListener(_handleScroll);
    _dateScrollController = ScrollController()..addListener(_handleScroll);
    _startDate = DateTime(2026, 7, 25);
    _endDate = DateTime(2026, 7, 25, 18, 55);
  }

  @override
  void dispose() {
    _eventScrollController.dispose();
    _vehicleScrollController.dispose();
    _dateScrollController.dispose();
    super.dispose();
  }

  ScrollController get _activeScrollController {
    if (widget.vehicleOnly) {
      return _vehicleScrollController;
    }

    switch (_selectedTab) {
      case 1:
        return _vehicleScrollController;
      case 2:
        return _dateScrollController;
      case 0:
      default:
        return _eventScrollController;
    }
  }

  void _handleScroll() {
    final ScrollController controller = _activeScrollController;
    if (!controller.hasClients) {
      return;
    }

    final bool shouldBeBlue = controller.offset > 0;
    if (shouldBeBlue != _isHeaderBlue) {
      setState(() => _isHeaderBlue = shouldBeBlue);
    }
  }

  void _selectTab(int index) {
    if (_selectedTab == index) {
      return;
    }

    setState(() {
      _selectedTab = index;
      _isHeaderBlue = false;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ScrollController controller = _activeScrollController;
      if (controller.hasClients) {
        controller.jumpTo(0);
      }
    });
  }

  Future<void> _scrollDownOnEventTap() async {
    final ScrollController controller = _activeScrollController;
    if (!controller.hasClients) {
      return;
    }

    final double target = (controller.offset + 36)
        .clamp(0.0, controller.position.maxScrollExtent);

    await controller.animateTo(
      target,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
    );
  }

  List<String> get _filteredVehicles {
    if (_vehicleQuery.trim().isEmpty) {
      return _vehicleIds;
    }

    final String query = _vehicleQuery.trim().toLowerCase();
    return _vehicleIds
        .where((id) => id.toLowerCase().contains(query))
        .toList(growable: false);
  }

  void _toggleEvent(String event) {
    setState(() {
      if (event == 'All Event') {
        _selectedEvents
          ..clear()
          ..add('All Event');
        return;
      }

      _selectedEvents.remove('All Event');

      if (_selectedEvents.contains(event)) {
        _selectedEvents.remove(event);
      } else {
        _selectedEvents.add(event);
      }

      if (_selectedEvents.isEmpty) {
        _selectedEvents.add('All Event');
      }
    });
    _scrollDownOnEventTap();
  }

  void _toggleVehicle(String vehicleId) {
    setState(() {
      if (_selectedVehicles.contains(vehicleId)) {
        _selectedVehicles.remove(vehicleId);
      } else {
        _selectedVehicles.add(vehicleId);
      }
    });
    _scrollDownOnEventTap();
  }

  Future<void> _pickDateTime({required bool isStart}) async {
    final DateTime initial = isStart ? _startDate : _endDate;

    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (pickedDate == null || !mounted) {
      return;
    }

    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );

    if (pickedTime == null || !mounted) {
      return;
    }

    final DateTime combined = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    setState(() {
      if (isStart) {
        _startDate = combined;
      } else {
        _endDate = combined;
      }
      _selectedDatePreset = '';
    });
  }

  String _formatPickerDate(DateTime value) {
    final int hour12 = value.hour % 12 == 0 ? 12 : value.hour % 12;
    final String minute = value.minute.toString().padLeft(2, '0');
    final String period = value.hour >= 12 ? 'PM' : 'AM';
    final String month = value.month.toString().padLeft(2, '0');
    final String day = value.day.toString().padLeft(2, '0');

    return '${value.year}-$month-$day '
        '${hour12.toString().padLeft(2, '0')}:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    final Color textColor = context.textColor;
    final Color screenBackground = Theme.of(context).scaffoldBackgroundColor;
    final Color cardColor = context.containerColor;
    final Color headerColor = context.isHackingTheme
        ? cardColor
        : (_isHeaderBlue ? _lightBlueHeader : screenBackground);

    return Scaffold(
      backgroundColor: screenBackground,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SafeArea(
            bottom: false,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              color: headerColor,
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
              child: Text(
                'Search',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: widget.vehicleOnly
                  ? _buildVehicleOnlyPanel()
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(
                          width: _sidebarWidth,
                          child: ColoredBox(
                            color: screenBackground,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _buildSideTab(0, 'Event Types'),
                                _buildSideTab(1, 'Vehicle'),
                                _buildSideTab(2, 'Date'),
                                const Spacer(),
                              ],
                            ),
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: DecoratedBox(
                              decoration: context.containerDecoration(
                                borderRadius: BorderRadius.circular(10),
                              ).copyWith(
                                boxShadow: <BoxShadow>[
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.10),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: _buildTabContent(),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          ColoredBox(
            color: cardColor,
            child: SafeArea(
              top: false,
              child: SizedBox(
                height: _bottomBarHeight,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildActionButton(
                          label: 'CANCEL',
                          onTap: () => Navigator.pop(context),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildActionButton(
                          label: 'Apply',
                          onTap: () {
                            Navigator.pop(
                              context,
                              NotificationFilterResult(
                                eventTypes: Set<String>.from(_selectedEvents),
                                vehicles: Set<String>.from(_selectedVehicles),
                                datePreset: _selectedDatePreset,
                                startDate: _startDate,
                                endDate: _endDate,
                              ),
                            );
                          },
                        ),
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

  Widget _buildVehicleOnlyPanel() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.10),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: _buildVehicleTab(),
        ),
      ),
    );
  }

  Widget _buildSideTab(int index, String label) {
    final bool isSelected = _selectedTab == index;
    final Color textColor = context.textColor;

    return Material(
      color: isSelected ? context.containerColor : Colors.transparent,
      borderRadius: isSelected
          ? const BorderRadius.only(
              topRight: Radius.circular(10),
              bottomRight: Radius.circular(10),
            )
          : null,
      child: InkWell(
        onTap: () => _selectTab(index),
        borderRadius: isSelected
            ? const BorderRadius.only(
                topRight: Radius.circular(10),
                bottomRight: Radius.circular(10),
              )
            : null,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(10, 18, 2, 18),
          alignment: Alignment.centerLeft,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected
                  ? textColor
                  : textColor.withValues(alpha: 0.55),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_selectedTab) {
      case 1:
        return _buildVehicleTab();
      case 2:
        return _buildDateTab();
      case 0:
      default:
        return _buildEventTypesTab();
    }
  }

  Widget _wrapWithLightBlueScrollbar({
    required ScrollController controller,
    required Widget child,
  }) {
    return Theme(
      data: Theme.of(context).copyWith(
        scrollbarTheme: ScrollbarThemeData(
          thumbColor: WidgetStateProperty.resolveWith((Set<WidgetState> states) {
            if (states.contains(WidgetState.dragged) ||
                states.contains(WidgetState.pressed)) {
              return const Color(0xFF7EC8E3);
            }
            return const Color(0xFFB3E5FC);
          }),
          thickness: WidgetStateProperty.all(5),
          radius: const Radius.circular(6),
          crossAxisMargin: 2,
          mainAxisMargin: 4,
          minThumbLength: 36,
        ),
      ),
      child: Scrollbar(
        controller: controller,
        interactive: true,
        child: child,
      ),
    );
  }

  Widget _buildEventTypesTab() {
    return _wrapWithLightBlueScrollbar(
      controller: _eventScrollController,
      child: ListView.builder(
        controller: _eventScrollController,
        padding: const EdgeInsets.fromLTRB(8, 8, 6, 8),
        itemCount: _eventTypes.length,
        itemBuilder: (BuildContext context, int index) {
          final String event = _eventTypes[index];
          final bool isSelected = _selectedEvents.contains(event);

          return _FilterCheckTile(
            label: event,
            isSelected: isSelected,
            onTap: () => _toggleEvent(event),
          );
        },
      ),
    );
  }

  Widget _buildVehicleTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 4),
          child: TextField(
            onChanged: (value) => setState(() => _vehicleQuery = value),
            style: const TextStyle(fontSize: 12, color: Color(0xFF333333)),
            decoration: InputDecoration(
              isDense: true,
              hintText: 'Search Vehi...',
              hintStyle: const TextStyle(
                color: Color(0xFFB0B0B0),
                fontSize: 12,
              ),
              filled: true,
              fillColor: Colors.white,
              prefixIcon: const Icon(Icons.search, color: _accent, size: 18),
              prefixIconConstraints: const BoxConstraints(
                minWidth: 36,
                minHeight: 32,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: const BorderSide(color: _accent),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: const BorderSide(color: _accent),
              ),
            ),
          ),
        ),
        Expanded(
          child: _wrapWithLightBlueScrollbar(
            controller: _vehicleScrollController,
            child: ListView.builder(
              controller: _vehicleScrollController,
              padding: const EdgeInsets.fromLTRB(8, 0, 6, 8),
              itemCount: _filteredVehicles.length,
              itemBuilder: (BuildContext context, int index) {
                final String vehicleId = _filteredVehicles[index];
                final bool isSelected = _selectedVehicles.contains(vehicleId);

                return _FilterCheckTile(
                  label: vehicleId,
                  isSelected: isSelected,
                  onTap: () => _toggleVehicle(vehicleId),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateTab() {
    return _wrapWithLightBlueScrollbar(
      controller: _dateScrollController,
      child: ListView(
        controller: _dateScrollController,
        padding: const EdgeInsets.fromLTRB(8, 8, 6, 8),
        children: [
        ..._datePresets.map((preset) {
          final bool isSelected = _selectedDatePreset == preset;

          return _FilterCheckTile(
            label: preset,
            isSelected: isSelected,
            onTap: () {
              setState(() => _selectedDatePreset = preset);
              _scrollDownOnEventTap();
            },
          );
        }),
        const Padding(
          padding: EdgeInsets.fromLTRB(8, 12, 8, 6),
          child: Text(
            'Custom Range',
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF444444),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: _DateTimeField(
            value: _formatPickerDate(_startDate),
            onTap: () => _pickDateTime(isStart: true),
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 4),
          child: Center(
            child: Text(
              'To',
              style: TextStyle(fontSize: 12, color: Color(0xFF555555)),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: _DateTimeField(
            value: _formatPickerDate(_endDate),
            onTap: () => _pickDateTime(isStart: false),
          ),
        ),
      ],
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: _accent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          height: 40,
          child: Center(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 17,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FilterCheckTile extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterCheckTile({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color textColor = context.textColor;
    final Color accentColor = Theme.of(context).colorScheme.primary;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        child: Row(
          children: [
            Container(
              width: 13,
              height: 13,
              decoration: BoxDecoration(
                color: isSelected
                    ? accentColor
                    : _NotificationFilterScreenState._checkboxEmpty,
                border: Border.all(
                  color: isSelected
                      ? accentColor
                      : _NotificationFilterScreenState._checkboxBorder,
                ),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: textColor,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DateTimeField extends StatelessWidget {
  final String value;
  final VoidCallback onTap;

  const _DateTimeField({
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color textColor = context.textColor;
    final Color accentColor = Theme.of(context).colorScheme.primary;

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
        decoration: BoxDecoration(
          border: Border.all(
            color: context.appTokens.containerBorderColor ??
                textColor.withValues(alpha: 0.5),
          ),
          borderRadius: BorderRadius.circular(3),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today,
              size: 16,
              color: accentColor.withValues(alpha: 0.95),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 12,
                  color: textColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
