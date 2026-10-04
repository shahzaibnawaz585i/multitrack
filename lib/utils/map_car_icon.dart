import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'vehicle_status_colors.dart';

/// Top-down vehicle marker for live tracking — tinted by [VehicleStatusColors].
class MapCarIcon {
  MapCarIcon._();

  static final Map<int, BitmapDescriptor> _cache = <int, BitmapDescriptor>{};

  static BitmapDescriptor? cachedForColor(Color color) =>
      _cache[color.toARGB32()];

  static Future<BitmapDescriptor> forColor(Color color) async {
    final int key = color.toARGB32();
    final BitmapDescriptor? cached = _cache[key];
    if (cached != null) {
      return cached;
    }
    final BitmapDescriptor icon = await _create(color);
    _cache[key] = icon;
    return icon;
  }

  static Future<void> preloadStatusIcons() async {
    await Future.wait<BitmapDescriptor>(<Future<BitmapDescriptor>>[
      forColor(VehicleStatusColors.running),
      forColor(VehicleStatusColors.idle),
      forColor(VehicleStatusColors.stopped),
      forColor(VehicleStatusColors.offline),
    ]);
  }

  static Future<BitmapDescriptor> forVehicleStatus({
    required String status,
    required String speed,
  }) async {
    return forColor(
      VehicleStatusColors.markerColor(status: status, speed: speed),
    );
  }

  /// Fleet map markers — status only (no speed string).
  static Future<BitmapDescriptor> forStatus(String status) {
    return forVehicleStatus(status: status, speed: '');
  }

  static void clearCache() => _cache.clear();

  static Future<BitmapDescriptor> _create(Color bodyColor) async {
    const double size = 112;
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(recorder);
    final Offset center = Offset(size / 2, size / 2);

    canvas.drawCircle(
      center.translate(0, 3),
      22,
      Paint()..color = const Color(0x55000000),
    );

    final Paint bodyPaint = Paint()..color = bodyColor;
    final Paint cabinPaint = Paint()..color = bodyColor.withValues(alpha: 0.82);
    final Paint outline = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2;

    final RRect body = RRect.fromRectAndRadius(
      Rect.fromCenter(center: center.translate(0, 4), width: 34, height: 58),
      const Radius.circular(10),
    );
    canvas.drawRRect(body, bodyPaint);
    canvas.drawRRect(body, outline);

    final RRect cabin = RRect.fromRectAndRadius(
      Rect.fromCenter(center: center.translate(0, -6), width: 26, height: 22),
      const Radius.circular(6),
    );
    canvas.drawRRect(cabin, cabinPaint);
    canvas.drawRRect(cabin, outline);

    canvas.drawCircle(
      center.translate(-11, 18),
      4.5,
      Paint()..color = const Color(0xFF212121),
    );
    canvas.drawCircle(
      center.translate(11, 18),
      4.5,
      Paint()..color = const Color(0xFF212121),
    );
    canvas.drawCircle(
      center.translate(-11, -14),
      4.5,
      Paint()..color = const Color(0xFF212121),
    );
    canvas.drawCircle(
      center.translate(11, -14),
      4.5,
      Paint()..color = const Color(0xFF212121),
    );

    final ui.Image image =
        await recorder.endRecording().toImage(size.toInt(), size.toInt());
    final ByteData? bytes =
        await image.toByteData(format: ui.ImageByteFormat.png);
    if (bytes == null) {
      return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
    }
    return BitmapDescriptor.bytes(bytes.buffer.asUint8List(), width: 46);
  }

  /// Car nose points up; rotation on the map aligns with bearing.
  static const Offset markerAnchor = Offset(0.5, 0.5);
}
