import 'package:geolocator/geolocator.dart';
import 'geo_point.dart';

/// Why the device's position couldn't be read — each needs a different
/// message and a different way out for the user.
enum DeviceLocationError {
  /// Location services (GPS) are switched off.
  serviceDisabled,

  /// The user declined this time.
  permissionDenied,

  /// The user declined permanently; only system settings can change it.
  permissionDeniedForever,

  /// Anything else (timeout, no fix).
  unavailable,
}

class DeviceLocationException implements Exception {
  final DeviceLocationError error;
  const DeviceLocationException(this.error);

  String get messageAr => switch (error) {
    DeviceLocationError.serviceDisabled =>
      'خدمة تحديد الموقع مقفولة في الجهاز. فعّلها أو حرّك الخريطة بنفسك.',
    DeviceLocationError.permissionDenied =>
      'محتاجين إذن الوصول للموقع. تقدر كمان تحرّك الخريطة بنفسك.',
    DeviceLocationError.permissionDeniedForever =>
      'إذن الموقع مرفوض من إعدادات الجهاز. حرّك الخريطة لتحديد مكانك.',
    DeviceLocationError.unavailable =>
      'تعذَّر تحديد موقعك الآن. حرّك الخريطة لتحديد مكانك.',
  };
}

/// The device's own position, asked for only when the user taps "my
/// location" — never in the background, never stored by itself.
abstract class DeviceLocationService {
  /// Throws [DeviceLocationException].
  Future<GeoPoint> currentPosition();
}

class GeolocatorDeviceLocationService implements DeviceLocationService {
  const GeolocatorDeviceLocationService();

  @override
  Future<GeoPoint> currentPosition() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const DeviceLocationException(DeviceLocationError.serviceDisabled);
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      throw const DeviceLocationException(DeviceLocationError.permissionDenied);
    }
    if (permission == LocationPermission.deniedForever) {
      throw const DeviceLocationException(
        DeviceLocationError.permissionDeniedForever,
      );
    }
    try {
      final p = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
      return GeoPoint(p.latitude, p.longitude);
    } catch (_) {
      throw const DeviceLocationException(DeviceLocationError.unavailable);
    }
  }
}
