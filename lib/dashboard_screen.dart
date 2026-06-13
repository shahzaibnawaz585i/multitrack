import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:multitrack/list_screen.dart';
import 'package:multitrack/map_screen.dart';

// اگر میپ اسکرین الگ فائل میں ہے تو اسے امپورٹ کریں:
// import 'map_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int selectedIndex = 0;

  // اسکرینز کی لسٹ - آپ کا ڈیزائن انڈیکس 0 پر ہے
  final List<Widget> _screens = [
    const MainDashboardContent(),
    const MapScreen(),
    const ListScreen(),
    const Center(child: Text("Profile Screen")),
    const Center(child: Text("Settings Screen")),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: _screens[selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [BoxShadow(blurRadius: 15, color: Colors.transparent.withOpacity(0.1))],
        ),
        child: CurvedNavigationBar(
          index: selectedIndex,
          height: 65,
          backgroundColor: Colors.transparent!,
          color: Colors.white,
          buttonBackgroundColor: Colors.white,
          animationDuration: const Duration(milliseconds: 300),
          items: [
            _navItem(Icons.dashboard, 0),
            _navItem(Icons.location_on_rounded, 1),
            _navItem(Icons.local_shipping, 2),
            _navItem(Icons.person, 3),
            _navItem(Icons.settings, 4),
          ],
          onTap: (index) {
            setState(() {
              selectedIndex = index;
            });
          },
        ),
      ),
    );
  }

  Widget _navItem(IconData icon, int index) {
    bool isSelected = selectedIndex == index;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isSelected ? Colors.black : Colors.transparent,
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 26, color: const Color(0xFFF43A6B)),
    );
  }
}

// 🔥 یہ آپ کا وہی ڈیزائن ہے جو آپ نے دیا تھا، بغیر کسی تبدیلی کے
class MainDashboardContent extends StatelessWidget {
  const MainDashboardContent({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            /// 🔝 HEADER
            Padding(
              padding: const EdgeInsets.all(9),
              child: Row(
                children: [
                  Image.asset('assets/loginicon.png', height: 40, width: 40, errorBuilder: (c,e,s) => Icon(Icons.apps)),
                  const SizedBox(width: 8),
                  const Text('multiTrack', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'normalbold.ttf', color: Color(0xFFF43A6B))),
                  const Spacer(),
                  Image.asset('assets/penicons.png', height: 50, width: 50, errorBuilder: (c,e,s) => Icon(Icons.edit)),
                  const SizedBox(width: 8),
                  const Icon(Icons.refresh_outlined, size: 27),
                ],
              ),
            ),
            const SizedBox(height: 10),
            /// 🔹 DASHBOARD TITLE
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Text('Dashboard', style: TextStyle(fontSize: 20, fontFamily: 'normalbold.ttf', fontWeight: FontWeight.w600)),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(border: Border.all(color: Colors.black), borderRadius: BorderRadius.circular(8)),
                    child: Row(
                      children: const [
                        Text('RJ14UG839', style: TextStyle(fontSize: 13)),
                        Icon(Icons.arrow_drop_down, color: Color(0xFFF43A6B), size: 18),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16),
              child: const Text('Fleet Status', style: TextStyle(fontSize: 16, fontFamily: 'normalbold.ttf', fontWeight: FontWeight.w600)),
            ),
            /// 🔥 FLEET CARD
            Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: 160, width: 120,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 30),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            PieChart(PieChartData(startDegreeOffset: -90, sectionsSpace: 0, centerSpaceRadius: 38, sections: [
                              PieChartSectionData(value: 72, color: Colors.red, radius: 30, showTitle: false),
                              PieChartSectionData(value: 34, color: Colors.blue, radius: 30, showTitle: false),
                              PieChartSectionData(value: 10, color: Colors.green, radius: 30, showTitle: false),
                              PieChartSectionData(value: 8, color: Colors.orange, radius: 30, showTitle: false),
                            ])),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Text("124", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, fontFamily: 'normalbold.ttf')),
                                Text("Objects", style: TextStyle(color: Colors.grey, fontSize: 13, fontFamily: 'normalbold.ttf')),
                              ],
                            )
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 40),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          StatusRow("Running", 10, Colors.green),
                          StatusRow("Idle", 8, Colors.orange),
                          StatusRow("Stopped", 72, Colors.red),
                          StatusRow("Expired", 0, Colors.pink),
                          StatusRow("InActive", 34, Colors.blue),
                          StatusRow("No Data", 0, Colors.grey),
                        ],
                      ),
                    )
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 16, left: 16),
              child: Text('Engine Hours', style: TextStyle(fontFamily: 'normalbold.ttf', fontSize: 16)),
            ),
            /// 📉 LINE CHART
            Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                padding: const EdgeInsets.all(16),
                height: 220,
                width: 350,
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                child: LineChart(
                  LineChartData(
                    borderData: FlBorderData(show: false),
                    gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: 4),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, interval: 4, reservedSize: 30)),
                      bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (value, meta) {
                        List<String> dates = ["21/6", "22/6", "23/6", "24/6", "25/6", "26/6", "27/6", "28/6"];
                        return value.toInt() < dates.length ? Text(dates[value.toInt()], style: const TextStyle(fontSize: 10)) : const SizedBox();
                      })),
                      topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    lineBarsData: [
                      LineChartBarData(
                        isCurved: true,
                        color: Colors.teal,
                        barWidth: 3,
                        spots: const [FlSpot(0, 2), FlSpot(1, 2.5), FlSpot(2, 3), FlSpot(3, 0.5), FlSpot(4, 5), FlSpot(5, 1), FlSpot(6, 0.5), FlSpot(7, 1.5)],
                        dotData: FlDotData(show: false),
                        belowBarData: BarAreaData(show: true, gradient: LinearGradient(colors: [Colors.green.withOpacity(0.2), Colors.green.withOpacity(0.0012)], begin: Alignment.topCenter, end: Alignment.bottomCenter)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }
}

class StatusRow extends StatelessWidget {
  final String title; final int value; final Color color;
  const StatusRow(this.title, this.value, this.color, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(width: 14, height: 14, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 14),
          Expanded(child: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, fontFamily: 'bold.ttf'))),
          Text(value.toString(), style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}