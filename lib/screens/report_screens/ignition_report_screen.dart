import 'package:flutter/material.dart';

import '../../constants/report_ids.dart';
import '../../utils/report_response_parser.dart';
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
      foundLabel: 'Events Found',
      showGenerateButton: true,
      reportId: ReportIds.ignition,
      buildGeneratedContent: (context, vehicle, reportData) {
        return ReportResponseParser.buildTimeline(reportData, vehicle);
      },
    );
  }
}
