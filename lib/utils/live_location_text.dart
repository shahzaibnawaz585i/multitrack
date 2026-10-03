import '../models/vehicle_model.dart';
import 'coordinate_parser.dart';

/// Shared rules for showing live street addresses across the app.
class LiveLocationText {
  LiveLocationText._();

  static const String unavailable = 'Location not available';

  static bool isPlaceholder(String? value) {
    final String trimmed = (value ?? '').trim();
    if (trimmed.isEmpty ||
        trimmed == '-' ||
        trimmed == '--' ||
        trimmed == unavailable) {
      return true;
    }
    final String lower = trimmed.toLowerCase();
    return lower == 'no data' ||
        lower == 'null' ||
        lower == 'n/a' ||
        lower == 'unknown' ||
        lower == 'nodata';
  }

  static bool isUsableAddress(String? value) {
    if (isPlaceholder(value)) {
      return false;
    }
    return !CoordinateParser.looksLikeCoordinatePair(value!.trim());
  }

  static String formatCoordinates(double lat, double lng) {
    return '${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}';
  }

  /// Best label for UI: API address, else coordinates, else placeholder.
  static String forVehicle(VehicleModel vehicle) {
    final String raw = vehicle.location.trim();
    if (isUsableAddress(raw)) {
      return raw;
    }

    final double? lat = vehicle.latitude;
    final double? lng = vehicle.longitude;
    if (lat != null && lng != null && (lat != 0.0 || lng != 0.0)) {
      return formatCoordinates(lat, lng);
    }

    if (!isPlaceholder(raw) && raw.isNotEmpty) {
      return raw;
    }

    return unavailable;
  }
}
