import 'package:flutter/material.dart';

import '../../constants/app_theme.dart';
import '../../models/expense_model.dart';

class ExpenseDetailScreen extends StatelessWidget {
  final ExpenseModel expense;

  const ExpenseDetailScreen({
    super.key,
    required this.expense,
  });

  static const Color pinkColor = AppThemeContext.pinkColor;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appBackground,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _DetailField(label: 'Description', value: expense.description),
                    _DetailField(label: 'Device Name', value: expense.deviceName),
                    _DetailField(label: 'Odometer', value: expense.odometer),
                    _DetailField(
                      label: 'Quantity',
                      value: expense.quantity.toStringAsFixed(1),
                    ),
                    _DetailField(
                      label: 'Amount',
                      value: expense.amount.toStringAsFixed(1),
                    ),
                    _DetailField(label: 'Payment Mode', value: expense.paymentMode),
                    _DetailField(label: 'Date', value: expense.date),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      color: context.appHeaderBackground,
      padding: const EdgeInsets.fromLTRB(4, 6, 16, 10),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(
              Icons.arrow_back_ios_new,
              color: pinkColor,
              size: 20,
            ),
          ),
          Text(
            'Expense Detail',
            style: TextStyle(
              color: context.appTextColor,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailField extends StatelessWidget {
  final String label;
  final String value;

  const _DetailField({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: context.appTextColor,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: context.appSurface,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: context.appBorder),
            ),
            child: Text(
              value,
              style: TextStyle(
                color: context.appTextColor,
                fontSize: 15,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
