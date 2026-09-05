import 'package:flutter/material.dart';

import '../../constants/report_ids.dart';
import '../../utils/report_response_parser.dart';
import 'report_screen_scaffold.dart';

class SpeedReportScreen extends StatelessWidget {
  const SpeedReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ReportScreenScaffold(
      title: 'OverSpeed Report',
      emptyTitle: 'OverSpeed Report is not available',
      generatedSnackMessage: 'Generated OverSpeed Report for',
      detailsTitle: 'Speed Events',
      foundLabel: 'Events Found',
      showGenerateButton: true,
      reportId: ReportIds.speed,
      buildGeneratedContent: (context, vehicle, reportData) {
        return ReportResponseParser.buildTimeline(
          reportData,
          vehicle,
          defaultColor: Colors.orange,
        );
      },
    );
  }
}
