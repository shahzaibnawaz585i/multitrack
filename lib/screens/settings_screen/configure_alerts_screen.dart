import 'package:flutter/material.dart';

import '../../data/vehicle_data.dart';
import '../../l10n/app_l10n.dart';
import '../../services/alert_service.dart';
import '../../theme/app_theme_tokens.dart';

class ConfigureAlertsScreen extends StatefulWidget {
  const ConfigureAlertsScreen({super.key});

  @override
  State<ConfigureAlertsScreen> createState() => _ConfigureAlertsScreenState();
}

class _ConfigureAlertsScreenState extends State<ConfigureAlertsScreen> {
  static const Color _pinkColor = Color(0xFFFF2F68);

  static const List<String> _defaultAlertTypes = <String>[
    'Ignition On',
    'Ignition Off',
    'OverSpeed',
    'Geofence Enter',
    'Geofence Exit',
    'Device Offline',
    'AC On',
    'AC Off',
    'Maintenance',
  ];

  List<String> _alertTypes = _defaultAlertTypes;

  bool _isLoading = false;
  late List<String> _vehicles;
  late String _selectedVehicle;
  final Set<String> _enabledAlerts = <String>{};

  @override
  void initState() {
    super.initState();
    _vehicles = VehicleData.vehicles
        .map((v) => v.name)
        .where((name) => name.isNotEmpty)
        .toSet()
        .toList();
    _selectedVehicle = _vehicles.isNotEmpty ? _vehicles.first : '';
    _loadConfiguredAlerts();
    _loadAlertTypes();
  }

  Future<void> _loadAlertTypes() async {
    final List<String> types = await AlertService.getAlertTypes();
    if (types.isNotEmpty && mounted) {
      setState(() => _alertTypes = types);
    }
  }

  Future<void> _loadConfiguredAlerts() async {
    setState(() => _isLoading = true);
    try {
      final List<Map<String, dynamic>> alerts = await AlertService.getAlerts();
      if (alerts.isNotEmpty && mounted) {
        setState(() {
          for (final Map<String, dynamic> a in alerts) {
            final String name = (a['name'] ?? a['type'] ?? '').toString();
            if (name.isNotEmpty) {
              _enabledAlerts.add(name);
            }
          }
        });
      }
    } catch (_) {
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _openSelectVehicle() async {
    final String? selected = await showDialog<String>(
      context: context,
      barrierColor: Colors.black45,
      builder: (_) => _SelectVehicleAlertsDialog(
        vehicles: _vehicles,
        initialSelected: _selectedVehicle,
      ),
    );

    if (selected == null || !mounted) {
      return;
    }

    setState(() {
      _selectedVehicle = selected;
    });
  }

  void _toggleAlert(String alert) {
    setState(() {
      if (_enabledAlerts.contains(alert)) {
        _enabledAlerts.remove(alert);
      } else {
        _enabledAlerts.add(alert);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).cardColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).cardColor,
        surfaceTintColor: Theme.of(context).cardColor,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: _pinkColor,
            size: 20,
          ),
        ),
        titleSpacing: 0,
        title: Text(
          context.tr('Configure Alerts'),
          style: TextStyle(
            color: context.textColor,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: _LoadingDots())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: InkWell(
                    onTap: _openSelectVehicle,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      height: 48,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: context.containerColor,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFF555555),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.search,
                            color: _pinkColor,
                            size: 22,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _selectedVehicle,
                              style: TextStyle(
                                color: context.textColor,
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.arrow_drop_down,
                            color: context.mutedTextColor,
                            size: 26,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.only(top: 4),
                    itemCount: _alertTypes.length,
                    separatorBuilder: (BuildContext context, int index) => const Divider(
                      height: 1,
                      thickness: 1,
                      color: Color(0xFFE8E8E8),
                    ),
                    itemBuilder: (BuildContext context, int index) {
                      final String alert = _alertTypes[index];
                      final bool isEnabled = _enabledAlerts.contains(alert);

                      return InkWell(
                        onTap: () => _toggleAlert(alert),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  alert,
                                  style: TextStyle(
                                    color: context.textColor,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              Container(
                                width: 26,
                                height: 26,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isEnabled
                                        ? _pinkColor
                                        : context.labelTextColor,
                                    width: 1.6,
                                  ),
                                ),
                                padding: const EdgeInsets.all(4),
                                child: isEnabled
                                    ? Container(
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: _pinkColor,
                                        ),
                                      )
                                    : null,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}

class _SelectVehicleAlertsDialog extends StatefulWidget {
  final List<String> vehicles;
  final String initialSelected;

  const _SelectVehicleAlertsDialog({
    required this.vehicles,
    required this.initialSelected,
  });

  @override
  State<_SelectVehicleAlertsDialog> createState() =>
      _SelectVehicleAlertsDialogState();
}

class _SelectVehicleAlertsDialogState
    extends State<_SelectVehicleAlertsDialog> {
  static const Color _pinkColor = Color(0xFFFF2F68);

  final TextEditingController _searchController = TextEditingController();
  late List<String> _filtered;

  @override
  void initState() {
    super.initState();
    _filtered = widget.vehicles;
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
        _filtered = widget.vehicles;
      } else {
        _filtered = widget.vehicles
            .where((String v) => v.toLowerCase().contains(query))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.sizeOf(context);

    return Dialog(
      backgroundColor: Theme.of(context).cardColor,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 48),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: SizedBox(
        width: size.width * 0.86,
        height: size.height * 0.58,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Column(
            children: [
              TextField(
                controller: _searchController,
                style: TextStyle(
                  color: context.textColor,
                  fontSize: 15,
                ),
                decoration: InputDecoration(
                  hintText: 'Search Vehicle',
                  hintStyle: TextStyle(
                    color: context.labelTextColor,
                    fontSize: 15,
                  ),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                      color: _pinkColor,
                      width: 1.2,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                      color: _pinkColor,
                      width: 1.4,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: _filtered.isEmpty
                    ? Center(
                        child: Text(
                          'No vehicles found',
                          style: TextStyle(color: context.labelTextColor),
                        ),
                      )
                    : ListView.builder(
                        padding: EdgeInsets.zero,
                        itemCount: _filtered.length,
                        itemBuilder: (BuildContext context, int index) {
                          final String vehicle = _filtered[index];
                          return InkWell(
                            onTap: () => Navigator.pop(context, vehicle),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 12,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.directions_car,
                                    color: _pinkColor,
                                    size: 22,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    vehicle,
                                    style: TextStyle(
                                      color: context.textColor,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
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

class _LoadingDots extends StatefulWidget {
  const _LoadingDots();

  @override
  State<_LoadingDots> createState() => _LoadingDotsState();
}

class _LoadingDotsState extends State<_LoadingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, Widget? child) {
        final int active = (_controller.value * 3).floor() % 3;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List<Widget>.generate(3, (int index) {
            final bool isActive = index == active;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: isActive ? 12 : 9,
                height: isActive ? 12 : 9,
                decoration: BoxDecoration(
                  color: isActive
                      ? const Color(0xFFFF2F68)
                      : const Color(0xFFFF2F68).withValues(alpha: 0.45),
                  shape: BoxShape.circle,
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
