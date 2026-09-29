import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/expense_model.dart';

class ExpenseLocalStore {
  ExpenseLocalStore._();

  static const String _storageKey = 'local_expenses_v1';

  static Future<List<ExpenseModel>> loadAll() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) {
      return <ExpenseModel>[];
    }

    try {
      final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .whereType<Map>()
          .map(
            (Map<dynamic, dynamic> m) => ExpenseModel(
              description: m['description']?.toString() ?? '',
              deviceName: m['deviceName']?.toString() ?? '',
              odometer: m['odometer']?.toString() ?? '',
              quantity: (m['quantity'] as num?)?.toDouble() ?? 0,
              amount: (m['amount'] as num?)?.toDouble() ?? 0,
              paymentMode: m['paymentMode']?.toString() ?? '',
              date: m['date']?.toString() ?? '',
              category: m['category']?.toString() ?? 'Other',
            ),
          )
          .toList();
    } catch (_) {
      return <ExpenseModel>[];
    }
  }

  static Future<void> add(ExpenseModel expense) async {
    final List<ExpenseModel> current = await loadAll();
    current.insert(0, expense);
    await _save(current);
  }

  static Future<void> _save(List<ExpenseModel> items) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<Map<String, dynamic>> encoded = items
        .map(
          (ExpenseModel e) => <String, dynamic>{
            'description': e.description,
            'deviceName': e.deviceName,
            'odometer': e.odometer,
            'quantity': e.quantity,
            'amount': e.amount,
            'paymentMode': e.paymentMode,
            'date': e.date,
            'category': e.category,
          },
        )
        .toList();
    await prefs.setString(_storageKey, jsonEncode(encoded));
  }

  static double totalAmount(List<ExpenseModel> items) {
    return items.fold(0.0, (double sum, ExpenseModel e) => sum + e.amount);
  }
}
