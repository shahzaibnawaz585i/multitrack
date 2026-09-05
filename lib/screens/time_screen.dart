import 'package:flutter/material.dart';

import '../l10n/app_l10n.dart';
import 'esaytracking_screen.dart';
import 'login_screen.dart';

class TimeScreen extends StatefulWidget {
  const TimeScreen({super.key});

  @override
  State<TimeScreen> createState() => _TimeScreenState();
}

class _TimeScreenState extends State<TimeScreen> {
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
            const SizedBox(height: 23),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (context) => const LoginScreen(),
                    ),
                  );
                },
                child: Text(
                  context.tr('Skip'),
                  style: TextStyle(color: textColor),
                ),
              ),
            ),
            const SizedBox(height: 60),
            Image.asset('assets/time_screen.png'),
            const SizedBox(height: 60),
            Text(
              context.tr('Esay Tracking'),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: textColor,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              context.tr('Tracking any device with user friendly software'),
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
              child: Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: accentColor,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (context) => EsaytrackingScreen(),
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
    );
  }
}
