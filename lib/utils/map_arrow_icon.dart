import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Cached navigation-style arrow markers for Google Maps.
class MapArrowIcon {
  MapArrowIcon._();

  static final Map<int, BitmapDescriptor> _cache = <int, BitmapDescriptor>{};

  static Future<BitmapDescriptor> forColor(Color color) async {
    final int key = color.toARGB32();
    final BitmapDescriptor? cached = _cache[key];
    if (cached != null) return cached;

    final BitmapDescriptor icon = await _create(color);
    _cache[key] = icon;
    return icon;
  }

  static Future<BitmapDescriptor> _create(Color color) async {
    const double size = 96;
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(recorder);
    final Offset center = Offset(size / 2, size / 2);

    canvas.drawCircle(
      center.translate(0, 2),
      16,
      Paint()..color = const Color(0x44000000),
    );
    canvas.drawCircle(center, 16, Paint()..color = Colors.white);

    final Path arrow = Path()
      ..moveTo(center.dx, center.dy - 20)
      ..lineTo(center.dx + 13, center.dy + 12)
      ..lineTo(center.dx, center.dy + 2)
      ..lineTo(center.dx - 13, center.dy + 12)
      ..close();
    canvas.drawPath(arrow, Paint()..color = color);

    final ui.Image image =
        await recorder.endRecording().toImage(size.toInt(), size.toInt());
    final ByteData? bytes =
        await image.toByteData(format: ui.ImageByteFormat.png);
    if (bytes == null) {
      return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
    }
    return BitmapDescriptor.bytes(bytes.buffer.asUint8List(), width: 42);
  }

  /// Anchor so the arrow tip sits on the road (Google Maps style).
  static const Offset markerAnchor = Offset(0.5, 0.29);
}
