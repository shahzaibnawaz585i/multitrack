import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../theme/app_theme_controller.dart';
import '../../theme/app_theme_mode.dart';
import '../../theme/app_theme_tokens.dart';
import '../../theme/app_themes.dart';

class GeneralSettingScreen extends StatefulWidget {
  const GeneralSettingScreen({super.key});

  @override
  State<GeneralSettingScreen> createState() => _GeneralSettingScreenState();
}

class _GeneralSettingScreenState extends State<GeneralSettingScreen> {
  static const Color _pinkColor = AppThemes.pinkAccent;
  static const Color _lightBackground = AppThemes.lightBackground;
  static const Color _lightText = AppThemes.lightText;
  static const Color _darkBackground = AppThemes.darkBackground;
  static const Color _darkSurface = AppThemes.darkSurface;

  static const Color _hackBackground = AppThemes.hackBackground;
  static const Color _hackSurface = AppThemes.hackSurface;
  static const Color _hackText = AppThemes.hackText;
  static const Color _hackAccent = AppThemes.hackAccent;

  double _zoomLevel = 17;

  final Map<String, String> _values = <String, String>{
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

  static const List<_GeneralSettingData> _dropdownSettings = <_GeneralSettingData>[
    _GeneralSettingData(
      title: 'Vehicle Icon Size',
      dialogTitle: 'Choose Vehicle icon',
      icon: Icons.directions_car_outlined,
      iconColor: Color(0xFF4D91C5),
      image: 'assets/vehicle_icon_size.png',
      options: <String>['Small', 'Medium', 'Large'],
    ),
    _GeneralSettingData(
      title: 'Time Format',
      icon: Icons.timer_outlined,
      iconColor: Color(0xFFE53935),
      image: 'assets/time_formate.png',
      options: <String>['12 Hours', '24 Hours'],
    ),
    _GeneralSettingData(
      title: 'Speedo Meter',
      icon: Icons.speed_outlined,
      iconColor: Color(0xFF4D91C5),
      image: 'assets/speedo_meter.png',
      options: <String>['Analog', 'Digital'],
    ),
    _GeneralSettingData(
      title: 'Default Page',
      icon: Icons.layers_outlined,
      iconColor: Color(0xFF4D91C5),
      image: 'assets/default_page.png',
      options: <String>['Live Page', 'Map Page', 'Reports Page'],
    ),
    _GeneralSettingData(
      title: 'Map Type',
      icon: Icons.map_outlined,
      iconColor: Color(0xFF4D91C5),
      image: 'assets/steet_map.png',
      options: <String>['Normal', 'Satellite', 'Hybrid'],
    ),
    _GeneralSettingData(
      title: 'Fuel Unit',
      icon: Icons.local_gas_station_outlined,
      iconColor: Color(0xFFE53935),
      image: 'assets/fuel_unit.png',
      options: <String>['Liter', 'Gallon'],
    ),
    _GeneralSettingData(
      title: 'Language',
      icon: Icons.translate_outlined,
      iconColor: Color(0xFF4D91C5),
      image: 'assets/language.png',
      options: <String>['English', 'Hindi', 'Urdu'],
    ),
    _GeneralSettingData(
      title: 'Speed',
      icon: Icons.speed_outlined,
      iconColor: Color(0xFF4D91C5),
      image: 'assets/speed.png',
      options: <String>['kmh', 'mph'],
    ),
    _GeneralSettingData(
      title: 'Distance',
      icon: Icons.route_outlined,
      iconColor: Color(0xFF4D91C5),
      image: 'assets/distance.png',
      options: <String>['km', 'mile'],
    ),
    _GeneralSettingData(
      title: 'Area',
      icon: Icons.map_outlined,
      iconColor: Color(0xFF4D91C5),
      image: 'assets/steet_map.png',
      options: <String>['Hectare', 'Acre'],
    ),
    _GeneralSettingData(
      title: 'Voice Command',
      icon: Icons.mic_outlined,
      iconColor: Color(0xFFFFC107),
      image: 'assets/voice_command.png',
      options: <String>['ON', 'OFF'],
    ),
    _GeneralSettingData(
      title: 'Currency',
      icon: Icons.currency_exchange_outlined,
      iconColor: Color(0xFF4D91C5),
      image: 'assets/currency.png',
      options: <String>['INR', 'USD', 'PKR'],
    ),
    _GeneralSettingData(
      title: 'Live Page Trail',
      icon: Icons.timeline_outlined,
      iconColor: Color(0xFF4D91C5),
      image: 'assets/live_page.png',
      options: <String>['ON', 'OFF'],
    ),
    _GeneralSettingData(
      title: 'Show History on Live',
      icon: Icons.history_outlined,
      iconColor: Color(0xFFE53935),
      image: 'assets/show_history.png',
      options: <String>['ON', 'OFF'],
    ),
    _GeneralSettingData(
      title: 'Filter History Fluctuation',
      icon: Icons.filter_alt_outlined,
      iconColor: Color(0xFF4D91C5),
      image: 'assets/route_history.png',
      options: <String>['ON', 'OFF'],
    ),
    _GeneralSettingData(
      title: 'Farm Calculation',
      icon: Icons.agriculture_outlined,
      iconColor: Color(0xFF4D91C5),
      image: 'assets/steet_map.png',
      options: <String>['ON', 'OFF'],
    ),
    _GeneralSettingData(
      title: 'Notification',
      icon: Icons.notifications_active_outlined,
      iconColor: Color(0xFFFFC107),
      image: 'assets/notification.png',
      options: <String>['ON', 'OFF'],
    ),
    _GeneralSettingData(
      title: 'Fuel Reading',
      icon: Icons.local_gas_station_outlined,
      iconColor: Color(0xFFFF9800),
      image: 'assets/fule_reaging.png',
      options: <String>['Device', 'Sensor'],
    ),
    _GeneralSettingData(
      title: 'History Route Color',
      icon: Icons.route_outlined,
      iconColor: Color(0xFFE53935),
      image: 'assets/route_history.png',
      options: <String>['Default Color', 'Blue', 'Green', 'Red'],
    ),
    _GeneralSettingData(
      title: 'App Color',
      icon: Icons.palette_outlined,
      iconColor: Color(0xFFFF2F68),
      image: 'assets/app_color.png',
      options: <String>['Default Color', 'Blue', 'Green', 'Pink'],
    ),
    _GeneralSettingData(
      title: 'Relay Password',
      icon: Icons.lock_outline,
      iconColor: Color(0xFF4D91C5),
      image: 'assets/relay_password.png',
      options: <String>['Set Password', 'Change Password', 'Remove Password'],
    ),
  ];

  Color _backgroundColorFor(AppThemeMode themeMode) {
    switch (themeMode) {
      case AppThemeMode.light:
        return _lightBackground;
      case AppThemeMode.dark:
        return _darkBackground;
      case AppThemeMode.hacking:
        return _hackBackground;
    }
  }

  Color _textColorFor(AppThemeMode themeMode) {
    switch (themeMode) {
      case AppThemeMode.light:
        return _lightText;
      case AppThemeMode.dark:
        return Colors.white;
      case AppThemeMode.hacking:
        return _hackText;
    }
  }

  Color _accentColorFor(AppThemeMode themeMode) =>
      themeMode == AppThemeMode.hacking ? _hackAccent : _pinkColor;

  void _showThemePickerDialog(AppThemeMode currentTheme) {
    final AppThemeController themeController =
        context.read<AppThemeController>();

    showDialog<void>(
      context: context,
      barrierColor: Colors.black54,
      builder: (BuildContext dialogContext) {
        return _ThemePickerDialog(
          selectedTheme: currentTheme,
          onSelected: (AppThemeMode selected) async {
            Navigator.pop(dialogContext);
            if (!context.mounted) {
              return;
            }
            // Save first so theme persists even if app is closed during alert.
            await themeController.setMode(selected);
            if (selected == AppThemeMode.hacking &&
                currentTheme != AppThemeMode.hacking &&
                context.mounted) {
              await _showHackingAlertDialog();
            }
          },
        );
      },
    );
  }

  Future<void> _showHackingAlertDialog() {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.82),
      builder: (BuildContext dialogContext) {
        return const _HackingAlertDialog();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppThemeMode themeMode = context.watch<AppThemeController>().mode;
    final bool isHacking = themeMode.isHacking;
    final Color backgroundColor = _backgroundColorFor(themeMode);
    final Color textColor = _textColorFor(themeMode);
    final Color accentColor = _accentColorFor(themeMode);

    final Widget settingsContainer = Material(
      color: Colors.transparent,
      elevation: isHacking ? 12 : 0,
      shadowColor: isHacking ? _hackAccent.withOpacity(0.3) : null,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: double.infinity,
        decoration: context.containerDecoration(),
        child: Padding(
          padding: const EdgeInsets.only(
            left: 22,
            right: 16,
            top: 18,
            bottom: 12,
          ),
          child: Column(
            children: <Widget>[
              _ThemeSettingRow(
                themeLabel: 'Theme',
                themeMode: themeMode,
                valueLabel: themeMode.label,
                textColor: textColor,
                accentColor: accentColor,
                onTap: () => _showThemePickerDialog(themeMode),
              ),
              for (final _GeneralSettingData setting in _dropdownSettings)
                _SettingDropdownRow(
                  setting: setting,
                  value: _values[setting.title] ?? setting.options.first,
                  textColor: textColor,
                  accentColor: accentColor,
                  onTap: () => _showOptionDialog(setting, themeMode),
                ),
              _ZoomLevelRow(
                zoomLevel: _zoomLevel,
                textColor: textColor,
                accentColor: accentColor,
                onChanged: (double value) {
                  setState(() {
                    _zoomLevel = value;
                  });
                },
              ),
            ],
          ),
        ),
      ),
    );

    return Scaffold(
      backgroundColor: isHacking ? Colors.transparent : backgroundColor,
      appBar: AppBar(
        backgroundColor: isHacking ? Colors.transparent : backgroundColor,
        surfaceTintColor: isHacking ? Colors.transparent : backgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: accentColor,
            size: 20,
          ),
        ),
        title: Text(
          'Settings',
          style: TextStyle(
            color: textColor,
            fontSize: isHacking ? 22 : 20,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(15, 40, 15, 24),
        child: settingsContainer,
      ),
    );
  }

