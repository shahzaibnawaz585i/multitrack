import 'package:flutter/material.dart';

import 'report_content_widgets.dart';
import 'report_screen_scaffold.dart';

class StoppageReportScreen extends StatelessWidget {
  const StoppageReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ReportScreenScaffold(
      title: 'Stoppage Report',
      emptyTitle: 'Stoppage Report is not available',
      generatedSnackMessage: 'Generated Stoppage Report for',
      detailsTitle: 'Stoppages Timeline',
      foundLabel: '3 Stops Found',
      buildGeneratedContent: (context, vehicle) {
        return Column(
          children: [
            ReportTimelineEvent(
              time: '09:00 AM',
              duration: 'Duration: 25 min',
              status: 'Stopped',
              statusColor: Colors.orange,
              location: vehicle.location,
            ),
            const ReportTimelineEvent(
              time: '11:30 AM',
              duration: 'Duration: 40 min',
              status: 'Stopped',
              statusColor: Colors.orange,
              location: 'Liberty Market, Gulberg, Lahore',
            ),
            const ReportTimelineEvent(
              time: '02:15 PM',
              duration: 'Duration: 15 min',
              status: 'Stopped',
              statusColor: Colors.orange,
              location: 'M.M. Alam Road, Gulberg III, Lahore',
              isLast: true,
            ),
          ],
        );
      },
    );
  }
}
