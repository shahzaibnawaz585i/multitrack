import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../constants/app_theme.dart';
import '../../providers/theme_provider.dart';

class GeneralSettingScreen extends StatefulWidget {
  const GeneralSettingScreen({super.key});

  @override
  State<GeneralSettingScreen> createState() => _GeneralSettingScreenState();
}

class _GeneralSettingScreenState extends State<GeneralSettingScreen> {
  static const Color pinkColor = Color(0xFFFF2F68);

  double _zoomLevel = 17;

  final Map<String, String> _values = {
    'Vehicle Icon Size': 'Medium',
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
    'Fuel Reading': 'Sensor',
    'History Route Color': 'Default Color',
    'App Color': 'Default Color',
    'Relay Password': 'Set Password',
  };

  static const List<_GeneralSettingData> _dropdownSettings = [
    _GeneralSettingData(
      title: 'Vehicle Icon Size',
      dialogTitle: 'Choose Vehicle icon',
      icon: Icons.directions_car_outlined,
      iconColor: Color(0xFF4D91C5),
      image: 'assets/caricon.png',
      options: ['Small', 'Medium', 'Large'],
    ),
    _GeneralSettingData(
      title: 'Time Format',
      icon: Icons.timer_outlined,
      iconColor: Color(0xFFE53935),
      options: ['12 Hours', '24 Hours'],
    ),
    _GeneralSettingData(
      title: 'Speedo Meter',
      icon: Icons.speed_outlined,
      iconColor: Color(0xFF4D91C5),
      options: ['Analog', 'Digital'],
    ),
    _GeneralSettingData(
      title: 'Default Page',
      icon: Icons.layers_outlined,
      iconColor: Color(0xFF4D91C5),
      options: ['Live Page', 'Map Page', 'Reports Page'],
    ),
    _GeneralSettingData(
      title: 'Map Type',
      icon: Icons.map_outlined,
      iconColor: Color(0xFF4D91C5),
      image: 'assets/map_fold.png',
      options: ['Normal', 'Satellite', 'Hybrid'],
    ),
    _GeneralSettingData(
      title: 'Fuel Unit',
      icon: Icons.local_gas_station_outlined,
      iconColor: Color(0xFFE53935),
      options: ['Liter', 'Gallon'],
    ),
    _GeneralSettingData(
      title: 'Language',
      icon: Icons.translate_outlined,
      iconColor: Color(0xFF4D91C5),
      options: ['English', 'Hindi', 'Urdu'],
    ),
    _GeneralSettingData(
      title: 'Speed',
      icon: Icons.speed_outlined,
      iconColor: Color(0xFF4D91C5),
      options: ['kmh', 'mph'],
    ),
    _GeneralSettingData(
      title: 'Distance',
      icon: Icons.route_outlined,
      iconColor: Color(0xFF4D91C5),
      options: ['km', 'mile'],
    ),
    _GeneralSettingData(
      title: 'Area',
      icon: Icons.map_outlined,
      iconColor: Color(0xFF4D91C5),
      options: ['Hectare', 'Acre'],
    ),
    _GeneralSettingData(
      title: 'Voice Command',
      icon: Icons.mic_outlined,
      iconColor: Color(0xFFFFC107),
      options: ['ON', 'OFF'],
    ),
    _GeneralSettingData(
      title: 'Currency',
      icon: Icons.currency_exchange_outlined,
      iconColor: Color(0xFF4D91C5),
      options: ['INR', 'USD', 'PKR'],
    ),
    _GeneralSettingData(
      title: 'Live Page Trail',
      icon: Icons.timeline_outlined,
      iconColor: Color(0xFF4D91C5),
      options: ['ON', 'OFF'],
    ),
    _GeneralSettingData(
      title: 'Show History on Live',
      icon: Icons.history_outlined,
      iconColor: Color(0xFFE53935),
      options: ['ON', 'OFF'],
    ),
    _GeneralSettingData(
      title: 'Filter History Fluctuation',
      icon: Icons.filter_alt_outlined,
      iconColor: Color(0xFF4D91C5),
      options: ['ON', 'OFF'],
    ),
    _GeneralSettingData(
      title: 'Farm Calculation',
      icon: Icons.grid_on_outlined,
      iconColor: Color(0xFF4CAF50),
      options: ['ON', 'OFF'],
    ),
    _GeneralSettingData(
      title: 'Notification',
      icon: Icons.notifications_active_outlined,
      iconColor: Color(0xFFFFC107),
      options: ['ON', 'OFF'],
    ),
    _GeneralSettingData(
      title: 'Fuel Reading',
      icon: Icons.local_gas_station_outlined,
      iconColor: Color(0xFFFF9800),
      options: ['Sensor', 'Manual'],
    ),
    _GeneralSettingData(
      title: 'History Route Color',
      icon: Icons.route_outlined,
      iconColor: Color(0xFFE53935),
      options: ['Default Color', 'Red', 'Blue', 'Green'],
    ),
    _GeneralSettingData(
      title: 'App Color',
      icon: Icons.palette_outlined,
      iconColor: pinkColor,
      options: ['Default Color', 'Pink', 'Blue', 'Green'],
    ),
    _GeneralSettingData(
      title: 'Relay Password',
      icon: Icons.lock_outline,
      iconColor: Color(0xFF4D91C5),
      options: ['Set Password', 'Change Password', 'Remove Password'],
    ),
  ];

