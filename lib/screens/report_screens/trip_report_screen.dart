import 'package:flutter/material.dart';

import 'report_content_widgets.dart';
import 'report_screen_scaffold.dart';

class TripReportScreen extends StatelessWidget {
  const TripReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ReportScreenScaffold(
      title: 'Trip Report',
      emptyTitle: 'Trip Detail Report is not available',
      generatedSnackMessage: 'Generated Trip Report for',
      detailsTitle: 'Trip Details',
      foundLabel: '2 Trips Found',
      buildGeneratedContent: (context, vehicle) {
        return const Column(
          children: [
            ReportTripCard(
              tripNum: 1,
              startTime: '08:00 AM',
              endTime: '09:30 AM',
              duration: '1 hr 30 min',
              distance: '15.4 km',
              avgSpeed: '42 km/h',
              startLocation: 'Heading towards Lower Mall, Anarkali, Lahore',
              endLocation: 'Liberty Market Parking, Gaddafi Stadium, Lahore',
            ),
            ReportTripCard(
              tripNum: 2,
              startTime: '10:15 AM',
              endTime: '12:00 PM',
              duration: '1 hr 45 min',
              distance: '22.8 km',
              avgSpeed: '39 km/h',
              startLocation: 'Liberty Market Parking, Gaddafi Stadium, Lahore',
              endLocation: 'M.M. Alam Road, Gulberg III, Lahore',
            ),
          ],
        );
      },
    );
  }
}
