import 'package:google_maps_flutter/google_maps_flutter.dart';

class GeofenceModel {
  const GeofenceModel({
    this.id,
    required this.name,
    required this.position,
    required this.radiusMeters,
    required this.address,
    required this.isCircular,
  });

  final int? id;
  final String name;
  final LatLng position;
  final double radiusMeters;
  final String address;
  final bool isCircular;

  String get radiusLabel => 'Radius : ${radiusMeters.toStringAsFixed(2)}';

  static GeofenceModel? fromJson(Map<String, dynamic> json) {
    final String name = (json['name'] ?? json['title'] ?? '').toString().trim();
    if (name.isEmpty) {
      return null;
    }

    final int? id = _parseInt(json['id']);
    final bool isCircular = _isCircular(json);
    final double radius = _parseDouble(
          json['radius'] ?? json['radius_meters'] ?? json['distance'],
        ) ??
        0;

    LatLng? position;
    final dynamic center = json['center'];
    if (center is Map) {
      position = _latLngFromMap(center);
    }
    position ??= _latLngFromCoordinates(json['coordinates']?.toString());

    if (position == null) {
      final double? lat = _parseDouble(json['lat'] ?? json['latitude']);
      final double? lng = _parseDouble(json['lng'] ?? json['longitude'] ?? json['lon']);
      if (lat != null && lng != null) {
        position = LatLng(lat, lng);
      }
    }

    if (position == null) {
      return null;
    }

    final String address = (json['address'] ??
            json['description'] ??
            json['formatted_address'] ??
            '')
        .toString()
        .trim();

    return GeofenceModel(
      id: id,
      name: name,
      position: position,
      radiusMeters: radius,
      address: address.isNotEmpty ? address : '${position.latitude}, ${position.longitude}',
      isCircular: isCircular,
    );
  }

  static bool _isCircular(Map<String, dynamic> json) {
    final String type = (json['type'] ?? json['shape'] ?? '').toString().toLowerCase();
    if (type.contains('poly')) {
      return false;
    }
    if (type.contains('circle') || type.contains('round')) {
      return true;
    }
    final double radius = _parseDouble(json['radius']) ?? 0;
    return radius > 0;
  }

  static LatLng? _latLngFromMap(Map<dynamic, dynamic> map) {
    final double? lat = _parseDouble(map['lat'] ?? map['latitude']);
    final double? lng = _parseDouble(map['lng'] ?? map['longitude'] ?? map['lon']);
    if (lat != null && lng != null) {
      return LatLng(lat, lng);
    }
    return null;
  }

  static LatLng? _latLngFromCoordinates(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return null;
    }
    final RegExp pair = RegExp(r'(-?\d+\.?\d*)[,\s]+(-?\d+\.?\d*)');
    final RegExpMatch? match = pair.firstMatch(raw);
    if (match == null) {
      return null;
    }
    final double? lat = double.tryParse(match.group(1)!);
    final double? lng = double.tryParse(match.group(2)!);
    if (lat != null && lng != null) {
      return LatLng(lat, lng);
    }
    return null;
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value.toString().replaceAll(RegExp(r'[^0-9.\-]'), ''));
  }

  static int? _parseInt(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is int) {
      return value;
    }
    return int.tryParse(value.toString());
  }
}
