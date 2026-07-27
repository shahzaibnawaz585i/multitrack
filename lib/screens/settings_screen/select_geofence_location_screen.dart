import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class GeofenceLocationResult {
  final LatLng position;
  final double radiusMeters;
  final String address;

  const GeofenceLocationResult({
    required this.position,
    required this.radiusMeters,
    required this.address,
  });
}

class SelectGeofenceLocationScreen extends StatefulWidget {
  final LatLng? initialPosition;
  final double initialRadius;
  final String? initialAddress;
  final bool isPolygonMode;

  const SelectGeofenceLocationScreen({
    super.key,
    this.initialPosition,
    this.initialRadius = 100,
    this.initialAddress,
    this.isPolygonMode = false,
  });

  @override
  State<SelectGeofenceLocationScreen> createState() =>
      _SelectGeofenceLocationScreenState();
}

class _SelectGeofenceLocationScreenState
    extends State<SelectGeofenceLocationScreen> {
  static const Color _pinkColor = Color(0xFFFF2F68);
  static const LatLng _defaultCenter = LatLng(31.4504, 74.2940);

  GoogleMapController? _mapController;
  late LatLng _center;
  late double _radius;
  late String _address;
  double _zoom = 15;

  @override
  void initState() {
    super.initState();
    _center = widget.initialPosition ?? _defaultCenter;
    _radius = widget.initialRadius.clamp(100, 5000);
    _address = widget.initialAddress ??
        '99W5+QCQ Gajju Matah Gajju Matah Lahore Punjab,';
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _zoomBy(double delta) async {
    _zoom = (_zoom + delta).clamp(3, 20);
    await _mapController?.animateCamera(CameraUpdate.zoomTo(_zoom));
  }

  void _changeRadius(double delta) {
    setState(() {
      _radius = (_radius + delta).clamp(100, 5000);
    });
  }

  void _confirm() {
    Navigator.pop(
      context,
      GeofenceLocationResult(
        position: _center,
        radiusMeters: _radius,
        address: _address,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: _center,
                      zoom: _zoom,
                    ),
                    myLocationButtonEnabled: false,
                    zoomControlsEnabled: false,
                    mapToolbarEnabled: false,
                    compassEnabled: false,
                    markers: <Marker>{
                      Marker(
                        markerId: const MarkerId('selected'),
                        position: _center,
                        icon: BitmapDescriptor.defaultMarkerWithHue(
                          BitmapDescriptor.hueRose,
                        ),
                      ),
                    },
                    circles: widget.isPolygonMode
                        ? <Circle>{}
                        : <Circle>{
                            Circle(
                              circleId: const CircleId('radius'),
                              center: _center,
                              radius: _radius,
                              fillColor: _pinkColor.withValues(alpha: 0.10),
                              strokeColor: Colors.transparent,
                              strokeWidth: 0,
                            ),
                          },
                    onTap: widget.isPolygonMode
                        ? (LatLng point) {
                            setState(() {
                              _center = point;
                            });
                          }
                        : null,
                    onMapCreated: (GoogleMapController controller) {
                      _mapController = controller;
                    },
                    onCameraMove: (CameraPosition position) {
                      _center = position.target;
                      _zoom = position.zoom;
                    },
                    onCameraIdle: () {
                      setState(() {});
                    },
                  ),
                  Positioned(
                    left: 14,
                    right: 14,
                    top: 12,
                    child: Container(
                      height: 48,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: _pinkColor, width: 1.4),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.search, color: _pinkColor, size: 22),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Search Location',
                              style: TextStyle(
                                color: Colors.black54,
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    right: 14,
                    bottom: 18,
                    child: Column(
                      children: [
                        _ZoomButton(
                          icon: Icons.add,
                          onTap: () => _zoomBy(1),
                        ),
                        const SizedBox(height: 8),
                        _ZoomButton(
                          icon: Icons.remove,
                          onTap: () => _zoomBy(-1),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!widget.isPolygonMode) ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.location_on,
                          color: _pinkColor,
                          size: 22,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            _address,
                            style: const TextStyle(
                              color: Color(0xFF444444),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Select Radius Meter',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Text(
                          _radius.toStringAsFixed(1),
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _RadiusRoundButton(
                          icon: Icons.remove,
                          onTap: () => _changeRadius(-50),
                        ),
                        Expanded(
                          child: SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              activeTrackColor: const Color(0xFF555555),
                              inactiveTrackColor: const Color(0xFFBDBDBD),
                              thumbColor: _pinkColor,
                              overlayColor:
                                  _pinkColor.withValues(alpha: 0.15),
                              trackHeight: 3,
                              thumbShape: const RoundSliderThumbShape(
                                enabledThumbRadius: 10,
                              ),
                            ),
                            child: Slider(
                              min: 100,
                              max: 5000,
                              value: _radius,
                              onChanged: (double value) {
                                setState(() {
                                  _radius = value;
                                });
                              },
                            ),
                          ),
                        ),
                        _RadiusRoundButton(
                          icon: Icons.add,
                          onTap: () => _changeRadius(50),
                        ),
                      ],
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '100m',
                            style: TextStyle(
                              color: Colors.black54,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '5000m',
                            style: TextStyle(
                              color: Colors.black54,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ] else ...[
                    const Padding(
                      padding: EdgeInsets.only(bottom: 14),
                      child: Text(
                        'Note: Click on the map to draw a polygon',
                        style: TextStyle(
                          color: Colors.black87,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _confirm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _pinkColor,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Confirm Location',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
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

class _ZoomButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _ZoomButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(6),
      elevation: 3,
      shadowColor: Colors.black26,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(icon, color: Colors.black87, size: 22),
        ),
      ),
    );
  }
}

class _RadiusRoundButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _RadiusRoundButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFFF2F68),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 36,
          height: 36,
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      ),
    );
  }
}
