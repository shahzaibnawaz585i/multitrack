import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/notification_model.dart';

class LiveAlertItem {
  final String title;
  final String message;
  final NotificationEventType eventType;
  final DateTime timestamp;
  final String? vehicleName;
  final double? speed;
  final int queuedBehind;

  const LiveAlertItem({
    required this.title,
    required this.message,
    required this.eventType,
    required this.timestamp,
    this.vehicleName,
    this.speed,
    this.queuedBehind = 0,
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
    with TickerProviderStateMixin {
  static const Duration _visibleDuration = Duration(seconds: 6);

  late AnimationController _entryController;
  late AnimationController _progressController;
  late Animation<Offset> _offsetAnimation;
  late Animation<double> _fadeAnimation;
  Timer? _autoDismissTimer;

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _progressController = AnimationController(
      vsync: this,
      duration: _visibleDuration,
    );

    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0, -1.15),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _entryController, curve: Curves.easeOutCubic),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _entryController,
      curve: Curves.easeOut,
    );

    if (widget.alert != null) {
      _presentAlert();
    }
  }

  @override
  void didUpdateWidget(covariant LiveAlertBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.alert != oldWidget.alert) {
      if (widget.alert != null) {
        _presentAlert();
      } else {
        _dismissAnimated();
      }
    }
  }

  void _presentAlert() {
    _autoDismissTimer?.cancel();
    _progressController.reset();
    _entryController.forward(from: 0);
    _progressController.forward();
    _autoDismissTimer = Timer(_visibleDuration, () {
      if (mounted) {
        _dismissAnimated();
      }
    });
  }

  void _dismissAnimated() {
    _autoDismissTimer?.cancel();
    _progressController.stop();
    _entryController.reverse().then((_) {
      if (mounted) {
        widget.onDismiss?.call();
      }
    });
  }

  @override
  void dispose() {
    _autoDismissTimer?.cancel();
    _entryController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  _AlertTheme _themeFor(NotificationEventType type) {
    switch (type) {
      case NotificationEventType.ignitionOn:
        return const _AlertTheme(
          accent: Color(0xFF10B981),
          accentDeep: Color(0xFF059669),
          icon: Icons.key_rounded,
        );
      case NotificationEventType.ignitionOff:
        return const _AlertTheme(
          accent: Color(0xFFEF4444),
          accentDeep: Color(0xFFDC2626),
          icon: Icons.power_settings_new_rounded,
        );
      case NotificationEventType.overSpeed:
        return const _AlertTheme(
          accent: Color(0xFFF43F5E),
          accentDeep: Color(0xFFE11D48),
          icon: Icons.speed_rounded,
        );
      case NotificationEventType.geofenceIn:
        return const _AlertTheme(
          accent: Color(0xFF0EA5E9),
          accentDeep: Color(0xFF0284C7),
          icon: Icons.login_rounded,
        );
      case NotificationEventType.geofenceOut:
        return const _AlertTheme(
          accent: Color(0xFFF97316),
          accentDeep: Color(0xFFEA580C),
          icon: Icons.logout_rounded,
        );
      case NotificationEventType.offline:
        return const _AlertTheme(
          accent: Color(0xFF64748B),
          accentDeep: Color(0xFF475569),
          icon: Icons.signal_wifi_off_rounded,
        );
      case NotificationEventType.movement:
        return const _AlertTheme(
          accent: Color(0xFF8B5CF6),
          accentDeep: Color(0xFF7C3AED),
          icon: Icons.directions_car_filled_rounded,
        );
      case NotificationEventType.generic:
        return const _AlertTheme(
          accent: Color(0xFF6366F1),
          accentDeep: Color(0xFF4F46E5),
          icon: Icons.notifications_active_rounded,
        );
    }
  }

  String _formatTime(DateTime time) {
    return DateFormat('h:mm a').format(time);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.alert == null) {
      return const SizedBox.shrink();
    }

    final LiveAlertItem alert = widget.alert!;
    final _AlertTheme theme = _themeFor(alert.eventType);
    final String vehicle =
        (alert.vehicleName ?? '').trim().isEmpty ? 'Vehicle' : alert.vehicleName!.trim();

    return SlideTransition(
      position: _offsetAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Dismissible(
          key: ValueKey<String>(
            '${alert.title}_${alert.timestamp.millisecondsSinceEpoch}',
          ),
          direction: DismissDirection.up,
          onDismissed: (_) => widget.onDismiss?.call(),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 6, 12, 4),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: widget.onTap,
                    child: Ink(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: <Color>[
                            Colors.white.withValues(alpha: 0.97),
                            Colors.white.withValues(alpha: 0.92),
                          ],
                        ),
                        border: Border.all(
                          color: theme.accent.withValues(alpha: 0.28),
                          width: 1.2,
                        ),
                        boxShadow: <BoxShadow>[
                          BoxShadow(
                            color: theme.accentDeep.withValues(alpha: 0.22),
                            blurRadius: 24,
                            offset: const Offset(0, 10),
                          ),
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Container(
                                width: 5,
                                height: 88,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: <Color>[
                                      theme.accent,
                                      theme.accentDeep,
                                    ],
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.fromLTRB(12, 12, 8, 10),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Container(
                                        width: 46,
                                        height: 46,
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: <Color>[
                                              theme.accent.withValues(alpha: 0.18),
                                              theme.accentDeep.withValues(alpha: 0.28),
                                            ],
                                          ),
                                          borderRadius: BorderRadius.circular(14),
                                        ),
                                        child: Icon(
                                          theme.icon,
                                          color: theme.accentDeep,
                                          size: 24,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: <Widget>[
                                            Row(
                                              children: <Widget>[
                                                Expanded(
                                                  child: Text(
                                                    alert.title,
                                                    style: TextStyle(
                                                      fontSize: 15,
                                                      fontWeight: FontWeight.w800,
                                                      letterSpacing: -0.2,
                                                      color: theme.accentDeep,
                                                    ),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                Text(
                                                  _formatTime(alert.timestamp),
                                                  style: const TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w600,
                                                    color: Color(0xFF94A3B8),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              vehicle,
                                              style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w700,
                                                color: Color(0xFF0F172A),
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              alert.message,
                                              style: const TextStyle(
                                                fontSize: 12.5,
                                                height: 1.35,
                                                fontWeight: FontWeight.w500,
                                                color: Color(0xFF475569),
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            if (alert.speed != null && alert.speed! > 0) ...<Widget>[
                                              const SizedBox(height: 8),
                                              Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                  vertical: 4,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: theme.accent.withValues(alpha: 0.12),
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Text(
                                                  '${alert.speed!.toStringAsFixed(0)} km/h',
                                                  style: TextStyle(
                                                    fontSize: 11.5,
                                                    fontWeight: FontWeight.w800,
                                                    color: theme.accentDeep,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                      IconButton(
                                        visualDensity: VisualDensity.compact,
                                        icon: const Icon(
                                          Icons.close_rounded,
                                          size: 20,
                                          color: Color(0xFF94A3B8),
                                        ),
                                        onPressed: _dismissAnimated,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (alert.queuedBehind > 0)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    '+${alert.queuedBehind} more in queue',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          AnimatedBuilder(
                            animation: _progressController,
                            builder: (BuildContext context, Widget? child) {
                              return LinearProgressIndicator(
                                value: 1 - _progressController.value,
                                minHeight: 3,
                                backgroundColor: theme.accent.withValues(alpha: 0.12),
                                valueColor: AlwaysStoppedAnimation<Color>(theme.accent),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AlertTheme {
  const _AlertTheme({
    required this.accent,
    required this.accentDeep,
    required this.icon,
  });

  final Color accent;
  final Color accentDeep;
  final IconData icon;
}
