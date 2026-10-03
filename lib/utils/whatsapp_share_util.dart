import 'package:url_launcher/url_launcher.dart';

class WhatsAppShareUtil {
  WhatsAppShareUtil._();

  static Future<bool> shareText(String message) async {
    final String trimmed = message.trim();
    if (trimmed.isEmpty) {
      return false;
    }

    final Uri appUri = Uri.parse(
      'whatsapp://send?text=${Uri.encodeComponent(trimmed)}',
    );
    if (await canLaunchUrl(appUri)) {
      await launchUrl(appUri, mode: LaunchMode.externalApplication);
      return true;
    }

    final Uri webUri = Uri.parse(
      'https://wa.me/?text=${Uri.encodeComponent(trimmed)}',
    );
    if (await canLaunchUrl(webUri)) {
      await launchUrl(webUri, mode: LaunchMode.externalApplication);
      return true;
    }

    return false;
  }
}
