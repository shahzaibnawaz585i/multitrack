import 'package:flutter/material.dart';

/// Shared date/time picker styling for all report screens.
class ReportDatePicker {
  ReportDatePicker._();

  static const Color _headerColor = Color(0xFF292B32);

  static ThemeData theme(BuildContext context) {
    return Theme.of(context).copyWith(
      colorScheme: Theme.of(context).colorScheme.copyWith(
            primary: _headerColor,
            onPrimary: Colors.white,
            surface: Colors.white,
            onSurface: _headerColor,
          ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: Colors.white,
        headerBackgroundColor: _headerColor,
        headerForegroundColor: Colors.white,
        dayForegroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return Colors.white;
          }
          if (states.contains(WidgetState.disabled)) {
            return Colors.grey.shade400;
          }
          return _headerColor;
        }),
        dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return _headerColor;
          }
          return Colors.transparent;
        }),
        todayForegroundColor: WidgetStateProperty.all(_headerColor),
        todayBackgroundColor: WidgetStateProperty.all(Colors.transparent),
        yearForegroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return Colors.white;
          }
          return _headerColor;
        }),
        yearBackgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return _headerColor;
          }
          return Colors.transparent;
        }),
      ),
      timePickerTheme: TimePickerThemeData(
        backgroundColor: Colors.white,
        dialHandColor: _headerColor,
        dialBackgroundColor: const Color(0xFFF0F0F0),
        hourMinuteColor: WidgetStateColor.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return _headerColor;
          }
          return const Color(0xFFE8E8E8);
        }),
        hourMinuteTextColor: WidgetStateColor.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return Colors.white;
          }
          return _headerColor;
        }),
        dayPeriodColor: WidgetStateColor.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return _headerColor;
          }
          return const Color(0xFFE8E8E8);
        }),
        dayPeriodTextColor: WidgetStateColor.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return Colors.white;
          }
          return _headerColor;
        }),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      ),
    );
  }

  static Future<DateTime?> pickDateTime(
    BuildContext context, {
    required DateTime initialDate,
    DateTime? firstDate,
    DateTime? lastDate,
  }) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate ?? DateTime(2020),
      lastDate: lastDate ?? DateTime(2050),
      builder: (context, child) {
        return Theme(
          data: theme(context),
          child: child!,
        );
      },
    );

    if (pickedDate == null || !context.mounted) {
      return null;
    }

    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initialDate),
      builder: (context, child) {
        return Theme(
          data: theme(context),
          child: child!,
        );
      },
    );

    if (pickedTime == null || !context.mounted) {
      return null;
    }

    return DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );
  }
}
