import 'package:flutter/material.dart';
import 'package:multitrack/constants/app_theme.dart';
import 'package:multitrack/screens/report_screens/ignition_report_screen.dart';
import 'package:multitrack/screens/report_screens/ac_report_screen.dart';
import 'package:multitrack/screens/report_screens/trip_report_screen.dart';
import 'package:multitrack/screens/report_screens/summary_report_screen.dart';
import 'package:multitrack/screens/report_screens/stoppage_report_screen.dart';
import 'package:multitrack/screens/report_screens/daily_report_screen.dart';
import 'package:multitrack/screens/report_screens/speed_report_screen.dart';
import 'package:multitrack/screens/report_screens/geofence_report_screen.dart';
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  bool _isScrolled = false;

  bool _handleScrollNotification(ScrollNotification notification) {
    if (notification.depth == 0) {
      final bool newValue = notification.metrics.pixels > 0;

      if (newValue != _isScrolled && mounted) {
        setState(() {
          _isScrolled = newValue;
        });
      }
    }

    return false;
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appBackground,


      appBar: AppBar(

        automaticallyImplyLeading: false,
        backgroundColor:
            _isScrolled ? context.appScrolledHeader : context.appBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        title: Padding(
          padding: const EdgeInsets.only(left: 5),
          child: Text(
            "Reports",
            style: TextStyle(
              color: context.appTextColor,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),

      body: NotificationListener<ScrollNotification>(
        onNotification: _handleScrollNotification,

        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),

          padding: const EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: 120,
          ),

          child: LayoutBuilder(
            builder: (context, constraints) {
              // Screen ki available width
              final double availableWidth = constraints.maxWidth;

              // Default 2 cards ke darmiyan gap
              const double defaultGap = 16;

              // Default equal card width
              final double defaultCardWidth = (availableWidth - defaultGap) / 2;

              return Wrap(
                spacing: defaultGap,
                runSpacing: 16,
                children: [
                  // ==================================================
                  // 1. IGNITION REPORT
                  // ==================================================
                  ReportCard(
                    title: "Ignition Report",
                    image: "assets/ignition_report.png",

                    cardWidth: defaultCardWidth,
                    cardHeight: 160,

                    imageWidth: 70,
                    imageHeight: 70,

                    fontSize: 13,

                    imageTextGap: 15,

                    onTap: () {

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const IgnitionReportScreen(),
                        ),
                      );
                    },
                  ),

                  // ==================================================
                  // 2. AC REPORT
                  // ==================================================
                  ReportCard(
                    title: "AC Report",
                    image: "assets/ac_report.png",

                    cardWidth: defaultCardWidth,
                    cardHeight: 160,

                    imageWidth: 70,
                    imageHeight: 70,

                    fontSize: 13,

                    imageTextGap: 20,

                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              const AcReportScreen(),
                        ),
                      );
                    },
                  ),

                  // ==================================================
                  // 3. TRIP REPORT
                  // ==================================================
                  ReportCard(
                    title: "Trip Report",
                    image: "assets/trip_report.png",

                    cardWidth: defaultCardWidth,
                    cardHeight: 160,

                    imageWidth: 70,
                    imageHeight: 70,

                    fontSize: 13,

                    imageTextGap: 15,

                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              const TripReportScreen(),
                        ),
                      );
                    },
                  ),

                  // ==================================================
                  // 4. STOPPAGE REPORT
                  // ==================================================
                  ReportCard(
                    title: "Stoppage Report",
                    image: "assets/stoppage_report.png",

                    cardWidth: defaultCardWidth,
                    cardHeight: 160,

                    imageWidth: 80,
                    imageHeight: 80,

                    fontSize: 13,

                    imageTextGap: 10,

                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              const StoppageReportScreen(),
                        ),
                      );
                    },
                  ),

                  // ==================================================
                  // 5. SUMMARY REPORT
                  // ==================================================
                  ReportCard(
                    title: "Summary Report",
                    image: "assets/summary_report.png",

                    cardWidth: defaultCardWidth,
                    cardHeight: 160,

                    imageWidth: 70,
                    imageHeight: 70,

                    fontSize: 13,

                    imageTextGap: 15,

                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              const SummaryReportScreen(),
                        ),
                      );
                    },
                  ),

                  // ==================================================
                  // 6. DAILY REPORT
                  // ==================================================
                  ReportCard(
                    title: "Daily Report",
                    image: "assets/daily_report.png",

                    cardWidth: defaultCardWidth,
                    cardHeight: 160,

                    imageWidth: 70,
                    imageHeight: 70,

                    fontSize: 14,

                    imageTextGap: 15,

                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const DailyReportScreen(),
                        ),
                      );
                    },
                  ),

                  // ==================================================
                  // 7. SPEED REPORT
                  // ==================================================
                  ReportCard(
                    title: "Speed Report",
                    image: "assets/speeds_report.png",

                    cardWidth: defaultCardWidth,
                    cardHeight: 160,

                    imageWidth: 70,
                    imageHeight: 70,

                    fontSize: 13,
                    imageTextGap: 15,

                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SpeedReportScreen(),
                        ),
                      );
                    },
                  ),

                  // ==================================================
                  // 8. GEOFENCE REPORT
                  // ==================================================
                  ReportCard(
                    title: "Geofence Report",
                    image: "assets/geofences_report.png",

                    cardWidth: defaultCardWidth,
                    cardHeight: 160,

                    imageWidth: 80,
                    imageHeight: 80,

                    fontSize: 13,
                    imageTextGap: 5,

                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const GeofenceReportScreen(),
                        ),
                      );
                    },
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
// ============================================================
// REUSABLE REPORT CARD
// ============================================================

class ReportCard extends StatelessWidget {
  final String title;
  final String image;
  final VoidCallback onTap;

  // POORE CONTAINER KA SIZE
  final double cardWidth;
  final double cardHeight;

  // IMAGE KA SIZE
  final double imageWidth;
  final double imageHeight;

  // TEXT SIZE
  final double fontSize;

  // IMAGE AUR TEXT KE DARMIYAN GAP
  final double imageTextGap;

  const ReportCard({
    super.key,
    required this.title,
    required this.image,
    required this.onTap,
    required this.cardWidth,
    required this.cardHeight,
    this.imageWidth = 90,
    this.imageHeight = 90,
    this.fontSize = 17,
    this.imageTextGap = 8,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: cardWidth,
      height: cardHeight,

      child: Material(
        color: context.appSurface,
        borderRadius: BorderRadius.circular(10),
        clipBehavior: Clip.antiAlias,

        child: InkWell(
          // POORA CONTAINER CLICKABLE
          onTap: onTap,

          borderRadius: BorderRadius.circular(10),

          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),

            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // IMAGE
                Image.asset(
                  image,
                  width: imageWidth,
                  height: imageHeight,
                  fit: BoxFit.contain,

                  errorBuilder: (context, error, stackTrace) {
                    return SizedBox(
                      width: imageWidth,
                      height: imageHeight,

                      child: Center(
                        child: Icon(
                          Icons.description_outlined,
                          size: 60,
                          color: context.appSecondaryText,
                        ),
                      ),
                    );
                  },
                ),

                // IMAGE AUR TEXT KA GAP
                SizedBox(height: imageTextGap),

                // TITLE
                Text(
                  title,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,

                  style: TextStyle(
                    color: context.appTextColor,
                    fontSize: fontSize,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}