import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/app_l10n.dart';
import '../theme/app_theme_tokens.dart';

/// History map: stoppage threshold (minutes) + overspeed limit (km/h).
Future<({int stoppageMinutes, int overspeedKmph})?> showHistoryPlaybackSettingsDialog({
  required BuildContext context,
  required Color accentColor,
  required int initialStoppageMinutes,
  required int initialOverspeedKmph,
}) {
  return showDialog<({int stoppageMinutes, int overspeedKmph})>(
    context: context,
    barrierDismissible: true,
    builder: (BuildContext context) {
      return _HistoryPlaybackSettingsDialog(
        accentColor: accentColor,
        initialStoppageMinutes: initialStoppageMinutes,
        initialOverspeedKmph: initialOverspeedKmph,
      );
    },
  );
}

class _HistoryPlaybackSettingsDialog extends StatefulWidget {
  const _HistoryPlaybackSettingsDialog({
    required this.accentColor,
    required this.initialStoppageMinutes,
    required this.initialOverspeedKmph,
  });

  final Color accentColor;
  final int initialStoppageMinutes;
  final int initialOverspeedKmph;

  @override
  State<_HistoryPlaybackSettingsDialog> createState() =>
      _HistoryPlaybackSettingsDialogState();
}

class _HistoryPlaybackSettingsDialogState
    extends State<_HistoryPlaybackSettingsDialog> {
  late final TextEditingController _stoppageCtrl;
  late final TextEditingController _overspeedCtrl;

  @override
  void initState() {
    super.initState();
    _stoppageCtrl = TextEditingController(
      text: widget.initialStoppageMinutes.toString(),
    );
    _overspeedCtrl = TextEditingController(
      text: widget.initialOverspeedKmph.toString(),
    );
  }

  @override
  void dispose() {
    _stoppageCtrl.dispose();
    _overspeedCtrl.dispose();
    super.dispose();
  }

  InputDecoration _fieldDecoration() {
    return InputDecoration(
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: BorderSide(color: widget.accentColor, width: 1.2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: BorderSide(color: widget.accentColor, width: 1.5),
      ),
    );
  }

  void _submit() {
    final int stoppage =
        int.tryParse(_stoppageCtrl.text.trim()) ?? widget.initialStoppageMinutes;
    final int overspeed =
        int.tryParse(_overspeedCtrl.text.trim()) ?? widget.initialOverspeedKmph;
    if (stoppage < 1 || overspeed < 1) {
      return;
    }
    Navigator.of(context).pop((
      stoppageMinutes: stoppage.clamp(1, 120),
      overspeedKmph: overspeed.clamp(1, 300),
    ));
  }

  Widget _actionButton(String label, VoidCallback onTap) {
    return Expanded(
      child: Material(
        color: widget.accentColor,
        borderRadius: BorderRadius.circular(8),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Center(
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              context.tr('Settings'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: context.textColor,
              ),
            ),
            const SizedBox(height: 8),
            Divider(color: Colors.grey.shade300, height: 1),
            const SizedBox(height: 16),
            Text(
              context.tr('Stoppage >='),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: context.textColor,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: TextField(
                    controller: _stoppageCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: <TextInputFormatter>[
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    decoration: _fieldDecoration(),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  context.tr('Minutes'),
                  style: TextStyle(
                    fontSize: 13,
                    color: context.mutedTextColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              context.tr('Overspeed >'),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: context.textColor,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: TextField(
                    controller: _overspeedCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: <TextInputFormatter>[
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    decoration: _fieldDecoration(),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  context.tr('Km/hr'),
                  style: TextStyle(
                    fontSize: 13,
                    color: context.mutedTextColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                _actionButton(context.tr('CANCEL'), () => Navigator.pop(context)),
                const SizedBox(width: 12),
                _actionButton(context.tr('OK'), _submit),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
