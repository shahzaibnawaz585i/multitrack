import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../services/location_service.dart';
import 'add_geofence_screen.dart';
import 'edit_geofence_screen.dart';

class GeofenceScreen extends StatefulWidget {
  const GeofenceScreen({super.key});

  @override
  State<GeofenceScreen> createState() => _GeofenceScreenState();
}

class _GeofenceScreenState extends State<GeofenceScreen> {
  static const Color _pinkColor = Color(0xFFFF2F68);
  static const Color _backgroundColor = Color(0xFFF5F5F5);
  static const Color _radiusChipColor = Color(0xFF3A3A3A);
  static const LatLng _defaultCenter = LatLng(24.4825, 87.8550);

  GoogleMapController? _mapController;
  bool _isLoading = true;
  bool _isCircularSelected = true;
  LatLng _mapCenter = _defaultCenter;

  final List<_GeofenceItem> _geofences = <_GeofenceItem>[
    const _GeofenceItem(
      title: 'zone1',
      radiusLabel: 'Radius : 1242.08',
      address:
          'Dhulian - Pakur Road, Dhuliyan Municipality, Murshidabad, West Bengal, 742202, India',
      position: LatLng(24.4825, 87.8550),
      radiusMeters: 1242.08,
      isCircular: true,
    ),
    const _GeofenceItem(
      title: '1',
      radiusLabel: 'Radius : 1242.08',
      address:
          'Dhulian - Pakur Road, Dhuliyan Municipality, Murshidabad, West Bengal, 742202, India',
      position: LatLng(24.4850, 87.8580),
      radiusMeters: 1242.08,
      isCircular: true,
    ),
    const _GeofenceItem(
      title: 'round',
      radiusLabel: 'Radius : 0',
      address: 'Indore region polygon area',
      position: LatLng(22.7196, 75.8577),
      radiusMeters: 0,
      isCircular: false,
    ),
    const _GeofenceItem(
      title: 'halku kabeela',
      radiusLabel: 'Radius : 0',
      address: 'Ujjain region polygon area',
      position: LatLng(23.1765, 75.7885),
      radiusMeters: 0,
      isCircular: false,
    ),
  ];

