import 'package:url_launcher/url_launcher.dart';

/// Opens Google Maps at the given coordinates, or falls back to a text
/// search on the address when no coordinates are on file (see the
/// no-GPS-picker assumption in new_maintenance_request_screen.dart).
abstract final class MapsLauncher {
  static Future<void> open({
    double? latitude,
    double? longitude,
    String? address,
  }) async {
    final Uri uri;
    if (latitude != null && longitude != null) {
      uri = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude',
      );
    } else if (address != null && address.trim().isNotEmpty) {
      uri = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(address)}',
      );
    } else {
      return;
    }
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
