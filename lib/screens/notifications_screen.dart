import 'dart:async';

import 'package:flutter/material.dart';

import '../data/notification_data.dart';
import '../data/vehicle_data.dart';
import '../l10n/app_l10n.dart';
import '../models/notification_model.dart';
import '../services/alert_service.dart';
import '../services/notification_feed_service.dart';
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
  List<AppNotification> _announcements = <AppNotification>[];
  List<AppNotification> _reminders = <AppNotification>[];
  bool _feedLoading = false;
  bool _disposed = false;
  Timer? _refreshTimer;

  void _safeSetState(VoidCallback fn) {
    if (_disposed || !mounted) {
      return;
    }
    setState(fn);
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);
    _scrollController = ScrollController()..addListener(_onScroll);
    _alerts = _getFilteredAlerts(NotificationData.alerts);
    _announcements = List<AppNotification>.from(NotificationData.announcements);
    _reminders = List<AppNotification>.from(NotificationData.reminders);
    LiveNotificationController.instance.addListener(_onLiveAlertsChanged);
    NotificationData.alertsRevision.addListener(_onLiveAlertsChanged);
    VehicleData.revision.addListener(_onLiveAlertsChanged);
    _refreshTimer = Timer.periodic(const Duration(seconds: 45), (_) {
      if (_disposed || !mounted) {
        return;
      }
      unawaited(_loadEvents(isRefresh: true));
    });
    unawaited(_loadEvents());
  }

  void _onLiveAlertsChanged() {
    _safeSetState(() {
      _alerts = _getFilteredAlerts(NotificationData.alerts);
      _announcements = List<AppNotification>.from(NotificationData.announcements);
      _reminders = List<AppNotification>.from(NotificationData.reminders);
    });
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) {
      return;
    }
    _safeSetState(() {});
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
    if (_disposed) {
      return;
    }
    if (!isRefresh && _alerts.isEmpty) {
      _safeSetState(() => _isLoading = true);
    }
    if (isRefresh) {
      _currentPage = 1;
      _hasMore = true;
    }

    List<AppNotification> fetched = const <AppNotification>[];
    try {
      fetched = await AlertService.getDisplayAlerts(
        deviceId: widget.deviceId,
        vehicleName: widget.vehicleName,
        forceRefresh: isRefresh || _alerts.isEmpty,
      );
    } catch (_) {
      fetched = const <AppNotification>[];
    }

    if (_disposed || !mounted) {
      return;
    }

    if (fetched.isNotEmpty) {
      try {
        LiveNotificationController.instance.enqueueBatch(
          fetched.where(
            (AppNotification n) =>
                n.category == NotificationCategory.alerts &&
                n.eventType != NotificationEventType.generic,
          ),
          maxCount: 100,
        );
      } catch (_) {}
    }

    _safeSetState(() {
      _isLoading = false;
      _alerts = _getFilteredAlerts(fetched);
      if (fetched.length < 30) {
        _hasMore = false;
      }
    });

    await _loadFeedTabs(recentEvents: fetched);
  }

  Future<void> _loadFeedTabs({List<AppNotification>? recentEvents}) async {
    if (_disposed) {
      return;
    }
    _safeSetState(() => _feedLoading = true);
    try {
      final List<AppNotification> announcements =
          await NotificationFeedService.loadAnnouncements(
        deviceId: widget.deviceId,
        recentEvents: recentEvents,
      );
      final List<AppNotification> reminders =
          await NotificationFeedService.loadReminders(
        deviceId: widget.deviceId,
      );
      if (_disposed || !mounted) {
        return;
      }
      _safeSetState(() {
        _announcements = announcements;
        _reminders = reminders;
      });
    } catch (_) {
      // Keep previously loaded cards; do not crash the screen.
    } finally {
      _safeSetState(() => _feedLoading = false);
    }
  }

  String _tabTitle(String label, int count) {
    final String base = context.tr(label);
    if (count <= 0) {
      return base;
    }
    return '$base ($count)';
  }

  int _overdueCount(List<AppNotification> items) {
    final DateTime now = DateTime.now();
    return items.where((AppNotification n) => n.timestamp.isBefore(now)).length;
  }

  Future<void> _loadMoreEvents() async {
    if (_disposed || _isLoadingMore || !_hasMore) return;
    _safeSetState(() => _isLoadingMore = true);

    final int nextPage = _currentPage + 1;
    List<AppNotification> fetched = const <AppNotification>[];
    try {
      fetched = await AlertService.getEvents(
        deviceId: widget.deviceId,
        page: nextPage,
        limit: 50,
        forceRefresh: true,
      );
    } catch (_) {
      fetched = const <AppNotification>[];
    }

    if (_disposed || !mounted) return;

    _safeSetState(() {
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
    _disposed = true;
    _refreshTimer?.cancel();
    _refreshTimer = null;
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
                    tabs: <Tab>[
                      Tab(text: _tabTitle('Alerts', _alerts.length)),
                      Tab(text: _tabTitle('Announcements', _announcements.length)),
                      Tab(text: _tabTitle('Reminders', _reminders.length)),
                    ],
                  ),
                ),
              ),
      ),
      body: widget.showAlertsOnly
          ? (_isLoading && _alerts.isEmpty
              ? const _ThreeDotLoader()
              : _buildAlertsFeed())
          : TabBarView(
              controller: _tabController,
              children: <Widget>[
                _isLoading && _alerts.isEmpty
                    ? const _ThreeDotLoader()
                    : _buildAlertsFeed(),
                _buildCategoryFeed(
                  items: _announcements,
                  feedKind: _FeedKind.announcements,
                  hero: _FeedHeroConfig(
                    title: context.tr('Announcements'),
                    subtitle: _announcements.isEmpty
                        ? context.tr('Company updates and broadcasts')
                        : _announcements.first.eventTitle,
                    icon: Icons.campaign_rounded,
                    gradientStart: const Color(0xFF0EA5E9),
                    gradientEnd: const Color(0xFF0369A1),
                    countLabel: _announcements.isEmpty
                        ? context.tr('Up to date')
                        : '${_announcements.length} ${context.tr('active')}',
                  ),
                  emptyMessage: context.tr('No announcements'),
                  emptyHint: context.tr(
                    'Company news and broadcasts from your fleet panel will appear here.',
                  ),
                ),
                _buildCategoryFeed(
                  items: _reminders,
                  feedKind: _FeedKind.reminders,
                  hero: _FeedHeroConfig(
                    title: context.tr('Reminders'),
                    subtitle: _reminders.isEmpty
                        ? context.tr('Maintenance and service due dates')
                        : _reminders.first.eventTitle,
                    icon: Icons.notifications_active_rounded,
                    gradientStart: const Color(0xFFF97316),
                    gradientEnd: const Color(0xFFC2410C),
                    countLabel: _reminders.isEmpty
                        ? context.tr('No due items')
                        : _overdueCount(_reminders) > 0
                            ? '${_overdueCount(_reminders)} ${context.tr('overdue')}'
                            : '${_reminders.length} ${context.tr('scheduled')}',
                  ),
                  emptyMessage: context.tr('No reminders'),
                  emptyHint: context.tr(
                    'Service intervals and maintenance tasks from your account will show here.',
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildAlertsFeed() {
    return _buildCategoryFeed(
      items: _alerts,
      feedKind: _FeedKind.alerts,
      hero: _FeedHeroConfig(
        title: context.tr('Alerts'),
        subtitle: _alerts.isEmpty
            ? context.tr('Device events and live alerts')
            : _alerts.first.eventTitle,
        icon: Icons.warning_amber_rounded,
        gradientStart: const Color(0xFFEF4444),
        gradientEnd: const Color(0xFFB91C1C),
        countLabel: _alerts.isEmpty
            ? context.tr('No alerts')
            : '${_alerts.length} ${context.tr('active')}',
      ),
      emptyMessage: context.tr('No notifications'),
      emptyHint: context.tr(
        'Ignition, overspeed, geofence and offline events from your devices will appear here.',
      ),
    );
  }

  Widget _buildCategoryFeed({
    required List<AppNotification> items,
    required _FeedKind feedKind,
    required _FeedHeroConfig hero,
    required String emptyMessage,
    required String emptyHint,
  }) {
    final Color accent;
    final IconData kindIcon;
    final String leftLabel;
    final String leftValue;
    final String rightLabel;
    final String rightValue;

    switch (feedKind) {
      case _FeedKind.alerts:
        accent = const Color(0xFFDC2626);
        kindIcon = Icons.warning_amber_rounded;
        leftLabel = context.tr('Total');
        leftValue = items.length.toString();
        rightLabel = context.tr('Latest');
        rightValue = items.isEmpty
            ? '—'
            : _formatTimestamp(items.first.timestamp);
      case _FeedKind.announcements:
        accent = const Color(0xFF0284C7);
        kindIcon = Icons.campaign_rounded;
        leftLabel = context.tr('Total');
        leftValue = items.length.toString();
        rightLabel = context.tr('Latest');
        rightValue = items.isEmpty
            ? '—'
            : _formatTimestamp(items.first.timestamp);
      case _FeedKind.reminders:
        accent = const Color(0xFFEA580C);
        kindIcon = Icons.build_circle_outlined;
        leftLabel = context.tr('Scheduled');
        leftValue =
            (items.length - _overdueCount(items)).clamp(0, 999).toString();
        rightLabel = context.tr('Overdue');
        rightValue = _overdueCount(items).toString();
    }

    final bool showAlertLoader =
        feedKind == _FeedKind.alerts && (_isLoadingMore || _hasMore);
    final bool showSkeleton = feedKind == _FeedKind.alerts
        ? _isLoading && items.isEmpty
        : _feedLoading && items.isEmpty;

    return RefreshIndicator(
      onRefresh: () => _loadEvents(isRefresh: true),
      child: CustomScrollView(
        controller: feedKind == _FeedKind.alerts ? _scrollController : null,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: <Widget>[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
              child: _FeedHeroCard(config: hero),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
              child: _FeedStatRow(
                accent: accent,
                leftLabel: leftLabel,
                leftValue: leftValue,
                rightLabel: rightLabel,
                rightValue: rightValue,
              ),
            ),
          ),
          if (showSkeleton)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 20),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (BuildContext context, int index) =>
                      _FeedSkeletonCard(accent: accent),
                  childCount: 3,
                ),
              ),
            )
          else if (items.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 20),
                child: _FeedEmptyCard(
                  accent: accent,
                  icon: kindIcon,
                  title: emptyMessage,
                  hint: emptyHint,
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 20),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (BuildContext context, int index) {
                    if (showAlertLoader && index == items.length) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Center(
                          child: _isLoadingMore
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                  ),
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
                  childCount: items.length + (showAlertLoader ? 1 : 0),
                ),
              ),
            ),
        ],
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

  _NotificationCardVisual _visualFor(AppNotification n) {
    if (n.category == NotificationCategory.announcements) {
      return const _NotificationCardVisual(
        accent: Color(0xFF0284C7),
        accentDeep: Color(0xFF0369A1),
        icon: Icons.campaign_rounded,
        categoryLabel: 'Announcement',
      );
    }
    if (n.category == NotificationCategory.reminders) {
      return const _NotificationCardVisual(
        accent: Color(0xFFEA580C),
        accentDeep: Color(0xFFC2410C),
        icon: Icons.notifications_active_rounded,
        categoryLabel: 'Reminder',
      );
    }
    return _NotificationCardVisual(
      accent: n.eventType.iconColor,
      accentDeep: Color.lerp(n.eventType.iconColor, Colors.black, 0.18)!,
      icon: n.eventType.icon,
      categoryLabel: 'Alert',
    );
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

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color textColor = theme.colorScheme.onSurface;
    final Color mutedColor = textColor.withValues(alpha: 0.62);
    final _NotificationCardVisual visual = _visualFor(notification);
    final bool isDark = theme.brightness == Brightness.dark;
    final Color cardFill = context.containerColor;
    final String location = NotificationLocationText.resolve(notification);
    final bool isReminder = notification.category == NotificationCategory.reminders;
    final bool isAnnouncement =
        notification.category == NotificationCategory.announcements;
    final bool isOverdue = isReminder &&
        notification.timestamp.isBefore(DateTime.now());

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: visual.accent.withValues(alpha: isDark ? 0.22 : 0.14),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.06),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Material(
            color: cardFill,
            child: InkWell(
              onTap: () => VoiceAlertService.instance.speak(notification),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Container(
                      width: 5,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: <Color>[
                            visual.accent,
                            visual.accentDeep,
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: <Color>[
                                        visual.accent,
                                        visual.accentDeep,
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(14),
                                    boxShadow: <BoxShadow>[
                                      BoxShadow(
                                        color: visual.accent
                                            .withValues(alpha: 0.35),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    visual.icon,
                                    color: Colors.white,
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Row(
                                        children: <Widget>[
                                          Expanded(
                                            child: Text(
                                              notification.vehicleId,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontWeight: FontWeight.w800,
                                                fontSize: 15,
                                                letterSpacing: -0.2,
                                                color: textColor,
                                              ),
                                            ),
                                          ),
                                          _CategoryChip(
                                            label: context
                                                .tr(visual.categoryLabel),
                                            accent: visual.accent,
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        _eventLabel(context, notification),
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          height: 1.25,
                                          color: textColor
                                              .withValues(alpha: 0.92),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 4),
                                _VoiceChip(accent: visual.accent),
                              ],
                            ),
                            if (isOverdue) ...<Widget>[
                              const SizedBox(height: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFDC2626)
                                      .withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: const Color(0xFFDC2626)
                                        .withValues(alpha: 0.28),
                                  ),
                                ),
                                child: Text(
                                  context.tr('Overdue'),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFFB91C1C),
                                  ),
                                ),
                              ),
                            ],
                            if (notification.eventType ==
                                    NotificationEventType.overSpeed &&
                                notification.speed != null) ...<Widget>[
                              const SizedBox(height: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: visual.accent.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color:
                                        visual.accent.withValues(alpha: 0.25),
                                  ),
                                ),
                                child: Text(
                                  '${notification.speed!.toStringAsFixed(0)} km/h',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: visual.accentDeep,
                                  ),
                                ),
                              ),
                            ],
                            const SizedBox(height: 12),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.05)
                                    : visual.accent.withValues(alpha: 0.06),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: visual.accent.withValues(alpha: 0.12),
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Icon(
                                    isReminder
                                        ? Icons.event_note_rounded
                                        : isAnnouncement
                                            ? Icons.article_outlined
                                            : Icons.place_rounded,
                                    size: 16,
                                    color: visual.accent,
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      location,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 12,
                                        height: 1.35,
                                        color: mutedColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: <Widget>[
                                Icon(
                                  Icons.schedule_rounded,
                                  size: 14,
                                  color: mutedColor,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    formattedTime,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: mutedColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

enum _FeedKind { alerts, announcements, reminders }

class _FeedStatRow extends StatelessWidget {
  const _FeedStatRow({
    required this.accent,
    required this.leftLabel,
    required this.leftValue,
    required this.rightLabel,
    required this.rightValue,
  });

  final Color accent;
  final String leftLabel;
  final String leftValue;
  final String rightLabel;
  final String rightValue;

  @override
  Widget build(BuildContext context) {
    final Color fill = context.containerColor;
    return Row(
      children: <Widget>[
        Expanded(
          child: _FeedStatTile(
            accent: accent,
            fill: fill,
            label: leftLabel,
            value: leftValue,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _FeedStatTile(
            accent: accent,
            fill: fill,
            label: rightLabel,
            value: rightValue,
            compactValue: rightValue.length > 14,
          ),
        ),
      ],
    );
  }
}

class _FeedStatTile extends StatelessWidget {
  const _FeedStatTile({
    required this.accent,
    required this.fill,
    required this.label,
    required this.value,
    this.compactValue = false,
  });

  final Color accent;
  final Color fill;
  final String label;
  final String value;
  final bool compactValue;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.18)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: accent.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.55),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              maxLines: compactValue ? 2 : 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: compactValue ? 13 : 20,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
                color: accent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeedEmptyCard extends StatelessWidget {
  const _FeedEmptyCard({
    required this.accent,
    required this.icon,
    required this.title,
    required this.hint,
  });

  final Color accent;
  final IconData icon;
  final String title;
  final String hint;

  @override
  Widget build(BuildContext context) {
    final Color fill = context.containerColor;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: accent.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Material(
          color: fill,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: <Color>[accent, Color.lerp(accent, Colors.black, 0.15)!],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        hint,
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.4,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.62),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: <Widget>[
                          Icon(
                            Icons.refresh_rounded,
                            size: 16,
                            color: accent,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            context.tr('Pull down to refresh'),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: accent,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FeedSkeletonCard extends StatelessWidget {
  const _FeedSkeletonCard({required this.accent});

  final Color accent;

  @override
  Widget build(BuildContext context) {
    final Color base = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        height: 118,
        decoration: BoxDecoration(
          color: context.containerColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: accent.withValues(alpha: 0.1)),
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: <Widget>[
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: base,
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Container(
                    height: 12,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: base,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    height: 10,
                    width: 180,
                    decoration: BoxDecoration(
                      color: base,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    height: 8,
                    width: 120,
                    decoration: BoxDecoration(
                      color: base,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeedHeroConfig {
  const _FeedHeroConfig({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradientStart,
    required this.gradientEnd,
    required this.countLabel,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color gradientStart;
  final Color gradientEnd;
  final String countLabel;
}

class _FeedHeroCard extends StatelessWidget {
  const _FeedHeroCard({required this.config});

  final _FeedHeroConfig config;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[config.gradientStart, config.gradientEnd],
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: config.gradientStart.withValues(alpha: isDark ? 0.35 : 0.28),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
              ),
              child: Icon(config.icon, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    config.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    config.subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.92),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.28),
                      ),
                    ),
                    child: Text(
                      config.countLabel,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationCardVisual {
  const _NotificationCardVisual({
    required this.accent,
    required this.accentDeep,
    required this.icon,
    required this.categoryLabel,
  });

  final Color accent;
  final Color accentDeep;
  final IconData icon;
  final String categoryLabel;
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.accent,
  });

  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent.withValues(alpha: 0.28)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.3,
          color: accent,
        ),
      ),
    );
  }
}

class _VoiceChip extends StatelessWidget {
  const _VoiceChip({required this.accent});

  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        shape: BoxShape.circle,
        border: Border.all(color: accent.withValues(alpha: 0.22)),
      ),
      alignment: Alignment.center,
      child: Icon(
        Icons.volume_up_rounded,
        size: 18,
        color: accent,
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
