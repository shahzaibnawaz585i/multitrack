import 'package:flutter/material.dart';

import 'report_content_widgets.dart';
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
      buildGeneratedContent: (context, vehicle) {
        return SummaryReportCard(vehicle: vehicle);
      },
    );
  }
}
