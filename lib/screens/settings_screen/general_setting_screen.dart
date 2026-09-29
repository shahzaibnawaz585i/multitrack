import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../l10n/app_l10n.dart';
import '../../l10n/app_locale_controller.dart';
import '../../models/notification_model.dart';
import '../../services/general_settings_controller.dart';
import '../../services/live_notification_controller.dart';
import '../../services/voice_alert_service.dart';
import '../../theme/app_theme_controller.dart';
import '../../theme/app_theme_mode.dart';
import '../../theme/app_theme_tokens.dart';
import '../../theme/app_themes.dart';

import '../../widgets/animated_aurora_border_container.dart';

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
  static const Color _auroraBackground = AppThemes.auroraBackground;
  static const Color _auroraSurface = AppThemes.auroraSurface;
  static const Color _auroraText = AppThemes.auroraText;

  double _zoomLevel = 17;

  @override
  void initState() {
    super.initState();
    _loadSavedSettings();
  }

  Future<void> _loadSavedSettings() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final GeneralSettingsController generalSettings =
          context.read<GeneralSettingsController>();
      final String storedAppColor =
          context.read<AppThemeController>().appColorName;
      final String? storedPassword = prefs.getString('relay_password_secret');

      if (mounted) {
        setState(() {
          _values['App Color'] = storedAppColor;
          if (storedPassword != null && storedPassword.isNotEmpty) {
            _values['Relay Password'] = 'Password Set';
          } else {
            _values['Relay Password'] = 'Set Password';
          }
          _zoomLevel = generalSettings.zoomLevel;

          for (final _GeneralSettingData setting in _dropdownSettings) {
            if (setting.title == 'Language' ||
                setting.title == 'App Color' ||
                setting.title == 'Relay Password') {
              continue;
            }
            _values[setting.title] = generalSettings.get(
              setting.title,
              defaultValue: setting.options.first,
            );
          }

          final String notifVal = _values['Notification'] ?? 'ON';
          VoiceAlertService.instance.enabled = (notifVal.toUpperCase() == 'ON');
        });
      }
    } catch (error) {
      debugPrint('Error loading saved general settings: $error');
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _values['Language'] = context.read<AppLocaleController>().languageName;
  }

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
    'Currency': 'PKR',
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
      options: <String>['Vehicle List', 'Live Page', 'Map Page', 'Reports Page'],
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
      icon: Icons.language_outlined,
      iconColor: Color(0xFF4D91C5),
      image: 'assets/laguage.png',
      options: <String>[
        'English',
        'Hindi',
        'Urdu',
        'Arabic',
        'Bengali',
        'Punjabi',
        'Marathi',
        'Telugu',
        'Tamil',
        'Gujarati',
        'Kannada',
        'Malayalam',
        'Spanish',
        'French',
        'German',
        'Russian',
        'Chinese',
        'Japanese',
        'Korean',
        'Turkish',
      ],
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
      icon: Icons.straighten_outlined,
      iconColor: Color(0xFF4D91C5),
      image: 'assets/distance.png',
      options: <String>['km', 'mile'],
    ),
    _GeneralSettingData(
      title: 'Area',
      icon: Icons.aspect_ratio_outlined,
      iconColor: Color(0xFF4D91C5),
      image: 'assets/area.png',
      options: <String>['Hectare', 'Acre'],
    ),
    _GeneralSettingData(
      title: 'Voice Command',
      icon: Icons.record_voice_over_outlined,
      iconColor: Color(0xFF4D91C5),
      image: 'assets/voice_command.png',
      options: <String>['ON', 'OFF'],
    ),
    _GeneralSettingData(
      title: 'Currency',
      icon: Icons.attach_money_outlined,
      iconColor: Color(0xFF4CAF50),
      image: 'assets/currency.png',
      options: <String>['INR', 'USD', 'PKR'],
    ),
    _GeneralSettingData(
      title: 'Live Page Trail',
      icon: Icons.route_outlined,
      iconColor: Color(0xFF4D91C5),
      image: 'assets/live_page_trail.png',
      options: <String>['ON', 'OFF'],
    ),
    _GeneralSettingData(
      title: 'Show History on Live',
      icon: Icons.history_outlined,
      iconColor: Color(0xFF4D91C5),
      image: 'assets/show_history_on_live.png',
      options: <String>['ON', 'OFF'],
    ),
    _GeneralSettingData(
      title: 'Filter History Fluctuation',
      icon: Icons.filter_alt_outlined,
      iconColor: Color(0xFF4D91C5),
      image: 'assets/filter_history_flucation.png',
      options: <String>['ON', 'OFF'],
    ),
    _GeneralSettingData(
      title: 'Farm Calculation',
      icon: Icons.agriculture_outlined,
      iconColor: Color(0xFF4CAF50),
      image: 'assets/farm_calculation.png',
      options: <String>['ON', 'OFF'],
    ),
    _GeneralSettingData(
      title: 'Notification',
      icon: Icons.notifications_outlined,
      iconColor: Color(0xFFE53935),
      image: 'assets/notification.png',
      options: <String>['ON', 'OFF'],
    ),
    _GeneralSettingData(
      title: 'Fuel Reading',
      icon: Icons.local_gas_station_outlined,
      iconColor: Color(0xFF4D91C5),
      image: 'assets/fuel_reading.png',
      options: <String>['Device', 'Sensor'],
    ),
    _GeneralSettingData(
      title: 'History Route Color',
      icon: Icons.color_lens_outlined,
      iconColor: Color(0xFFE53935),
      image: 'assets/history_route_color.png',
      options: <String>['Default Color', 'Blue', 'Green', 'Red'],
    ),
    _GeneralSettingData(
      title: 'App Color',
      icon: Icons.palette_outlined,
      iconColor: Color(0xFFFF2F68),
      image: 'assets/app_color.png',
      options: <String>['Default Color', 'Blue', 'Green', 'Red', 'Pink'],
    ),
    _GeneralSettingData(
      title: 'Relay Password',
      icon: Icons.lock_outline,
      iconColor: Color(0xFF4D91C5),
      image: 'assets/password.png',
      options: <String>['Set Password', 'Change Password', 'Remove Password'],
    ),
  ];

  Color _backgroundColorFor(AppThemeMode themeMode) {
    switch (themeMode) {
      case AppThemeMode.light:
        return _lightBackground;
      case AppThemeMode.dark:
        return _darkBackground;
      case AppThemeMode.aurora:
        return _auroraBackground;
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
      case AppThemeMode.aurora:
        return _auroraSurface;
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
      case AppThemeMode.aurora:
        return _auroraText;
      case AppThemeMode.hacking:
        return _hackText;
    }
  }

  Color _accentColorFor(AppThemeMode themeMode) =>
      themeMode == AppThemeMode.hacking
          ? _hackAccent
          : context.watch<AppThemeController>().customAccentColor;

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
    final bool isAurora = themeMode.isAurora;
    final bool useGlowBackdrop = isHacking || isAurora;
    final Color backgroundColor = _backgroundColorFor(themeMode);
    final Color textColor = _textColorFor(themeMode);
    final Color accentColor = _accentColorFor(themeMode);

    final Widget innerList = Column(
      children: <Widget>[
        _ThemeSettingRow(
          themeLabel: context.tr('Choose Theme'),
          themeMode: themeMode,
          valueLabel: context.tr(themeMode.label),
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
          onChanged: (double value) async {
            setState(() {
              _zoomLevel = value;
            });
            await context
                .read<GeneralSettingsController>()
                .setZoomLevel(value);
          },
        ),
      ],
    );

    final Widget settingsContainer = isAurora
        ? AnimatedAuroraBorderContainer(
            borderRadius: 20,
            borderWidth: 2.2,
            padding: const EdgeInsets.only(
              left: 22,
              right: 16,
              top: 18,
              bottom: 12,
            ),
            child: innerList,
          )
        : Material(
            color: Colors.transparent,
            elevation: useGlowBackdrop ? 12 : 0,
            shadowColor: isHacking
                ? _hackAccent.withOpacity(0.3)
                : null,
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
                child: innerList,
              ),
            ),
          );

    return Scaffold(
      backgroundColor: useGlowBackdrop ? Colors.transparent : backgroundColor,
      appBar: AppBar(
        backgroundColor: useGlowBackdrop ? Colors.transparent : backgroundColor,
        surfaceTintColor: useGlowBackdrop ? Colors.transparent : backgroundColor,
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
          context.tr('Settings'),
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
    if (setting.title == 'Relay Password') {
      await _handleRelayPasswordFlow(themeMode);
      return;
    }

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
          translateOptions: setting.title != 'Language',
        );
      },
    );

    if (selected == null || !mounted) {
      return;
    }

    setState(() {
      _values[setting.title] = selected;
    });

    try {
      if (setting.title == 'Language') {
        await context.read<AppLocaleController>().setLanguageName(selected);
      } else if (setting.title == 'App Color') {
        await context.read<AppThemeController>().setAppColorName(selected);
        await context
            .read<GeneralSettingsController>()
            .setSetting(setting.title, selected);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.tr('App Color updated to {color}')
                  .replaceAll('{color}', context.tr(selected))),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        await context
            .read<GeneralSettingsController>()
            .setSetting(setting.title, selected);

        if (setting.title == 'Notification' || setting.title == 'Voice Command') {
          final bool isEnabled = (selected.toUpperCase() == 'ON');
          VoiceAlertService.instance.enabled = isEnabled;
          if (isEnabled) {
            LiveNotificationController.instance.push(
              AppNotification(
                vehicleId: 'PB11DD9661',
                eventTitle: 'Ignition On',
                location: 'Live GPS Alert Active',
                timestamp: DateTime.now(),
                category: NotificationCategory.alerts,
                eventType: NotificationEventType.ignitionOn,
              ),
            );
          }
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.tr('{title} set to {value}')
                  .replaceAll('{title}', context.tr(setting.title))
                  .replaceAll('{value}', context.tr(selected))),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error saving option for ${setting.title}: $e');
    }
  }

  Future<void> _handleRelayPasswordFlow(AppThemeMode themeMode) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? savedPassword = prefs.getString('relay_password_secret');
    final bool hasPassword = savedPassword != null && savedPassword.isNotEmpty;

    final String? selectedAction = await showDialog<String>(
      context: context,
      barrierColor: Colors.black54,
      builder: (BuildContext dialogContext) {
        return _OptionPickerDialog(
          title: 'Relay Password',
          options: const <String>[
            'Set Password',
            'Change Password',
            'Remove Password'
          ],
          selectedValue: hasPassword ? 'Change Password' : 'Set Password',
          themeMode: themeMode,
        );
      },
    );

    if (selectedAction == null || !mounted) {
      return;
    }

    if (selectedAction == 'Remove Password') {
      if (!hasPassword) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr('No Relay Password is currently set.')),
          ),
        );
        return;
      }
      final bool? confirm = await showDialog<bool>(
        context: context,
        barrierColor: Colors.black54,
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            backgroundColor: _surfaceColorFor(themeMode),
            title: Text(
              context.tr('Remove Password'),
              style: TextStyle(color: _textColorFor(themeMode)),
            ),
            content: Text(
              context.tr('Are you sure you want to remove your Relay Password?'),
              style: TextStyle(color: _textColorFor(themeMode)),
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: Text(context.tr('CANCEL')),
              ),
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: Text(
                  context.tr('OK'),
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            ],
          );
        },
      );

      if (confirm == true && mounted) {
        await prefs.remove('relay_password_secret');
        setState(() {
          _values['Relay Password'] = 'Set Password';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr('Relay Password removed successfully')),
          ),
        );
      }
      return;
    }

    if (selectedAction == 'Change Password' && !hasPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              context.tr('No password set yet. Please set a password first.')),
        ),
      );
    }

    final String? newPassword = await showDialog<String>(
      context: context,
      barrierColor: Colors.black54,
      builder: (BuildContext dialogContext) {
        return _RelayPasswordInputDialog(
          isChangeMode: hasPassword && selectedAction == 'Change Password',
          existingPassword: savedPassword ?? '',
          themeMode: themeMode,
        );
      },
    );

    if (newPassword != null && newPassword.isNotEmpty && mounted) {
      await prefs.setString('relay_password_secret', newPassword);
      setState(() {
        _values['Relay Password'] = 'Password Set';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr('Relay Password saved successfully')),
        ),
      );
    }
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
      mode: AppThemeMode.aurora,
      label: 'Aurora Theme',
      icon: Icons.auto_awesome,
      iconColor: Color(0xFF5CE1FF),
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
                context.tr('Choose Theme'),
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
                        context.tr(option.label),
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
                    label: context.tr('CANCEL'),
                    accentColor: accentColor,
                    onTap: () => Navigator.pop(context),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _DialogButton(
                    label: context.tr('OK'),
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
    double containerWidth = 30;
    double containerHeight = 30;

    if (setting.title == 'Vehicle Icon Size') {
      containerWidth = 44;
      containerHeight = 44;
      if (value == 'Small') iconSize = 14;
      if (value == 'Medium') iconSize = 24;
      if (value == 'Large') iconSize = 38;
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
                width: containerWidth,
                height: containerHeight,
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
                  context.tr(setting.title),
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
                        setting.title == 'Language'
                            ? value
                            : context.tr(value),
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
              context.tr('Zoom Level'),
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
  final bool translateOptions;

  const _OptionPickerDialog({
    required this.title,
    required this.options,
    required this.selectedValue,
    required this.themeMode,
    this.translateOptions = true,
  });

  @override
  State<_OptionPickerDialog> createState() => _OptionPickerDialogState();
}

class _OptionPickerDialogState extends State<_OptionPickerDialog> {
  late String _selectedValue;
  late final TextEditingController _searchController;
  late List<String> _filteredOptions;

  bool get _showSearch => widget.options.length > 10;

  @override
  void initState() {
    super.initState();
    _selectedValue = widget.selectedValue;
    _searchController = TextEditingController();
    _filteredOptions = widget.options;
    _searchController.addListener(_filterOptions);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterOptions() {
    final String query = _searchController.text.trim().toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredOptions = widget.options;
      } else {
        _filteredOptions = widget.options
            .where((String option) => option.toLowerCase().contains(query))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final Color surfaceColor = switch (widget.themeMode) {
      AppThemeMode.light => Colors.white,
      AppThemeMode.dark => const Color(0xFF23252E),
      AppThemeMode.aurora => AppThemes.auroraSurface,
      AppThemeMode.hacking => const Color(0xFF050805),
    };
    final Color textColor = switch (widget.themeMode) {
      AppThemeMode.light => const Color(0xFF292B32),
      AppThemeMode.dark => Colors.white,
      AppThemeMode.aurora => AppThemes.auroraText,
      AppThemeMode.hacking => const Color(0xFF9DFFB5),
    };
    final Color accentColor = widget.themeMode == AppThemeMode.hacking
        ? const Color(0xFF00FF88)
        : const Color(0xFFFF2F68);
    final Color mutedColor = textColor.withValues(alpha: 0.45);
    final double maxDialogHeight = MediaQuery.sizeOf(context).height * 0.72;

    final bool isVehicleIconSetting =
        widget.title.contains('Vehicle icon') || widget.title == 'Vehicle Icon Size';
    final bool isColorSetting =
        widget.title == 'App Color' || widget.title == 'History Route Color';
    final bool isToggleSetting =
        widget.options.length == 2 && widget.options.contains('ON') && widget.options.contains('OFF');
    final bool isCurrencySetting = widget.title == 'Currency';

    final Widget optionList = _filteredOptions.isEmpty
        ? Padding(
            padding: const EdgeInsets.symmetric(vertical: 28),
            child: Center(
              child: Text(
                context.tr('No language found'),
                style: TextStyle(color: mutedColor, fontSize: 14),
              ),
            ),
          )
        : ListView.builder(
            shrinkWrap: !_showSearch,
            padding: const EdgeInsets.symmetric(vertical: 4),
            itemCount: _filteredOptions.length,
            itemBuilder: (BuildContext context, int index) {
              final String option = _filteredOptions[index];
              double previewIconSize = 22;
              if (isVehicleIconSetting) {
                if (option == 'Small') previewIconSize = 14;
                if (option == 'Medium') previewIconSize = 24;
                if (option == 'Large') previewIconSize = 36;
              }

              Color? previewColor;
              if (isColorSetting) {
                switch (option) {
                  case 'Blue':
                    previewColor = const Color(0xFF2196F3);
                    break;
                  case 'Green':
                    previewColor = const Color(0xFF4CAF50);
                    break;
                  case 'Red':
                    previewColor = const Color(0xFFE53935);
                    break;
                  case 'Pink':
                    previewColor = const Color(0xFFFF2F68);
                    break;
                  case 'Default Color':
                  default:
                    previewColor = const Color(0xFFFF2F68);
                    break;
                }
              }

              return InkWell(
                onTap: () {
                  setState(() {
                    _selectedValue = option;
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
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
                      if (isVehicleIconSetting) ...<Widget>[
                        SizedBox(
                          width: 40,
                          height: 40,
                          child: Center(
                            child: SizedBox(
                              width: previewIconSize,
                              height: previewIconSize,
                              child: Image.asset(
                                'assets/vehicle_icon_size.png',
                                fit: BoxFit.contain,
                                errorBuilder:
                                    (BuildContext context, Object error, StackTrace? stackTrace) {
                                  return Icon(
                                    Icons.directions_car_outlined,
                                    color: const Color(0xFF4D91C5),
                                    size: previewIconSize,
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      if (isColorSetting && previewColor != null) ...<Widget>[
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: previewColor,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: textColor.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      if (isCurrencySetting) ...<Widget>[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: accentColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            option == 'USD'
                                ? '\$'
                                : option == 'PKR'
                                    ? 'Rs'
                                    : '₹',
                            style: TextStyle(
                              color: accentColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      Expanded(
                        child: Text(
                          widget.translateOptions ? context.tr(option) : option,
                          style: TextStyle(
                            color: textColor,
                            fontSize: 15,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                      if (isToggleSetting)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: option == 'ON'
                                ? const Color(0xFF4CAF50).withOpacity(0.18)
                                : Colors.grey.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            option,
                            style: TextStyle(
                              color: option == 'ON' ? const Color(0xFF4CAF50) : mutedColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          );

    return Dialog(
      backgroundColor: surfaceColor,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SizedBox(
        height: _showSearch ? maxDialogHeight : null,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxDialogHeight),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    context.tr(widget.title),
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
              if (_showSearch)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: TextField(
                    controller: _searchController,
                    style: TextStyle(color: textColor, fontSize: 15),
                    decoration: InputDecoration(
                      hintText: context.tr('Search language'),
                      hintStyle: TextStyle(color: mutedColor, fontSize: 15),
                      prefixIcon: Icon(Icons.search, color: mutedColor, size: 20),
                      isDense: true,
                      filled: true,
                      fillColor: textColor.withValues(alpha: 0.06),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: textColor.withValues(alpha: 0.18),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: accentColor, width: 1.2),
                      ),
                    ),
                  ),
                ),
              if (_showSearch)
                Expanded(child: optionList)
              else
                optionList,
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: _DialogButton(
                        label: context.tr('CANCEL'),
                        accentColor: accentColor,
                        onTap: () => Navigator.pop(context),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _DialogButton(
                        label: context.tr('OK'),
                        accentColor: accentColor,
                        onTap: () => Navigator.pop(context, _selectedValue),
                      ),
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

class _RelayPasswordInputDialog extends StatefulWidget {
  final bool isChangeMode;
  final String existingPassword;
  final AppThemeMode themeMode;

  const _RelayPasswordInputDialog({
    required this.isChangeMode,
    required this.existingPassword,
    required this.themeMode,
  });

  @override
  State<_RelayPasswordInputDialog> createState() =>
      _RelayPasswordInputDialogState();
}

class _RelayPasswordInputDialogState
    extends State<_RelayPasswordInputDialog> {
  final TextEditingController _oldPassController = TextEditingController();
  final TextEditingController _newPassController = TextEditingController();
  final TextEditingController _confirmPassController =
      TextEditingController();

  bool _hideOld = true;
  bool _hideNew = true;
  bool _hideConfirm = true;
  String? _errorText;

  @override
  void dispose() {
    _oldPassController.dispose();
    _newPassController.dispose();
    _confirmPassController.dispose();
    super.dispose();
  }

  void _submit() {
    setState(() {
      _errorText = null;
    });

    if (widget.isChangeMode) {
      if (_oldPassController.text != widget.existingPassword) {
        setState(() {
          _errorText = context.tr('Incorrect old password');
        });
        return;
      }
    }

    final String newPass = _newPassController.text.trim();
    final String confirmPass = _confirmPassController.text.trim();

    if (newPass.length < 4) {
      setState(() {
        _errorText = context.tr('Password must be at least 4 characters');
      });
      return;
    }

    if (newPass != confirmPass) {
      setState(() {
        _errorText = context.tr('Passwords do not match');
      });
      return;
    }

    Navigator.pop(context, newPass);
  }

  @override
  Widget build(BuildContext context) {
    final Color surfaceColor = switch (widget.themeMode) {
      AppThemeMode.light => Colors.white,
      AppThemeMode.dark => const Color(0xFF23252E),
      AppThemeMode.aurora => AppThemes.auroraSurface,
      AppThemeMode.hacking => const Color(0xFF050805),
    };
    final Color textColor = switch (widget.themeMode) {
      AppThemeMode.light => const Color(0xFF292B32),
      AppThemeMode.dark => Colors.white,
      AppThemeMode.aurora => AppThemes.auroraText,
      AppThemeMode.hacking => const Color(0xFF9DFFB5),
    };
    final Color accentColor = widget.themeMode == AppThemeMode.hacking
        ? const Color(0xFF00FF88)
        : context.watch<AppThemeController>().customAccentColor;

    return Dialog(
      backgroundColor: surfaceColor,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              widget.isChangeMode
                  ? context.tr('Change Relay Password')
                  : context.tr('Set Relay Password'),
              style: TextStyle(
                color: textColor,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            if (widget.isChangeMode) ...<Widget>[
              TextField(
                controller: _oldPassController,
                obscureText: _hideOld,
                style: TextStyle(color: textColor),
                decoration: InputDecoration(
                  labelText: context.tr('Old Password*'),
                  labelStyle: TextStyle(color: textColor.withOpacity(0.6)),
                  filled: true,
                  fillColor: textColor.withOpacity(0.05),
                  isDense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _hideOld
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: textColor.withOpacity(0.6),
                      size: 20,
                    ),
                    onPressed: () => setState(() => _hideOld = !_hideOld),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: accentColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: accentColor, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
            TextField(
              controller: _newPassController,
              obscureText: _hideNew,
              style: TextStyle(color: textColor),
              decoration: InputDecoration(
                labelText: widget.isChangeMode
                    ? context.tr('New Password*')
                    : context.tr('Relay Password*'),
                labelStyle: TextStyle(color: textColor.withOpacity(0.6)),
                filled: true,
                fillColor: textColor.withOpacity(0.05),
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                suffixIcon: IconButton(
                  icon: Icon(
                    _hideNew
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: textColor.withOpacity(0.6),
                    size: 20,
                  ),
                  onPressed: () => setState(() => _hideNew = !_hideNew),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: accentColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: accentColor, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _confirmPassController,
              obscureText: _hideConfirm,
              style: TextStyle(color: textColor),
              decoration: InputDecoration(
                labelText: context.tr('Confirm Password*'),
                labelStyle: TextStyle(color: textColor.withOpacity(0.6)),
                filled: true,
                fillColor: textColor.withOpacity(0.05),
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                suffixIcon: IconButton(
                  icon: Icon(
                    _hideConfirm
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: textColor.withOpacity(0.6),
                    size: 20,
                  ),
                  onPressed: () => setState(() => _hideConfirm = !_hideConfirm),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: accentColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: accentColor, width: 1.5),
                ),
              ),
            ),
            if (_errorText != null) ...<Widget>[
              const SizedBox(height: 8),
              Text(
                _errorText!,
                style: const TextStyle(color: Colors.red, fontSize: 13),
              ),
            ],
            const SizedBox(height: 20),
            Row(
              children: <Widget>[
                Expanded(
                  child: _DialogButton(
                    label: context.tr('CANCEL'),
                    accentColor: textColor.withOpacity(0.3),
                    onTap: () => Navigator.pop(context),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _DialogButton(
                    label: context.tr('Apply'),
                    accentColor: accentColor,
                    onTap: _submit,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

