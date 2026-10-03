import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../l10n/app_l10n.dart';
import '../../models/trip_report_event.dart';
import '../../services/history_service.dart';

class TripReportMapScreen extends StatefulWidget {
  const TripReportMapScreen({
    super.key,
    required this.event,
  });

  final TripReportEvent event;

  @override
  State<TripReportMapScreen> createState() => _TripReportMapScreenState();
}

class _TripReportMapScreenState extends State<TripReportMapScreen> {
  static const Color _accent = Color(0xFFF53D6B);

  GoogleMapController? _mapController;
  bool _loadingRoute = true;
  List<LatLng> _routePoints = <LatLng>[];

  @override
  void initState() {
    super.initState();
    _loadRoute();
  }

  Future<void> _loadRoute() async {
    final TripReportEvent event = widget.event;
    List<LatLng> points = <LatLng>[];

    final (double lat, double lng)? startValid = _validCoord(
      event.startLatitude,
      event.startLongitude,
    );
    final (double lat, double lng)? endValid = _validCoord(
      event.endLatitude,
      event.endLongitude,
    );

    if (event.deviceId != null &&
        event.startDateTime != null &&
        event.endDateTime != null) {
      try {
        final HistoryRoute route = await HistoryService.getRoute(
          deviceId: event.deviceId!,
          from: event.startDateTime!,
          to: event.endDateTime!,
          forceRefresh: false,
        );
        points = route.points.map((HistoryPoint p) => p.position).toList();
      } catch (_) {}
    }

    if (points.length < 2) {
      if (startValid != null && endValid != null) {
        points = <LatLng>[
          LatLng(startValid.$1, startValid.$2),
          LatLng(endValid.$1, endValid.$2),
        ];
      } else if (startValid != null) {
        points = <LatLng>[LatLng(startValid.$1, startValid.$2)];
      } else if (endValid != null) {
        points = <LatLng>[LatLng(endValid.$1, endValid.$2)];
      }
    }

    if (!mounted) {
      return;
    }
    setState(() {
      _routePoints = points;
      _loadingRoute = false;
    });

    if (_mapController != null && points.isNotEmpty) {
      await _fitCamera(points);
    }
  }

  (double lat, double lng)? _validCoord(double lat, double lng) {
    if (lat == 0 && lng == 0) {
      return null;
    }
    if (lat.abs() > 90 || lng.abs() > 180) {
      return null;
    }
    return (lat, lng);
  }

  Future<void> _fitCamera(List<LatLng> points) async {
    if (points.length == 1) {
      await _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(points.first, 15),
      );
      return;
    }

    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (final LatLng p in points) {
      minLat = minLat < p.latitude ? minLat : p.latitude;
      maxLat = maxLat > p.latitude ? maxLat : p.latitude;
      minLng = minLng < p.longitude ? minLng : p.longitude;
      maxLng = maxLng > p.longitude ? maxLng : p.longitude;
    }

    final LatLngBounds bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
    await _mapController?.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 48),
    );
  }

  Set<Marker> _buildMarkers() {
    final TripReportEvent event = widget.event;
    final Set<Marker> markers = <Marker>{};

    final (double lat, double lng)? start = _validCoord(
      event.startLatitude,
      event.startLongitude,
    );
    final (double lat, double lng)? end = _validCoord(
      event.endLatitude,
      event.endLongitude,
    );

    if (start != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('trip_start'),
          position: LatLng(start.$1, start.$2),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueGreen,
          ),
          infoWindow: InfoWindow(
            title: context.tr('Start'),
            snippet: event.startLocation,
          ),
        ),
      );
    }
    if (end != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('trip_end'),
          position: LatLng(end.$1, end.$2),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: InfoWindow(
            title: context.tr('End'),
            snippet: event.endLocation,
          ),
        ),
      );
    }

    if (markers.isEmpty && _routePoints.isNotEmpty) {
      markers.add(
        Marker(
          markerId: const MarkerId('trip_start'),
          position: _routePoints.first,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueGreen,
          ),
        ),
      );
      if (_routePoints.length > 1) {
        markers.add(
          Marker(
            markerId: const MarkerId('trip_end'),
            position: _routePoints.last,
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          ),
        );
      }
    }

    return markers;
  }

  @override
  Widget build(BuildContext context) {
    final LatLng fallback = _routePoints.isNotEmpty
        ? _routePoints.first
        : const LatLng(24.8607, 67.0011);

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
          context.tr('Trip Report'),
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
              target: fallback,
              zoom: 13,
            ),
            polylines: _routePoints.length >= 2
                ? <Polyline>{
                    Polyline(
                      polylineId: const PolylineId('trip_route'),
                      points: _routePoints,
                      color: _accent,
                      width: 5,
                      startCap: Cap.roundCap,
                      endCap: Cap.roundCap,
                    ),
                  }
                : const <Polyline>{},
            markers: _buildMarkers(),
            myLocationButtonEnabled: false,
            zoomControlsEnabled: true,
            onMapCreated: (GoogleMapController controller) async {
              _mapController = controller;
              if (!_loadingRoute && _routePoints.isNotEmpty) {
                await _fitCamera(_routePoints);
              }
            },
          ),
          if (_loadingRoute)
            const Center(
              child: CircularProgressIndicator(color: _accent),
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
                    Text(
                      '${context.tr('Duration')}: ${widget.event.durationLabel}  •  ${widget.event.distanceLabel}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const Icon(Icons.circle, color: Colors.green, size: 12),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            widget.event.startLocation,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const Icon(Icons.circle, color: _accent, size: 12),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            widget.event.endLocation,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade800,
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
