import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../navigation/root_navigator.dart';
import '../screens/notifications_screen.dart';
import '../services/live_notification_controller.dart';
import 'live_alert_banner.dart';

/// In-app alert banner on every screen (detail, history, settings, …).
class GlobalLiveAlertOverlay extends StatelessWidget {
  const GlobalLiveAlertOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<LiveNotificationController>.value(
      value: LiveNotificationController.instance,
      child: Consumer<LiveNotificationController>(
        builder: (
          BuildContext context,
          LiveNotificationController ctrl,
          Widget? _,
        ) {
          return LiveAlertBanner(
            alert: ctrl.currentAlert,
            onDismiss: ctrl.dismiss,
            onTap: () {
              ctrl.dismiss();
              rootNavigatorKey.currentState?.push<void>(
                MaterialPageRoute<void>(
                  builder: (_) => const NotificationsScreen(),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
