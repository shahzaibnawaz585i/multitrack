import 'package:flutter/material.dart';

import 'report_content_widgets.dart';
import 'report_screen_scaffold.dart';

class IgnitionReportScreen extends StatelessWidget {
  const IgnitionReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ReportScreenScaffold(
      title: 'Ignition Report',
      emptyTitle: 'Ignition Report is not available',
      generatedSnackMessage: 'Generated Ignition Report for',
      detailsTitle: 'Report Timeline',
      foundLabel: '3 Events Found',
      buildGeneratedContent: (context, vehicle) {
        return Column(
          children: [
            ReportTimelineEvent(
              time: '07:15 AM',
              duration: 'Duration: 45 min',
              status: 'Ignition ON',
              statusColor: Colors.green,
              location: vehicle.location,
            ),
            const ReportTimelineEvent(
              time: '08:00 AM',
              duration: 'Duration: 2 hrs 10 min',
              status: 'Ignition OFF',
              statusColor: Colors.redAccent,
              location: 'Kalma Chowk Flyover, Lahore',
            ),
            ReportTimelineEvent(
              time: '10:10 AM',
              duration: 'Duration: Ongoing',
              status: 'Ignition ON',
              statusColor: Colors.green,
              location: 'M.M. Alam Road, Gulberg, Lahore',
              isLast: true,
            ),
          ],
        );
      },
    );
  }
}
