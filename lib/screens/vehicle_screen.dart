import 'package:flutter/material.dart';

import 'login_screen.dart';

class VehicleScreen extends StatefulWidget {
  const VehicleScreen({super.key});

  @override
  State<VehicleScreen> createState() => _VehicleScreenState();
}

class _VehicleScreenState extends State<VehicleScreen> {
  void _goToLogin() {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (BuildContext context) => const LoginScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color textColor = theme.colorScheme.onSurface;
    final Color accentColor = theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: <Widget>[
              const SizedBox(height: 23),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _goToLogin,
                  child: Text('Skip', style: TextStyle(color: textColor)),
                ),
              ),
              const SizedBox(height: 60),
              Image.asset(
                'assets/icons.jpeg',
                errorBuilder: (
                  BuildContext context,
                  Object error,
                  StackTrace? stackTrace,
                ) {
                  return Icon(
                    Icons.directions_car,
                    size: 120,
                    color: accentColor,
                  );
                },
              ),
              const SizedBox(height: 60),
              Text(
                'Vehicle Maintenance',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Get your daily mileage and other reports on your finger',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: textColor),
              ),
              Text(
                'tips',
                style: TextStyle(fontSize: 13, color: textColor),
              ),
              const SizedBox(height: 60),
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: accentColor,
                    width: 1.5,
                  ),
                ),
                child: Material(
                  color: accentColor,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: _goToLogin,
                    child: const SizedBox(
                      width: 70,
                      height: 70,
                      child: Icon(
                        Icons.arrow_forward,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
