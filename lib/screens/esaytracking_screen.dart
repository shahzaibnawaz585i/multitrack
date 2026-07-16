// import 'package:flutter/material.dart';
// import 'package:multitrack/screens/vehicle_screen.dart';
// import 'package:multitrack/vehicle_screen.dart';
import 'package:flutter/material.dart';

import 'vehicle_screen.dart';

class EsaytrackingScreen extends StatefulWidget {
  const EsaytrackingScreen({super.key});

  @override
  State<EsaytrackingScreen> createState() => _EsaytrackingScreenState();
}

class _EsaytrackingScreenState extends State<EsaytrackingScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(height: 23),
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 295),
                  child: TextButton(
                    onPressed: () {},
                    child: Text("Skip", style: TextStyle(color: Colors.black)),
                  ),
                ),
              ],
            ),
            SizedBox(height: 60),
            Column(
              children: [Container(child: Image.asset('assets/icon.jpeg'))],
            ),
            SizedBox(height: 60),
            Text(
              'Save Your Time',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
            SizedBox(height: 20),
            Text(
              'save your time by optimization of your operations',
              style: TextStyle(fontSize: 13),
            ),

            SizedBox(height: 60),
            Container(
              padding: EdgeInsets.all(9), // gap between border & inner circle
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Color(0xFFFF3B6F), // outer ring color
                  width: 1.5,
                ),
              ),
              child: Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: Color(0xFFFF3B6F),
                  shape: BoxShape.circle,
                ),
                // child: Icon(
                //   Icons.arrow_forward, // 👈 same icon
                //   color: Colors.white,
                //   size: 30,
                // ),
                child: IconButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => VehicleScreen()),
                    );
                  },
                  icon: Icon(
                    Icons.arrow_forward, // 👈 same icon
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
