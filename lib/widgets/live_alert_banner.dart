import 'dart:async';
import 'package:flutter/material.dart';

import '../models/notification_model.dart';

class LiveAlertItem {
  final String title;
  final String message;
  final NotificationEventType eventType;
  final DateTime timestamp;
  final String? vehicleName;
  final double? speed;

  const LiveAlertItem({
    required this.title,
    required this.message,
    required this.eventType,
    required this.timestamp,
    this.vehicleName,
    this.speed,
  });
}

class LiveAlertBanner extends StatefulWidget {
  final LiveAlertItem? alert;
  final VoidCallback? onDismiss;
  final VoidCallback? onTap;

  const LiveAlertBanner({
    super.key,
    required this.alert,
    this.onDismiss,
    this.onTap,
  });

  @override
  State<LiveAlertBanner> createState() => _LiveAlertBannerState();
}

class _LiveAlertBannerState extends State<LiveAlertBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<Offset> _offsetAnimation;
  late Animation<double> _fadeAnimation;
  Timer? _autoDismissTimer;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );

    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0.0, -1.0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeIn,
    );

    if (widget.alert != null) {
      _animController.forward();
      _startAutoDismiss();
    }
  }

  @override
  void didUpdateWidget(covariant LiveAlertBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.alert != oldWidget.alert) {
      if (widget.alert != null) {
        _animController.forward(from: 0.0);
        _startAutoDismiss();
      } else {
        _animController.reverse();
      }
    }
  }

  void _startAutoDismiss() {
    _autoDismissTimer?.cancel();
    _autoDismissTimer = Timer(const Duration(milliseconds: 5000), () {
      if (mounted) {
        _animController.reverse().then((_) {
          if (mounted) {
            widget.onDismiss?.call();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _autoDismissTimer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  Color _getPrimaryColor(NotificationEventType type) {
    switch (type) {
      case NotificationEventType.ignitionOn:
        return const Color(0xFF00A854);
      case NotificationEventType.ignitionOff:
        return const Color(0xFFE53935);
      case NotificationEventType.overSpeed:
        return const Color(0xFFE91E63);
      case NotificationEventType.geofenceIn:
        return const Color(0xFF0288D1);
      case NotificationEventType.geofenceOut:
        return const Color(0xFFF57C00);
      default:
        return const Color(0xFF673AB7);
    }
  }

  IconData _getIcon(NotificationEventType type) {
    switch (type) {
      case NotificationEventType.ignitionOn:
        return Icons.power_settings_new_rounded;
      case NotificationEventType.ignitionOff:
        return Icons.power_off_rounded;
      case NotificationEventType.overSpeed:
        return Icons.speed_rounded;
      case NotificationEventType.geofenceIn:
        return Icons.login_rounded;
      case NotificationEventType.geofenceOut:
        return Icons.logout_rounded;
      default:
        return Icons.notifications_active_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.alert == null) {
      return const SizedBox.shrink();
    }

    final LiveAlertItem alert = widget.alert!;
    final Color alertColor = _getPrimaryColor(alert.eventType);
    final IconData icon = _getIcon(alert.eventType);

    return SlideTransition(
      position: _offsetAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Dismissible(
          key: ValueKey<String>('${alert.title}_${alert.timestamp.millisecondsSinceEpoch}'),
          direction: DismissDirection.up,
          onDismissed: (_) => widget.onDismiss?.call(),
          child: GestureDetector(
            onTap: widget.onTap,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: alertColor.withValues(alpha: 0.35),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 18,
                    spreadRadius: 0,
                    offset: const Offset(0, 6),
                  ),
                  BoxShadow(
                    color: alertColor.withValues(alpha: 0.12),
                    blurRadius: 10,
                    spreadRadius: 1,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Vibrant Icon badge
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: alertColor.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: alertColor.withValues(alpha: 0.35),
                        width: 1.5,
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        icon,
                        color: alertColor,
                        size: 22,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                alert.title,
                                style: TextStyle(
                                  color: alertColor,
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.2,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (alert.speed != null && alert.speed! > 0) ...[
                              Container(
                                margin: const EdgeInsets.only(left: 6),
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: alertColor.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '${alert.speed!.toStringAsFixed(0)} km/h',
                                  style: TextStyle(
                                    color: alertColor,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          alert.message,
                          style: const TextStyle(
                            color: Color(0xFF1E293B),
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                            height: 1.25,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Color(0xFF94A3B8), size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                    onPressed: () {
                      _animController.reverse().then((_) {
                        if (mounted) widget.onDismiss?.call();
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
