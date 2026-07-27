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
      image: 'assets/caricon.png',
      options: <String>['Small', 'Medium', 'Large'],
    ),
    _GeneralSettingData(
      title: 'Time Format',
      icon: Icons.timer_outlined,
      iconColor: Color(0xFFE53935),
      options: <String>['12 Hours', '24 Hours'],
    ),
    _GeneralSettingData(
      title: 'Speedo Meter',
      icon: Icons.speed_outlined,
      iconColor: Color(0xFF4D91C5),
      options: <String>['Analog', 'Digital'],
    ),
    _GeneralSettingData(
      title: 'Default Page',
      icon: Icons.layers_outlined,
      iconColor: Color(0xFF4D91C5),
      options: <String>['Live Page', 'Map Page', 'Reports Page'],
    ),
    _GeneralSettingData(
      title: 'Map Type',
      icon: Icons.map_outlined,
      iconColor: Color(0xFF4D91C5),
      image: 'assets/map_fold.png',
      options: <String>['Normal', 'Satellite', 'Hybrid'],
    ),
    _GeneralSettingData(
      title: 'Fuel Unit',
      icon: Icons.local_gas_station_outlined,
      iconColor: Color(0xFFE53935),
      options: <String>['Liter', 'Gallon'],
    ),
    _GeneralSettingData(
      title: 'Language',
      icon: Icons.translate_outlined,
      iconColor: Color(0xFF4D91C5),
      options: <String>['English', 'Hindi', 'Urdu'],
    ),
    _GeneralSettingData(
      title: 'Speed',
      icon: Icons.speed_outlined,
      iconColor: Color(0xFF4D91C5),
      options: <String>['kmh', 'mph'],
    ),
    _GeneralSettingData(
      title: 'Distance',
      icon: Icons.route_outlined,
      iconColor: Color(0xFF4D91C5),
      options: <String>['km', 'mile'],
    ),
    _GeneralSettingData(
      title: 'Area',
      icon: Icons.map_outlined,
      iconColor: Color(0xFF4D91C5),
      image: 'assets/map_fold.png',
      options: <String>['Hectare', 'Acre'],
    ),
    _GeneralSettingData(
      title: 'Voice Command',
      icon: Icons.mic_outlined,
      iconColor: Color(0xFFFFC107),
      options: <String>['ON', 'OFF'],
    ),
    _GeneralSettingData(
      title: 'Currency',
      icon: Icons.currency_exchange_outlined,
      iconColor: Color(0xFF4D91C5),
      options: <String>['INR', 'USD', 'PKR'],
    ),
    _GeneralSettingData(
      title: 'Live Page Trail',
      icon: Icons.timeline_outlined,
      iconColor: Color(0xFF4D91C5),
      options: <String>['ON', 'OFF'],
    ),
    _GeneralSettingData(
      title: 'Show History on Live',
      icon: Icons.history_outlined,
      iconColor: Color(0xFFE53935),
      options: <String>['ON', 'OFF'],
    ),
    _GeneralSettingData(
      title: 'Filter History Fluctuation',
      icon: Icons.filter_alt_outlined,
      iconColor: Color(0xFF4D91C5),
      options: <String>['ON', 'OFF'],
    ),
    _GeneralSettingData(
      title: 'Farm Calculation',
      icon: Icons.agriculture_outlined,
      iconColor: Color(0xFF4D91C5),
      image: 'assets/map_fold.png',
      options: <String>['ON', 'OFF'],
    ),
    _GeneralSettingData(
      title: 'Notification',
      icon: Icons.notifications_active_outlined,
      iconColor: Color(0xFFFFC107),
      options: <String>['ON', 'OFF'],
    ),
    _GeneralSettingData(
      title: 'Fuel Reading',
      icon: Icons.local_gas_station_outlined,
      iconColor: Color(0xFFFF9800),
      options: <String>['Device', 'Sensor'],
    ),
    _GeneralSettingData(
      title: 'History Route Color',
      icon: Icons.route_outlined,
      iconColor: Color(0xFFE53935),
      options: <String>['Default Color', 'Blue', 'Green', 'Red'],
    ),
    _GeneralSettingData(
      title: 'App Color',
      icon: Icons.palette_outlined,
      iconColor: Color(0xFFFF2F68),
      options: <String>['Default Color', 'Blue', 'Green', 'Pink'],
    ),
    _GeneralSettingData(
      title: 'Relay Password',
      icon: Icons.lock_outline,
      iconColor: Color(0xFF4D91C5),
      image: 'assets/key.png',
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

  Color _surfaceColorFor(AppThemeMode themeMode) {
    switch (themeMode) {
      case AppThemeMode.light:
        return Colors.white;
      case AppThemeMode.dark:
        return _darkSurface;
      case AppThemeMode.hacking:
        return _hackSurface;
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
      barrierColor: Colors.black.withValues(alpha: 0.82),
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
      shadowColor: isHacking ? _hackAccent.withValues(alpha: 0.3) : null,
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
              Icon(
                Icons.brush_outlined,
                color: themeMode == AppThemeMode.hacking
                    ? const Color(0xFF00FF88)
                    : const Color(0xFFE53935),
                size: 22,
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
  static const Color _pinkColor = Color(0xFFFF2F68);

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
        side: BorderSide(color: _neon.withValues(alpha: 0.55)),
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
                    color: _alertRed.withValues(
                      alpha: 0.18 + (_pulseController.value * 0.18),
                    ),
                    border: Border.all(
                      color: _alertRed.withValues(alpha: 0.85),
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
                color: _neon.withValues(alpha: 0.75),
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

class _HackingLiveAlertBanner extends StatefulWidget {
  const _HackingLiveAlertBanner();

  @override
  State<_HackingLiveAlertBanner> createState() =>
      _HackingLiveAlertBannerState();
}

class _HackingLiveAlertBannerState extends State<_HackingLiveAlertBanner>
    with SingleTickerProviderStateMixin {
  static const Color _alertRed = Color(0xFFFF3355);
  static const Color _neon = Color(0xFF00FF88);

  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, Widget? child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: _alertRed.withValues(alpha: 0.14 + _controller.value * 0.12),
            border: Border.all(
              color: Color.lerp(_alertRed, _neon, _controller.value)!,
              width: 1.2,
            ),
            borderRadius: BorderRadius.circular(8),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: _alertRed.withValues(alpha: 0.25),
                blurRadius: 14,
              ),
            ],
          ),
          child: Row(
            children: <Widget>[
              Icon(
                Icons.gpp_bad_rounded,
                color: Color.lerp(_alertRed, _neon, _controller.value),
                size: 22,
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'LIVE HACK ALERT :: INTRUSION DETECTED',
                  style: TextStyle(
                    color: _neon,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ],
          ),
        );
      },
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
                            size: 22,
                          );
                        },
                      )
                    : Icon(setting.icon, color: setting.iconColor, size: 22),
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
          const Icon(Icons.zoom_in_outlined, color: Color(0xFF4D91C5), size: 22),
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
                      overlayColor: accentColor.withValues(alpha: 0.12),
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
                ? Colors.black.withValues(alpha: 0.08)
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

