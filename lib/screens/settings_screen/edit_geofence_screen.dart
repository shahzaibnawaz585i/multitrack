import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'select_geofence_location_screen.dart';

class EditGeofenceScreen extends StatefulWidget {
  final String initialName;
  final LatLng initialPosition;
  final double initialRadius;
  final String initialAddress;
  final bool isCircular;

  const EditGeofenceScreen({
    super.key,
    required this.initialName,
    required this.initialPosition,
    required this.initialRadius,
    required this.initialAddress,
    required this.isCircular,
  });

  @override
  State<EditGeofenceScreen> createState() => _EditGeofenceScreenState();
}

class _EditGeofenceScreenState extends State<EditGeofenceScreen> {
  static const Color _pinkColor = Color(0xFFFF2F68);
  static const Color _bgColor = Color(0xFFF5F5F5);

  late final TextEditingController _nameController;
  GoogleMapController? _mapController;
  late LatLng _position;
  late double _radius;
  late String _address;
  double _zoom = 15;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _position = widget.initialPosition;
    _radius = widget.initialRadius;
    _address = widget.initialAddress;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _openLocationPicker() async {
    final GeofenceLocationResult? result =
        await Navigator.push<GeofenceLocationResult>(
      context,
      MaterialPageRoute<GeofenceLocationResult>(
        builder: (_) => SelectGeofenceLocationScreen(
          initialPosition: _position,
          initialRadius: _radius,
          initialAddress: _address,
          isPolygonMode: !widget.isCircular,
        ),
      ),
    );

    if (result == null || !mounted) {
      return;
    }

    setState(() {
      _position = result.position;
      _radius = result.radiusMeters;
      _address = result.address;
    });

    await _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(_position, _zoom),
    );
  }

  void _onUpdate() {
    final String name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter fence name')),
      );
      return;
    }

    Navigator.pop(
      context,
      EditGeofenceResult(
        name: name,
        position: _position,
        radiusMeters: _radius,
        address: _address,
      ),
    );
  }

  Future<void> _zoomBy(double delta) async {
    _zoom = (_zoom + delta).clamp(3, 20);
    await _mapController?.animateCamera(CameraUpdate.zoomTo(_zoom));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: _bgColor,
        surfaceTintColor: _bgColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: _pinkColor,
            size: 20,
          ),
        ),
        title: const Text(
          'Edit Geofences',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Enter Fence Name',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _nameController,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 15,
                      ),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 14,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: _pinkColor,
                            width: 1.2,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: _pinkColor,
                            width: 1.6,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Update Location',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: _openLocationPicker,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 13,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.black87),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.search,
                              color: _pinkColor,
                              size: 22,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _address.isEmpty ? 'Search Location' : _address,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: _address.isEmpty
                                      ? Colors.black45
                                      : Colors.black87,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: SizedBox(
                        height: 220,
                        width: double.infinity,
                        child: Stack(
                          children: [
                            GoogleMap(
                              initialCameraPosition: CameraPosition(
                                target: _position,
                                zoom: _zoom,
                              ),
                              myLocationButtonEnabled: false,
                              zoomControlsEnabled: false,
                              mapToolbarEnabled: false,
                              compassEnabled: false,
                              markers: <Marker>{
                                Marker(
                                  markerId: const MarkerId('edit'),
                                  position: _position,
                                  icon: BitmapDescriptor.defaultMarkerWithHue(
                                    BitmapDescriptor.hueRose,
                                  ),
                                ),
                              },
                              circles: widget.isCircular
                                  ? <Circle>{
                                      Circle(
                                        circleId: const CircleId('editRadius'),
                                        center: _position,
                                        radius: _radius,
                                        fillColor: _pinkColor.withValues(
                                          alpha: 0.10,
                                        ),
                                        strokeColor: Colors.transparent,
                                        strokeWidth: 0,
                                      ),
                                    }
                                  : <Circle>{},
                              onMapCreated: (GoogleMapController controller) {
                                _mapController = controller;
                              },
                            ),
                            Positioned(
                              right: 10,
                              bottom: 10,
                              child: Column(
                                children: [
                                  _MiniZoomButton(
                                    icon: Icons.add,
                                    onTap: () => _zoomBy(1),
                                  ),
                                  const SizedBox(height: 8),
                                  _MiniZoomButton(
                                    icon: Icons.remove,
                                    onTap: () => _zoomBy(-1),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _pinkColor,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'CANCEL',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _onUpdate,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _pinkColor,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'UPDATE',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class EditGeofenceResult {
  final String name;
  final LatLng position;
  final double radiusMeters;
  final String address;

  const EditGeofenceResult({
    required this.name,
    required this.position,
    required this.radiusMeters,
    required this.address,
  });
}

class _MiniZoomButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _MiniZoomButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(6),
      elevation: 3,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: SizedBox(
          width: 36,
          height: 36,
          child: Icon(icon, size: 20, color: Colors.black87),
        ),
      ),
    );
  }
}
