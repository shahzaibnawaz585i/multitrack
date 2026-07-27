import 'package:flutter/material.dart';

import 'login_screen.dart';

class ForgetScreen extends StatelessWidget {
  const ForgetScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color accentColor = theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Column(
        children: [
          const SizedBox(height: 123),
          SizedBox(
            height: 400,
            width: double.infinity,
            child: Image.asset('assets/forgeticon.jpeg'),
          ),
          const SizedBox(height: 65),
          SizedBox(
            width: 260,
            height: 50,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (context) => const LoginScreen(),
                  ),
                );
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
                'Go Back',
                style: TextStyle(fontFamily: 'normalbold.ttf'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
