import 'package:flutter/material.dart';

/// App-wide calendar + time picker — same look on every screen.
class AppDateTimePicker {
  AppDateTimePicker._();

  static const Color headerColor = Color(0xFF292B32);
  static const Color accentCursor = Color(0xFFF53D6B);
  static const Color mutedSurface = Color(0xFFE8E8E8);

  /// Fresh light theme so pink/hacking parent colors never leak into pickers.
  static ThemeData theme() {
    const ColorScheme scheme = ColorScheme.light(
      primary: headerColor,
      onPrimary: Colors.white,
      secondary: headerColor,
      onSecondary: Colors.white,
      surface: Colors.white,
      onSurface: headerColor,
      onSurfaceVariant: Color(0xFF5F6368),
      outline: Color(0xFF79747E),
      surfaceContainerHighest: mutedSurface,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: scheme,
      primaryColor: headerColor,
      scaffoldBackgroundColor: Colors.white,
      canvasColor: Colors.white,
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: accentCursor,
        selectionColor: Color(0x33292B32),
        selectionHandleColor: headerColor,
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: headerColor,
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        headerBackgroundColor: headerColor,
        headerForegroundColor: Colors.white,
        headerHeadlineStyle: const TextStyle(
          color: Colors.white,
          fontSize: 32,
          fontWeight: FontWeight.w400,
        ),
        headerHelpStyle: const TextStyle(
          color: Colors.white70,
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        weekdayStyle: const TextStyle(
          color: headerColor,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
        dayStyle: const TextStyle(color: headerColor, fontSize: 14),
        dayForegroundColor: WidgetStateProperty.resolveWith((
          Set<WidgetState> states,
        ) {
          if (states.contains(WidgetState.selected)) {
            return Colors.white;
          }
          if (states.contains(WidgetState.disabled)) {
            return Colors.grey.shade400;
          }
          return headerColor;
        }),
        dayBackgroundColor: WidgetStateProperty.resolveWith((
          Set<WidgetState> states,
        ) {
          if (states.contains(WidgetState.selected)) {
            return headerColor;
          }
          return Colors.transparent;
        }),
        todayForegroundColor: const WidgetStatePropertyAll<Color>(headerColor),
        todayBackgroundColor:
            const WidgetStatePropertyAll<Color>(Colors.transparent),
        todayBorder: const BorderSide(color: headerColor),
        yearForegroundColor: WidgetStateProperty.resolveWith((
          Set<WidgetState> states,
        ) {
          if (states.contains(WidgetState.selected)) {
            return Colors.white;
          }
          return headerColor;
        }),
        yearBackgroundColor: WidgetStateProperty.resolveWith((
          Set<WidgetState> states,
        ) {
          if (states.contains(WidgetState.selected)) {
            return headerColor;
          }
          return Colors.transparent;
        }),
        rangePickerHeaderBackgroundColor: headerColor,
        rangePickerHeaderForegroundColor: Colors.white,
        cancelButtonStyle: TextButton.styleFrom(foregroundColor: headerColor),
        confirmButtonStyle: TextButton.styleFrom(foregroundColor: headerColor),
      ),
      timePickerTheme: TimePickerThemeData(
        backgroundColor: Colors.white,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        hourMinuteShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        dayPeriodShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        dialHandColor: headerColor,
        dialBackgroundColor: mutedSurface,
        dialTextColor: WidgetStateColor.resolveWith((Set<WidgetState> states) {
          if (states.contains(WidgetState.selected)) {
            return Colors.white;
          }
          return headerColor;
        }),
        hourMinuteColor: WidgetStateColor.resolveWith((Set<WidgetState> states) {
          if (states.contains(WidgetState.selected)) {
            return headerColor;
          }
          return mutedSurface;
        }),
        hourMinuteTextColor: WidgetStateColor.resolveWith((
          Set<WidgetState> states,
        ) {
          if (states.contains(WidgetState.selected)) {
            return Colors.white;
          }
          return headerColor;
        }),
        hourMinuteTextStyle: const TextStyle(
          fontSize: 48,
          fontWeight: FontWeight.w400,
        ),
        dayPeriodColor: WidgetStateColor.resolveWith((Set<WidgetState> states) {
          if (states.contains(WidgetState.selected)) {
            return headerColor;
          }
          return mutedSurface;
        }),
        dayPeriodTextColor: WidgetStateColor.resolveWith((
          Set<WidgetState> states,
        ) {
          if (states.contains(WidgetState.selected)) {
            return Colors.white;
          }
          return headerColor;
        }),
        entryModeIconColor: headerColor,
        helpTextStyle: const TextStyle(color: headerColor),
        cancelButtonStyle: TextButton.styleFrom(foregroundColor: headerColor),
        confirmButtonStyle: TextButton.styleFrom(foregroundColor: headerColor),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      ),
    );
  }

  static Widget _themedBuilder(BuildContext context, Widget? child) {
    return Theme(
      data: theme(),
      child: MediaQuery(
        data: MediaQuery.of(context).copyWith(
          alwaysUse24HourFormat: true,
        ),
        child: child ?? const SizedBox.shrink(),
      ),
    );
  }

  static Future<DateTime?> pickDate(
    BuildContext context, {
    required DateTime initialDate,
    DateTime? firstDate,
    DateTime? lastDate,
  }) {
    return showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate ?? DateTime(2020),
      lastDate: lastDate ?? DateTime(2050),
      builder: _themedBuilder,
    );
  }

  static Future<TimeOfDay?> pickTime(
    BuildContext context, {
    required TimeOfDay initialTime,
  }) {
    return showTimePicker(
      context: context,
      initialTime: initialTime,
      // Dial first (clock) — keyboard icon switches to input like screenshots.
      initialEntryMode: TimePickerEntryMode.dial,
      builder: _themedBuilder,
    );
  }

  static Future<DateTime?> pickDateTime(
    BuildContext context, {
    required DateTime initialDate,
    DateTime? firstDate,
    DateTime? lastDate,
  }) async {
    final DateTime? pickedDate = await pickDate(
      context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );

    if (pickedDate == null || !context.mounted) {
      return null;
    }

    final TimeOfDay? pickedTime = await pickTime(
      context,
      initialTime: TimeOfDay.fromDateTime(initialDate),
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

/// Backward-compatible alias used by report screens.
typedef ReportDatePicker = AppDateTimePicker;
