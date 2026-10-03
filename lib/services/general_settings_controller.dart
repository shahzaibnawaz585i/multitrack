import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GeneralSettingsController extends ChangeNotifier {
  static const String _prefix = 'general_setting_';

  final Map<String, String> _settings = <String, String>{
    'Vehicle Icon Size': 'Small',
    'Time Format': '12 Hours',
    'Speedo Meter': 'Analog',
    'Default Page': 'Vehicle List',
    'Map Type': 'Normal',
    'Fuel Unit': 'Liter',
    'Language': 'English',
    'Speed': 'kmh',
    'Distance': 'km',
    'Area': 'Hectare',
    'Voice Command': 'ON',
    'Currency': 'PKR',
    'Live Page Trail': 'OFF',
    'Show History on Live': 'OFF',
    'Filter History Fluctuation': 'OFF',
    'Farm Calculation': 'OFF',
    'Notification': 'ON',
    'Fuel Reading': 'Device',
    'History Route Color': 'Default Color',
    'History Stoppage Minutes': '5',
    'App Color': 'Default Color',
    'Relay Password': 'Set Password',
  };

  double _zoomLevel = 17.0;
  bool _isReady = false;

  Map<String, String> get settings => Map<String, String>.unmodifiable(_settings);
  bool get isReady => _isReady;
  double get zoomLevel => _zoomLevel;

  String get(String key, {String defaultValue = ''}) {
    return _settings[key] ?? defaultValue;
  }

  String get fuelUnit => get('Fuel Unit', defaultValue: 'Liter');
  String get speedUnit => get('Speed', defaultValue: 'kmh');
  String get distanceUnit => get('Distance', defaultValue: 'km');
  String get timeFormat => get('Time Format', defaultValue: '12 Hours');
  String get mapType => get('Map Type', defaultValue: 'Normal');
  String get currency => get('Currency', defaultValue: 'PKR');

  /// Server/local amounts for this deployment are in PKR.
  static const double pkrPerUsd = 280.0;
  String get vehicleIconSize => get('Vehicle Icon Size', defaultValue: 'Small');
  String get speedoMeter => get('Speedo Meter', defaultValue: 'Analog');
  String get areaUnit => get('Area', defaultValue: 'Hectare');
  bool get isNotificationOn => get('Notification', defaultValue: 'ON') == 'ON';
  bool get isVoiceCommandOn => get('Voice Command', defaultValue: 'ON') == 'ON';
  bool get isAnalogSpeedometer =>
      speedoMeter.trim().toLowerCase() != 'digital';
  bool get livePageTrailOn => get('Live Page Trail', defaultValue: 'OFF') == 'ON';
  bool get showHistoryOnLive =>
      get('Show History on Live', defaultValue: 'OFF') == 'ON';
  bool get filterHistoryFluctuation =>
      get('Filter History Fluctuation', defaultValue: 'OFF') == 'ON';
  bool get farmCalculationOn =>
      get('Farm Calculation', defaultValue: 'OFF') == 'ON';
  String get fuelReadingSource =>
      get('Fuel Reading', defaultValue: 'Device');
  String get historyRouteColorName =>
      get('History Route Color', defaultValue: 'Default Color');

  int get historyStoppageMinutes {
    final int parsed =
        int.tryParse(get('History Stoppage Minutes', defaultValue: '5')) ?? 5;
    return parsed.clamp(1, 120);
  }

  Future<void> setHistoryStoppageMinutes(int minutes) async {
    await setSetting(
      'History Stoppage Minutes',
      minutes.clamp(1, 120).toString(),
    );
  }

  /// Dashboard bottom nav: 0 home, 1 map, 2 list, 3 reports, 4 settings.
  int get defaultDashboardTabIndex {
    switch (get('Default Page', defaultValue: 'Vehicle List')) {
      case 'Map Page':
        return 1;
      case 'Reports Page':
        return 3;
      case 'Vehicle List':
      case 'Live Page':
      default:
        return 2;
    }
  }

  MapType get googleMapType {
    switch (mapType.trim().toLowerCase()) {
      case 'satellite':
        return MapType.satellite;
      case 'hybrid':
        return MapType.hybrid;
      case 'normal':
      default:
        return MapType.normal;
    }
  }

  MapType nextMapType(MapType current) {
    if (current == MapType.normal) {
      return MapType.satellite;
    }
    if (current == MapType.satellite) {
      return MapType.hybrid;
    }
    return MapType.normal;
  }

  String mapTypeLabelFor(MapType type) {
    switch (type) {
      case MapType.satellite:
        return 'Satellite';
      case MapType.hybrid:
        return 'Hybrid';
      case MapType.normal:
      default:
        return 'Normal';
    }
  }

  Color historyRouteColor(Color themePrimary) {
    switch (historyRouteColorName.trim().toLowerCase()) {
      case 'blue':
        return const Color(0xFF2196F3);
      case 'green':
        return const Color(0xFF4CAF50);
      case 'red':
        return const Color(0xFFE53935);
      case 'default color':
      default:
        return themePrimary;
    }
  }

  Future<void> initialize() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      for (final String key in _settings.keys) {
        final String? val = prefs.getString('$_prefix$key');
        if (val != null && val.isNotEmpty) {
          _settings[key] = val;
        }
      }
      _zoomLevel = prefs.getDouble('${_prefix}zoom_level') ?? 17.0;
    } catch (e) {
      debugPrint('GeneralSettingsController.initialize error: $e');
    } finally {
      _isReady = true;
      notifyListeners();
    }
  }

  Future<void> setSetting(String key, String value) async {
    if (_settings[key] != value) {
      _settings[key] = value;
      notifyListeners();
    }
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('$_prefix$key', value);
    } catch (e) {
      debugPrint('GeneralSettingsController.setSetting error: $e');
    }
  }

  Future<void> setZoomLevel(double value) async {
    if (_zoomLevel != value) {
      _zoomLevel = value;
      notifyListeners();
    }
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('${_prefix}zoom_level', value);
    } catch (e) {
      debugPrint('GeneralSettingsController.setZoomLevel error: $e');
    }
  }

  // Conversion & Formatting Helpers
  String formatSpeed(double speedKmh) {
    if (speedUnit == 'mph') {
      final double mph = speedKmh * 0.621371;
      return '${mph.toStringAsFixed(1)} mph';
    }
    return '${speedKmh.toStringAsFixed(1)} kmh';
  }

  String formatDistance(double distKm) {
    if (distanceUnit == 'mile') {
      final double miles = distKm * 0.621371;
      return '${miles.toStringAsFixed(1)} mi';
    }
    return '${distKm.toStringAsFixed(1)} km';
  }

  String formatFuel(double liters) {
    if (fuelUnit == 'Gallon') {
      final double gallons = liters * 0.264172;
      return '${gallons.toStringAsFixed(1)} Gal';
    }
    return '${liters.toStringAsFixed(1)} L';
  }

  double parseMoneyToPkr(String raw) {
    final String trimmed = raw.trim();
    if (trimmed.isEmpty || trimmed == '-' || trimmed == '—') {
      return 0;
    }
    final String digits = trimmed.replaceAll(RegExp(r'[^0-9.]'), '');
    if (digits.isEmpty) {
      return 0;
    }
    return double.tryParse(digits) ?? 0;
  }

  String formatCurrency(double amountPkr) {
    switch (currency) {
      case 'USD':
        final double usd = amountPkr / pkrPerUsd;
        return '\$${usd.toStringAsFixed(2)}';
      case 'INR':
        return '₹${amountPkr.toStringAsFixed(2)}';
      case 'PKR':
      default:
        return 'Rs. ${amountPkr.toStringAsFixed(2)}';
    }
  }

  String formatMoneyString(String raw) {
    final String trimmed = raw.trim();
    if (trimmed.isEmpty || trimmed == '-' || trimmed == '—') {
      return trimmed.isEmpty ? '—' : trimmed;
    }
    return formatCurrency(parseMoneyToPkr(trimmed));
  }

  String formatPricePerLiter(double pkrPerLiter) {
    return '${formatCurrency(pkrPerLiter)}/Ltr';
  }
}
