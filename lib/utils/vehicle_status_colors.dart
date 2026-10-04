import 'package:flutter/material.dart';

/// Live map marker colors: stopped = red, idle = yellow, running = green.
class VehicleStatusColors {
  VehicleStatusColors._();

  static const Color running = Color(0xFF00C853);
  static const Color idle = Color(0xFFFFC107);
  static const Color stopped = Color(0xFFD50000);
  static const Color offline = Color(0xFF757575);

  static Color markerColor({
    required String status,
    required String speed,
  }) {
    switch (status.trim().toLowerCase()) {
      case 'running':
      case 'move':
      case 'moving':
        return running;
      case 'idle':
        return idle;
      case 'stopped':
        return stopped;
      case 'not reporting':
      case 'inactive':
        return offline;
      default:
        break;
    }
    final double kmh = double.tryParse(speed.trim()) ?? 0.0;
    if (kmh > 3.0) {
      return running;
    }
    if (kmh > 0.5) {
      return idle;
    }
    return stopped;
  }
}
