import 'package:flutter/material.dart';

import 'report_content_widgets.dart';
import 'report_screen_scaffold.dart';

class SpeedReportScreen extends StatelessWidget {
  const SpeedReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ReportScreenScaffold(
      title: 'Speed Report',
      emptyTitle: 'Speed Report is not available',
      generatedSnackMessage: 'Generated Speed Report for',
      detailsTitle: 'Speed Violations',
      foundLabel: '3 Alerts Found',
      buildGeneratedContent: (context, vehicle) {
        return const Column(
          children: [
            ReportDetailCard(
              title: 'Alert #1',
              statusLabel: 'Over Speed',
              statusColor: Colors.red,
              stats: [
                ReportStatItem(
                  label: 'Limit',
                  value: '60 km/h',
                  icon: Icons.speed,
                ),
                ReportStatItem(
                  label: 'Actual',
                  value: '92 km/h',
                  icon: Icons.warning_amber_rounded,
                ),
                ReportStatItem(
                  label: 'Duration',
                  value: '4 min',
                  icon: Icons.timer,
                ),
              ],
              infoRows: [
                ReportInfoRow(
                  icon: Icons.access_time,
                  iconColor: Colors.orange,
                  title: 'Time: 09:15 AM',
                  subtitle: 'Canal Road, Lahore',
                ),
                ReportInfoRow(
                  icon: Icons.location_on,
                  iconColor: Colors.red,
                  title: 'Location',
                  subtitle: 'Near Thokar Niaz Baig Interchange',
                ),
              ],
            ),
            ReportDetailCard(
              title: 'Alert #2',
              statusLabel: 'Over Speed',
              statusColor: Colors.red,
              stats: [
                ReportStatItem(
                  label: 'Limit',
                  value: '60 km/h',
                  icon: Icons.speed,
                ),
                ReportStatItem(
                  label: 'Actual',
                  value: '88 km/h',
                  icon: Icons.warning_amber_rounded,
                ),
                ReportStatItem(
                  label: 'Duration',
                  value: '2 min',
                  icon: Icons.timer,
                ),
              ],
              infoRows: [
                ReportInfoRow(
                  icon: Icons.access_time,
                  iconColor: Colors.orange,
                  title: 'Time: 01:40 PM',
                  subtitle: 'Ferozepur Road, Lahore',
                ),
                ReportInfoRow(
                  icon: Icons.location_on,
                  iconColor: Colors.red,
                  title: 'Location',
                  subtitle: 'Kalma Chowk Flyover',
                ),
              ],
            ),
            ReportDetailCard(
              title: 'Alert #3',
              statusLabel: 'Over Speed',
              statusColor: Colors.red,
              stats: [
                ReportStatItem(
                  label: 'Limit',
                  value: '80 km/h',
                  icon: Icons.speed,
                ),
                ReportStatItem(
                  label: 'Actual',
                  value: '105 km/h',
                  icon: Icons.warning_amber_rounded,
                ),
                ReportStatItem(
                  label: 'Duration',
                  value: '6 min',
                  icon: Icons.timer,
                ),
              ],
              infoRows: [
                ReportInfoRow(
                  icon: Icons.access_time,
                  iconColor: Colors.orange,
                  title: 'Time: 06:05 PM',
                  subtitle: 'Motorway M-2, Lahore',
                ),
                ReportInfoRow(
                  icon: Icons.location_on,
                  iconColor: Colors.red,
                  title: 'Location',
                  subtitle: 'Near Babu Sabu Interchange',
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
