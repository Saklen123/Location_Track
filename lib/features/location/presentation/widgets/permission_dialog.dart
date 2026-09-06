import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart' as ph;
import '../../../../core/errors/location_exceptions.dart';
import '../../../../core/utils/app_settings_helper.dart';

class PermissionDialog extends StatelessWidget {
  final LocationException error;
  final VoidCallback onDismiss;
  final VoidCallback? onSettingsOpened;

  const PermissionDialog({
    super.key,
    required this.error,
    required this.onDismiss,
    this.onSettingsOpened,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.red.shade50,
      elevation: 4,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning_amber, color: Colors.red.shade700, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _getTitle(),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.red.shade700,
                      fontSize: 16,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: onDismiss,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              error.message,
              style: const TextStyle(fontSize: 14, height: 1.4),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: _buildButtons(context),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildButtons(BuildContext context) {
    switch (error.type) {
      case LocationErrorType.permissionPermanentlyDenied:
      case LocationErrorType.backgroundPermissionDenied:
        return [
          TextButton(
            onPressed: onDismiss,
            child: const Text('Cancel'),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            icon: const Icon(Icons.settings, size: 18),
            label: const Text('Open Settings'),
            onPressed: () async {
              await AppSettingsHelper.openAppSettings();
              onSettingsOpened?.call();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ];

      case LocationErrorType.locationServicesDisabled:
        return [
          TextButton(
            onPressed: onDismiss,
            child: const Text('Cancel'),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            icon: const Icon(Icons.location_on, size: 18),
            label: const Text('Enable Location'),
            onPressed: () async {
              await AppSettingsHelper.openLocationSettings();
              onSettingsOpened?.call();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ];

      case LocationErrorType.permissionDenied:
        return [
          TextButton(
            onPressed: onDismiss,
            child: const Text('Cancel'),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            icon: const Icon(Icons.location_on, size: 18),
            label: const Text('Allow Location'),
            onPressed: () async {
              await AppSettingsHelper.requestLocationPermission();
              onSettingsOpened?.call();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ];

      default:
        return [
          TextButton(
            onPressed: onDismiss,
            child: const Text('Dismiss'),
          ),
        ];
    }
  }

  String _getTitle() {
    switch (error.type) {
      case LocationErrorType.permissionDenied:
        return 'Location Permission Needed';
      case LocationErrorType.permissionPermanentlyDenied:
        return 'Permission Permanently Denied';
      case LocationErrorType.backgroundPermissionDenied:
        return 'Background Permission Required';
      case LocationErrorType.locationServicesDisabled:
        return 'Location Services Disabled';
      case LocationErrorType.backgroundLocationFailed:
        return 'Background Location Error';
      default:
        return 'Location Error';
    }
  }
}