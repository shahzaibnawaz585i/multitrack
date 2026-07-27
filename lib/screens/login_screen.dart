// import 'package:flutter/material.dart';
// import 'package:multitrack/dashboard_screen.dart';
// import 'package:multitrack/forget_screen.dart';
// import 'package:multitrack/screens/dashboard_screen.dart';
// import 'package:multitrack/screens/forget_screen.dart';
import 'package:flutter/material.dart';

import 'dashboard_screen.dart';
import 'forget_screen.dart';
import '../services/auth_service.dart';
import '../theme/app_theme_tokens.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _obscurePassword = true;
  bool isPasswordHidden = true;
  String selectedServer = "Server 1";
  TextEditingController userId = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  final List<String> servers = ["Server 1", "Server 2", "Server 3"];
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
            const SizedBox(height: 90),
            Padding(
              padding: const EdgeInsets.only(left: 40),
              child: Row(
                children: [
                  Container(
                    height: 75,
                    width: 75,
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
            const SizedBox(height: 50),
            Padding(
              padding: const EdgeInsets.all(14.0),
              child: Column(
                children: [
                  Container(
                    height: 300,
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
                      padding: const EdgeInsets.all(14.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(
                            'Login',
                            style: TextStyle(
                              fontFamily: 'normalbold.ttf',
                              fontSize: 25,
                              color: textColor,
                            ),
                          ),
                          Form(
                            key: _formKey,
                            child: TextFormField(
                              controller: userId,
                              style: TextStyle(color: textColor),
                              decoration: InputDecoration(
                                label: Text(
                                  'User ID',
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
                          ),
                          TextFormField(
                            obscureText: _obscurePassword,
                            style: TextStyle(color: textColor),
                            decoration: InputDecoration(
                              label: Text(
                                'Password',
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
                            value: selectedServer,
                            dropdownColor: context.containerColor,
                            style: TextStyle(color: textColor),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: context.containerColor,
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 16,
                              ),
                              enabledBorder: const UnderlineInputBorder(
                                borderSide: BorderSide(color: Colors.grey),
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
                                child: Text(server),
                              );
                            }).toList(),
                            onChanged: (String? value) {
                              if (value != null) {
                                setState(() {
                                  selectedServer = value;
                                });
                              }
                            },
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
                                'Forget Your Password?',
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
                        onPressed: () async {
                          if (_formKey.currentState!.validate()) {
                            final String userid = userId.text.trim();
                            if (userid == 'admin@gmail.com') {
                              await AuthService.setLoggedIn(true);
                              if (!context.mounted) {
                                return;
                              }
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute<void>(
                                  builder: (context) =>
                                      const DashboardScreen(),
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Invalid User Id'),
                                ),
                              );
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accentColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 40,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          'LOG IN',
                          style: TextStyle(fontFamily: 'normalbold.ttf'),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 195,
              width: double.infinity,
              child: Image.asset(
                'assets/loginscreenicons.jpeg',
                fit: BoxFit.cover,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
