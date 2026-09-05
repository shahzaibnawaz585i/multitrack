import 'package:flutter/material.dart';

import '../../constants/report_ids.dart';
import '../../utils/report_response_parser.dart';
import 'report_screen_scaffold.dart';

class AcReportScreen extends StatelessWidget {
  const AcReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ReportScreenScaffold(
      title: 'AC Report',
      emptyTitle: 'AC Report is not available',
      generatedSnackMessage: 'Generated AC Report for',
      detailsTitle: 'AC Events',
      foundLabel: 'Events Found',
      showGenerateButton: true,
      reportId: ReportIds.ac,
      buildGeneratedContent: (context, vehicle, reportData) {
        return ReportResponseParser.buildTimeline(reportData, vehicle);
      },
    );
  }
}
