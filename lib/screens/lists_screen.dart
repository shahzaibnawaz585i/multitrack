import 'dart:async';

import 'package:flutter/material.dart';

import '../constants/app_images.dart';
import '../data/notification_data.dart';
import '../data/vehicle_data.dart';
import '../models/vehicle_model.dart';
import '../l10n/app_l10n.dart';
import '../services/vehicle_service.dart';
import '../theme/app_theme_tokens.dart';
import '../utils/vehicle_refresh_utils.dart';
import '../widgets/status_card.dart';
import '../widgets/vehicle_card.dart';
import 'notifications_screen.dart';

class ListScreen extends StatefulWidget {
  final String initialFilter;
  final bool isVisible;

  const ListScreen({
    super.key,
    this.initialFilter = 'all',
    this.isVisible = true,
  });

  @override
  State<ListScreen> createState() => _ListScreenState();
}

class _ListScreenState extends State<ListScreen> {
  late String selectedFilter;
  bool _isSearchVisible = false;
  bool _isLoading = true;
  List<VehicleModel> _vehicles = VehicleData.vehicles;
  List<VehicleModel> _visibleVehicles = VehicleData.vehicles;
  Map<String, int> _statusCounts = <String, int>{'all': 0};
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  Timer? _searchDebounce;
  Timer? _refreshTimer;

  static const Duration _refreshInterval = Duration(seconds: 20);

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
    if (VehicleData.vehicles.isNotEmpty) {
      _vehicles = VehicleData.vehicles;
      _isLoading = false;
      _recomputeDerivedLists();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _fetchVehicles(isRefresh: false);
        }
      });
    } else {
      _isLoading = true;
      _recomputeDerivedLists();
      _fetchVehicles();
    }
    if (widget.isVisible) {
      _startAutoRefresh();
    }
    VehicleData.revision.addListener(_onVehicleDataRevision);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _precacheVehicleImages();
    });
  }

  void _onVehicleDataRevision() {
    if (!mounted) {
      return;
    }
    final List<VehicleModel> next = VehicleData.vehicles;
    if (next.isEmpty && _isLoading) {
      return;
    }
    if (VehicleRefreshUtils.listDisplayChanged(_vehicles, next)) {
      setState(() {
        _vehicles = next;
        _isLoading = false;
        _recomputeDerivedLists();
      });
    }
  }

  void _recomputeDerivedLists() {
    _statusCounts = VehicleRefreshUtils.computeStatusCounts(_vehicles);
    _visibleVehicles = VehicleRefreshUtils.filterVehicles(
      vehicles: _vehicles,
      selectedFilter: selectedFilter,
      searchQuery: _searchQuery,
    );
  }

  Future<void> _fetchVehicles({bool isRefresh = false}) async {
    final bool showBlockingLoader = !isRefresh && _vehicles.isEmpty;
    if (showBlockingLoader) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final List<VehicleModel> data = await VehicleService.getDevices(
        forceRefresh: isRefresh && _vehicles.isNotEmpty,
      );
      if (!mounted) return;

      final bool changed =
          VehicleRefreshUtils.listDisplayChanged(_vehicles, data);
      if (!changed) {
        if (_isLoading) {
          setState(() => _isLoading = false);
        }
        return;
      }

      setState(() {
        _vehicles = data;
        _isLoading = false;
        _recomputeDerivedLists();
      });
    } catch (_) {
      if (!mounted) return;
      if (_vehicles.isNotEmpty && _isLoading == false) return;
      setState(() {
        _vehicles = VehicleData.vehicles;
        _isLoading = false;
        _recomputeDerivedLists();
      });
    }
  }

  void _precacheVehicleImages() {
    const List<String> assets = <String>[
      AppImages.listRunningCar,
      AppImages.listStopCar,
      AppImages.listIdleCar,
      AppImages.listInactiveCar,
      AppImages.runningLock,
      AppImages.stopLock,
      AppImages.idleLock,
      AppImages.inactiveLock,
    ];
    for (final String asset in assets) {
      precacheImage(
        ResizeImage(AssetImage(asset), width: 96, height: 96),
        context,
      );
    }
  }

  void _startAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(_refreshInterval, (_) {
      _fetchVehicles(isRefresh: true);
    });
  }

  void _stopAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  @override
  void dispose() {
    VehicleData.revision.removeListener(_onVehicleDataRevision);
    _searchDebounce?.cancel();
    _stopAutoRefresh();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant ListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.isVisible != widget.isVisible) {
      if (widget.isVisible) {
        _fetchVehicles(isRefresh: true);
        _startAutoRefresh();
      } else {
        _stopAutoRefresh();
      }
    }

    if (oldWidget.initialFilter != widget.initialFilter) {
      final String newFilter = _normalizeFilter(widget.initialFilter);

      if (selectedFilter != newFilter) {
        setState(() {
          selectedFilter = newFilter;
          _recomputeDerivedLists();
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
      _recomputeDerivedLists();
    });
  }

  void _updateSearchQuery(String value) {
    if (_searchQuery == value) return;
    setState(() {
      _searchQuery = value;
      _recomputeDerivedLists();
    });
  }

  void _toggleSearch() {
    setState(() {
      _isSearchVisible = !_isSearchVisible;
      if (!_isSearchVisible) {
        _searchController.clear();
        _searchQuery = '';
        _searchFocusNode.unfocus();
        _recomputeDerivedLists();
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

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 120), () {
      if (!mounted) {
        return;
      }
      _updateSearchQuery(value);
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<VehicleModel> vehicles = _visibleVehicles;

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
                      _updateSearchQuery('');
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
      physics: const ClampingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
      cacheExtent: 480,
      addAutomaticKeepAlives: false,
      addRepaintBoundaries: true,
      itemCount: vehicles.length,
      itemBuilder: (BuildContext context, int index) {
        final VehicleModel vehicle = vehicles[index];
        final String itemKey = vehicle.id != null
            ? 'vehicle_${vehicle.id}'
            : 'vehicle_${vehicle.name}';

        return RepaintBoundary(
          child: VehicleCard(
            key: ValueKey<String>(itemKey),
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
