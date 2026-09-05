import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GeneralSettingsController extends ChangeNotifier {
  static const String _prefix = 'general_setting_';

  final Map<String, String> _settings = <String, String>{
    'Vehicle Icon Size': 'Small',
    'Time Format': '12 Hours',
    'Speedo Meter': 'Analog',
    'Default Page': 'Live Page',
    'Map Type': 'Normal',
    'Fuel Unit': 'Liter',
    'Language': 'English',
    'Speed': 'kmh',
    'Distance': 'km',
    'Area': 'Hectare',
    'Voice Command': 'ON',
    'Currency': 'INR',
    'Live Page Trail': 'OFF',
    'Show History on Live': 'OFF',
    'Filter History Fluctuation': 'OFF',
    'Farm Calculation': 'OFF',
    'Notification': 'ON',
    'Fuel Reading': 'Device',
    'History Route Color': 'Default Color',
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
  String get currency => get('Currency', defaultValue: 'INR');
  String get vehicleIconSize => get('Vehicle Icon Size', defaultValue: 'Small');
  String get speedoMeter => get('Speedo Meter', defaultValue: 'Analog');
  String get areaUnit => get('Area', defaultValue: 'Hectare');
  bool get isNotificationOn => get('Notification', defaultValue: 'ON') == 'ON';
  bool get isVoiceCommandOn => get('Voice Command', defaultValue: 'ON') == 'ON';

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

  String formatCurrency(double amount) {
    switch (currency) {
      case 'USD':
        return '\$${amount.toStringAsFixed(2)}';
      case 'PKR':
        return 'Rs. ${amount.toStringAsFixed(0)}';
      case 'INR':
      default:
        return '₹${amount.toStringAsFixed(0)}';
    }
  }
}
