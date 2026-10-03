import 'package:flutter/material.dart';

import '../../l10n/app_l10n.dart';
import '../../widgets/geofence_report_panel.dart';

class GeofenceReportScreen extends StatelessWidget {
  const GeofenceReportScreen({super.key});

  static const Color _accent = Color(0xFFF53D6B);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Theme.of(context).cardColor,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: _accent, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          context.tr('Geofence Report'),
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        actions: <Widget>[
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: _accent),
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              PopupMenuItem<String>(
                value: 'export',
                child: Text(context.tr('Export')),
              ),
            ],
          ),
        ],
      ),
      body: const GeofenceReportPanel(),
    );
  }
}
