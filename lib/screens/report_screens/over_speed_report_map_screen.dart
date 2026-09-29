import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../l10n/app_l10n.dart';
import '../../models/over_speed_report_event.dart';

class OverSpeedReportMapScreen extends StatefulWidget {
  const OverSpeedReportMapScreen({
    super.key,
    required this.event,
  });

  final OverSpeedReportEvent event;

  @override
  State<OverSpeedReportMapScreen> createState() =>
      _OverSpeedReportMapScreenState();
}

class _OverSpeedReportMapScreenState extends State<OverSpeedReportMapScreen> {
  static const Color _accent = Color(0xFFF53D6B);

  GoogleMapController? _mapController;

  @override
  Widget build(BuildContext context) {
    final LatLng target = LatLng(widget.event.latitude, widget.event.longitude);

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
          context.tr('Over Speed Report'),
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
                markerId: const MarkerId('overspeed_event'),
                position: target,
                infoWindow: InfoWindow(
                  title: widget.event.speedLabel,
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
                        const Icon(Icons.speed, color: _accent, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          widget.event.speedLabel,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
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
