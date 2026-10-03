import 'package:flutter/material.dart';

import '../constants/app_fonts.dart';
import '../constants/app_images.dart';
import '../models/vehicle_model.dart';
import '../utils/live_location_text.dart';
import '../screens/vehicle_detail_screen.dart';
import '../theme/app_theme_tokens.dart';
import '../theme/fast_page_transitions.dart';

class VehicleCard extends StatelessWidget {
  const VehicleCard({super.key, required this.vehicle});

  final VehicleModel vehicle;

  Color _expiredColor(BuildContext context) => context.expiredContainerColor;

  bool get _isExpired => vehicle.status.trim().toLowerCase() == 'expired';

  bool get _isLocked {
    final String status = vehicle.status.toLowerCase();
    return status == 'stopped' || status == 'inactive';
  }

  String get _lockImage {
    if (_isLocked) {
      return AppImages.stopLock;
    }
    if (vehicle.status.toLowerCase() == 'running') {
      return AppImages.runningLock;
    }
    return AppImages.inactiveLock;
  }

  String get _carImage {
    switch (vehicle.status.toLowerCase()) {
      case 'running':
        return AppImages.listRunningCar;
      case 'stopped':
        return AppImages.listStopCar;
      case 'idle':
        return AppImages.listIdleCar;
      case 'not reporting':
        return AppImages.listInactiveCar;
      case 'expired':
        return AppImages.listStopCar;
      default:
        return AppImages.listStopCar;
    }
  }

  String get _statusLine {
    final String status = vehicle.status;
    if (status.toLowerCase() == 'running') {
      return 'RUNNING ${vehicle.time}';
    }
    return '$status ${vehicle.time}';
  }

  String get _expiredStatusLine => 'EXPIRED ${vehicle.time}';

  Color get _timelineIconColor {
    switch (vehicle.status.toLowerCase()) {
      case 'running':
        return Colors.green;
      case 'stopped':
        return Colors.red;
      default:
        return Colors.pinkAccent;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isExpired) {
      return _buildExpiredCard(context);
    }

    return _buildNormalCard(context);
  }