  List<_GeofenceItem> get _visibleGeofences {
    return _geofences
        .where(
          (_GeofenceItem item) => item.isCircularFence == _isCircularSelected,
        )
        .toList();
  }

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(milliseconds: 900), () {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoading = false;
      });
    });
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  Set<Circle> get _circles {
    if (!_isCircularSelected) {
      return <Circle>{};
    }

    return _visibleGeofences
        .map(
          (_GeofenceItem item) => Circle(
            circleId: CircleId(item.title),
            center: item.position,
            radius: item.radiusMeters,
            fillColor: _pinkColor.withValues(alpha: 0.10),
            strokeColor: Colors.transparent,
            strokeWidth: 0,
          ),
        )
        .toSet();
  }

  Set<Marker> get _markers {
    return _visibleGeofences
        .map(
          (_GeofenceItem item) => Marker(
            markerId: MarkerId(item.title),
            position: item.position,
            infoWindow: InfoWindow(title: item.title),
          ),
        )
        .toSet();
  }

  Future<void> _goToMyLocation() async {
    try {
      final bool serviceEnabled = await LocationService.isServiceEnabled();
      if (!serviceEnabled) {
        if (!mounted) {
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enable location services')),
        );
        return;
      }

      final Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      final LatLng target = LatLng(position.latitude, position.longitude);
      setState(() {
        _mapCenter = target;
      });

      await _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(target, 15),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not get current location')),
      );
    }
  }

  Future<void> _onAddPressed() async {
    final AddGeofenceResult? result = await Navigator.push<AddGeofenceResult>(
      context,
      MaterialPageRoute<AddGeofenceResult>(
        builder: (_) => const AddGeofenceScreen(),
      ),
    );

    if (result == null || !mounted) {
      return;
    }

    setState(() {
      _isCircularSelected = result.isCircular;
      _geofences.insert(
        0,
        _GeofenceItem(
          title: result.name,
          radiusLabel:
              'Radius : ${result.location.radiusMeters.toStringAsFixed(2)}',
          address: result.location.address,
          position: result.location.position,
          radiusMeters: result.location.radiusMeters,
          isCircular: result.isCircular,
        ),
      );
      _mapCenter = result.location.position;
      _isLoading = false;
    });

    await _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(result.location.position, 14.5),
    );
  }

  Future<void> _showItemMenu(_GeofenceItem item) async {
    final String? action = await showDialog<String>(
      context: context,
      barrierColor: Colors.black38,
      builder: (BuildContext dialogContext) {
        return Dialog(
          backgroundColor: Colors.white,
          insetPadding: const EdgeInsets.symmetric(horizontal: 70),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.edit, color: _pinkColor),
                  title: const Text(
                    'Edit',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onTap: () => Navigator.pop(dialogContext, 'edit'),
                ),
                ListTile(
                  leading: const Icon(Icons.delete, color: _pinkColor),
                  title: const Text(
                    'Delete',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onTap: () => Navigator.pop(dialogContext, 'delete'),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (action == null || !mounted) {
      return;
    }

    if (action == 'delete') {
      setState(() {
        _geofences.remove(item);
      });
      return;
    }

    final int index = _geofences.indexOf(item);
    final EditGeofenceResult? edited =
        await Navigator.push<EditGeofenceResult>(
      context,
      MaterialPageRoute<EditGeofenceResult>(
        builder: (_) => EditGeofenceScreen(
          initialName: item.title,
          initialPosition: item.position,
          initialRadius: item.radiusMeters <= 0 ? 100 : item.radiusMeters,
          initialAddress: item.address,
          isCircular: item.isCircularFence,
        ),
      ),
    );

    if (edited == null || !mounted || index < 0) {
      return;
    }

    setState(() {
      _geofences[index] = _GeofenceItem(
        title: edited.name,
        radiusLabel: 'Radius : ${edited.radiusMeters.toStringAsFixed(2)}',
        address: edited.address,
        position: edited.position,
        radiusMeters: edited.radiusMeters,
        isCircular: item.isCircularFence,
      );
      _mapCenter = edited.position;
    });

    await _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(edited.position, 14.5),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: _pinkColor,
            size: 20,
          ),
        ),
        titleSpacing: 0,
        title: const Text(
          'Geofence',
          style: TextStyle(
            color: Colors.black,
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: Material(
              color: _pinkColor,
              shape: const CircleBorder(),
              elevation: 2,
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: _onAddPressed,
                child: const SizedBox(
                  width: 42,
                  height: 42,
                  child: Icon(Icons.add, color: Colors.white, size: 26),
                ),
              ),
            ),
          ),
        ],
      ),
      body: _isLoading ? _buildLoadingBody() : _buildContentBody(),
    );
  }

  Widget _buildLoadingBody() {
    return Stack(
      children: [
        const Center(child: _LoadingDots()),
        Positioned(
          right: 14,
          top: MediaQuery.sizeOf(context).height * 0.28,
          child: _MyLocationButton(onTap: _goToMyLocation),
        ),
      ],
    );
  }

  Widget _buildContentBody() {
    final List<_GeofenceItem> visible = _visibleGeofences;

    return ColoredBox(
      color: _backgroundColor,
      child: Column(
        children: [
          SizedBox(
            height: MediaQuery.sizeOf(context).height * 0.38,
            width: double.infinity,
            child: Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: _mapCenter,
                    zoom: 14.5,
                  ),
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  mapToolbarEnabled: false,
                  compassEnabled: false,
                  circles: _circles,
                  markers: _markers,
                  onMapCreated: (GoogleMapController controller) {
                    _mapController = controller;
                  },
                ),
                Positioned(
                  right: 14,
                  bottom: 14,
                  child: _MyLocationButton(onTap: _goToMyLocation),
                ),
              ],
            ),
          ),
          Expanded(
            child: Column(
              children: [
                const SizedBox(height: 14),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _TypeToggle(
                    isCircularSelected: _isCircularSelected,
                    onChanged: (bool isCircular) {
                      setState(() {
                        _isCircularSelected = isCircular;
                        final List<_GeofenceItem> list = _geofences
                            .where(
                              (_GeofenceItem e) =>
                                  e.isCircularFence == isCircular,
                            )
                            .toList();
                        if (list.isNotEmpty) {
                          _mapCenter = list.first.position;
                        }
                      });

                      final List<_GeofenceItem> current = _geofences
                          .where(
                            (_GeofenceItem e) =>
                                e.isCircularFence == isCircular,
                          )
                          .toList();
                      if (current.isNotEmpty) {
                        _mapController?.animateCamera(
                          CameraUpdate.newLatLngZoom(
                            current.first.position,
                            12,
                          ),
                        );
                      }
                    },
                  ),
                ),
                const SizedBox(height: 14),
                Expanded(
                  child: visible.isEmpty
                      ? const Center(
                          child: Text(
                            'No geofences found',
                            style: TextStyle(color: Colors.black54),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                          itemCount: visible.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (BuildContext context, int index) {
                            final _GeofenceItem item = visible[index];
                            return _GeofenceCard(
                              item: item,
                              compact: !item.isCircularFence,
                              onMenuTap: () => _showItemMenu(item),
                            );
                          },
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

class _GeofenceItem {
  final String title;
  final String radiusLabel;
  final String address;
  final LatLng position;
  final double radiusMeters;
  final bool? isCircular;

  const _GeofenceItem({
    required this.title,
    required this.radiusLabel,
    required this.address,
    required this.position,
    required this.radiusMeters,
    this.isCircular = true,
  });

  bool get isCircularFence => isCircular ?? true;
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

class _MyLocationButton extends StatelessWidget {
  final VoidCallback onTap;

  const _MyLocationButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 3,
      shadowColor: Colors.black26,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: const SizedBox(
          width: 44,
          height: 44,
          child: Icon(
            Icons.gps_fixed,
            color: Colors.black87,
            size: 22,
          ),
        ),
      ),
    );
  }
}

class _TypeToggle extends StatelessWidget {
  final bool isCircularSelected;
  final ValueChanged<bool> onChanged;

  const _TypeToggle({
    required this.isCircularSelected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _ToggleChip(
              label: 'Circular',
              isSelected: isCircularSelected,
              onTap: () => onChanged(true),
            ),
          ),
          Expanded(
            child: _ToggleChip(
              label: 'Polygon',
              isSelected: !isCircularSelected,
              onTap: () => onChanged(false),
            ),
          ),
        ],
      ),
    );
  }
}

class _ToggleChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ToggleChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? const Color(0xFFFF2F68) : Colors.transparent,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : const Color(0xFFFF2F68),
              fontSize: 15,
              fontWeight: label == 'Polygon'
                  ? FontWeight.w500
                  : FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _GeofenceCard extends StatelessWidget {
  final _GeofenceItem item;
  final bool compact;
  final VoidCallback onMenuTap;

  const _GeofenceCard({
    required this.item,
    required this.compact,
    required this.onMenuTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(14, compact ? 6 : 12, 4, compact ? 6 : 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: compact
          ? Row(
              children: [
                Expanded(
                  child: Text(
                    item.title,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: onMenuTap,
                  icon: const Icon(
                    Icons.more_vert,
                    color: Color(0xFFFF2F68),
                  ),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.title,
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _GeofenceScreenState._radiusChipColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        item.radiusLabel,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 2),
                      child: Icon(
                        Icons.location_on,
                        color: Color(0xFFFF2F68),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        item.address,
                        style: const TextStyle(
                          color: Color(0xFF333333),
                          fontSize: 13,
                          height: 1.35,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: onMenuTap,
                      icon: const Icon(
                        Icons.more_vert,
                        color: Color(0xFFFF2F68),
                      ),
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}
