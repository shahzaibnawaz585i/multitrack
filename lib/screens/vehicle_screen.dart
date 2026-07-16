import 'package:flutter/material.dart';
import 'package:multitrack/screens/login_screen.dart';

class VehicleScreen extends StatefulWidget {
  const VehicleScreen({super.key});

  @override
  State<VehicleScreen> createState() => _VehicleScreenState();
}

class _VehicleScreenState extends State<VehicleScreen> {
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
              children: [Container(child: Image.asset('assets/icons.jpeg'))],
            ),
            SizedBox(height: 60),
            Text(
              'Vehicle Maintenance',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
            SizedBox(height: 20),
            Text(
              'Get your daily mileageand other reports on your finger',
              style: TextStyle(fontSize: 13),
            ),
            Text('tips', style: TextStyle(fontSize: 13)),
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
                      MaterialPageRoute(builder: (context) => LoginScreen()),
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
