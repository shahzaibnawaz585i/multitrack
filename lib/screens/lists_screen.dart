import 'dart:async';

import 'package:flutter/material.dart';

import '../constants/app_images.dart';
import '../data/notification_data.dart';
import '../data/vehicle_data.dart';
import '../models/vehicle_model.dart';
import '../l10n/app_l10n.dart';
import '../services/vehicle_service.dart';
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
  bool _isLoading = true;
  List<VehicleModel> _vehicles = VehicleData.vehicles;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  Timer? _searchDebounce;

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
    _isLoading = _vehicles.isEmpty;
    _fetchVehicles();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _precacheVehicleImages();
    });
  }

  Future<void> _fetchVehicles({bool isRefresh = false}) async {
    if (!isRefresh && _vehicles.isEmpty) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final List<VehicleModel> data =
          await VehicleService.getDevices(forceRefresh: isRefresh);
      if (!mounted) return;
      setState(() {
        _vehicles = data;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _vehicles = VehicleData.vehicles;
        _isLoading = false;
      });
    }
  }

  void _precacheVehicleImages() {
    const List<String> assets = <String>[
      AppImages.runningCar,
      AppImages.stopCar,
      AppImages.idleCar,
      AppImages.inactiveCar,
      AppImages.runningLock,
      AppImages.stopLock,
      AppImages.idleLock,
      AppImages.inactiveLock,
    ];
    for (final String asset in assets) {
      precacheImage(AssetImage(asset), context);
    }
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
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

    return _vehicles.where((VehicleModel vehicle) {
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

  Map<String, int> get _statusCounts {
    int running = 0;
    int idle = 0;
    int stopped = 0;
    int expired = 0;
    int inactive = 0;

    for (final VehicleModel vehicle in _vehicles) {
      final String value = vehicle.status.trim().toLowerCase();
      if (value == 'running') {
        running++;
      } else if (value == 'idle') {
        idle++;
      } else if (value == 'stopped') {
        stopped++;
      } else if (value == 'expired') {
        expired++;
      } else if (value == 'inactive' || value == 'not reporting') {
        inactive++;
      }
    }

    return <String, int>{
      'all': _vehicles.length,
      'running': running,
      'idle': idle,
      'stopped': stopped,
      'expired': expired,
      'inactive': inactive,
    };
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 120), () {
      if (!mounted) {
        return;
      }
      setState(() {
        _searchQuery = value;
      });
    });
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
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    )
                  : RefreshIndicator(
                      onRefresh: () => _fetchVehicles(isRefresh: true),
                      child: vehicles.isEmpty
                          ? _buildEmptyState()
                          : _buildVehicleList(vehicles),
                    ),
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
              context.tr('Vehicle List'),
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
                    color: Color(0xFFFF2F68),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${NotificationData.totalBadgeCount}',
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
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
      color: context.containerColor,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Container(
        height: 40,
        width: double.infinity,
        decoration: BoxDecoration(
          color: context.containerColor,
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
          onChanged: _onSearchChanged,
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
            hintText: context.tr('Search Vehicle'),
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
                      _searchDebounce?.cancel();
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
    final Map<String, int> counts = _statusCounts;

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
            count: (counts['all'] ?? 0).toString(),
            isSelected: selectedFilter == 'all',
            onTap: () => _changeFilter('all'),
          ),
          StatusCard(
            color: Colors.green,
            title: 'Running',
            count: (counts['running'] ?? 0).toString(),
            isSelected: selectedFilter == 'running',
            onTap: () => _changeFilter('running'),
          ),
          StatusCard(
            color: Colors.orange,
            title: 'Idle',
            count: (counts['idle'] ?? 0).toString(),
            isSelected: selectedFilter == 'idle',
            onTap: () => _changeFilter('idle'),
          ),
          StatusCard(
            color: Colors.red,
            title: 'Stopped',
            count: (counts['stopped'] ?? 0).toString(),
            isSelected: selectedFilter == 'stopped',
            onTap: () => _changeFilter('stopped'),
          ),
          StatusCard(
            color: const Color(0xFFF43A6B),
            title: 'Expired',
            count: (counts['expired'] ?? 0).toString(),
            isSelected: selectedFilter == 'expired',
            onTap: () => _changeFilter('expired'),
          ),
          StatusCard(
            color: Colors.grey,
            title: 'Inactive',
            count: (counts['inactive'] ?? 0).toString(),
            isSelected: selectedFilter == 'inactive',
            onTap: () => _changeFilter('inactive'),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleList(List<VehicleModel> vehicles) {
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(
        parent: ClampingScrollPhysics(),
      ),
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
      cacheExtent: 280,
      addAutomaticKeepAlives: false,
      itemCount: vehicles.length,
      itemBuilder: (BuildContext context, int index) {
        final VehicleModel vehicle = vehicles[index];

        return RepaintBoundary(
          child: VehicleCard(
            key: ValueKey<String>('${vehicle.name}_$index'),
            vehicle: vehicle,
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.15),
        Center(
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
                context.tr('No Vehicle Found'),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: context.textColor,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => _fetchVehicles(isRefresh: true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: const Icon(Icons.refresh, size: 18),
                label: Text(context.tr('Retry')),
              ),
            ],
          ),
        ),
      ],
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
