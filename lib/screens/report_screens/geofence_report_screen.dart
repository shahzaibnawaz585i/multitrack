import 'package:flutter/material.dart';

import '../../constants/report_ids.dart';
import '../../utils/report_response_parser.dart';
import 'report_screen_scaffold.dart';

class GeofenceReportScreen extends StatelessWidget {
  const GeofenceReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ReportScreenScaffold(
      title: 'Geofence Report',
      emptyTitle: 'Geofence Report is not available',
      generatedSnackMessage: 'Generated Geofence Report for',
      detailsTitle: 'Geofence Events',
      foundLabel: 'Events Found',
      showGenerateButton: true,
      reportId: ReportIds.geofence,
      buildGeneratedContent: (context, vehicle, reportData) {
        return ReportResponseParser.buildTimeline(
          reportData,
          vehicle,
          defaultColor: Colors.purple,
        );
      },
    );
  }
}
