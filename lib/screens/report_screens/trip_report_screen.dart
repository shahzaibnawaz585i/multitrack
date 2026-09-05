import 'package:flutter/material.dart';

import '../../constants/report_ids.dart';
import '../../utils/report_response_parser.dart';
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
      foundLabel: 'Trips Found',
      showGenerateButton: true,
      reportId: ReportIds.trip,
      buildGeneratedContent: (context, vehicle, reportData) {
        return ReportResponseParser.buildTimeline(
          reportData,
          vehicle,
          defaultColor: Colors.blue,
        );
      },
    );
  }
}
