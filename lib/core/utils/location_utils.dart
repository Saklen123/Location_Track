import 'package:geolocator/geolocator.dart';
import '../constants/app_constants.dart';
import '../errors/location_exceptions.dart';

class LocationUtils {
  LocationUtils._();

  static Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  static Future<LocationPermission> checkPermission() async {
    return await Geolocator.checkPermission();
  }

  static Future<LocationPermission> requestPermission() async {
    return await Geolocator.requestPermission();
  }

  static Future<void> openLocationSettings() async {
    await Geolocator.openLocationSettings();
  }

  static Future<void> openAppSettings() async {
    await Geolocator.openAppSettings();
  }

  static Future<Position> getCurrentPosition() async {
    try {
      final hasPermission = await handlePermissionCheck();
      if (!hasPermission) {
        throw const LocationException(
          message: 'Location permission is required',
          type: LocationErrorType.permissionDenied,
        );
      }

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: AppConstants.locationAccuracy,
      );
    } catch (e) {
      throw LocationErrorHandler.handle(e);
    }
  }

  static Future<bool> handlePermissionCheck() async {
    final serviceEnabled = await isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw const LocationException(
        message: 'Location services are disabled. Please enable them.',
        type: LocationErrorType.locationServicesDisabled,
      );
    }

    var permission = await checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await requestPermission();
    }

    if (permission == LocationPermission.denied) {
      throw const LocationException(
        message: 'Location permission denied',
        type: LocationErrorType.permissionDenied,
      );
    }

    if (permission == LocationPermission.deniedForever) {
      throw const LocationException(
        message: 'Location permission permanently denied. Please enable it in settings.',
        type: LocationErrorType.permissionPermanentlyDenied,
      );
    }

    return true;
  }

  static Stream<Position> getPositionStream() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: AppConstants.locationAccuracy,
        distanceFilter: AppConstants.distanceFilter,
      ),
    );
  }

  static String formatCoordinates(double value, {bool isLatitude = true}) {
    final direction = isLatitude
        ? (value >= 0 ? 'N' : 'S')
        : (value >= 0 ? 'E' : 'W');
    return '${value.abs().toStringAsFixed(6)}° $direction';
  }
}