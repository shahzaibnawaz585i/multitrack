import 'package:flutter/material.dart';

import '../../constants/report_ids.dart';
import '../../utils/report_response_parser.dart';
import 'report_screen_scaffold.dart';

class SummaryReportScreen extends StatelessWidget {
  const SummaryReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ReportScreenScaffold(
      title: 'Summary Report',
      emptyTitle: 'Summary Report is not available',
      generatedSnackMessage: 'Generated Summary Report for',
      showResultsHeader: false,
      showGenerateButton: true,
      reportId: ReportIds.summary,
      buildGeneratedContent: (context, vehicle, reportData) {
        return ReportResponseParser.buildSummaryCard(reportData, vehicle);
      },
    );
  }
}
