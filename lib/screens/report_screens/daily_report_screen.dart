import 'package:flutter/material.dart';

import '../../constants/report_ids.dart';
import '../../utils/report_response_parser.dart';
import 'report_screen_scaffold.dart';

class DailyReportScreen extends StatelessWidget {
  const DailyReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ReportScreenScaffold(
      title: 'Daily Report',
      emptyTitle: 'Daily Report is not available',
      generatedSnackMessage: 'Generated Daily Report for',
      detailsTitle: 'Daily Details',
      foundLabel: 'Records Found',
      showGenerateButton: true,
      reportId: ReportIds.daily,
      buildGeneratedContent: (context, vehicle, reportData) {
        return ReportResponseParser.buildTimeline(reportData, vehicle);
      },
    );
  }
}
