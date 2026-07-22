import 'package:flutter/material.dart';

import 'report_content_widgets.dart';
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
      foundLabel: '2 Days Found',
      buildGeneratedContent: (context, vehicle) {
        return const Column(
          children: [
            ReportDetailCard(
              title: 'Day #1',
              statusLabel: 'Completed',
              statusColor: Colors.green,
              stats: [
                ReportStatItem(
                  label: 'Distance',
                  value: '175.7 km',
                  icon: Icons.straighten,
                ),
                ReportStatItem(
                  label: 'Running',
                  value: '6 hr 20 min',
                  icon: Icons.timer,
                ),
                ReportStatItem(
                  label: 'Max Speed',
                  value: '82 km/h',
                  icon: Icons.speed,
                ),
              ],
              infoRows: [
                ReportInfoRow(
                  icon: Icons.play_circle_fill,
                  iconColor: Colors.green,
                  title: 'Start: 08:00 AM',
                  subtitle: 'Heading towards Lower Mall, Anarkali, Lahore',
                ),
                ReportInfoRow(
                  icon: Icons.stop_circle_rounded,
                  iconColor: Colors.red,
                  title: 'End: 08:30 PM',
                  subtitle: 'GPO Chowk, Mall Road, Lahore',
                ),
              ],
            ),
            ReportDetailCard(
              title: 'Day #2',
              statusLabel: 'Completed',
              statusColor: Colors.green,
              stats: [
                ReportStatItem(
                  label: 'Distance',
                  value: '142.3 km',
                  icon: Icons.straighten,
                ),
                ReportStatItem(
                  label: 'Running',
                  value: '5 hr 45 min',
                  icon: Icons.timer,
                ),
                ReportStatItem(
                  label: 'Max Speed',
                  value: '76 km/h',
                  icon: Icons.speed,
                ),
              ],
              infoRows: [
                ReportInfoRow(
                  icon: Icons.play_circle_fill,
                  iconColor: Colors.green,
                  title: 'Start: 07:45 AM',
                  subtitle: 'Liberty Market Parking, Gaddafi Stadium, Lahore',
                ),
                ReportInfoRow(
                  icon: Icons.stop_circle_rounded,
                  iconColor: Colors.red,
                  title: 'End: 07:15 PM',
                  subtitle: 'M.M. Alam Road, Gulberg III, Lahore',
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
