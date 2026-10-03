import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/app_l10n.dart';

enum ShareLiveDurationPreset {
  onlyOnce,
  oneHour,
  twelveHours,
  oneDay,
  oneWeek,
  twoWeeks,
  custom,
}

class ShareLiveLocationChoice {
  const ShareLiveLocationChoice({
    required this.onlyOnce,
    this.hours,
  });

  final bool onlyOnce;
  final int? hours;
}

class ShareLiveLocationDialog extends StatefulWidget {
  const ShareLiveLocationDialog({
    super.key,
    required this.vehicleName,
  });

  final String vehicleName;

  static Future<ShareLiveLocationChoice?> show(
    BuildContext context, {
    required String vehicleName,
  }) {
    return showDialog<ShareLiveLocationChoice>(
      context: context,
      useRootNavigator: true,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return ShareLiveLocationDialog(vehicleName: vehicleName);
      },
    );
  }

  @override
  State<ShareLiveLocationDialog> createState() =>
      _ShareLiveLocationDialogState();
}

class _ShareLiveLocationDialogState extends State<ShareLiveLocationDialog> {
  static const Color _accent = Color(0xFFF5365C);

  ShareLiveDurationPreset _preset = ShareLiveDurationPreset.onlyOnce;
  final TextEditingController _customHoursController = TextEditingController();

  @override
  void dispose() {
    _customHoursController.dispose();
    super.dispose();
  }

  ShareLiveLocationChoice? _buildChoice() {
    switch (_preset) {
      case ShareLiveDurationPreset.onlyOnce:
        return const ShareLiveLocationChoice(onlyOnce: true);
      case ShareLiveDurationPreset.oneHour:
        return const ShareLiveLocationChoice(onlyOnce: false, hours: 1);
      case ShareLiveDurationPreset.twelveHours:
        return const ShareLiveLocationChoice(onlyOnce: false, hours: 12);
      case ShareLiveDurationPreset.oneDay:
        return const ShareLiveLocationChoice(onlyOnce: false, hours: 24);
      case ShareLiveDurationPreset.oneWeek:
        return const ShareLiveLocationChoice(onlyOnce: false, hours: 168);
      case ShareLiveDurationPreset.twoWeeks:
        return const ShareLiveLocationChoice(onlyOnce: false, hours: 336);
      case ShareLiveDurationPreset.custom:
        final int? hours = int.tryParse(_customHoursController.text.trim());
        if (hours == null || hours <= 0) {
          return null;
        }
        return ShareLiveLocationChoice(onlyOnce: false, hours: hours);
    }
  }

  void _onShare() {
    final ShareLiveLocationChoice? choice = _buildChoice();
    if (choice == null) {
      return;
    }
    Navigator.pop(context, choice);
  }

  Widget _durationRow({
    required ShareLiveDurationPreset value,
    required String label,
    Widget? trailing,
  }) {
    final bool selected = _preset == value;
    return InkWell(
      onTap: () {
        setState(() {
          _preset = value;
        });
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: selected ? const Color(0xFF374151) : const Color(0xFF9CA3AF),
              size: 22,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: trailing ??
                  Text(
                    context.tr(label),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                      color: const Color(0xFF1F2937),
                    ),
                  ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool customSelected = _preset == ShareLiveDurationPreset.custom;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              widget.vehicleName.trim().isEmpty
                  ? context.tr('Vehicle')
                  : widget.vehicleName.trim(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 12),
            const Divider(height: 1, color: Color(0xFFE5E7EB)),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                context.tr('Share Live Location'),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF374151),
                ),
              ),
            ),
            const SizedBox(height: 8),
            _durationRow(
              value: ShareLiveDurationPreset.onlyOnce,
              label: 'Only Once',
            ),
            _durationRow(
              value: ShareLiveDurationPreset.oneHour,
              label: '1 HOUR',
            ),
            _durationRow(
              value: ShareLiveDurationPreset.twelveHours,
              label: '12 hours',
            ),
            _durationRow(
              value: ShareLiveDurationPreset.oneDay,
              label: '1 day',
            ),
            _durationRow(
              value: ShareLiveDurationPreset.oneWeek,
              label: '1 week',
            ),
            _durationRow(
              value: ShareLiveDurationPreset.twoWeeks,
              label: '2 weeks',
            ),
            _durationRow(
              value: ShareLiveDurationPreset.custom,
              label: 'Custom (in Hours)',
              trailing: TextField(
                controller: _customHoursController,
                keyboardType: TextInputType.number,
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.digitsOnly,
                ],
                onTap: () {
                  setState(() {
                    _preset = ShareLiveDurationPreset.custom;
                  });
                },
                decoration: InputDecoration(
                  isDense: true,
                  hintText: context.tr('Custom (in Hours)'),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: customSelected ? _accent : const Color(0xFFD1D5DB),
                      width: customSelected ? 1.4 : 1,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: customSelected ? _accent : const Color(0xFFD1D5DB),
                      width: customSelected ? 1.4 : 1,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: _accent, width: 1.4),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: <Widget>[
                Expanded(
                  child: SizedBox(
                    height: 42,
                    child: ElevatedButton(
                      onPressed: _onShare,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _accent,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        context.tr('Share'),
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 42,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _accent,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        context.tr('Cancel'),
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
