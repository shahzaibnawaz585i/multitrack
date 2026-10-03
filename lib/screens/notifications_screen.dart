import 'dart:async';

import 'package:flutter/material.dart';

import '../data/notification_data.dart';
import '../data/vehicle_data.dart';
import '../l10n/app_l10n.dart';
import '../models/notification_model.dart';
import '../services/alert_service.dart';
import '../services/live_notification_controller.dart';
import '../services/voice_alert_service.dart';
import '../theme/app_theme_tokens.dart';
import '../utils/notification_location_text.dart';
import 'notification_filter_screen.dart';

class NotificationsScreen extends StatefulWidget {
  final bool showAlertsOnly;
  final String? vehicleName;
  final int? deviceId;

  const NotificationsScreen({
    super.key,
    this.showAlertsOnly = false,
    this.vehicleName,
    this.deviceId,
  });

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final ScrollController _scrollController;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _currentPage = 1;
  List<AppNotification> _alerts = <AppNotification>[];
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);
    _scrollController = ScrollController()..addListener(_onScroll);
    _alerts = _getFilteredAlerts(NotificationData.alerts);
    LiveNotificationController.instance.addListener(_onLiveAlertsChanged);
    NotificationData.alertsRevision.addListener(_onLiveAlertsChanged);
    VehicleData.revision.addListener(_onLiveAlertsChanged);
    _refreshTimer = Timer.periodic(const Duration(seconds: 45), (_) {
      _loadEvents(isRefresh: true);
    });
    _loadEvents();
  }

  void _onLiveAlertsChanged() {
    if (!mounted) {
      return;
    }
    setState(() {
      _alerts = _getFilteredAlerts(NotificationData.alerts);
    });
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) {
      return;
    }
    setState(() {});
  }

  void _onScroll() {
    if (_tabController.index != 0 && !widget.showAlertsOnly) return;
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 250 &&
        !_isLoading &&
        !_isLoadingMore &&
        _hasMore) {
      _loadMoreEvents();
    }
  }

  Future<void> _loadEvents({bool isRefresh = false}) async {
    if (!isRefresh && _alerts.isEmpty) {
      setState(() => _isLoading = true);
    }
    if (isRefresh) {
      _currentPage = 1;
      _hasMore = true;
    }

    final List<AppNotification> fetched = await AlertService.getDisplayAlerts(
      deviceId: widget.deviceId,
      vehicleName: widget.vehicleName,
      forceRefresh: isRefresh || _alerts.isEmpty,
    );

    if (mounted && fetched.isNotEmpty) {
      LiveNotificationController.instance.enqueueBatch(
        fetched.where(
          (AppNotification n) =>
              n.category == NotificationCategory.alerts &&
              n.eventType != NotificationEventType.generic,
        ),
        maxCount: 100,
      );
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _isLoading = false;
      _alerts = _getFilteredAlerts(fetched);
      if (fetched.length < 30) {
        _hasMore = false;
      }
    });
  }

  Future<void> _loadMoreEvents() async {
    if (_isLoadingMore || !_hasMore) return;
    setState(() => _isLoadingMore = true);

    final int nextPage = _currentPage + 1;
    final List<AppNotification> fetched = await AlertService.getEvents(
      deviceId: widget.deviceId,
      page: nextPage,
      limit: 50,
      forceRefresh: true,
    );

    if (!mounted) return;

    setState(() {
      _isLoadingMore = false;
      if (fetched.isEmpty) {
        _hasMore = false;
      } else {
        _currentPage = nextPage;
        final List<AppNotification> filtered = _getFilteredAlerts(fetched);
        final Set<String> existingKeys = _alerts.map((AppNotification n) => '${n.id}_${n.timestamp}').toSet();
        for (final AppNotification item in filtered) {
          final String key = '${item.id}_${item.timestamp}';
          if (!existingKeys.contains(key)) {
            _alerts.add(item);
            existingKeys.add(key);
          }
        }
        if (fetched.length < 20) {
          _hasMore = false;
        }
      }
    });
  }

  List<AppNotification> _getFilteredAlerts(List<AppNotification> raw) {
    Iterable<AppNotification> items = raw.where(
      (AppNotification n) => n.category == NotificationCategory.alerts,
    );

    if (widget.vehicleName != null && widget.vehicleName!.isNotEmpty) {
      final String filter = widget.vehicleName!.toLowerCase().trim();
      final List<AppNotification> byVehicle = items
          .where(
            (AppNotification n) =>
                n.vehicleId.toLowerCase().contains(filter) ||
                filter.contains(n.vehicleId.toLowerCase()),
          )
          .toList();
      if (byVehicle.isNotEmpty) {
        items = byVehicle;
      }
    }

    final List<AppNotification> list = items.toList();
    list.sort(
      (AppNotification a, AppNotification b) =>
          b.timestamp.compareTo(a.timestamp),
    );
    return list;
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    LiveNotificationController.instance.removeListener(_onLiveAlertsChanged);
    NotificationData.alertsRevision.removeListener(_onLiveAlertsChanged);
    VehicleData.revision.removeListener(_onLiveAlertsChanged);
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
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
          widget.showAlertsOnly ? context.tr('Alerts') : context.tr('Notifications'),
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: accent),
            onPressed: () => _loadEvents(isRefresh: true),
          ),
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
                        text: '${context.tr('Alerts')}(${_isLoading ? 0 : _alerts.length})',
                      ),
                      Tab(
                        text: '${context.tr('Announcements')}(${_isLoading ? 0 : NotificationData.announcementCount})',
                      ),
                      Tab(
                        text: '${context.tr('Reminders')}(${_isLoading ? 0 : NotificationData.reminderCount})',
                      ),
                    ],
                  ),
                ),
              ),
      ),
      body: _isLoading
          ? const _ThreeDotLoader()
          : widget.showAlertsOnly
              ? RefreshIndicator(
                  onRefresh: () => _loadEvents(isRefresh: true),
                  child: _buildNotificationList(_alerts, isAlertTab: true),
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    RefreshIndicator(
                      onRefresh: () => _loadEvents(isRefresh: true),
                      child: _buildNotificationList(_alerts, isAlertTab: true),
                    ),
                    RefreshIndicator(
                      onRefresh: () => _loadEvents(isRefresh: true),
                      child: _buildNotificationList(NotificationData.announcements),
                    ),
                    RefreshIndicator(
                      onRefresh: () => _loadEvents(isRefresh: true),
                      child: _buildNotificationList(NotificationData.reminders),
                    ),
                  ],
                ),
    );
  }

  Widget _buildNotificationList(
    List<AppNotification> items, {
    bool isAlertTab = false,
  }) {
    if (items.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: 300,
            child: Center(
              child: Text(
                context.tr('No notifications'),
                style: TextStyle(
                  fontSize: 15,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ),
          ),
        ),
      );
    }

    final int extraItemCount = (isAlertTab && (_isLoadingMore || _hasMore)) ? 1 : 0;

    return ListView.builder(
      controller: isAlertTab ? _scrollController : null,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      itemCount: items.length + extraItemCount,
      itemBuilder: (BuildContext context, int index) {
        if (index == items.length) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: _isLoadingMore
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    )
                  : const SizedBox.shrink(),
            ),
          );
        }
        return _NotificationCard(
          notification: items[index],
          formattedTime: _formatTimestamp(items[index].timestamp),
        );
      },
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

  IconData _getIcon() {
    if (notification.category == NotificationCategory.announcements) {
      return Icons.campaign_rounded;
    }
    if (notification.category == NotificationCategory.reminders) {
      return Icons.event_note_rounded;
    }
    return notification.eventType.icon;
  }

  String _eventLabel(BuildContext context, AppNotification notification) {
    final String title = notification.eventTitle.trim();
    if (title.isNotEmpty &&
        title.toLowerCase() != 'alert' &&
        title.toLowerCase() != 'event') {
      return context.tr(title);
    }

    switch (notification.eventType) {
      case NotificationEventType.ignitionOn:
        return context.tr('Ignition On');
      case NotificationEventType.ignitionOff:
        return context.tr('Ignition Off');
      case NotificationEventType.overSpeed:
        return context.tr('Device OverSpeed');
      case NotificationEventType.geofenceIn:
        return context.tr('Geofence Entered');
      case NotificationEventType.geofenceOut:
        return context.tr('Geofence Exit');
      case NotificationEventType.offline:
        return context.tr('Device Offline');
      case NotificationEventType.movement:
        return context.tr('Movement Detected');
      case NotificationEventType.generic:
        return title.isNotEmpty ? context.tr(title) : context.tr('Alert');
    }
  }

  Color _getIconColor() {
    if (notification.category == NotificationCategory.announcements) {
      return const Color(0xFF0288D1);
    }
    if (notification.category == NotificationCategory.reminders) {
      return const Color(0xFFF57C00);
    }
    return notification.eventType.iconColor;
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color textColor = theme.colorScheme.onSurface;
    final Color mutedColor = textColor.withValues(alpha: 0.65);
    final Color iconColor = _getIconColor();
    final IconData icon = _getIcon();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
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
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () {
            VoiceAlertService.instance.speak(notification);
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: iconColor,
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
                        _eventLabel(context, notification),
                        style: TextStyle(
                          fontSize: 14,
                          color: textColor.withValues(alpha: 0.85),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (notification.eventType ==
                              NotificationEventType.overSpeed &&
                          notification.speed != null) ...<Widget>[
                        const SizedBox(height: 4),
                        Text(
                          '${notification.speed!.toStringAsFixed(0)} km/h',
                          style: TextStyle(
                            fontSize: 12,
                            color: iconColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                      const SizedBox(height: 4),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Icon(
                            Icons.location_on_outlined,
                            size: 14,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              NotificationLocationText.resolve(notification),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                color: mutedColor,
                                height: 1.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Icon(
                  Icons.volume_up_outlined,
                  size: 18,
                  color: theme.colorScheme.primary.withValues(alpha: 0.7),
                ),
              ],
            ),
          ),
        ),
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
