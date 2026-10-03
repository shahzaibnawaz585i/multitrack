import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/app_l10n.dart';

/// Compact phone bar (reference: Phone(…) + call / edit icons).
class CallDriverDialog extends StatelessWidget {
  const CallDriverDialog({
    super.key,
    required this.phone,
  });

  final String phone;

  static Future<void> show(BuildContext context, {required String phone}) {
    return showDialog<void>(
      context: context,
      useRootNavigator: true,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return CallDriverDialog(phone: phone);
      },
    );
  }

  static const Color _accent = Color(0xFFF53D6B);

  Future<void> _call(BuildContext context) async {
    final String digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) {
      return;
    }
    final Uri uri = Uri(scheme: 'tel', path: digits);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _copyNumber(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: phone));
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.tr('Phone number copied'))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String display = phone.trim().isEmpty
        ? context.tr('No driver phone on file')
        : 'Phone($phone)';

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 36),
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              height: 5,
              width: double.infinity,
              color: const Color(0xFF2D2D2D),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      display,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF333333),
                      ),
                    ),
                  ),
                  if (phone.trim().isNotEmpty) ...<Widget>[
                    IconButton(
                      onPressed: () => _call(context),
                      icon: const Icon(Icons.phone, color: _accent),
                      tooltip: context.tr('Call'),
                    ),
                    IconButton(
                      onPressed: () => _copyNumber(context),
                      icon: const Icon(Icons.edit, color: _accent),
                      tooltip: context.tr('Copy'),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
