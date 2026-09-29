import 'dart:async';

import 'package:flutter/material.dart';
import 'dashboard_screen.dart';
import '../theme/fast_page_transitions.dart';
import 'forget_screen.dart';
import '../l10n/app_l10n.dart';
import '../constants/api_config.dart';
import '../services/app_bootstrap_service.dart';
import '../services/auth_service.dart';
import '../services/fcm_service.dart';
import '../theme/app_theme_tokens.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _obscurePassword = true;
  bool _isLoading = false;
  final TextEditingController userId = TextEditingController();
  final TextEditingController password = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    userId.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final String userid = userId.text.trim();
    final String pass = password.text;
    if (userid.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('Please enter User ID'))),
      );
      return;
    }

    if (pass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('Please enter Password'))),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final result = await AuthService.login(
      userId: userid,
      password: pass,
      server: ApiConfig.appServerId,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _isLoading = false;
    });

    if (!result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr(result.message))),
      );
      return;
    }

    if (!mounted) {
      return;
    }

    Navigator.pushReplacement(
      context,
      FastMaterialPageRoute<void>(
        builder: (context) => const DashboardScreen(),
      ),
    );

    unawaited(AppBootstrapService.prefetchAfterLogin());
    unawaited(FcmService.registerStoredToken());
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color textColor = theme.colorScheme.onSurface;
    final Color accentColor = theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 70),
            Padding(
              padding: const EdgeInsets.only(left: 40),
              child: Row(
                children: [
                  Container(
                    height: 70,
                    width: 70,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Image.asset('assets/loginicon.png'),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'multiTrack',
                    style: TextStyle(
                      fontFamily: 'normalbold.ttf',
                      fontSize: 32,
                      color: accentColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 35),
            Padding(
              padding: const EdgeInsets.all(14.0),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    decoration: context.containerDecoration(
                      borderRadius: BorderRadius.circular(14),
                    ).copyWith(
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 2,
                          spreadRadius: 0.3,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(
                            context.tr('Login'),
                            style: TextStyle(
                              fontFamily: 'normalbold.ttf',
                              fontSize: 25,
                              color: textColor,
                            ),
                          ),
                          Form(
                            key: _formKey,
                            child: Column(
                              children: [
                                TextFormField(
                                  controller: userId,
                                  enabled: !_isLoading,
                                  textInputAction: TextInputAction.next,
                                  style: TextStyle(color: textColor),
                                  decoration: InputDecoration(
                                    label: Text(
                                      context.tr('User ID / Email'),
                                      style: TextStyle(color: textColor),
                                    ),
                                    enabledBorder: const UnderlineInputBorder(
                                      borderSide: BorderSide(
                                        color: Colors.grey,
                                        width: 1,
                                      ),
                                    ),
                                    focusedBorder: UnderlineInputBorder(
                                      borderRadius: const BorderRadius.only(
                                        bottomRight: Radius.circular(8),
                                        bottomLeft: Radius.circular(8),
                                      ),
                                      borderSide: BorderSide(
                                        color: accentColor,
                                        width: 3,
                                      ),
                                    ),
                                  ),
                                ),
                                TextFormField(
                                  controller: password,
                                  enabled: !_isLoading,
                                  obscureText: _obscurePassword,
                                  textInputAction: TextInputAction.done,
                                  onFieldSubmitted: (_) {
                                    if (!_isLoading) {
                                      _login();
                                    }
                                  },
                                  style: TextStyle(color: textColor),
                                  decoration: InputDecoration(
                                    label: Text(
                                      context.tr('Password'),
                                      style: TextStyle(color: textColor),
                                    ),
                                    suffixIcon: IconButton(
                                      onPressed: () {
                                        setState(() {
                                          _obscurePassword = !_obscurePassword;
                                        });
                                      },
                                      icon: Icon(
                                        _obscurePassword
                                            ? Icons.visibility_off
                                            : Icons.visibility,
                                        color: textColor,
                                      ),
                                    ),
                                    enabledBorder: const UnderlineInputBorder(
                                      borderSide: BorderSide(
                                        color: Colors.grey,
                                        width: 1,
                                      ),
                                    ),
                                    focusedBorder: UnderlineInputBorder(
                                      borderRadius: const BorderRadius.only(
                                        bottomLeft: Radius.circular(8),
                                        bottomRight: Radius.circular(8),
                                      ),
                                      borderSide: BorderSide(
                                        color: accentColor,
                                        width: 3,
                                      ),
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(top: 12),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.dns_outlined,
                                        size: 20,
                                        color: accentColor,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          ApiConfig.defaultBaseUrl,
                                          style: TextStyle(
                                            color: textColor.withValues(
                                              alpha: 0.85,
                                            ),
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute<void>(
                                    builder: (context) => const ForgetScreen(),
                                  ),
                                );
                              },
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                              ),
                              child: Text(
                                context.tr('Forget Your Password?'),
                                style: TextStyle(
                                  fontSize: 14,
                                  fontFamily: 'normalbold.ttf',
                                  color: textColor,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  Align(
                    alignment: Alignment.center,
                    child: SizedBox(
                      width: 150,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accentColor,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: accentColor,
                          disabledForegroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 40,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.4,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                context.tr('LOG IN'),
                                style: const TextStyle(
                                  fontFamily: 'normalbold.ttf',
                                ),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 160,
              width: double.infinity,
              child: Image.asset(
                'assets/login_screen_image.png',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
