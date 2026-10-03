import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../l10n/app_l10n.dart';
import '../../models/ignition_report_event.dart';

class IgnitionReportMapScreen extends StatefulWidget {
  const IgnitionReportMapScreen({
    super.key,
    required this.event,
  });

  final IgnitionReportEvent event;

  @override
  State<IgnitionReportMapScreen> createState() =>
      _IgnitionReportMapScreenState();
}

class _IgnitionReportMapScreenState extends State<IgnitionReportMapScreen> {
  static const Color _accent = Color(0xFFF53D6B);

  GoogleMapController? _mapController;

  @override
  Widget build(BuildContext context) {
    final LatLng target = LatLng(
      widget.event.latitude,
      widget.event.longitude,
    );
    final Color statusColor =
        widget.event.isOn ? const Color(0xFF43A047) : _accent;

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
          context.tr('Ignition Report'),
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
      ),
      body: Stack(
        children: <Widget>[
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: target,
              zoom: 15,
            ),
            markers: <Marker>{
              Marker(
                markerId: const MarkerId('ignition_event'),
                position: target,
                icon: BitmapDescriptor.defaultMarkerWithHue(
                  widget.event.isOn
                      ? BitmapDescriptor.hueGreen
                      : BitmapDescriptor.hueRed,
                ),
                infoWindow: InfoWindow(
                  title: context.tr(widget.event.statusLabel),
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
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: Material(
              elevation: 6,
              borderRadius: BorderRadius.circular(14),
              color: Theme.of(context).cardColor,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Icon(Icons.power_settings_new, color: statusColor, size: 22),
                        const SizedBox(width: 8),
                        Text(
                          context.tr(widget.event.statusLabel),
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const Icon(Icons.access_time, color: _accent, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            widget.event.timeLabel,
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const Icon(Icons.location_on, color: _accent, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            widget.event.address,
                            style: TextStyle(
                              color: Colors.grey.shade800,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}
