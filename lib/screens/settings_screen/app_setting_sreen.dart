import 'package:flutter/material.dart';

import 'expense_screen.dart';
import 'general_setting_screen.dart';
import '../../theme/app_theme_tokens.dart';

class AppSettingScreen extends StatelessWidget {
  const AppSettingScreen({super.key});

  static const Color _backgroundColor = Color(0xFFF7F7F7);
  static const Color _textColor = Color(0xFF292B32);
  static const Color _pinkColor = Color(0xFFFF2F68);
  static const Color _fieldFill = Color(0xFFF2F2F2);

  static const List<_AppSettingItemData> _settings = <_AppSettingItemData>[
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
      image: 'assets/radio.png',
      icon: Icons.warning_amber_rounded,
      iconColor: Color(0xFFFF9800),
    ),
    _AppSettingItemData(
      title: 'Expense',
      image: 'assets/daily_report.png',
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
      image: 'assets/summary_report.png',
      icon: Icons.notifications_active_outlined,
      iconColor: Color(0xFFFFC107),
    ),
    _AppSettingItemData(
      title: 'Groups',
      image: 'assets/icons.jpeg',
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
      image: 'assets/loginicon.png',
      icon: Icons.share_outlined,
      iconColor: Color(0xFF4D91C5),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color backgroundColor = theme.scaffoldBackgroundColor;
    final Color textColor = theme.colorScheme.onSurface;
    final Color pinkColor = theme.colorScheme.primary;
    final Color cardColor = theme.cardColor;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: cardColor,
        surfaceTintColor: cardColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(
            Icons.arrow_back,
            color: textColor,
            size: 24,
          ),
        ),
        title: Text(
          'App Settings',
          style: TextStyle(
            color: textColor,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(15, 40, 15, 24),
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
              children: [
                for (int i = 0; i < _settings.length; i++)
                  AppSettingMenuItem(
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$title coming soon')),
        );
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

class AppSettingMenuItem extends StatelessWidget {
  final String title;
  final String? image;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;

  const AppSettingMenuItem({
    super.key,
    required this.title,
    this.image,
    required this.icon,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color textColor = context.textColor;
    final Color accentColor = Theme.of(context).colorScheme.primary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          height: 54,
          child: Row(
            children: [
              SizedBox(
                width: 40,
                height: 40,
                child: image != null
                    ? Image.asset(
                        image!,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(icon, color: iconColor, size: 28);
                        },
                      )
                    : Icon(icon, color: iconColor, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_right,
                color: accentColor,
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

  InputDecoration _fieldDecoration(
    BuildContext context, {
    required String label,
    required bool obscure,
    required VoidCallback onToggleVisibility,
  }) {
    final Color accentColor = Theme.of(context).colorScheme.primary;
    final Color fillColor = context.containerColor;

    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: context.mutedTextColor),
      floatingLabelBehavior: FloatingLabelBehavior.never,
      filled: true,
      fillColor: fillColor,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      suffixIcon: IconButton(
        onPressed: onToggleVisibility,
        icon: Icon(
          obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
          color: context.mutedTextColor,
          size: 20,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: accentColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: context.textColor, width: 1.2),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: accentColor),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color textColor = context.textColor;
    final Color accentColor = Theme.of(context).colorScheme.primary;

    return Dialog(
      backgroundColor: context.containerColor,
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
                color: textColor,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _oldPasswordController,
              obscureText: _hideOldPassword,
              style: TextStyle(color: textColor),
              decoration: _fieldDecoration(
                context,
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
              style: TextStyle(color: textColor),
              decoration: _fieldDecoration(
                context,
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
              style: TextStyle(color: textColor),
              decoration: _fieldDecoration(
                context,
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
                color: accentColor,
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
