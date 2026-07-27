import 'package:flutter/material.dart';

import '../../constants/app_theme.dart';
import 'expense_screen.dart';
import 'general_setting_screen.dart';

class AppSettingScreen extends StatelessWidget {
  const AppSettingScreen({super.key});

  static const Color pinkColor = AppThemeContext.pinkColor;

  static const List<_AppSettingItemData> _settings = [
    _AppSettingItemData(
      title: 'General Settings',
      image: 'assets/app_setting.png',
      icon: Icons.manage_accounts_outlined,
      iconColor: Color(0xFF4D91C5),
    ),
    _AppSettingItemData(
      title: 'Change Password',
      image: 'assets/lock.png',
      icon: Icons.lock_outline,
      iconColor: Color(0xFF4D91C5),
    ),
    _AppSettingItemData(
      title: 'Configure Alerts',
      icon: Icons.warning_amber_rounded,
      iconColor: Color(0xFFFF9800),
    ),
    _AppSettingItemData(
      title: 'Expense',
      icon: Icons.payments_outlined,
      iconColor: Color(0xFFFFB300),
    ),
    _AppSettingItemData(
      title: 'Drivers',
      image: 'assets/caricon.png',
      icon: Icons.drive_eta_outlined,
      iconColor: Color(0xFF4D91C5),
    ),
    _AppSettingItemData(
      title: 'Reminders',
      icon: Icons.notifications_active_outlined,
      iconColor: Color(0xFFFFC107),
    ),
    _AppSettingItemData(
      title: 'Groups',
      icon: Icons.groups_outlined,
      iconColor: Color(0xFF4D91C5),
    ),
    _AppSettingItemData(
      title: 'Geofences',
      image: 'assets/geofences_report.png',
      icon: Icons.location_on_outlined,
      iconColor: Color(0xFF4CAF50),
    ),
    _AppSettingItemData(
      title: 'Share app',
      icon: Icons.share_outlined,
      iconColor: Color(0xFF4D91C5),
    ),
  ];

  @override
  Widget build(BuildContext context) {
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
              color: context.appSurface,
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
                        'App Settings',
                        style: TextStyle(
                          color: context.appTextColor,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  for (int i = 0; i < _settings.length; i++)
                    AppSettingItem(
                      title: _settings[i].title,
                      image: _settings[i].image,
                      icon: _settings[i].icon,
                      iconColor: _settings[i].iconColor,
                      onTap: () => _handleItemTap(context, _settings[i].title),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _handleItemTap(BuildContext context, String title) {
    switch (title) {
      case 'General Settings':
        Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (context) => const GeneralSettingScreen(),
          ),
        );
        return;
      case 'Change Password':
        _showChangePasswordDialog(context);
        return;
      case 'Expense':
        Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (context) => const ExpenseScreen(),
          ),
        );
        return;
      default:
        debugPrint('$title Clicked');
    }
  }

  void _showChangePasswordDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black54,
      builder: (dialogContext) => const _ChangePasswordDialog(),
    );
  }
}

class _AppSettingItemData {
  final String title;
  final String? image;
  final IconData icon;
  final Color iconColor;

  const _AppSettingItemData({
    required this.title,
    this.image,
    required this.icon,
    required this.iconColor,
  });
}

class AppSettingItem extends StatelessWidget {
  final String title;
  final String? image;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;

  const AppSettingItem({
    super.key,
    required this.title,
    this.image,
    required this.icon,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          height: 50,
          child: Row(
            children: [
              SizedBox(
                width: 25,
                height: 25,
                child: image != null
                    ? Image.asset(
                        image!,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(icon, color: iconColor, size: 22);
                        },
                      )
                    : Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: context.appTextColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const Icon(
                Icons.arrow_right,
                color: AppSettingScreen.pinkColor,
                size: 28,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChangePasswordDialog extends StatefulWidget {
  const _ChangePasswordDialog();

  @override
  State<_ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<_ChangePasswordDialog> {
  static const Color pinkColor = AppSettingScreen.pinkColor;

  final TextEditingController _oldPasswordController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _hideOldPassword = true;
  bool _hidePassword = true;
  bool _hideConfirmPassword = true;

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  InputDecoration _fieldDecoration({
    required String label,
    required bool obscure,
    required VoidCallback onToggleVisibility,
  }) {
    return InputDecoration(
      labelText: label,
      floatingLabelBehavior: FloatingLabelBehavior.never,
      filled: true,
      fillColor: context.appFieldFill,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      suffixIcon: IconButton(
        onPressed: onToggleVisibility,
        icon: Icon(
          obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
          color: context.appSecondaryText,
          size: 20,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: pinkColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(
          color: context.isDarkTheme ? Colors.white : const Color(0xFF333333),
          width: 1.2,
        ),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: pinkColor),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: context.appSurface,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Change Password',
              style: TextStyle(
                color: context.appTextColor,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _oldPasswordController,
              obscureText: _hideOldPassword,
              decoration: _fieldDecoration(
                label: 'Old Password*',
                obscure: _hideOldPassword,
                onToggleVisibility: () {
                  setState(() => _hideOldPassword = !_hideOldPassword);
                },
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passwordController,
              obscureText: _hidePassword,
              decoration: _fieldDecoration(
                label: 'Password',
                obscure: _hidePassword,
                onToggleVisibility: () {
                  setState(() => _hidePassword = !_hidePassword);
                },
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _confirmPasswordController,
              obscureText: _hideConfirmPassword,
              decoration: _fieldDecoration(
                label: 'Confirm Password*',
                obscure: _hideConfirmPassword,
                onToggleVisibility: () {
                  setState(() => _hideConfirmPassword = !_hideConfirmPassword);
                },
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: Material(
                color: pinkColor,
                borderRadius: BorderRadius.circular(8),
                child: InkWell(
                  onTap: () => Navigator.pop(context),
                  borderRadius: BorderRadius.circular(8),
                  child: const Center(
                    child: Text(
                      'Apply',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
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
