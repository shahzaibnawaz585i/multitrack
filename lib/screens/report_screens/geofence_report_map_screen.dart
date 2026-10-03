import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../l10n/app_l10n.dart';
import '../../models/geofence_report_event.dart';

class GeofenceReportMapScreen extends StatefulWidget {
  const GeofenceReportMapScreen({
    super.key,
    required this.event,
  });

  final GeofenceReportEvent event;

  @override
  State<GeofenceReportMapScreen> createState() =>
      _GeofenceReportMapScreenState();
}

class _GeofenceReportMapScreenState extends State<GeofenceReportMapScreen> {
  static const Color _accent = Color(0xFFF53D6B);

  GoogleMapController? _mapController;

  @override
  Widget build(BuildContext context) {
    final LatLng target = LatLng(
      widget.event.latitude,
      widget.event.longitude,
    );
    final Color statusColor =
        widget.event.isEnter ? const Color(0xFF43A047) : _accent;

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
          context.tr('Geofence Report'),
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
              target: target.latitude != 0 || target.longitude != 0
                  ? target
                  : const LatLng(24.8607, 67.0011),
              zoom: 15,
            ),
            markers: <Marker>{
              if (target.latitude != 0 || target.longitude != 0)
                Marker(
                  markerId: const MarkerId('geofence_event'),
                  position: target,
                  icon: BitmapDescriptor.defaultMarkerWithHue(
                    widget.event.isEnter
                        ? BitmapDescriptor.hueGreen
                        : BitmapDescriptor.hueRed,
                  ),
                  infoWindow: InfoWindow(
                    title: widget.event.statusLabel,
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
                        GeofenceStatusPentagon(
                          color: statusColor,
                          size: 28,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            context.tr(widget.event.statusLabel),
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                              color: statusColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
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

/// Pentagon outline used on geofence report cards (green enter / red exit).
class GeofenceStatusPentagon extends StatelessWidget {
  const GeofenceStatusPentagon({
    super.key,
    required this.color,
    this.size = 36,
  });

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _PentagonOutlinePainter(color: color),
      ),
    );
  }
}

class _PentagonOutlinePainter extends CustomPainter {
  _PentagonOutlinePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final Path path = Path();
    final double w = size.width;
    final double h = size.height;
    path.moveTo(w * 0.5, h * 0.05);
    path.lineTo(w * 0.95, h * 0.38);
    path.lineTo(w * 0.78, h * 0.95);
    path.lineTo(w * 0.22, h * 0.95);
    path.lineTo(w * 0.05, h * 0.38);
    path.close();

    final Paint stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2;
    canvas.drawPath(path, stroke);
  }

  @override
  bool shouldRepaint(covariant _PentagonOutlinePainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
