import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart' as ph;
import '../../../core/utils/location_utils.dart';
import '../data/location_repository.dart';
import '../../../core/errors/location_exceptions.dart';

final locationRepositoryProvider = Provider<LocationRepository>((ref) {
  final repository = LocationRepository();
  ref.onDispose(() => repository.dispose());
  return repository;
});

final currentPositionProvider = StateProvider<Position?>((ref) => null);
final locationErrorProvider = StateProvider<LocationException?>((ref) => null);
final isTrackingProvider = StateProvider<bool>((ref) => false);
final isBackgroundTrackingProvider = StateProvider<bool>((ref) => false);
final lastUpdatedProvider = StateProvider<DateTime?>((ref) => null);

final locationStreamProvider = StreamProvider<Position>((ref) {
  final repository = ref.watch(locationRepositoryProvider);
  return repository.positionStream;
});

final locationControllerProvider = StateNotifierProvider<LocationController, LocationState>((ref) {
  return LocationController(ref);
});

class LocationState {
  final Position? currentPosition;
  final LocationException? error;
  final bool isTracking;
  final bool isBackgroundTracking;
  final DateTime? lastUpdated;
  final bool isLocationServiceEnabled;

  const LocationState({
    this.currentPosition,
    this.error,
    this.isTracking = false,
    this.isBackgroundTracking = false,
    this.lastUpdated,
    this.isLocationServiceEnabled = true,
  });

  LocationState copyWith({
    Position? currentPosition,
    LocationException? error,
    bool? isTracking,
    bool? isBackgroundTracking,
    DateTime? lastUpdated,
    bool? isLocationServiceEnabled,
    bool clearError = false,
  }) {
    return LocationState(
      currentPosition: currentPosition ?? this.currentPosition,
      error: clearError ? null : (error ?? this.error),
      isTracking: isTracking ?? this.isTracking,
      isBackgroundTracking: isBackgroundTracking ?? this.isBackgroundTracking,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      isLocationServiceEnabled: isLocationServiceEnabled ?? this.isLocationServiceEnabled,
    );
  }
}

class LocationController extends StateNotifier<LocationState> {
  final Ref _ref;
  StreamSubscription<Position>? _positionSubscription;

  LocationController(this._ref) : super(const LocationState()) {
    _listenToPositionStream();
  }

  void _listenToPositionStream() {
    final repository = _ref.read(locationRepositoryProvider);
    _positionSubscription = repository.positionStream.listen(
          (position) {
        updatePosition(position);
      },
      onError: (error) {
        handleError(LocationErrorHandler.handle(error));
      },
    );
  }

  Future<void> initialize() async {
    try {
      // Check location services
      final isServiceEnabled = await LocationUtils.isLocationServiceEnabled();
      if (!isServiceEnabled) {
        state = state.copyWith(
          isLocationServiceEnabled: false,
          error: const LocationException(
            message: 'Location services are disabled. Please enable GPS/location services.',
            type: LocationErrorType.locationServicesDisabled,
          ),
        );
        return;
      }

      // Check permissions
      final hasPermission = await LocationUtils.handlePermissionCheck();
      if (!hasPermission) {
        return;
      }

      final repository = _ref.read(locationRepositoryProvider);
      final position = await LocationUtils.getCurrentPosition();

      state = state.copyWith(
        currentPosition: position,
        lastUpdated: DateTime.now(),
        clearError: true,
        isLocationServiceEnabled: true,
      );

      // Start foreground tracking
      await startForegroundTracking();

      // Try background tracking
      await startBackgroundTracking();

    } catch (e) {
      debugPrint('Initialize error: $e');
      state = state.copyWith(
        error: LocationErrorHandler.handle(e),
      );
    }
  }

  Future<void> startForegroundTracking() async {
    try {
      final repository = _ref.read(locationRepositoryProvider);
      await repository.startForegroundTracking();
      state = state.copyWith(isTracking: true, clearError: true);
    } catch (e) {
      state = state.copyWith(
        error: LocationErrorHandler.handle(e),
        isTracking: false,
      );
    }
  }

  Future<void> stopForegroundTracking() async {
    try {
      final repository = _ref.read(locationRepositoryProvider);
      await repository.stopForegroundTracking();
      state = state.copyWith(isTracking: false);
    } catch (e) {
      state = state.copyWith(error: LocationErrorHandler.handle(e));
    }
  }

  Future<void> startBackgroundTracking() async {
    try {
      // Check background permission
      final hasBackgroundPermission = await _checkBackgroundPermission();
      if (!hasBackgroundPermission) {
        state = state.copyWith(
          error: const LocationException(
            message: 'Background location permission is required.\n\n'
                'Please follow these steps:\n'
                '1. Tap "Open Settings" below\n'
                '2. Go to Permissions → Location\n'
                '3. Select "Allow all the time"\n'
                '4. Come back to the app',
            type: LocationErrorType.backgroundPermissionDenied,
          ),
          isBackgroundTracking: false,
        );
        return;
      }

      final repository = _ref.read(locationRepositoryProvider);
      await repository.configureBackgroundTracking();
      state = state.copyWith(isBackgroundTracking: true, clearError: true);

    } catch (e) {
      debugPrint('Background tracking error: $e');
      state = state.copyWith(
        error: LocationErrorHandler.handle(e),
        isBackgroundTracking: false,
      );
    }
  }

  Future<bool> _checkBackgroundPermission() async {
    try {
      // Check using permission_handler
      final status = await ph.Permission.locationAlways.status;

      if (status.isGranted) {
        return true;
      }

      if (status.isPermanentlyDenied) {
        return false;
      }

      // Request permission
      final result = await ph.Permission.locationAlways.request();
      return result.isGranted;

    } catch (e) {
      debugPrint('Check background permission error: $e');

      // Fallback to geolocator
      try {
        final permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.always) {
          return true;
        }

        final requested = await Geolocator.requestPermission();
        return requested == LocationPermission.always;
      } catch (geoError) {
        debugPrint('Geolocator background permission error: $geoError');
        return false;
      }
    }
  }

  Future<void> stopBackgroundTracking() async {
    try {
      final repository = _ref.read(locationRepositoryProvider);
      await repository.stopBackgroundTracking();
      state = state.copyWith(isBackgroundTracking: false);
    } catch (e) {
      state = state.copyWith(error: LocationErrorHandler.handle(e));
    }
  }

  void updatePosition(Position position) {
    state = state.copyWith(
      currentPosition: position,
      lastUpdated: DateTime.now(),
      clearError: true,
    );
  }

  void handleError(LocationException error) {
    state = state.copyWith(error: error);
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  Future<void> checkLocationService() async {
    final isEnabled = await LocationUtils.isLocationServiceEnabled();
    state = state.copyWith(
      isLocationServiceEnabled: isEnabled,
      error: isEnabled ? null : const LocationException(
        message: 'Location services are disabled',
        type: LocationErrorType.locationServicesDisabled,
      ),
    );
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    super.dispose();
  }
}