class HackingOverlay extends StatefulWidget {
  const HackingOverlay({super.key});

  @override
  State<HackingOverlay> createState() => HackingOverlayState();
}

class HackingOverlayState extends State<HackingOverlay>
    with TickerProviderStateMixin {
  static const Color _neon = Color(0xFF00FF88);
  static const Color _cyan = Color(0xFF00E5FF);
  static const Color _amber = Color(0xFFFFB000);
  static const Color _alertRed = Color(0xFFFF3355);

  late AnimationController _controller;
  late List<_MatrixColumn> _columns;
  Timer? _messageTimer;
  Timer? _glitchTimer;
  Timer? _commandTimer;
  Timer? _hexTimer;
  Timer? _statsTimer;
  bool _initialized = false;
  int _messageIndex = 0;
  int _commandSeed = 0;
  int _cpuLoad = 67;
  int _memLoad = 54;
  int _netLoad = 88;
  double _breachProgress = 0.34;
  double _decryptProgress = 0.58;
  double _uploadProgress = 0.72;
  bool _glitchOn = false;
  bool _redFlash = false;
  final List<String> _liveCommands = <String>[];
  final List<String> _hexLines = <String>[];
  final math.Random _random = math.Random(21);

  static const List<String> _statusMessages = <String>[
    '>> SYSTEM OVERRIDE ACTIVE <<',
    '>> BYPASSING FIREWALL... OK',
    '>> DECRYPTING GPS PAYLOAD...',
    '>> INJECTING TRACKER MODULE...',
    '>> ACCESS GRANTED :: ROOT MODE',
  ];

  static const List<String> _hackCommands = <String>[
    '> init sequence --force --silent',
    '> sudo access root@multitrack',
    '> scan open ports 22,80,443,8080',
    '> nmap -A 192.168.0.0/24',
    '> ssh tunnel establish :: SUCCESS',
    '> decrypt packet stream [AES-256]',
    '> inject payload :: tracker_module.dll',
    '> bypass auth token validation',
    '> read gps buffer :: 148 records',
    '> dump vehicle registry --live',
    '> spoof handshake :: node 0xAF21',
    '> escalate privilege level 3',
    '> hook location callback API',
    '> rewrite map tile cache',
    '> intercept CAN bus frames',
    '> clone device fingerprint',
    '> sync fleet telemetry uplink',
    '> brute force relay password...',
    '> crack hash sha512 :: running',
    '> mount encrypted partition /dev/sda2',
    '> exfiltrate route history.csv',
    '> overwrite watchdog timer',
    '> ping tracker-server :: 12ms',
    '> trace route lahore-gw-01',
    '> enable stealth mode :: ON',
    '> disable alarm trigger :: OK',
    '> parse geofence ruleset [42]',
    '> load driver profile DB',
    '> compile exploit chain v2.1',
    '> deploy backdoor service',
    '> rotate session key 0x9C4F',
    '> sniff OBD-II live stream',
    '> decode ignition events [ON/OFF]',
    '> mirror dashboard socket',
    '> patch firmware checksum',
    '> upload shell to remote node',
    '> clear security event logs',
    '> activate command relay',
    '> start packet flood analysis',
    '> hijack websocket channel',
    '> rewrite fuel sensor values',
    '> simulate ignition OFF signal',
    '> unlock immobilizer relay',
    '> export trip report :: encrypted',
    '> connect proxy chain [3 hops]',
    '> validate exploit success :: TRUE',
    '> maintain persistence daemon',
    '> broadcast fake GPS fix',
    '> override speed limit alert',
    '> inject fake maintenance alert',
    '> root shell ready :: awaiting input',
  ];

  @override
  void initState() {
    super.initState();
    _initializeOverlay();
  }

  @override
  void reassemble() {
    super.reassemble();
    _disposeOverlay();
    _initializeOverlay();
  }

  void _initializeOverlay() {
    if (_initialized) {
      return;
    }

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    )..repeat();

    if (_hexLines.isEmpty) {
      _hexLines.addAll(_generateHexBlock(6));
    }
    if (_liveCommands.isEmpty) {
      _liveCommands.addAll(_hackCommands.take(8));
    }

    _messageTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _messageIndex = (_messageIndex + 1) % _statusMessages.length;
      });
    });

    _glitchTimer = Timer.periodic(const Duration(milliseconds: 180), (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _glitchOn = !_glitchOn;
        _redFlash = _random.nextBool();
      });
    });

    _hexTimer = Timer.periodic(const Duration(milliseconds: 220), (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _hexLines.add(_generateHexLine());
        if (_hexLines.length > 14) {
          _hexLines.removeAt(0);
        }
      });
    });

    _statsTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _cpuLoad = 55 + _random.nextInt(45);
        _memLoad = 40 + _random.nextInt(50);
        _netLoad = 60 + _random.nextInt(40);
        _breachProgress = (_breachProgress + 0.03) % 1.0;
        _decryptProgress = (_decryptProgress + 0.05) % 1.0;
        _uploadProgress = (_uploadProgress + 0.04) % 1.0;
      });
    });

    _commandTimer = Timer.periodic(const Duration(milliseconds: 350), (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _commandSeed++;
        _liveCommands.add(_hackCommands[_commandSeed % _hackCommands.length]);
        if (_liveCommands.length > 22) {
          _liveCommands.removeAt(0);
        }
      });
    });

    final math.Random random = math.Random(7);
    _columns = List<_MatrixColumn>.generate(28, (int index) {
      return _MatrixColumn(
        xFactor: (index + 1) / 19,
        speed: 0.4 + random.nextDouble() * 0.9,
        chars: List<String>.generate(
          30,
          (_) => _randomChar(random),
        ),
      );
    });

    _initialized = true;
  }

  void _disposeOverlay() {
    _messageTimer?.cancel();
    _glitchTimer?.cancel();
    _commandTimer?.cancel();
    _hexTimer?.cancel();
    _statsTimer?.cancel();
    _messageTimer = null;
    _glitchTimer = null;
    _commandTimer = null;
    _hexTimer = null;
    _statsTimer = null;
    if (_initialized) {
      _controller.dispose();
    }
    _initialized = false;
  }

  @override
  void dispose() {
    _disposeOverlay();
    super.dispose();
  }

  List<String> _generateHexBlock(int count) {
    return List<String>.generate(count, (_) => _generateHexLine());
  }

  String _generateHexLine() {
    final int address = _random.nextInt(0xFFFFFF);
    final String bytes = List<String>.generate(
      8,
      (_) => _random.nextInt(256).toRadixString(16).padLeft(2, '0').toUpperCase(),
    ).join(' ');
    return '0x${address.toRadixString(16).padLeft(6, '0').toUpperCase()}  $bytes';
  }

  String _randomIp() {
    return '${_random.nextInt(220) + 10}.'
        '${_random.nextInt(255)}.'
        '${_random.nextInt(255)}.'
        '${_random.nextInt(255)}';
  }

  static String _randomChar(math.Random random) {
    const String chars = '01ABCDEF<>[]{}|/\\#@\$%&*';
    return chars[random.nextInt(chars.length)];
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      _initializeOverlay();
    }

    final double radarSweep =
        (DateTime.now().millisecondsSinceEpoch % 4000) / 4000 * math.pi * 2;

    return SizedBox.expand(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (BuildContext context, Widget? child) {
          return Stack(
            fit: StackFit.expand,
            children: <Widget>[
              const ColoredBox(color: Color(0xFF000000)),
              Positioned.fill(
                child: CustomPaint(
                  painter: _MatrixRainPainter(
                    columns: _columns,
                    progress: _controller.value,
                  ),
                ),
              ),
              Positioned.fill(
                child: CustomPaint(
                  painter: _RadarScanPainter(
                    sweepAngle: radarSweep,
                  ),
                ),
              ),
              Positioned.fill(
                child: CustomPaint(
                  painter: _DataPacketPainter(
                    progress: _controller.value,
                    seed: _commandSeed,
                  ),
                ),
              ),
              Positioned.fill(
                child: CustomPaint(
                  painter: _ScanlinePainter(
                    progress: _controller.value,
                    glitchOn: _glitchOn,
                    random: _random,
                  ),
                ),
              ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.center,
                      radius: 1.15,
                      colors: <Color>[
                        Colors.black.withValues(alpha: 0.18),
                        Colors.black.withValues(alpha: 0.62),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: ColoredBox(
                  color: Colors.black.withValues(alpha: 0.22),
                ),
              ),
              if (_glitchOn)
                ColoredBox(color: _cyan.withValues(alpha: 0.018)),
              if (_redFlash && _glitchOn)
                ColoredBox(color: _alertRed.withValues(alpha: 0.035)),
              if (_glitchOn)
                Transform.translate(
                  offset: Offset(_random.nextInt(3) - 1.0, 0),
                  child: const SizedBox.expand(),
                ),
              _buildHudCorner(Alignment.topLeft),
              _buildHudCorner(Alignment.topRight),
              _buildHudCorner(Alignment.bottomLeft),
              _buildHudCorner(Alignment.bottomRight),
              Positioned(
                top: 52,
                left: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: _neon.withValues(alpha: 0.12),
                    border: Border.all(color: _neon.withValues(alpha: 0.45)),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _statusMessages[_messageIndex],
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: _neon,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.1,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 86,
                left: 10,
                right: 10,
                child: _buildSystemStatsBar(),
              ),
              Positioned(
                top: 118,
                left: 0,
                right: 0,
                child: _buildProgressDashboard(),
              ),
              Positioned(
                top: 168,
                left: 8,
                width: 158,
                bottom: 168,
                child: _buildCommandPanel(
                  title: 'SHELL-A',
                  commands: _liveCommands,
                  accent: _neon,
                  footer: 'TARGET :: ${_randomIp()}',
                ),
              ),
              Positioned(
                top: 168,
                right: 8,
                width: 158,
                bottom: 168,
                child: _buildCommandPanel(
                  title: 'SHELL-B',
                  commands: _liveCommands.reversed.take(18).toList(),
                  accent: _cyan,
                  footer:
                      'NODE :: 0x${(_commandSeed * 17).toRadixString(16).toUpperCase()}',
                ),
              ),
              Positioned(
                top: 190,
                left: 0,
                right: 0,
                child: _buildFloatingCommands(),
              ),
              Positioned(
                left: 12,
                right: 12,
                bottom: 158,
                height: 72,
                child: _buildHexDumpPanel(),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  height: 150,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: <Color>[
                        Colors.black.withValues(alpha: 0.72),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Text(
                            '>> TERMINAL OUTPUT :: LIVE',
                            style: TextStyle(
                              color: _amber.withValues(alpha: 0.9),
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              fontFamily: 'monospace',
                            ),
                          ),
                          const Spacer(),
                          Text(
                            'PID:${4200 + _commandSeed} | THREADS:16',
                            style: TextStyle(
                              color: _neon.withValues(alpha: 0.65),
                              fontSize: 8,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Expanded(
                        child: SingleChildScrollView(
                          reverse: true,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: _liveCommands
                                .reversed
                                .take(12)
                                .map(
                                  (String cmd) => Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 1,
                                    ),
                                    child: Text(
                                      '[${(_commandSeed % 999).toString().padLeft(3, '0')}] $cmd ... OK',
                                      style: TextStyle(
                                        color: _neon.withValues(alpha: 0.85),
                                        fontSize: 9.5,
                                        height: 1.25,
                                        fontFamily: 'monospace',
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSystemStatsBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: _neon.withValues(alpha: 0.25)),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            _buildStatChip('CPU', _cpuLoad, _alertRed),
            const SizedBox(width: 6),
            _buildStatChip('MEM', _memLoad, _amber),
            const SizedBox(width: 6),
            _buildStatChip('NET', _netLoad, _cyan),
            const SizedBox(width: 6),
            Text(
              'ROOT@MULTITRACK',
              style: TextStyle(
                color: _neon.withValues(alpha: 0.8),
                fontSize: 8,
                fontWeight: FontWeight.w800,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatChip(String label, int value, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          '$label:',
          style: TextStyle(
            color: color.withValues(alpha: 0.85),
            fontSize: 8,
            fontFamily: 'monospace',
          ),
        ),
        const SizedBox(width: 4),
        SizedBox(
          width: 36,
          child: LinearProgressIndicator(
            value: value / 100,
            minHeight: 4,
            backgroundColor: Colors.white.withValues(alpha: 0.12),
            color: color,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          '$value%',
          style: TextStyle(
            color: color.withValues(alpha: 0.9),
            fontSize: 8,
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }

  Widget _buildProgressDashboard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 72),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.38),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _cyan.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: <Widget>[
            _buildHackProgress('BREACH', _breachProgress, _alertRed),
            const SizedBox(height: 5),
            _buildHackProgress('DECRYPT', _decryptProgress, _neon),
            const SizedBox(height: 5),
            _buildHackProgress('UPLOAD', _uploadProgress, _cyan),
          ],
        ),
      ),
    );
  }

  Widget _buildHackProgress(String label, double value, Color color) {
    return Row(
      children: <Widget>[
        SizedBox(
          width: 58,
          child: Text(
            label,
            style: TextStyle(
              color: color.withValues(alpha: 0.9),
              fontSize: 8,
              fontWeight: FontWeight.w800,
              fontFamily: 'monospace',
            ),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: value,
              minHeight: 6,
              backgroundColor: Colors.white.withValues(alpha: 0.12),
              color: color,
            ),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          '${(value * 100).round()}%',
          style: TextStyle(
            color: color.withValues(alpha: 0.85),
            fontSize: 8,
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }

  Widget _buildHexDumpPanel() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _amber.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            '[HEX MEMORY DUMP]',
            style: TextStyle(
              color: _amber.withValues(alpha: 0.9),
              fontSize: 8,
              fontWeight: FontWeight.w800,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: ListView.builder(
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _hexLines.length,
              itemBuilder: (BuildContext context, int index) {
                return Text(
                  _hexLines[index],
                  style: TextStyle(
                    color: _amber.withValues(alpha: 0.75),
                    fontSize: 7.5,
                    height: 1.2,
                    fontFamily: 'monospace',
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommandPanel({
    required String title,
    required List<String> commands,
    required Color accent,
    required String footer,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 6, 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.48),
        border: Border.all(color: accent.withValues(alpha: 0.45)),
        borderRadius: BorderRadius.circular(8),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: accent.withValues(alpha: 0.12),
            blurRadius: 12,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            '[$title]',
            style: TextStyle(
              color: accent,
              fontSize: 9,
              fontWeight: FontWeight.w800,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: ListView.builder(
              itemCount: commands.length,
              itemBuilder: (BuildContext context, int index) {
                final String cmd = commands[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    cmd,
                    style: TextStyle(
                      color: accent.withValues(alpha: 0.78),
                      fontSize: 8.5,
                      height: 1.2,
                      fontFamily: 'monospace',
                    ),
                  ),
                );
              },
            ),
          ),
          Text(
            footer,
            style: TextStyle(
              color: accent.withValues(alpha: 0.55),
              fontSize: 7.5,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingCommands() {
    final List<String> floating = _liveCommands.reversed.take(8).toList();
    return Column(
      children: List<Widget>.generate(floating.length, (int index) {
        final Color color = index.isEven ? _neon : _cyan;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Text(
            floating[index],
            textAlign: TextAlign.center,
            style: TextStyle(
              color: color.withValues(alpha: 0.22),
              fontSize: 10,
              fontWeight: FontWeight.w600,
              fontFamily: 'monospace',
            ),
          ),
        );
      }),
    );
  }

  Widget _buildHudCorner(Alignment alignment) {
    return Positioned.fill(
      child: Align(
        alignment: alignment,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              border: Border(
                top: alignment.y < 0
                    ? BorderSide(color: _neon.withValues(alpha: 0.7), width: 2)
                    : BorderSide.none,
                bottom: alignment.y > 0
                    ? BorderSide(color: _neon.withValues(alpha: 0.7), width: 2)
                    : BorderSide.none,
                left: alignment.x < 0
                    ? BorderSide(color: _neon.withValues(alpha: 0.7), width: 2)
                    : BorderSide.none,
                right: alignment.x > 0
                    ? BorderSide(color: _neon.withValues(alpha: 0.7), width: 2)
                    : BorderSide.none,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MatrixColumn {
  final double xFactor;
  final double speed;
  final List<String> chars;

  const _MatrixColumn({
    required this.xFactor,
    required this.speed,
    required this.chars,
  });
}

class _MatrixRainPainter extends CustomPainter {
  final List<_MatrixColumn> columns;
  final double progress;

  _MatrixRainPainter({
    required this.columns,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final _MatrixColumn column in columns) {
      final double x = size.width * column.xFactor;
      final double offset =
          (progress * column.speed * size.height) % size.height;

      for (int i = 0; i < column.chars.length; i++) {
        final double y = (offset + i * 16) % (size.height + 32) - 16;
        final double opacity =
            (1 - (i / column.chars.length)).clamp(0.04, 0.32);

        final TextPainter painter = TextPainter(
          text: TextSpan(
            text: column.chars[i],
            style: TextStyle(
              color: const Color(0xFF00FF88).withValues(alpha: opacity),
              fontSize: 12,
              fontFamily: 'monospace',
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();

        painter.paint(canvas, Offset(x, y));
      }
    }
  }

  @override
  bool shouldRepaint(covariant _MatrixRainPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _ScanlinePainter extends CustomPainter {
  final double progress;
  final bool glitchOn;
  final math.Random random;

  _ScanlinePainter({
    required this.progress,
    required this.glitchOn,
    required this.random,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint linePaint = Paint()
      ..color = const Color(0xFF00FF88).withValues(alpha: glitchOn ? 0.03 : 0.015);

    for (double y = 0; y < size.height; y += 4) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    }

    final Paint gridPaint = Paint()
      ..color = const Color(0xFF00E5FF).withValues(alpha: 0.02)
      ..strokeWidth = 1;

    for (double x = 0; x < size.width; x += 42) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }

    final double sweepY = size.height * progress;
    final Paint sweepPaint = Paint()
      ..color = const Color(0xFF00FF88).withValues(alpha: 0.08)
      ..strokeWidth = 2;
    canvas.drawLine(
      Offset(0, sweepY),
      Offset(size.width, sweepY),
      sweepPaint,
    );

    if (glitchOn) {
      final Paint glitchPaint = Paint()
        ..color = const Color(0xFFFF3355).withValues(alpha: 0.12);
      for (int i = 0; i < 6; i++) {
        final double y = random.nextDouble() * size.height;
        canvas.drawRect(
          Rect.fromLTWH(0, y, size.width, 2 + random.nextDouble() * 4),
          glitchPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ScanlinePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.glitchOn != glitchOn;
  }
}

class _RadarScanPainter extends CustomPainter {
  final double sweepAngle;

  _RadarScanPainter({required this.sweepAngle});

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width / 2, size.height * 0.46);
    const double radius = 78;

    final Paint ringPaint = Paint()
      ..color = const Color(0xFF00FF88).withValues(alpha: 0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (int i = 1; i <= 3; i++) {
      canvas.drawCircle(center, radius * i / 3, ringPaint);
    }

    final Paint sweepPaint = Paint()
      ..shader = SweepGradient(
        startAngle: sweepAngle,
        endAngle: sweepAngle + 1.2,
        colors: <Color>[
          const Color(0xFF00FF88).withValues(alpha: 0.14),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawCircle(center, radius, sweepPaint);

    final Paint linePaint = Paint()
      ..color = const Color(0xFF00E5FF).withValues(alpha: 0.22)
      ..strokeWidth = 1.5;
    canvas.drawLine(
      center,
      Offset(
        center.dx + math.cos(sweepAngle) * radius,
        center.dy + math.sin(sweepAngle) * radius,
      ),
      linePaint,
    );

    final Paint blipPaint = Paint()
      ..color = const Color(0xFFFF3355).withValues(alpha: 0.55);
    canvas.drawCircle(
      Offset(center.dx + 24, center.dy - 18),
      3,
      blipPaint,
    );
    canvas.drawCircle(
      Offset(center.dx - 30, center.dy + 12),
      2.5,
      blipPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _RadarScanPainter oldDelegate) {
    return oldDelegate.sweepAngle != sweepAngle;
  }
}

class _DataPacketPainter extends CustomPainter {
  final double progress;
  final int seed;

  _DataPacketPainter({
    required this.progress,
    required this.seed,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint packetPaint = Paint()
      ..color = const Color(0xFF00E5FF).withValues(alpha: 0.35)
      ..strokeWidth = 1.2;

    for (int i = 0; i < 8; i++) {
      final double y = size.height * (0.22 + i * 0.08);
      final double x = ((progress + i * 0.11) % 1.0) * (size.width + 80) - 40;
      canvas.drawLine(Offset(x, y), Offset(x + 28, y), packetPaint);
      canvas.drawCircle(Offset(x + 28, y), 2, packetPaint);
    }

    final TextPainter labelPainter = TextPainter(
      text: TextSpan(
        text: 'PKT-${seed % 9999}',
        style: TextStyle(
          color: const Color(0xFF00FF88).withValues(alpha: 0.25),
          fontSize: 8,
          fontFamily: 'monospace',
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    labelPainter.paint(canvas, Offset(size.width * 0.42, size.height * 0.36));
  }

  @override
  bool shouldRepaint(covariant _DataPacketPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.seed != seed;
  }
}
