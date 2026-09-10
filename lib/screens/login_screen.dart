import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'dashboard_screen.dart';
import 'forget_screen.dart';
import '../l10n/app_l10n.dart';
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
  String selectedServer = "Server 1 (Live)";
  final TextEditingController userId = TextEditingController();
  final TextEditingController password = TextEditingController();
  final TextEditingController customServer =
      TextEditingController(text: 'https://gps.m-track.net.pk');
  final _formKey = GlobalKey<FormState>();

  final List<String> servers = [
    "Server 1 (Live)",
    "Server 2",
    "Nostrum Track",
    "Fleet Wox",
    "Fleet Wo",
    "Server 3",
    "Custom Server URL",
  ];

  @override
  void initState() {
    super.initState();
    _loadSavedServer();
  }

  Future<void> _loadSavedServer() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    if (!mounted) return;

    final String? savedServer = prefs.getString('logged_in_server');
    final String? savedCustomUrl = prefs.getString('custom_server_url');

    if (savedCustomUrl != null && savedCustomUrl.isNotEmpty) {
      customServer.text = savedCustomUrl;
    }

    if (savedServer != null && savedServer.isNotEmpty) {
      if (servers.contains(savedServer)) {
        if (!mounted) return;
        setState(() {
          selectedServer = savedServer;
        });
      } else if (savedServer.startsWith('http')) {
        if (!mounted) return;
        setState(() {
          selectedServer = 'Custom Server URL';
          customServer.text = savedServer;
        });
      }
    }
  }

  @override
  void dispose() {
    userId.dispose();
    password.dispose();
    customServer.dispose();
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

    String effectiveServer = selectedServer;
    if (selectedServer == 'Custom Server URL') {
      String url = customServer.text.trim();
      if (url.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter Server URL')),
        );
        return;
      }
      if (!url.startsWith('http://') && !url.startsWith('https://')) {
        url = 'https://$url';
      }
      effectiveServer = url;
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('custom_server_url', url);
    } else if (selectedServer == 'Server 1 (Live)') {
      effectiveServer = 'Server 1';
    }

    setState(() {
      _isLoading = true;
    });

    final result = await AuthService.login(
      userId: userid,
      password: pass,
      server: effectiveServer,
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

    await AppBootstrapService.prefetchAfterLogin();
    await FcmService.registerStoredToken();

    if (!mounted) {
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute<void>(
        builder: (context) => const DashboardScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color textColor = theme.colorScheme.onSurface;
    final Color accentColor = theme.colorScheme.primary;

    final bool isCustomServer = selectedServer == 'Custom Server URL';

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
                                DropdownButtonFormField<String>(
                                  isExpanded: true,
                                  initialValue: selectedServer,
                                  dropdownColor: context.containerColor,
                                  style: TextStyle(color: textColor),
                                  onChanged: _isLoading
                                      ? null
                                      : (String? value) {
                                          if (value != null) {
                                            setState(() {
                                              selectedServer = value;
                                            });
                                          }
                                        },
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: context.containerColor,
                                    contentPadding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    enabledBorder: const UnderlineInputBorder(
                                      borderSide:
                                          BorderSide(color: Colors.grey),
                                    ),
                                    focusedBorder: UnderlineInputBorder(
                                      borderSide: BorderSide(
                                        color: accentColor,
                                        width: 3,
                                      ),
                                      borderRadius: const BorderRadius.only(
                                        bottomLeft: Radius.circular(8),
                                        bottomRight: Radius.circular(8),
                                      ),
                                    ),
                                  ),
                                  icon: Icon(
                                    Icons.arrow_drop_down,
                                    color: accentColor,
                                  ),
                                  items: servers.map((String server) {
                                    return DropdownMenuItem<String>(
                                      value: server,
                                      child: Text(context.tr(server)),
                                    );
                                  }).toList(),
                                ),
                                if (isCustomServer) ...[
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    controller: customServer,
                                    enabled: !_isLoading,
                                    keyboardType: TextInputType.url,
                                    textInputAction: TextInputAction.done,
                                    style: TextStyle(
                                      color: textColor,
                                      fontSize: 13,
                                    ),
                                    decoration: InputDecoration(
                                      labelText: 'Server Base URL',
                                      hintText: 'https://gps.yourdomain.com',
                                      hintStyle: TextStyle(
                                        color: Colors.grey.shade500,
                                        fontSize: 12,
                                      ),
                                      prefixIcon: Icon(
                                        Icons.link,
                                        size: 20,
                                        color: accentColor,
                                      ),
                                      enabledBorder:
                                          const UnderlineInputBorder(
                                        borderSide: BorderSide(
                                          color: Colors.grey,
                                          width: 1,
                                        ),
                                      ),
                                      focusedBorder: UnderlineInputBorder(
                                        borderSide: BorderSide(
                                          color: accentColor,
                                          width: 2,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
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