  void _showThemeDialog(ThemeProvider themeProvider) {
    AppThemeType tempSelected = themeProvider.themeType;

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: Theme.of(context).cardColor,
              insetPadding: const EdgeInsets.symmetric(horizontal: 24),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Choose Theme',
                      style: TextStyle(
                        color: context.appTextColor,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 16),
                    for (final AppThemeType type in AppThemeType.values)
                      InkWell(
                        onTap: () {
                          setDialogState(() {
                            tempSelected = type;
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Row(
                            children: [
                              Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: tempSelected == type
                                        ? pinkColor
                                        : context.appBorder,
                                    width: 1.5,
                                  ),
                                  color: tempSelected == type
                                      ? pinkColor
                                      : Colors.transparent,
                                ),
                                child: tempSelected == type
                                    ? const Icon(
                                        Icons.check,
                                        size: 14,
                                        color: Colors.white,
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 14),
                              Icon(
                                _themeIcon(type),
                                size: 20,
                                color: _themeIconColor(type),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _themeLabel(type),
                                  style: TextStyle(
                                    color: context.appTextColor,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _DialogActionButton(
                            label: 'CANCEL',
                            filled: false,
                            onTap: () => Navigator.pop(dialogContext),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _DialogActionButton(
                            label: 'OK',
                            filled: true,
                            onTap: () {
                              themeProvider.setTheme(tempSelected);
                              Navigator.pop(dialogContext);
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _themeLabel(AppThemeType type) {
    switch (type) {
      case AppThemeType.light:
        return 'Light Theme';
      case AppThemeType.dark:
        return 'Dark Theme';
      case AppThemeType.screenHack:
        return 'Screen Hack Theme';
    }
  }

  IconData _themeIcon(AppThemeType type) {
    switch (type) {
      case AppThemeType.light:
        return Icons.wb_sunny_outlined;
      case AppThemeType.dark:
        return Icons.dark_mode_outlined;
      case AppThemeType.screenHack:
        return Icons.bug_report_outlined;
    }
  }

  Color _themeIconColor(AppThemeType type) {
    switch (type) {
      case AppThemeType.light:
        return const Color(0xFFFFB300);
      case AppThemeType.dark:
        return const Color(0xFF4D91C5);
      case AppThemeType.screenHack:
        return const Color(0xFFFF3355);
    }
  }

  void _showOptionDialog(_GeneralSettingData setting) {
    String tempSelected = _values[setting.title] ?? setting.options.first;

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: Theme.of(context).cardColor,
              insetPadding: const EdgeInsets.symmetric(horizontal: 24),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      setting.dialogTitle ?? setting.title,
                      style: TextStyle(
                        color: context.appTextColor,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 16),
                    for (final option in setting.options)
                      InkWell(
                        onTap: () {
                          setDialogState(() {
                            tempSelected = option;
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Row(
                            children: [
                              Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: tempSelected == option
                                        ? pinkColor
                                        : Colors.grey.shade500,
                                    width: 1.5,
                                  ),
                                  color: tempSelected == option
                                      ? pinkColor
                                      : Colors.transparent,
                                ),
                                child: tempSelected == option
                                    ? const Icon(
                                        Icons.check,
                                        size: 14,
                                        color: Colors.white,
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Text(
                                  option,
                                  style: TextStyle(
                                    color: context.appTextColor,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _DialogActionButton(
                            label: 'CANCEL',
                            filled: false,
                            onTap: () => Navigator.pop(dialogContext),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _DialogActionButton(
                            label: 'OK',
                            filled: true,
                            onTap: () {
                              setState(() {
                                _values[setting.title] = tempSelected;
                              });
                              Navigator.pop(dialogContext);
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeProvider themeProvider = context.watch<ThemeProvider>();
    final Color textColor = context.appTextColor;
    final Color cardColor = context.appSurface;

    return Scaffold(
      backgroundColor: context.appBackground,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.only(left: 10, right: 10, top: 50, bottom: 30),
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.only(left: 25, right: 20, top: 22, bottom: 15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: const Icon(
                          Icons.arrow_back_ios_new,
                          color: pinkColor,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Settings',
                        style: TextStyle(
                          color: textColor,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _ThemeSettingRow(
                    themeType: themeProvider.themeType,
                    themeLabel: themeProvider.themeLabel,
                    textColor: textColor,
                    onTap: () => _showThemeDialog(themeProvider),
                  ),
                  for (final setting in _dropdownSettings)
                    _SettingDropdownRow(
                      setting: setting,
                      value: _values[setting.title] ?? setting.options.first,
                      textColor: textColor,
                      onTap: () => _showOptionDialog(setting),
                    ),
                  _ZoomLevelRow(
                    zoomLevel: _zoomLevel,
                    textColor: textColor,
                    onChanged: (value) {
                      setState(() => _zoomLevel = value);
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
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
  final AppThemeType themeType;
  final String themeLabel;
  final Color textColor;
  final VoidCallback onTap;

  const _ThemeSettingRow({
    required this.themeType,
    required this.themeLabel,
    required this.textColor,
    required this.onTap,
  });

  IconData get _icon {
    switch (themeType) {
      case AppThemeType.light:
        return Icons.wb_sunny_outlined;
      case AppThemeType.dark:
        return Icons.dark_mode_outlined;
      case AppThemeType.screenHack:
        return Icons.bug_report_outlined;
    }
  }

  Color get _iconColor {
    switch (themeType) {
      case AppThemeType.light:
        return const Color(0xFFFFB300);
      case AppThemeType.dark:
        return GeneralSettingScreenState.pinkColor;
      case AppThemeType.screenHack:
        return const Color(0xFFFF3355);
    }
  }

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
            children: [
              const Icon(Icons.brush_outlined, color: Color(0xFFE53935), size: 22),
              const SizedBox(width: 18),
              Expanded(
                child: Text(
                  'Theme',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              Text(
                themeLabel,
                style: TextStyle(
                  color: textColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                ),
              ),
              IconButton(
                onPressed: onTap,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                icon: Icon(
                  _icon,
                  color: _iconColor,
                  size: 24,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

typedef GeneralSettingScreenState = _GeneralSettingScreenState;

class _SettingDropdownRow extends StatelessWidget {
  final _GeneralSettingData setting;
  final String value;
  final Color textColor;
  final VoidCallback onTap;

  const _SettingDropdownRow({
    required this.setting,
    required this.value,
    required this.textColor,
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
            children: [
              SizedBox(
                width: 25,
                height: 25,
                child: setting.image != null
                    ? Image.asset(
                        setting.image!,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
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
                  children: [
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
                    const Icon(
                      Icons.arrow_drop_down,
                      color: GeneralSettingScreenState.pinkColor,
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
  final ValueChanged<double> onChanged;

  const _ZoomLevelRow({
    required this.zoomLevel,
    required this.textColor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: Row(
        children: [
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
              children: [
                Expanded(
                  child: Slider(
                    value: zoomLevel,
                    min: 1,
                    max: 20,
                    divisions: 19,
                    onChanged: onChanged,
                  ),
                ),
                SizedBox(
                  width: 24,
                  child: Text(
                    zoomLevel.toInt().toString(),
                    style: TextStyle(
                      color: textColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
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

class _DialogActionButton extends StatelessWidget {
  final String label;
  final bool filled;
  final VoidCallback onTap;

  const _DialogActionButton({
    required this.label,
    required this.filled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: filled ? GeneralSettingScreenState.pinkColor : Colors.transparent,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: filled
                ? null
                : Border.all(color: GeneralSettingScreenState.pinkColor),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: filled
                  ? Colors.white
                  : GeneralSettingScreenState.pinkColor,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
