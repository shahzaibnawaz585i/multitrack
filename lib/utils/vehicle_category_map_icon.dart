import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../services/vehicle_icon_service.dart';

/// Top-down style markers per vehicle category (Update Icon dialog).
class VehicleCategoryMapIcon {
  VehicleCategoryMapIcon._();

  static final Map<String, BitmapDescriptor> _cache = <String, BitmapDescriptor>{};

  static const Offset markerAnchor = Offset(0.5, 0.5);

  static Future<BitmapDescriptor> forSlug(
    String slug, {
    Color tint = const Color(0xFFF53D6B),
  }) async {
    final String key = '${slug.trim().toLowerCase()}_${tint.toARGB32()}';
    final BitmapDescriptor? cached = _cache[key];
    if (cached != null) {
      return cached;
    }
    final BitmapDescriptor icon = await _create(slug, tint);
    _cache[key] = icon;
    return icon;
  }

  static IconData iconDataForSlug(String slug) {
    final VehicleIconCategory? cat = VehicleIconCategory.byApiSlug(slug);
    return _iconForCategory(cat?.label ?? slug);
  }

  static IconData _iconForCategory(String label) {
    switch (label.trim().toLowerCase()) {
      case 'bus':
        return Icons.directions_bus;
      case 'truck':
        return Icons.local_shipping;
      case 'scooter':
        return Icons.electric_scooter;
      case 'user':
        return Icons.person_pin;
      case 'jcb':
        return Icons.construction;
      case 'rickshaw':
        return Icons.electric_rickshaw;
      case 'pickup':
        return Icons.airport_shuttle;
      case 'tractor':
        return Icons.agriculture;
      case 'motorcycle':
        return Icons.two_wheeler;
      case 'ambulance':
        return Icons.local_hospital;
      case 'crane':
        return Icons.precision_manufacturing;
      case 'machine':
        return Icons.settings;
      default:
        return Icons.directions_car;
    }
  }

  static Future<BitmapDescriptor> _create(String slug, Color tint) async {
    const double size = 96;
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(recorder);
    final Offset center = Offset(size / 2, size / 2);

    canvas.drawCircle(
      center.translate(0, 3),
      22,
      Paint()..color = const Color(0x44000000),
    );
    canvas.drawCircle(center, 22, Paint()..color = Colors.white);
    canvas.drawCircle(
      center,
      22,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..color = tint,
    );

    final IconData glyph = iconDataForSlug(slug);
    final TextPainter painter = TextPainter(
      textDirection: TextDirection.ltr,
      text: TextSpan(
        text: String.fromCharCode(glyph.codePoint),
        style: TextStyle(
          fontSize: 34,
          fontFamily: glyph.fontFamily,
          package: glyph.fontPackage,
          color: tint,
        ),
      ),
    )..layout();
    painter.paint(
      canvas,
      Offset(
        center.dx - painter.width / 2,
        center.dy - painter.height / 2,
      ),
    );

    final ui.Image image =
        await recorder.endRecording().toImage(size.toInt(), size.toInt());
    final ByteData? bytes =
        await image.toByteData(format: ui.ImageByteFormat.png);
    if (bytes == null) {
      return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRose);
    }
    return BitmapDescriptor.bytes(bytes.buffer.asUint8List(), width: 44);
  }

  static void clearCache() {
    _cache.clear();
  }
}
