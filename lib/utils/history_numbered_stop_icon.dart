import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Red square markers with white index (history stop points).
class HistoryNumberedStopIcon {
  HistoryNumberedStopIcon._();

  static final Map<String, BitmapDescriptor> _cache =
      <String, BitmapDescriptor>{};

  static Future<BitmapDescriptor> forNumber(
    int number, {
    Color fill = const Color(0xFFE53935),
  }) async {
    final String label = number.toString();
    final String key = '${fill.toARGB32()}_$label';
    final BitmapDescriptor? cached = _cache[key];
    if (cached != null) {
      return cached;
    }
    final BitmapDescriptor icon = await _create(label, fill);
    _cache[key] = icon;
    return icon;
  }

  static Future<BitmapDescriptor> _create(String text, Color fill) async {
    const double width = 56;
    const double height = 56;
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(recorder);

    final RRect box = RRect.fromRectAndRadius(
      const Rect.fromLTWH(8, 8, width - 16, height - 16),
      const Radius.circular(4),
    );
    canvas.drawRRect(
      box.shift(const Offset(0, 2)),
      Paint()..color = const Color(0x55000000),
    );
    canvas.drawRRect(box, Paint()..color = fill);

    final double fontSize = text.length >= 3
        ? 13
        : text.length >= 2
        ? 17
        : 20;
    final TextPainter painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: Colors.white,
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          height: 1,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: width - 12);

    painter.paint(
      canvas,
      Offset(
        (width - painter.width) / 2,
        (height - painter.height) / 2,
      ),
    );

    final ui.Image image =
        await recorder.endRecording().toImage(width.toInt(), height.toInt());
    final ByteData? bytes =
        await image.toByteData(format: ui.ImageByteFormat.png);
    if (bytes == null) {
      return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
    }
    return BitmapDescriptor.bytes(bytes.buffer.asUint8List(), width: 32);
  }

  static const Offset markerAnchor = Offset(0.5, 0.5);
}
