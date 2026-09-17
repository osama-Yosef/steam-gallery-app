import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'geo_point.dart';

/// Turns a coordinate into a human-readable address line, used only to
/// pre-fill a field the customer can edit. Kept separate from map display:
/// tiles and geocoding are different services with different providers,
/// limits and costs (see docs/10-phase-3-locations.md).
abstract class GeocodingService {
  /// Best effort: null when nothing useful is known or the provider fails.
  /// Never throws — a missing suggestion must not block saving an address.
  Future<String?> reverseGeocode(GeoPoint point);
}

/// No lookups at all (and nothing leaves the device).
class NoopGeocodingService implements GeocodingService {
  const NoopGeocodingService();

  @override
  Future<String?> reverseGeocode(GeoPoint point) async => null;
}

/// OpenStreetMap's public Nominatim. Its usage policy allows light,
/// user-initiated lookups: at most one request per second, an identifying
/// User-Agent (browsers send their own on web), no autocomplete, no bulk use.
/// This is called once when the customer confirms a pin, never while the map
/// moves. For higher volume, point [endpoint] at a self-hosted or paid
/// Nominatim-compatible service.
class NominatimGeocodingService implements GeocodingService {
  final http.Client _client;
  final Uri endpoint;
  final String userAgent;
  DateTime _lastRequest = DateTime.fromMillisecondsSinceEpoch(0);

  NominatimGeocodingService({
    http.Client? client,
    Uri? endpoint,
    this.userAgent = 'Mokoji/1.0 (com.steamgallery.steam_gallery_app)',
  }) : _client = client ?? http.Client(),
       endpoint =
           endpoint ?? Uri.parse('https://nominatim.openstreetmap.org/reverse');

  @override
  Future<String?> reverseGeocode(GeoPoint point) async {
    final wait =
        const Duration(seconds: 1) - DateTime.now().difference(_lastRequest);
    if (wait > Duration.zero) await Future<void>.delayed(wait);
    _lastRequest = DateTime.now();

    try {
      final uri = endpoint.replace(
        queryParameters: {
          'format': 'jsonv2',
          'lat': point.latitude.toStringAsFixed(6),
          'lon': point.longitude.toStringAsFixed(6),
          'zoom': '18',
          'addressdetails': '1',
          'accept-language': 'ar',
        },
      );
      final res = await _client
          .get(uri, headers: {'User-Agent': userAgent})
          .timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) return null;
      final body = jsonDecode(utf8.decode(res.bodyBytes));
      return body is Map<String, dynamic> ? formatNominatimAddress(body) : null;
    } catch (_) {
      return null;
    }
  }
}

/// "street, neighbourhood" from a Nominatim reverse response — short enough
/// for an address line, without the country/postcode tail of display_name.
String? formatNominatimAddress(Map<String, dynamic> response) {
  final address = response['address'];
  if (address is! Map) return null;
  String? pick(List<String> keys) {
    for (final k in keys) {
      final v = address[k];
      if (v is String && v.trim().isNotEmpty) return v.trim();
    }
    return null;
  }

  final street = pick(['road', 'pedestrian', 'street', 'residential']);
  final number = pick(['house_number']);
  final area = pick(['neighbourhood', 'suburb', 'quarter', 'city_district']);
  final parts = <String>[
    if (street != null) number != null ? '$street $number' : street,
    if (area != null && area != street) area,
  ];
  return parts.isEmpty ? null : parts.join('، ');
}
