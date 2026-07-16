// import 'package:flutter/material.dart';
// import 'package:multitrack/login_screen.dart';
// import 'package:multitrack/screens/login_screen.dart';
import 'package:flutter/material.dart';

import 'login_screen.dart';

class ForgetScreen extends StatelessWidget {
  const ForgetScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Column(
        children: [
          SizedBox(height: 123),
          Container(
            height: 400,
            width: double.infinity,
            child: Image.asset('assets/forgeticon.jpeg'),
          ),
          SizedBox(height: 65),
          SizedBox(
            width: 260,
            height: 50,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => LoginScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFF43A6B), // button color
                foregroundColor: Colors.white, // text color
                padding: EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                "Go Back",
                style: TextStyle(fontFamily: 'normalbold.ttf'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
