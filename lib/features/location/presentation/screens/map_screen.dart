import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../../provider/location_providers.dart';
import '../widgets/location_info_card.dart';
import '../widgets/permission_dialog.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/app_settings_helper.dart';
import '../../../../core/utils/location_utils.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeLocation();
    });
  }

  Future<void> _initializeLocation() async {
    final controller = ref.read(locationControllerProvider.notifier);
    await controller.initialize();
  }

  void _updateMarker(Position position) {
    final marker = Marker(
      markerId: const MarkerId('current_location'),
      position: LatLng(position.latitude, position.longitude),
      infoWindow: const InfoWindow(title: 'Current Location'),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
    );

    setState(() {
      _markers.clear();
      _markers.add(marker);
    });
  }

  void _moveCamera(Position position) {
    if (_mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLng(
          LatLng(position.latitude, position.longitude),
        ),
      );
    }
  }

  // Helper method to build popup menu items
  List<PopupMenuEntry<String>> _buildPopupMenuItems(LocationState locationState) {
    return [
      PopupMenuItem<String>(
        value: 'toggle_background',
        child: Row(
          children: [
            Icon(
              locationState.isBackgroundTracking
                  ? Icons.stop_circle
                  : Icons.play_circle,
              color: locationState.isBackgroundTracking
                  ? Colors.red
                  : Colors.green,
            ),
            const SizedBox(width: 8),
            Text(
              locationState.isBackgroundTracking
                  ? 'Stop Background Tracking'
                  : 'Start Background Tracking',
            ),
          ],
        ),
      ),
      const PopupMenuDivider(),
      PopupMenuItem<String>(
        value: 'location_settings',
        child: const Row(
          children: [
            Icon(Icons.location_on, color: Colors.blue),
            SizedBox(width: 8),
            Text('Open Location Settings'),
          ],
        ),
      ),
      PopupMenuItem<String>(
        value: 'app_settings',
        child: const Row(
          children: [
            Icon(Icons.settings, color: Colors.grey),
            SizedBox(width: 8),
            Text('Open App Settings'),
          ],
        ),
      ),
    ];
  }

  // Handle popup menu selection
  Future<void> _handlePopupMenuSelection(String value) async {
    final controller = ref.read(locationControllerProvider.notifier);
    final locationState = ref.read(locationControllerProvider);

    switch (value) {
      case 'toggle_background':
        if (locationState.isBackgroundTracking) {
          await controller.stopBackgroundTracking();
        } else {
          await controller.startBackgroundTracking();
        }
        break;
      case 'location_settings':
        await AppSettingsHelper.openLocationSettings();
        await _initializeLocation();
        break;
      case 'app_settings':
        await AppSettingsHelper.openAppSettings();
        await _initializeLocation();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final locationState = ref.watch(locationControllerProvider);

    // Listen to location stream
    ref.listen(locationStreamProvider, (previous, next) {
      next.whenData((position) {
        final controller = ref.read(locationControllerProvider.notifier);
        controller.updatePosition(position);
        _updateMarker(position);
        _moveCamera(position);
      });
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Location Tracker'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _initializeLocation,
          ),
          PopupMenuButton<String>(
            onSelected: _handlePopupMenuSelection,
            itemBuilder: (context) => _buildPopupMenuItems(locationState),
          ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: LatLng(
                locationState.currentPosition?.latitude ?? AppConstants.defaultLatitude,
                locationState.currentPosition?.longitude ?? AppConstants.defaultLongitude,
              ),
              zoom: AppConstants.defaultZoom,
            ),
            markers: _markers,
            onMapCreated: (controller) {
              _mapController = controller;
            },
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            zoomControlsEnabled: true,
          ),
          Positioned(
            bottom: AppConstants.padding,
            left: AppConstants.padding,
            right: AppConstants.padding,
            child: LocationInfoCard(
              position: locationState.currentPosition,
              lastUpdated: locationState.lastUpdated,
              isTracking: locationState.isTracking,
              isBackgroundTracking: locationState.isBackgroundTracking,
            ),
          ),
          if (locationState.error != null)
            Positioned(
              top: AppConstants.padding,
              left: AppConstants.padding,
              right: AppConstants.padding,
              child: PermissionDialog(
                error: locationState.error!,
                onDismiss: () {
                  ref.read(locationControllerProvider.notifier).clearError();
                },
                onSettingsOpened: () {
                  // Re-check permissions when returning from settings
                  Future.delayed(const Duration(seconds: 1), () {
                    ref.read(locationControllerProvider.notifier).initialize();
                  });
                },
              ),
            ),
        ],
      ),
    );
  }
}