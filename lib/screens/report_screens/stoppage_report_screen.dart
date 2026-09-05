import 'package:flutter/material.dart';

import '../../constants/report_ids.dart';
import '../../utils/report_response_parser.dart';
import 'report_screen_scaffold.dart';

class StoppageReportScreen extends StatelessWidget {
  const StoppageReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ReportScreenScaffold(
      title: 'Stoppage Report',
      emptyTitle: 'Stoppage Report is not available',
      generatedSnackMessage: 'Generated Stoppage Report for',
      detailsTitle: 'Stoppage Details',
      foundLabel: 'Stops Found',
      showGenerateButton: true,
      reportId: ReportIds.stoppage,
      buildGeneratedContent: (context, vehicle, reportData) {
        return ReportResponseParser.buildTimeline(
          reportData,
          vehicle,
          defaultColor: Colors.redAccent,
        );
      },
    );
  }
}