  Future<void> _showOptionDialog(
    _GeneralSettingData setting,
    AppThemeMode themeMode,
  ) async {
    final String currentValue =
        _values[setting.title] ?? setting.options.first;
    final String? selected = await showDialog<String>(
      context: context,
      barrierColor: Colors.black54,
      builder: (BuildContext dialogContext) {
        return _OptionPickerDialog(
          title: setting.dialogTitle ?? setting.title,
          options: setting.options,
          selectedValue: currentValue,
          themeMode: themeMode,
        );
      },
    );

    if (selected == null || !mounted) {
      return;
    }

    setState(() {
      _values[setting.title] = selected;
    });
  }
}

class _GeneralSettingData {
  final String title;
  final String? dialogTitle;
  final IconData icon;
  final Color iconColor;
  final String? image;
  final List<String> options;

  const _GeneralSettingData({
    required this.title,
    this.dialogTitle,
    required this.icon,
    required this.iconColor,
    this.image,
    required this.options,
  });
}

class _ThemeSettingRow extends StatelessWidget {
  final String themeLabel;
  final String valueLabel;
  final AppThemeMode themeMode;
  final Color textColor;
  final Color accentColor;
  final VoidCallback onTap;

  const _ThemeSettingRow({
    required this.themeLabel,
    required this.valueLabel,
    required this.themeMode,
    required this.textColor,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          height: 50,
          child: Row(
            children: <Widget>[
              SizedBox(
                width: 25,
                height: 25,
                child: Image.asset(
                  'assets/theme.png',
                  fit: BoxFit.contain,
                  errorBuilder: (BuildContext context, Object error, StackTrace? stackTrace) {
                    return Icon(
                      Icons.brush_outlined,
                      color: themeMode == AppThemeMode.hacking
                          ? const Color(0xFF00FF88)
                          : const Color(0xFFE53935),
                      size: 22,
                    );
                  },
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                flex: 2,
                child: Text(
                  themeLabel,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: <Widget>[
                    Flexible(
                      child: Text(
                        valueLabel,
                        textAlign: TextAlign.right,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: textColor,
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.arrow_drop_down,
                      color: accentColor,
                      size: 24,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ThemePickerDialog extends StatefulWidget {
  final AppThemeMode selectedTheme;
  final ValueChanged<AppThemeMode> onSelected;

  const _ThemePickerDialog({
    required this.selectedTheme,
    required this.onSelected,
  });

  @override
  State<_ThemePickerDialog> createState() => _ThemePickerDialogState();
}

class _ThemePickerDialogState extends State<_ThemePickerDialog> {
  late AppThemeMode _selectedTheme;

  static const List<_ThemeOptionData> _options = <_ThemeOptionData>[
    _ThemeOptionData(
      mode: AppThemeMode.light,
      label: 'Light Theme',
      icon: Icons.wb_sunny_outlined,
      iconColor: Color(0xFFFFB300),
    ),
    _ThemeOptionData(
      mode: AppThemeMode.dark,
      label: 'Dark Theme',
      icon: Icons.dark_mode_outlined,
      iconColor: Color(0xFF4D91C5),
    ),
    _ThemeOptionData(
      mode: AppThemeMode.hacking,
      label: 'Hacking Theme',
      icon: Icons.terminal,
      iconColor: Color(0xFF00FF88),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _selectedTheme = widget.selectedTheme;
  }

  @override
  Widget build(BuildContext context) {
    final Color textColor = Theme.of(context).colorScheme.onSurface;
    final Color accentColor = Theme.of(context).colorScheme.primary;
    final Color cardColor = context.containerColor;

    return Dialog(
      backgroundColor: cardColor,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Choose Theme',
                style: TextStyle(
                  color: textColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          Divider(
            height: 1,
            color: Theme.of(context).dividerColor,
          ),
          for (final _ThemeOptionData option in _options)
            InkWell(
              onTap: () {
                setState(() {
                  _selectedTheme = option.mode;
                });
              },
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  children: <Widget>[
                    Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: _selectedTheme == option.mode
                            ? accentColor
                            : const Color(0xFFD9D9D9),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Icon(option.icon, color: option.iconColor, size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        option.label,
                        style: TextStyle(
                          color: textColor,
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: _DialogButton(
                    label: 'CANCEL',
                    accentColor: accentColor,
                    onTap: () => Navigator.pop(context),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _DialogButton(
                    label: 'OK',
                    accentColor: accentColor,
                    onTap: () => widget.onSelected(_selectedTheme),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ThemeOptionData {
  final AppThemeMode mode;
  final String label;
  final IconData icon;
  final Color iconColor;

  const _ThemeOptionData({
    required this.mode,
    required this.label,
    required this.icon,
    required this.iconColor,
  });
}

class _HackingAlertDialog extends StatefulWidget {
  const _HackingAlertDialog();

  @override
  State<_HackingAlertDialog> createState() => _HackingAlertDialogState();
}

class _HackingAlertDialogState extends State<_HackingAlertDialog>
    with SingleTickerProviderStateMixin {
  static const Color _neon = Color(0xFF00FF88);
  static const Color _alertRed = Color(0xFFFF3355);

  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF020402),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: _neon.withOpacity(0.55)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            AnimatedBuilder(
              animation: _pulseController,
              builder: (BuildContext context, Widget? child) {
                return Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: _alertRed.withOpacity(
                      0.18 + (_pulseController.value * 0.18),
                    ),
                    border: Border.all(
                      color: _alertRed.withOpacity(0.85),
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    '!!! SECURITY ALERT !!!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _alertRed,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                      fontFamily: 'monospace',
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            const Icon(Icons.warning_amber_rounded, color: _neon, size: 42),
            const SizedBox(height: 12),
            const Text(
              'HACKING MODE ACTIVATED',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _neon,
                fontSize: 16,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
                fontFamily: 'monospace',
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'System override engaged.\nUnauthorized access simulation running.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _neon.withOpacity(0.75),
                fontSize: 12,
                height: 1.4,
                fontFamily: 'monospace',
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 42,
              child: Material(
                color: _neon,
                borderRadius: BorderRadius.circular(24),
                child: InkWell(
                  onTap: () => Navigator.pop(context),
                  borderRadius: BorderRadius.circular(24),
                  child: const Center(
                    child: Text(
                      'ACTIVATE',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingDropdownRow extends StatelessWidget {
  final _GeneralSettingData setting;
  final String value;
  final Color textColor;
  final Color accentColor;
  final VoidCallback onTap;

  const _SettingDropdownRow({
    required this.setting,
    required this.value,
    required this.textColor,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    double iconSize = 22;
    if (setting.title == 'Vehicle Icon Size') {
      if (value == 'Small') iconSize = 16;
      if (value == 'Medium') iconSize = 22;
      if (value == 'Large') iconSize = 28;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          height: 50,
          child: Row(
            children: <Widget>[
              SizedBox(
                width: 30,
                height: 30,
                child: Center(
                  child: SizedBox(
                    width: iconSize,
                    height: iconSize,
                    child: setting.image != null
                        ? Image.asset(
                            setting.image!,
                            fit: BoxFit.contain,
                            errorBuilder: (
                              BuildContext context,
                              Object error,
                              StackTrace? stackTrace,
                            ) {
                              return Icon(
                                setting.icon,
                                color: setting.iconColor,
                                size: iconSize,
                              );
                            },
                          )
                        : Icon(setting.icon, color: setting.iconColor, size: iconSize),
                  ),
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                flex: 2,
                child: Text(
                  setting.title,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: <Widget>[
                    Flexible(
                      child: Text(
                        value,
                        textAlign: TextAlign.right,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: textColor,
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.arrow_drop_down,
                      color: accentColor,
                      size: 24,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ZoomLevelRow extends StatelessWidget {
  final double zoomLevel;
  final Color textColor;
  final Color accentColor;
  final ValueChanged<double> onChanged;

  const _ZoomLevelRow({
    required this.zoomLevel,
    required this.textColor,
    required this.accentColor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: Row(
        children: <Widget>[
          SizedBox(
            width: 25,
            height: 25,
            child: Image.asset(
              'assets/zoom_level.png',
              fit: BoxFit.contain,
              errorBuilder: (BuildContext context, Object error, StackTrace? stackTrace) {
                return const Icon(
                  Icons.zoom_in_outlined,
                  color: Color(0xFF4D91C5),
                  size: 22,
                );
              },
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            flex: 2,
            child: Text(
              'Zoom Level',
              style: TextStyle(
                color: textColor,
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Row(
              children: <Widget>[
                Expanded(
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: accentColor,
                      inactiveTrackColor: const Color(0xFFE0E0E0),
                      thumbColor: accentColor,
                      overlayColor: accentColor.withOpacity(0.12),
                      trackHeight: 3,
                    ),
                    child: Slider(
                      value: zoomLevel,
                      min: 1,
                      max: 20,
                      onChanged: onChanged,
                    ),
                  ),
                ),
                SizedBox(
                  width: 28,
                  child: Text(
                    zoomLevel.round().toString(),
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OptionPickerDialog extends StatefulWidget {
  final String title;
  final List<String> options;
  final String selectedValue;
  final AppThemeMode themeMode;

  const _OptionPickerDialog({
    required this.title,
    required this.options,
    required this.selectedValue,
    required this.themeMode,
  });

  @override
  State<_OptionPickerDialog> createState() => _OptionPickerDialogState();
}

class _OptionPickerDialogState extends State<_OptionPickerDialog> {
  late String _selectedValue;

  @override
  void initState() {
    super.initState();
    _selectedValue = widget.selectedValue;
  }

  @override
  Widget build(BuildContext context) {
    final Color surfaceColor = switch (widget.themeMode) {
      AppThemeMode.light => Colors.white,
      AppThemeMode.dark => const Color(0xFF23252E),
      AppThemeMode.hacking => const Color(0xFF050805),
    };
    final Color textColor = switch (widget.themeMode) {
      AppThemeMode.light => const Color(0xFF292B32),
      AppThemeMode.dark => Colors.white,
      AppThemeMode.hacking => const Color(0xFF9DFFB5),
    };
    final Color accentColor = widget.themeMode == AppThemeMode.hacking
        ? const Color(0xFF00FF88)
        : const Color(0xFFFF2F68);

    return Dialog(
      backgroundColor: surfaceColor,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                widget.title,
                style: TextStyle(
                  color: textColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          Divider(
            height: 1,
            color: widget.themeMode == AppThemeMode.light
                ? Colors.black.withOpacity(0.08)
                : Colors.white24,
          ),
          for (final String option in widget.options)
            InkWell(
              onTap: () {
                setState(() {
                  _selectedValue = option;
                });
              },
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  children: <Widget>[
                    Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: _selectedValue == option
                            ? accentColor
                            : const Color(0xFFD9D9D9),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Text(
                      option,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: _DialogButton(
                    label: 'CANCEL',
                    accentColor: accentColor,
                    onTap: () => Navigator.pop(context),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _DialogButton(
                    label: 'OK',
                    accentColor: accentColor,
                    onTap: () => Navigator.pop(context, _selectedValue),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DialogButton extends StatelessWidget {
  final String label;
  final Color accentColor;
  final VoidCallback onTap;

  const _DialogButton({
    required this.label,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: accentColor,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: SizedBox(
          height: 42,
          child: Center(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
