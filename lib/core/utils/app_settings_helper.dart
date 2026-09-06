import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart' as ph;

class AppSettingsHelper {
  AppSettingsHelper._();

  static Future<bool> openAppSettings() async {
    try {
      // Method 1: Try geolocator first
      final opened = await Geolocator.openAppSettings();
      if (opened) return true;
    } catch (e) {
      debugPrint('Geolocator openAppSettings failed: $e');
    }

    try {
      // Method 2: Try permission_handler
      await ph.openAppSettings();
      return true;
    } catch (e) {
      debugPrint('permission_handler openAppSettings failed: $e');
    }

    return false;
  }

  static Future<bool> openLocationSettings() async {
    try {
      // Try geolocator
      final opened = await Geolocator.openLocationSettings();
      if (opened) return true;
    } catch (e) {
      debugPrint('Geolocator openLocationSettings failed: $e');
    }

    return false;
  }

  static Future<void> requestLocationPermission() async {
    try {
      await Geolocator.requestPermission();
    } catch (e) {
      debugPrint('Request location permission failed: $e');
    }
  }

  static Future<void> requestBackgroundPermission() async {
    try {
      // For Android, request background permission
      await ph.Permission.locationAlways.request();
    } catch (e) {
      debugPrint('Request background permission failed: $e');
    }
  }
}