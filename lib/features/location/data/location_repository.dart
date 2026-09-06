import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:location/location.dart' as loc;
import '../../../core/utils/location_utils.dart';
import '../../../core/errors/location_exceptions.dart';

class LocationRepository {
  StreamSubscription<Position>? _positionSubscription;
  StreamSubscription<loc.LocationData>? _backgroundSubscription;
  final _positionController = StreamController<Position>.broadcast();
  final loc.Location _location = loc.Location();

  Stream<Position> get positionStream => _positionController.stream;

  Future<void> startForegroundTracking() async {
    try {
      await LocationUtils.handlePermissionCheck();

      _positionSubscription?.cancel();
      _positionSubscription = LocationUtils.getPositionStream().listen(
            (position) {
          _positionController.add(position);
        },
        onError: (error) {
          _positionController.addError(
            LocationErrorHandler.handle(error),
          );
        },
      );
    } catch (e) {
      throw LocationErrorHandler.handle(e);
    }
  }

  Future<void> stopForegroundTracking() async {
    await _positionSubscription?.cancel();
    _positionSubscription = null;
  }

  Future<void> configureBackgroundTracking() async {
    try {
      // Check if background mode is supported
      final backgroundModeEnabled = await _location.isBackgroundModeEnabled();

      if (!backgroundModeEnabled) {
        // Enable background mode
        await _location.enableBackgroundMode(enable: true);
      }

      // Cancel existing subscription if any
      _backgroundSubscription?.cancel();

      // Start background location updates
      _backgroundSubscription = _location.onLocationChanged.listen(
            (loc.LocationData locationData) {
          if (locationData.latitude != null && locationData.longitude != null) {
            final position = Position(
              latitude: locationData.latitude!,
              longitude: locationData.longitude!,
              timestamp: DateTime.now(),
              accuracy: locationData.accuracy ?? 0,
              altitude: locationData.altitude ?? 0,
              altitudeAccuracy: 0,
              heading: locationData.heading ?? 0,
              headingAccuracy: 0,
              speed: locationData.speed ?? 0,
              speedAccuracy: 0,
            );
            _positionController.add(position);
          }
        },
        onError: (error) {
          _positionController.addError(
            LocationException(
              message: 'Background location error: $error',
              type: LocationErrorType.backgroundLocationFailed,
            ),
          );
        },
      );
    } catch (e) {
      throw LocationErrorHandler.handle(e);
    }
  }

  Future<void> stopBackgroundTracking() async {
    try {
      await _backgroundSubscription?.cancel();
      _backgroundSubscription = null;
      await _location.enableBackgroundMode(enable: false);
    } catch (e) {
      throw LocationErrorHandler.handle(e);
    }
  }

  void dispose() {
    _positionSubscription?.cancel();
    _backgroundSubscription?.cancel();
    _positionController.close();
  }
}