import 'package:flutter/material.dart';

import '../constants/app_theme.dart';
import 'vehicle_screen.dart';

class EsaytrackingScreen extends StatefulWidget {
  const EsaytrackingScreen({super.key});

  @override
  State<EsaytrackingScreen> createState() => _EsaytrackingScreenState();
}

class _EsaytrackingScreenState extends State<EsaytrackingScreen> {
  static const Color _accentColor = Color(0xFFFF3B6F);

  @override
  Widget build(BuildContext context) {
    return PreLoginThemeScope(
      builder: (lightContext) => Scaffold(
        backgroundColor: lightContext.appBackground,
        body: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 23),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {},
                  child: Text(
                    'Skip',
                    style: TextStyle(color: lightContext.appTextColor),
                  ),
                ),
              ),
              const SizedBox(height: 60),
              Image.asset('assets/icon.jpeg'),
              const SizedBox(height: 60),
              Text(
                'Save Your Time',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: lightContext.appTextColor,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'save your time by optimization of your operations',
                style: TextStyle(
                  fontSize: 13,
                  color: lightContext.appSecondaryText,
                ),
              ),
              const SizedBox(height: 60),
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _accentColor,
                    width: 1.5,
                  ),
                ),
                child: Container(
                  width: 70,
                  height: 70,
                  decoration: const BoxDecoration(
                    color: _accentColor,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (context) => const VehicleScreen(),
                        ),
                      );
                    },
                    icon: const Icon(
                      Icons.arrow_forward,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
