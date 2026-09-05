import 'package:flutter/material.dart';

import '../../l10n/app_l10n.dart';
import '../../theme/app_theme_tokens.dart';

import 'select_geofence_location_screen.dart';

class AddGeofenceScreen extends StatefulWidget {
  const AddGeofenceScreen({super.key});

  @override
  State<AddGeofenceScreen> createState() => _AddGeofenceScreenState();
}

class _AddGeofenceScreenState extends State<AddGeofenceScreen> {
  static const Color _pinkColor = Color(0xFFFF2F68);
  
  final TextEditingController _nameController = TextEditingController();
  bool _isCircular = true;
  GeofenceLocationResult? _selectedLocation;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _openLocationPicker() async {
    final GeofenceLocationResult? result =
        await Navigator.push<GeofenceLocationResult>(
      context,
      MaterialPageRoute<GeofenceLocationResult>(
        builder: (_) => SelectGeofenceLocationScreen(
          initialPosition: _selectedLocation?.position,
          initialRadius: _selectedLocation?.radiusMeters ?? 100,
          initialAddress: _selectedLocation?.address,
          isPolygonMode: !_isCircular,
        ),
      ),
    );

    if (result == null || !mounted) {
      return;
    }

    setState(() {
      _selectedLocation = result;
    });
  }

  void _onApply() {
    final String name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('Please enter fence name'))),
      );
      return;
    }

    if (_selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add a location')),
      );
      return;
    }

    Navigator.pop(
      context,
      AddGeofenceResult(
        name: name,
        isCircular: _isCircular,
        location: _selectedLocation!,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        surfaceTintColor: Theme.of(context).scaffoldBackgroundColor,
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
          context.tr('Add Geofence'),
          style: TextStyle(
            color: context.textColor,
            fontSize: 22,
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
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 20),
                decoration: BoxDecoration(
                  color: context.containerColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Enter Fence Name',
                      style: TextStyle(
                        color: context.textColor,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _nameController,
                      style: TextStyle(
                        color: context.textColor,
                        fontSize: 15,
                      ),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: context.fieldFillColor,
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
                    Row(
                      children: [
                        _FenceTypeRadio(
                          label: 'Circular',
                          selected: _isCircular,
                          onTap: () => setState(() => _isCircular = true),
                        ),
                        const SizedBox(width: 28),
                        _FenceTypeRadio(
                          label: 'Polygon',
                          selected: !_isCircular,
                          onTap: () => setState(() => _isCircular = false),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    Text(
                      'Add Location',
                      style: TextStyle(
                        color: context.textColor,
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
                          color: context.containerColor,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: context.textColor,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.search,
                              color: context.textColor,
                              size: 22,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _selectedLocation?.address ?? 'Search Location',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: _selectedLocation == null
                                      ? context.labelTextColor
                                      : context.textColor,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                ),
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
                        child: Text(
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
                        onPressed: _onApply,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _pinkColor,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Apply',
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

class AddGeofenceResult {
  final String name;
  final bool isCircular;
  final GeofenceLocationResult location;

  const AddGeofenceResult({
    required this.name,
    required this.isCircular,
    required this.location,
  });
}

class _FenceTypeRadio extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FenceTypeRadio({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFFFF2F68),
                width: 2,
              ),
            ),
            padding: const EdgeInsets.all(3),
            child: selected
                ? Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFFFF2F68),
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 8),
          Text(
            context.tr(label),
            style: TextStyle(
              color: context.textColor,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
