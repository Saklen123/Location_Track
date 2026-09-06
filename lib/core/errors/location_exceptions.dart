class LocationException implements Exception {
  final String message;
  final LocationErrorType type;

  const LocationException({
    required this.message,
    required this.type,
  });

  @override
  String toString() => message;
}

enum LocationErrorType {
  permissionDenied,
  permissionPermanentlyDenied,
  locationServicesDisabled,
  locationUpdateFailed,
  backgroundLocationFailed,
  backgroundPermissionDenied,
  unknown,
}

class LocationErrorHandler {
  static LocationException handle(dynamic error) {
    if (error is LocationException) {
      return error;
    }

    // Check for specific platform exceptions
    final errorString = error.toString().toLowerCase();

    if (errorString.contains('background') && errorString.contains('permission')) {
      return const LocationException(
        message: 'Background location permission is required. Please enable "Allow all the time" in app settings.',
        type: LocationErrorType.backgroundPermissionDenied,
      );
    }

    if (errorString.contains('permission') && errorString.contains('denied')) {
      return const LocationException(
        message: 'Location permission denied. Please enable it in settings.',
        type: LocationErrorType.permissionDenied,
      );
    }

    return LocationException(
      message: 'An unexpected error occurred: $error',
      type: LocationErrorType.unknown,
    );
  }
}