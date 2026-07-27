import 'package:flutter/material.dart';

import 'report_content_widgets.dart';
import 'report_screen_scaffold.dart';

class GeofenceReportScreen extends StatelessWidget {
  const GeofenceReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ReportScreenScaffold(
      title: 'Geofence Report',
      emptyTitle: 'Geofence Report is not available',
      generatedSnackMessage: 'Generated Geofence Report for',
      detailsTitle: 'Geofence Events',
      foundLabel: '2 Events Found',
      buildGeneratedContent: (context, vehicle) {
        return const Column(
          children: [
            ReportDetailCard(
              title: 'Event #1',
              statusLabel: 'Entry',
              statusColor: Colors.green,
              stats: [
                ReportStatItem(
                  label: 'Geofence',
                  value: 'Office Zone',
                  icon: Icons.fence,
                ),
                ReportStatItem(
                  label: 'Duration',
                  value: '2 hr 15 min',
                  icon: Icons.timer,
                ),
                ReportStatItem(
                  label: 'Speed',
                  value: '28 km/h',
                  icon: Icons.speed,
                ),
              ],
              infoRows: [
                ReportInfoRow(
                  icon: Icons.login,
                  iconColor: Colors.green,
                  title: 'In: 10:05 AM',
                  subtitle: 'Office Zone Geofence, Gulberg, Lahore',
                ),
                ReportInfoRow(
                  icon: Icons.logout,
                  iconColor: Colors.red,
                  title: 'Out: 12:20 PM',
                  subtitle: 'Vehicle exited office zone boundary',
                ),
              ],
            ),
            ReportDetailCard(
              title: 'Event #2',
              statusLabel: 'Exit',
              statusColor: Colors.orange,
              stats: [
                ReportStatItem(
                  label: 'Geofence',
                  value: 'Warehouse',
                  icon: Icons.fence,
                ),
                ReportStatItem(
                  label: 'Duration',
                  value: '45 min',
                  icon: Icons.timer,
                ),
                ReportStatItem(
                  label: 'Speed',
                  value: '35 km/h',
                  icon: Icons.speed,
                ),
              ],
              infoRows: [
                ReportInfoRow(
                  icon: Icons.login,
                  iconColor: Colors.green,
                  title: 'In: 03:10 PM',
                  subtitle: 'Warehouse Zone, Kot Lakhpat, Lahore',
                ),
                ReportInfoRow(
                  icon: Icons.logout,
                  iconColor: Colors.red,
                  title: 'Out: 03:55 PM',
                  subtitle: 'Vehicle exited warehouse zone boundary',
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
