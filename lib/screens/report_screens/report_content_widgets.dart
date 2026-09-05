import 'package:flutter/material.dart';

import '../../l10n/app_l10n.dart';
import '../../models/vehicle_model.dart';

class ReportTimelineEvent extends StatelessWidget {
  final String time;
  final String duration;
  final String status;
  final Color statusColor;
  final String location;
  final bool isLast;

  const ReportTimelineEvent({
    super.key,
    required this.time,
    required this.duration,
    required this.status,
    required this.statusColor,
    required this.location,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 70,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  time,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Color(0xFF292B32),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  duration,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          Column(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: statusColor.withValues(alpha: 0.4),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: Colors.grey.shade300,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  status,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: statusColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  location,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ReportTripCard extends StatelessWidget {
  final int tripNum;
  final String startTime;
  final String endTime;
  final String duration;
  final String distance;
  final String avgSpeed;
  final String startLocation;
  final String endLocation;

  const ReportTripCard({
    super.key,
    required this.tripNum,
    required this.startTime,
    required this.endTime,
    required this.duration,
    required this.distance,
    required this.avgSpeed,
    required this.startLocation,
    required this.endLocation,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Trip #$tripNum',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Color(0xfff53d6b),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Completed',
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 20, color: Colors.black12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _TripStat(label: 'Duration', value: duration, icon: Icons.timer),
              _TripStat(label: 'Distance', value: distance, icon: Icons.straighten),
              _TripStat(label: 'Avg Speed', value: avgSpeed, icon: Icons.speed),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.play_circle_fill, color: Colors.green, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Start: $startTime',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                    Text(
                      startLocation,
                      style: const TextStyle(color: Colors.grey, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.stop_circle_rounded, color: Colors.red, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'End: $endTime',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                    Text(
                      endLocation,
                      style: const TextStyle(color: Colors.grey, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TripStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _TripStat({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: Colors.grey),
            const SizedBox(width: 4),
            Text(
              context.tr(label),
              style: const TextStyle(color: Colors.grey, fontSize: 11),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: Color(0xFF292B32),
          ),
        ),
      ],
    );
  }
}

class ReportDetailCard extends StatelessWidget {
  final String title;
  final String statusLabel;
  final Color statusColor;
  final List<ReportStatItem> stats;
  final List<ReportInfoRow> infoRows;

  const ReportDetailCard({
    super.key,
    required this.title,
    required this.statusLabel,
    required this.statusColor,
    required this.stats,
    required this.infoRows,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Color(0xfff53d6b),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 20, color: Colors.black12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: stats
                .map(
                  (item) => Expanded(
                    child: _ReportStat(
                      label: item.label,
                      value: item.value,
                      icon: item.icon,
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 16),
          for (final ReportInfoRow row in infoRows) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(row.icon, color: row.iconColor, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        row.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        row.subtitle,
                        style: const TextStyle(color: Colors.grey, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (row != infoRows.last) const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class ReportStatItem {
  final String label;
  final String value;
  final IconData icon;

  const ReportStatItem({
    required this.label,
    required this.value,
    required this.icon,
  });
}

class ReportInfoRow {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;

  const ReportInfoRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
  });
}

class SummaryReportCard extends StatelessWidget {
  final VehicleModel vehicle;

  const SummaryReportCard({super.key, required this.vehicle});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).cardColor,
      surfaceTintColor: Colors.transparent,
      elevation: 4,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.black12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Color(0xffffd8df),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.directions_car,
                          color: Color(0xfff53d6b),
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        vehicle.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Color(0xFF292B32),
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    const Icon(Icons.alt_route, color: Colors.blueAccent, size: 20),
                    const SizedBox(width: 4),
                    const Text(
                      '3.21 km',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Color(0xFF292B32),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: Colors.grey.shade400,
                      size: 14,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: Colors.black12, width: 0.8),
                  bottom: BorderSide(color: Colors.black12, width: 0.8),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  _MetricCol(label: 'Engine hours', value: '08:22:37'),
                  _MetricCol(label: 'Running', value: '03:00:20'),
                  _MetricCol(label: 'Stop', value: '143:20:47'),
                  _MetricCol(label: 'Idle', value: '05:22:17'),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.circle, color: Colors.green, size: 16),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '9842+5P7, near Juma masjid, Musliyarangadi, Malappuram...',
                        style: TextStyle(
                          color: Colors.grey.shade800,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 7),
                  child: Row(
                    children: [
                      Container(
                        width: 1.5,
                        height: 50,
                        color: Colors.black12,
                      ),
                      const SizedBox(width: 18),
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xffe2fbeb),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        child: const Text(
                          '000028138',
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(width: 40, height: 1, color: Colors.black12),
                      const SizedBox(width: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xffffd8df),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        child: const Text(
                          '000028141',
                          style: TextStyle(
                            color: Color(0xfff53d6b),
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.circle, color: Colors.red, size: 16),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Edakkara - Paleamad Road, Malappuram, 679331',
                        style: TextStyle(
                          color: Colors.grey.shade800,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Divider(color: Colors.black12),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                _BottomStat(label: 'Avg. 0', icon: Icons.speed),
                _BottomStat(label: 'Max. 41', icon: Icons.speed),
                _BottomStat(label: 'Fuel spent 0', icon: Icons.local_gas_station),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricCol extends StatelessWidget {
  final String label;
  final String value;

  const _MetricCol({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          context.tr(label),
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: Color(0xFF292B32),
          ),
        ),
      ],
    );
  }
}

class _BottomStat extends StatelessWidget {
  final String label;
  final IconData icon;

  const _BottomStat({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey.shade600, size: 18),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade800,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}

class _ReportStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _ReportStat({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: Colors.grey),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                style: const TextStyle(color: Colors.grey, fontSize: 11),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: Color(0xFF292B32),
          ),
        ),
      ],
    );
  }
}
