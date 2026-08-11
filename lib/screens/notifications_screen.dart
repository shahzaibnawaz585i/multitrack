import 'package:flutter/material.dart';

import '../data/notification_data.dart';
import '../models/notification_model.dart';
import '../theme/app_theme_tokens.dart';
import 'notification_filter_screen.dart';

class NotificationsScreen extends StatefulWidget {
  final bool showAlertsOnly;
  const NotificationsScreen({super.key, this.showAlertsOnly = false});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    await Future<void>.delayed(const Duration(seconds: 2));
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) {
      return;
    }

    setState(() {});
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _openFilter() async {
    await Navigator.push<NotificationFilterResult>(
      context,
      MaterialPageRoute<NotificationFilterResult>(
        builder: (_) => const NotificationFilterScreen(),
      ),
    );
  }

  String _formatTimestamp(DateTime value) {
    const List<String> months = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    final int hour = value.hour % 12 == 0 ? 12 : value.hour % 12;
    final String minute = value.minute.toString().padLeft(2, '0');
    final String period = value.hour >= 12 ? 'PM' : 'AM';

    return '${months[value.month - 1]} ${value.day} ${value.year} '
        '${hour.toString().padLeft(2, '0')}:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color accent = theme.colorScheme.primary;
    final Color textColor = theme.colorScheme.onSurface;
    final Color screenBackground = theme.scaffoldBackgroundColor;

    return Scaffold(
      backgroundColor: screenBackground,
      appBar: AppBar(
        backgroundColor: screenBackground,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: widget.showAlertsOnly 
            ? null 
            : IconButton(
                icon: Icon(Icons.arrow_back_ios_new, color: accent, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
        title: Text(
          widget.showAlertsOnly ? 'Alerts' : 'Notifications',
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.filter_alt_outlined, color: accent),
            onPressed: _openFilter,
          ),
        ],
        bottom: widget.showAlertsOnly 
            ? null 
            : PreferredSize(
                preferredSize: const Size.fromHeight(34),
                child: ColoredBox(
                  color: screenBackground,
                  child: TabBar(
                    controller: _tabController,
                    isScrollable: false,
                    tabAlignment: TabAlignment.fill,
                    indicatorSize: TabBarIndicatorSize.label,
                    indicator: UnderlineTabIndicator(
                      borderSide: BorderSide(color: accent, width: 2.5),
                    ),
                    labelColor: accent,
                    unselectedLabelColor: textColor.withValues(alpha: 0.55),
                    labelPadding: const EdgeInsets.symmetric(horizontal: 2),
                    labelStyle: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                      height: 1.1,
                    ),
                    unselectedLabelStyle: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 11,
                      height: 1.1,
                    ),
                    dividerColor: theme.dividerColor,
                    dividerHeight: 1,
                    tabs: [
                      Tab(
                        text: _isLoading
                            ? 'Alerts(0)'
                            : 'Alerts(${NotificationData.alertCount})',
                      ),
                      Tab(
                        text: _isLoading
                            ? 'Announcements(0)'
                            : 'Announcements(${NotificationData.announcementCount})',
                      ),
                      Tab(
                        text: _isLoading
                            ? 'Reminders(0)'
                            : 'Reminders(${NotificationData.reminderCount})',
                      ),
                    ],
                  ),
                ),
              ),
      ),
      body: _isLoading
          ? const _ThreeDotLoader()
          : widget.showAlertsOnly
              ? _buildNotificationList(NotificationData.alerts)
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildNotificationList(NotificationData.alerts),
                    _buildEmptyState('No announcements'),
                    _buildNotificationList(NotificationData.reminders),
                  ],
                ),
    );
  }

  Widget _buildNotificationList(List<AppNotification> items) {
    if (items.isEmpty) {
      return _buildEmptyState('No notifications');
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      itemCount: items.length,
      itemBuilder: (BuildContext context, int index) {
        return _NotificationCard(
          notification: items[index],
          formattedTime: _formatTimestamp(items[index].timestamp),
        );
      },
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Text(
        message,
        style: TextStyle(
          fontSize: 15,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
        ),
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final AppNotification notification;
  final String formattedTime;

  const _NotificationCard({
    required this.notification,
    required this.formattedTime,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color textColor = theme.colorScheme.onSurface;
    final Color mutedColor = textColor.withValues(alpha: 0.65);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: context.containerDecoration(
        borderRadius: BorderRadius.circular(8),
      ).copyWith(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: notification.eventType.iconColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              notification.eventType.icon,
              color: notification.eventType.iconColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        notification.vehicleId,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: textColor,
                        ),
                      ),
                    ),
                    Text(
                      formattedTime,
                      style: TextStyle(
                        fontSize: 11,
                        color: mutedColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  notification.eventTitle,
                  style: TextStyle(
                    fontSize: 14,
                    color: textColor.withValues(alpha: 0.85),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  notification.location,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: mutedColor,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ThreeDotLoader extends StatefulWidget {
  const _ThreeDotLoader();

  @override
  State<_ThreeDotLoader> createState() => _ThreeDotLoaderState();
}

class _ThreeDotLoaderState extends State<_ThreeDotLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color accent = Theme.of(context).colorScheme.primary;

    return Center(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (BuildContext context, Widget? child) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: List<Widget>.generate(3, (int index) {
              final double phase = (_controller.value + (index * 0.2)) % 1.0;
              final double scale = 0.6 + (phase < 0.5 ? phase : 1 - phase) * 0.8;

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Transform.scale(
                  scale: scale,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: accent,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}