  Widget _buildExpiredCard(BuildContext context) {
    return GestureDetector(
      onTap: () => _openDetail(context),
      child: Container(
        height: 92,
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.fromLTRB(10, 10, 12, 10),
        decoration: BoxDecoration(
          color: _expiredColor(context),
          borderRadius: BorderRadius.circular(8),
          border: context.appTokens.containerBorderColor == null
              ? null
              : Border.all(color: context.appTokens.containerBorderColor!),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.16),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: context.fieldFillColor,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Image.asset(
                _carImage,
                width: 40,
                height: 30,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.low,
                cacheWidth: (40 * MediaQuery.devicePixelRatioOf(context)).round(),
                cacheHeight: (30 * MediaQuery.devicePixelRatioOf(context)).round(),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.directions_car_filled,
                        size: 16,
                        color: Colors.orange,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          vehicle.name,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: context.textColor,
                            fontFamily: AppFonts.regular,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 15,
                        child: Center(
                          child: _TimelineStatusDot(
                            color: Colors.red,
                            status: vehicle.status,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _expiredStatusLine,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: context.textColor,
                            fontFamily: AppFonts.regular,
                          ),
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
    );
  }

  void _openDetail(BuildContext context) {
    Navigator.push(
      context,
      FastMaterialPageRoute<void>(
        builder: (_) => VehicleDetailScreen(
          deviceId: vehicle.id,
          name: vehicle.name,
          status: vehicle.status,
          color: vehicle.color,
          speed: vehicle.speed,
          distance: vehicle.distance,
          odometer: vehicle.odometer,
          time: vehicle.time,
          livetime: vehicle.liveTime,
          location: LiveLocationText.forVehicle(vehicle),
          date: vehicle.date,
          latitude: vehicle.latitude,
          longitude: vehicle.longitude,
          initialTail: vehicle.tail,
          deviceTime: vehicle.deviceTime,
          serverTime: vehicle.serverTime,
          runningDuration: vehicle.runningDuration,
          stopDuration: vehicle.stopDuration,
          idleDuration: vehicle.idleDuration,
          inactiveDuration: vehicle.inactiveDuration,
          fuelMileage: vehicle.fuelMileage,
          fuelConsumption: vehicle.fuelConsumption,
          fuelCost: vehicle.fuelCost,
          avgSpeed: vehicle.avgSpeed,
          maxSpeed: vehicle.maxSpeed,
          devBattery: vehicle.devBattery,
          engineHours: vehicle.engineHours,
          carBattery: vehicle.carBattery,
          satellites: vehicle.satellites,
          fuelLevel: vehicle.fuelLevel,
          accuracy: vehicle.accuracy,
          temperature: vehicle.temperature,
          movement: vehicle.movement,
          vehicle: vehicle,
        ),
      ),
    );
  }

  Widget _buildNormalCard(BuildContext context) {
    return GestureDetector(
      onTap: () => _openDetail(context),
      child: Container(
        constraints: const BoxConstraints(minHeight: 175),
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: context.containerColor,
          borderRadius: BorderRadius.circular(4),
          border: context.appTokens.containerBorderColor == null
              ? null
              : Border.all(color: context.appTokens.containerBorderColor!),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.14),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(26, 8, 12, 6),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 70,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const SizedBox(height: 18),
                            Image.asset(
                              _carImage,
                              width: 54,
                              height: 38,
                              fit: BoxFit.contain,
                              filterQuality: FilterQuality.low,
                              cacheWidth:
                                  (54 * MediaQuery.devicePixelRatioOf(context))
                                      .round(),
                              cacheHeight:
                                  (38 * MediaQuery.devicePixelRatioOf(context))
                                      .round(),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              vehicle.speed,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: context.textColor,
                                fontFamily: AppFonts.number,
                                height: 1,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'kmph',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w400,
                                color: context.mutedTextColor,
                                fontFamily: AppFonts.regular,
                                height: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.directions_car_filled,
                                        size: 16,
                                        color: vehicle.status.toLowerCase() ==
                                                'running'
                                            ? Colors.green
                                            : vehicle.status.toLowerCase() ==
                                                    'stopped'
                                                ? Colors.red
                                                : Colors.grey.shade700,
                                      ),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          vehicle.name,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                            fontFamily: AppFonts.regular,
                                            color: context.textColor,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.only(left: 6),
                                    child: _DashedLine(),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: 15,
                                      child: Center(
                                        child: _TimelineStatusDot(
                                          color: vehicle.color,
                                          status: vehicle.status,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: _TimelineText(
                                        text: _statusLine,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                const Padding(
                                  padding: EdgeInsets.only(left: 6),
                                  child: _DashedLine(),
                                ),
                                Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: 15,
                                      child: Center(
                                        child: _TimelinePlainIcon(
                                          icon: Icons.access_time,
                                          color: _timelineIconColor,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: _TimelineText(
                                        text:
                                            '${vehicle.date} ${vehicle.liveTime}',
                                      ),
                                    ),
                                  ],
                                ),
                                const Padding(
                                  padding: EdgeInsets.only(left: 6),
                                  child: _DashedLine(),
                                ),
                                Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(
                                      width: 15,
                                      child: Padding(
                                        padding:
                                            const EdgeInsets.only(top: 1),
                                        child: Center(
                                          child: _TimelinePlainIcon(
                                            icon: Icons.location_on_outlined,
                                            color: _timelineIconColor,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: _TimelineText(
                                        text: LiveLocationText.forVehicle(
                                          vehicle,
                                        ),
                                        maxLines: 2,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        _StatusIcon(
                          icon: Icons.ac_unit,
                          color: Colors.pinkAccent,
                          isActive: true,
                        ),
                        const SizedBox(width: 4),
                        _StatusIcon(
                          icon: Icons.satellite_alt,
                          color: Colors.green,
                          isActive:
                              vehicle.status.toLowerCase() != 'not reporting',
                        ),
                        const SizedBox(width: 4),
                        _StatusIcon(
                          icon: Icons.power_settings_new,
                          color: Colors.green,
                          isActive:
                              vehicle.status.toLowerCase() == 'running',
                        ),
                        const SizedBox(width: 4),
                        _StatusIcon(
                          icon: Icons.vpn_key_outlined,
                          color: Colors.pinkAccent,
                          isActive: !_isLocked,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Flexible(
                                child: _InfoPill(
                                  icon: Icons.local_gas_station_outlined,
                                  label: vehicle.distance,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: _InfoPill(
                                  icon: Icons.calendar_month_outlined,
                                  label: vehicle.validityLabel,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              left: 0,
              top: 15,
              child: Image.asset(
                _lockImage,
                width: 28,
                height: 28,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.low,
                cacheWidth:
                    (28 * MediaQuery.devicePixelRatioOf(context)).round(),
                cacheHeight:
                    (28 * MediaQuery.devicePixelRatioOf(context)).round(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimelineStatusDot extends StatelessWidget {
  final Color color;
  final String status;

  const _TimelineStatusDot({
    required this.color,
    required this.status,
  });

  bool get _isRunning => status.trim().toLowerCase() == 'running';

  Color get _innerColor => _isRunning ? Colors.green : color;

  Color get _outerColor => _isRunning
      ? Colors.green.withValues(alpha: 0.28)
      : color.withValues(alpha: 0.28);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 15,
      height: 15,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 15,
            height: 15,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _outerColor,
            ),
          ),
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _innerColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelinePlainIcon extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _TimelinePlainIcon({
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 14,
      child: Icon(
        icon,
        size: 13,
        color: color,
      ),
    );
  }
}

class _DashedLine extends StatelessWidget {
  const _DashedLine();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Column(
        children: [
          _dash(),
          const SizedBox(height: 2),
          _dash(),
        ],
      ),
    );
  }

  Widget _dash() {
    return Container(
      width: 1.5,
      height: 4,
      color: Colors.grey.shade400,
    );
  }
}

class _TimelineText extends StatelessWidget {
  final String text;
  final FontWeight fontWeight;
  final int maxLines;

  const _TimelineText({
    required this.text,
    this.fontWeight = FontWeight.w400,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    const double fontSize = 10;
    const double textHeight = 1.25;
    final Color textColor = context.mutedTextColor;

    return Text(
      text,
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
      softWrap: true,
      style: TextStyle(
        fontSize: fontSize,
        height: textHeight,
        fontWeight: fontWeight,
        color: textColor,
        fontFamily: AppFonts.regular,
      ),
    );
  }
}

class _StatusIcon extends StatelessWidget {
  static const double _boxSize = 28;
  static const double _iconSize = 14;

  final IconData icon;
  final Color color;
  final bool isActive;

  const _StatusIcon({
    required this.icon,
    required this.color,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return _MiniCardSurface(
      width: _boxSize,
      height: _boxSize,
      child: Icon(
        icon,
        size: _iconSize,
        color: isActive ? color : Colors.grey.shade400,
      ),
    );
  }
}

class _MiniCardSurface extends StatelessWidget {
  final Widget child;
  final double? width;
  final double height;
  final EdgeInsetsGeometry? padding;

  const _MiniCardSurface({
    required this.child,
    required this.height,
    this.width,
    this.padding,
  });

  static const BorderRadius _radius = BorderRadius.all(Radius.circular(6));

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: 3,
            left: 0,
            right: 0,
            bottom: -4,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: _radius,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const SizedBox.expand(),
            ),
          ),
          Container(
            width: width,
            height: height,
            padding: padding,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: context.containerColor,
              borderRadius: _radius,
            ),
            child: child,
          ),
        ],
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  static const double _boxHeight = 28;

  final IconData icon;
  final String label;

  const _InfoPill({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return _MiniCardSurface(
      height: _boxHeight,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: context.mutedTextColor),
          const SizedBox(width: 3),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 9,
                color: context.textColor,
                fontFamily: AppFonts.regular,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
