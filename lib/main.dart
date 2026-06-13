import 'package:flutter/material.dart';
import 'package:multitrack/login_screen.dart';
import 'package:multitrack/time_screen.dart';

void main() {
  runApp(const MyApp());
}
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        debugShowCheckedModeBanner: false,
      home:
      TimeScreen()
    );
  }
}
