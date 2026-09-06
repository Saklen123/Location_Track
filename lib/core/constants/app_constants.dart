import 'package:geolocator/geolocator.dart';

class AppConstants {
  AppConstants._();

  // Location settings
  static const locationAccuracy = LocationAccuracy.bestForNavigation;
  static const distanceFilter = 10; // meters
  static const locationInterval = 5000; // milliseconds

  // Map settings
  static const defaultZoom = 15.0;
  static const minZoom = 5.0;
  static const maxZoom = 20.0;

  // Default location (San Francisco)
  static const defaultLatitude = 37.7749;
  static const defaultLongitude = -122.4194;

  // UI constants
  static const cardElevation = 4.0;
  static const cardBorderRadius = 12.0;
  static const padding = 16.0;
}