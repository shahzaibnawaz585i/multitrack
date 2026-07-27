import 'package:flutter/material.dart';

import 'report_content_widgets.dart';
import 'report_screen_scaffold.dart';

class AcReportScreen extends StatelessWidget {
  const AcReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ReportScreenScaffold(
      title: 'AC Report',
      emptyTitle: 'AC Report is not available',
      generatedSnackMessage: 'Generated AC Report for',
      detailsTitle: 'Report Timeline',
      foundLabel: '3 Events Found',
      buildGeneratedContent: (context, vehicle) {
        return Column(
          children: [
            ReportTimelineEvent(
              time: '08:30 AM',
              duration: 'Duration: 1 hr 15 min',
              status: 'AC ON',
              statusColor: Colors.teal,
              location: vehicle.location,
            ),
            const ReportTimelineEvent(
              time: '09:45 AM',
              duration: 'Duration: 2 hrs 35 min',
              status: 'AC OFF',
              statusColor: Colors.redAccent,
              location: 'Kalma Chowk Flyover, Lahore',
            ),
            ReportTimelineEvent(
              time: '12:20 PM',
              duration: 'Duration: Ongoing',
              status: 'AC ON',
              statusColor: Colors.teal,
              location: 'M.M. Alam Road, Gulberg, Lahore',
              isLast: true,
            ),
          ],
        );
      },
    );
  }
}
