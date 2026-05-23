import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationHelper {
  /// Request location permissions (both permission_handler and geolocator service check)
  static Future<bool> requestLocationPermission() async {
    // 1. Check if location services are enabled
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    // 2. Check permission status using permission_handler
    var status = await Permission.location.status;
    if (status.isGranted) {
      return true;
    }

    if (status.isDenied) {
      status = await Permission.location.request();
      return status.isGranted;
    }

    if (status.isPermanentlyDenied) {
      // The user opted to never show this prompt again, they must enable it in settings.
      return false;
    }

    return false;
  }

  /// Get customer's current position using Geolocator
  static Future<Position?> getCurrentLocation() async {
    try {
      final hasPermission = await requestLocationPermission();
      if (!hasPermission) {
        return null;
      }

      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        ),
      );
    } catch (e) {
      // Fallback/log
      return null;
    }
  }

  /// Check if location permission is granted
  static Future<bool> hasPermission() async {
    return await Permission.location.isGranted;
  }

  /// Open app settings to manually enable location permission
  static Future<bool> openSettings() async {
    return await openAppSettings();
  }
}
