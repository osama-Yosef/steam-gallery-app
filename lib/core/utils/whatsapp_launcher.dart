import 'package:url_launcher/url_launcher.dart';

/// Opens a WhatsApp chat with the given number (any local/E.164-ish format —
/// digits are extracted and normalised to Egypt's country code, same rule
/// as Validators.toE164Egypt).
abstract final class WhatsappLauncher {
  static Future<void> open(String phone, {String? message}) async {
    var digits = phone.trim().replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('0')) digits = '20${digits.substring(1)}';
    if (!digits.startsWith('20')) digits = '20$digits';
    final uri = Uri.https('wa.me', '/$digits', {
      if (message != null && message.isNotEmpty) 'text': message,
    });
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
