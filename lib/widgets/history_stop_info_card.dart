import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/app_l10n.dart';
import '../theme/app_theme_tokens.dart';
import '../utils/history_route_utils.dart';

class HistoryStopInfoCard extends StatelessWidget {
  const HistoryStopInfoCard({
    super.key,
    required this.session,
    required this.accentColor,
    required this.fallbackAddress,
    this.onClose,
  });

  final HistoryStopSession session;
  final Color accentColor;
  final String fallbackAddress;
  final VoidCallback? onClose;

  static final DateFormat _timeFormat = DateFormat('dd MMM yyyy hh:mm a');

  String _durationLabel(Duration d) {
    final int h = d.inHours;
    final int m = d.inMinutes.remainder(60);
    if (h > 0) {
      return '$h h $m m';
    }
    if (m > 0) {
      return '$m m';
    }
    return '${d.inSeconds}s';
  }

  Future<void> _openMaps(LatLng pos) async {
    final Uri uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${pos.latitude},${pos.longitude}',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final String address = (session.address?.trim().isNotEmpty ?? false)
        ? session.address!.trim()
        : fallbackAddress.trim();
    final String latLong =
        '${session.position.latitude.toStringAsFixed(6)}, ${session.position.longitude.toStringAsFixed(6)}';

    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(14),
      color: context.containerColor,
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _row(context.tr('Arrival Time'), _timeFormat.format(session.arrival)),
            const SizedBox(height: 6),
            _row(
              context.tr('Departure Time'),
              _timeFormat.format(session.departure),
            ),
            const SizedBox(height: 6),
            _row(
              context.tr('Duration'),
              _durationLabel(session.duration),
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: TextStyle(
                        fontSize: 12,
                        color: context.textColor,
                        height: 1.35,
                      ),
                      children: [
                        TextSpan(
                          text: '${context.tr('Latlong')}: ',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        TextSpan(
                          text: latLong,
                          style: TextStyle(
                            color: Colors.lightBlue.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                  icon: Icon(Icons.navigation_outlined, color: accentColor),
                  onPressed: () => _openMaps(session.position),
                ),
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                  icon: Icon(Icons.share_outlined, color: accentColor),
                  onPressed: () {
                    final String text =
                        '$address\n$latLong\n${context.tr('Arrival Time')}: ${_timeFormat.format(session.arrival)}';
                    // Share handled by platform if integrated later; open maps as fallback.
                    _openMaps(session.position);
                    debugPrint(text);
                  },
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${context.tr('Address')}: $address',
              style: TextStyle(
                fontSize: 12,
                color: context.mutedTextColor,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Builder(
      builder: (BuildContext context) {
        return RichText(
          text: TextSpan(
            style: TextStyle(
              fontSize: 12,
              height: 1.35,
              color: context.textColor,
            ),
            children: [
              TextSpan(
                text: '$label: ',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              TextSpan(text: value),
            ],
          ),
        );
      },
    );
  }
}
