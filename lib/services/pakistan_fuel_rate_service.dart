import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// PSO Pakistan Euro-5 retail fuel prices (PKR / litre).
class PakistanFuelRateService {
  PakistanFuelRateService._();

  static const String defaultCity = 'Multan';
  static const Duration _cacheTtl = Duration(hours: 12);
  static const String _cacheKey = 'pk_fuel_rates_cache_v1';

  static const String _psoHomeUrl = 'https://psopk.com/';
  static const String _psoFuelPricesUrl = 'https://psopk.com/en/fuels/fuel-prices';

  /// PSO city list (same as psopk.com fuel widget).
  static const List<String> cities = <String>[
    'Karachi',
    'Lahore',
    'Rawalpindi',
    'Faisalabad',
    'Jhelum',
    'Peshawar',
    'Bahawalpur',
    'Sukkur',
    'Multan',
    'Gujranwala',
    'Hyderabad',
    'Sahiwal',
    'D.I Khan',
    'Gilgit',
    'Gawadar',
    'Abbottabad',
    'Quetta',
    'Skardu',
  ];

  /// Fallback when offline (PSO Euro-5 Premier / Hi-Cetane, PKR/L).
  static const ({double petrol, double diesel}) _fallbackRates =
      (petrol: 390.12, diesel: 414.75);

  static Future<({double petrol, double diesel})> ratesFor(String city) async {
    final ({double petrol, double diesel})? cached = await _readCache();
    if (cached != null) {
      return cached;
    }

    final ({double petrol, double diesel})? live = await _fetchFromPso();
    if (live != null) {
      await _writeCache(live);
      return live;
    }

    return _fallbackRates;
  }

  static Future<void> refresh() async {
    final ({double petrol, double diesel})? live = await _fetchFromPso();
    if (live != null) {
      await _writeCache(live);
    }
  }

  static String formatPkr(double value) {
    return 'Rs. ${value.toStringAsFixed(2)}/Ltr';
  }

  static Future<({double petrol, double diesel})?> _fetchFromPso() async {
    for (final String url in <String>[_psoHomeUrl, _psoFuelPricesUrl]) {
      try {
        final http.Response response = await http
            .get(
              Uri.parse(url),
              headers: <String, String>{
                'Accept': 'text/html,application/xhtml+xml',
                'User-Agent': 'multitrack/1.0',
              },
            )
            .timeout(const Duration(seconds: 15));

        if (response.statusCode != 200) {
          continue;
        }

        final ({double petrol, double diesel})? parsed =
            _parsePsoHtml(response.body);
        if (parsed != null) {
          return parsed;
        }
      } catch (_) {}
    }
    return null;
  }

  static ({double petrol, double diesel})? _parsePsoHtml(String html) {
    final double? petrol = _priceAfterFuelImage(
      html,
      <String>['premier5.png', 'premier.png', 'octane5.png'],
    );
    final double? diesel = _priceAfterFuelImage(
      html,
      <String>['cetane5.png', 'cetanewhite.png', 'cetane.png'],
    );

    if (petrol == null || diesel == null) {
      return null;
    }
    if (petrol < 100 || diesel < 100 || petrol > 999 || diesel > 999) {
      return null;
    }
    return (petrol: petrol, diesel: diesel);
  }

  static double? _priceAfterFuelImage(String html, List<String> imageNames) {
    for (final String image in imageNames) {
      final int index = html.indexOf(image);
      if (index < 0) {
        continue;
      }
      final String slice = html.substring(
        index,
        (index + 450).clamp(0, html.length),
      );
      final RegExp pricePattern = RegExp(r'Rs\.([\d,]+(?:\.\d{1,2})?)/Ltr');
      final Match? match = pricePattern.firstMatch(slice);
      if (match != null) {
        final String raw = match.group(1)!.replaceAll(',', '');
        return double.tryParse(raw);
      }
    }
    return null;
  }

  static Future<({double petrol, double diesel})?> _readCache() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? raw = prefs.getString(_cacheKey);
      if (raw == null || raw.isEmpty) {
        return null;
      }
      final Map<String, dynamic> map =
          jsonDecode(raw) as Map<String, dynamic>;
      final int? savedAtMs = map['savedAt'] as int?;
      if (savedAtMs == null) {
        return null;
      }
      final DateTime savedAt =
          DateTime.fromMillisecondsSinceEpoch(savedAtMs);
      if (DateTime.now().difference(savedAt) > _cacheTtl) {
        return null;
      }
      final double? petrol = (map['petrol'] as num?)?.toDouble();
      final double? diesel = (map['diesel'] as num?)?.toDouble();
      if (petrol == null || diesel == null) {
        return null;
      }
      return (petrol: petrol, diesel: diesel);
    } catch (_) {
      return null;
    }
  }

  static Future<void> _writeCache(({double petrol, double diesel}) rates) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _cacheKey,
      jsonEncode(<String, dynamic>{
        'petrol': rates.petrol,
        'diesel': rates.diesel,
        'savedAt': DateTime.now().millisecondsSinceEpoch,
      }),
    );
  }
}
