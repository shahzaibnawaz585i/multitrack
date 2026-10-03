import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../l10n/app_l10n.dart';
import '../../models/stoppage_report_event.dart';

class StoppageReportMapScreen extends StatefulWidget {
  const StoppageReportMapScreen({
    super.key,
    required this.event,
  });

  final StoppageReportEvent event;

  @override
  State<StoppageReportMapScreen> createState() =>
      _StoppageReportMapScreenState();
}

class _StoppageReportMapScreenState extends State<StoppageReportMapScreen> {
  static const Color _accent = Color(0xFFF53D6B);

  GoogleMapController? _mapController;

  @override
  Widget build(BuildContext context) {
    final LatLng target = LatLng(
      widget.event.latitude,
      widget.event.longitude,
    );

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Theme.of(context).cardColor,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: _accent, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          context.tr('Stoppage'),
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
      ),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: target,
          zoom: 15,
        ),
        markers: <Marker>{
          Marker(
            markerId: const MarkerId('stoppage_event'),
            position: target,
            infoWindow: InfoWindow(
              title: widget.event.durationLabel,
              snippet: widget.event.address,
            ),
          ),
        },
        myLocationButtonEnabled: false,
        zoomControlsEnabled: true,
        onMapCreated: (GoogleMapController controller) {
          _mapController = controller;
        },
      ),
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}
