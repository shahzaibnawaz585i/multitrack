import 'package:flutter/material.dart';

import '../data/notification_data.dart';
import '../data/vehicle_data.dart';
import '../models/vehicle_model.dart';
import '../theme/app_theme_tokens.dart';
import '../widgets/status_card.dart';
import '../widgets/vehicle_card.dart';
import 'notifications_screen.dart';

class ListScreen extends StatefulWidget {
  final String initialFilter;

  const ListScreen({super.key, this.initialFilter = 'all'});

  @override
  State<ListScreen> createState() => _ListScreenState();
}

class _ListScreenState extends State<ListScreen> {
  late String selectedFilter;
  bool _isSearchVisible = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  static const List<String> _validFilters = <String>[
    'all',
    'running',
    'idle',
    'stopped',
    'inactive',
    'expired',
  ];

  @override
  void initState() {
    super.initState();
    selectedFilter = _normalizeFilter(widget.initialFilter);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant ListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.initialFilter != widget.initialFilter) {
      final String newFilter = _normalizeFilter(widget.initialFilter);

      if (selectedFilter != newFilter) {
        setState(() {
          selectedFilter = newFilter;
        });
      }
    }
  }

  String _normalizeFilter(String filter) {
    final String normalizedFilter = filter.trim().toLowerCase();

    if (_validFilters.contains(normalizedFilter)) {
      return normalizedFilter;
    }

    return 'all';
  }

  void _changeFilter(String filter) {
    final String normalizedFilter = _normalizeFilter(filter);

    if (selectedFilter == normalizedFilter) {
      return;
    }

    setState(() {
      selectedFilter = normalizedFilter;
    });
  }

  bool _matchesFilter(VehicleModel vehicle) {
    final String status = vehicle.status.trim().toLowerCase();

    if (selectedFilter == 'all') {
      return true;
    }

    if (selectedFilter == 'inactive') {
      return status == 'inactive' || status == 'not reporting';
    }

    if (selectedFilter == 'expired') {
      return status == 'expired';
    }

    return status == selectedFilter;
  }

  List<VehicleModel> get _filteredVehicles {
    final String query = _searchQuery.trim().toLowerCase();

    return VehicleData.vehicles.where((VehicleModel vehicle) {
      if (!_matchesFilter(vehicle)) {
        return false;
      }

      if (query.isEmpty) {
        return true;
      }

      return vehicle.name.toLowerCase().contains(query) ||
          vehicle.location.toLowerCase().contains(query) ||
          vehicle.status.toLowerCase().contains(query);
    }).toList(growable: false);
  }

  void _toggleSearch() {
    setState(() {
      _isSearchVisible = !_isSearchVisible;
      if (!_isSearchVisible) {
        _searchController.clear();
        _searchQuery = '';
        _searchFocusNode.unfocus();
      }
    });

    if (_isSearchVisible) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _searchFocusNode.requestFocus();
        }
      });
    }
  }

  int _getVehicleCount(String status) {
    if (status == 'all') {
      return VehicleData.vehicles.length;
    }

    if (status == 'inactive') {
      return VehicleData.vehicles.where((VehicleModel vehicle) {
        final String value = vehicle.status.trim().toLowerCase();
        return value == 'inactive' || value == 'not reporting';
      }).length;
    }

    return VehicleData.vehicles.where((VehicleModel vehicle) {
      return vehicle.status.trim().toLowerCase() == status;
    }).length;
  }

  @override
  Widget build(BuildContext context) {
    final List<VehicleModel> vehicles = _filteredVehicles;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildSearchBar(),
            _buildStatusCards(),
            const SizedBox(height: 10),
            Container(
              height: 5,
              color: context.containerColor,
            ),
            Expanded(
              child: vehicles.isEmpty
                  ? _buildEmptyState()
                  : _buildVehicleList(vehicles),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final Color textColor = context.textColor;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Vehicle List',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
          ),
          _buildCircleIconButton(
            icon: Icons.search,
            color: Colors.pinkAccent,
            onTap: _toggleSearch,
          ),
          const SizedBox(width: 10),
          Stack(
            clipBehavior: Clip.none,
            children: [
              _buildCircleIconButton(
                icon: Icons.notifications_none,
                color: Colors.cyan,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => const NotificationsScreen(),
                    ),
                  );
                },
              ),
              Positioned(
                right: -1,
                top: -2,
                child: Container(
                  constraints: const BoxConstraints(
                    minHeight: 18,
                    minWidth: 18,
                  ),
                  alignment: Alignment.center,
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${NotificationData.totalBadgeCount}',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: context.textColor,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    final ThemeData theme = Theme.of(context);
    final Color accentColor = theme.colorScheme.primary;
    final Color textColor = context.textColor;
    final Color mutedColor = context.mutedTextColor;
    final bool isHacking = context.isHackingTheme;
    final Color pinkBorder = isHacking
        ? (context.appTokens.containerBorderColor ?? accentColor)
        : const Color(0xFFF43A6B);

    if (!_isSearchVisible) {
      return const SizedBox.shrink();
    }

    return Container(
      height: 60,
      width: double.infinity,
      color: isHacking ? context.containerColor : Colors.white,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Container(
        height: 40,
        width: double.infinity,
        decoration: BoxDecoration(
          color: isHacking ? Colors.transparent : Colors.white,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: pinkBorder,
            width: 1.2,
          ),
        ),
        alignment: Alignment.centerLeft,
        child: TextField(
          controller: _searchController,
          focusNode: _searchFocusNode,
          onChanged: (String value) {
            setState(() {
              _searchQuery = value;
            });
          },
          style: TextStyle(
            color: textColor,
            fontSize: 14,
            height: 1.2,
          ),
          cursorColor: accentColor,
          decoration: InputDecoration(
            isDense: true,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 10,
            ),
            hintText: 'Search Vehicle',
            hintStyle: TextStyle(
              color: mutedColor,
              fontSize: 14,
            ),
            suffixIcon: _searchQuery.isEmpty
                ? null
                : IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 36,
                      minHeight: 36,
                    ),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        _searchQuery = '';
                      });
                    },
                    icon: Icon(
                      Icons.close,
                      size: 18,
                      color: mutedColor,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusCards() {
    return SizedBox(
      height: 117,
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        clipBehavior: Clip.none,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        children: [
          StatusCard(
            color: Colors.purple,
            title: 'All vehicles',
            count: _getVehicleCount('all').toString(),
            isSelected: selectedFilter == 'all',
            onTap: () => _changeFilter('all'),
          ),
          StatusCard(
            color: Colors.green,
            title: 'Running',
            count: _getVehicleCount('running').toString(),
            isSelected: selectedFilter == 'running',
            onTap: () => _changeFilter('running'),
          ),
          StatusCard(
            color: Colors.orange,
            title: 'Idle',
            count: _getVehicleCount('idle').toString(),
            isSelected: selectedFilter == 'idle',
            onTap: () => _changeFilter('idle'),
          ),
          StatusCard(
            color: Colors.red,
            title: 'Stopped',
            count: _getVehicleCount('stopped').toString(),
            isSelected: selectedFilter == 'stopped',
            onTap: () => _changeFilter('stopped'),
          ),
          StatusCard(
            color: const Color(0xFFF43A6B),
            title: 'Expired',
            count: _getVehicleCount('expired').toString(),
            isSelected: selectedFilter == 'expired',
            onTap: () => _changeFilter('expired'),
          ),
          StatusCard(
            color: Colors.grey,
            title: 'Inactive',
            count: _getVehicleCount('inactive').toString(),
            isSelected: selectedFilter == 'inactive',
            onTap: () => _changeFilter('inactive'),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleList(List<VehicleModel> vehicles) {
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
      itemCount: vehicles.length,
      itemBuilder: (BuildContext context, int index) {
        final VehicleModel vehicle = vehicles[index];

        return VehicleCard(
          key: ValueKey<String>('${vehicle.name}_${vehicle.status}_$index'),
          vehicle: vehicle,
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.directions_car_outlined,
              size: 55,
              color: context.mutedTextColor,
            ),
            const SizedBox(height: 12),
            Text(
              'No Vehicle Found',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: context.textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCircleIconButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: color.withValues(alpha: 0.10),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          height: 40,
          width: 40,
          child: Icon(icon, color: color, size: 22),
        ),
      ),
    );
  }
}
