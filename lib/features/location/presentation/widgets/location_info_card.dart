import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/location_utils.dart';

class LocationInfoCard extends StatelessWidget {
  final Position? position;
  final DateTime? lastUpdated;
  final bool isTracking;
  final bool isBackgroundTracking;

  const LocationInfoCard({
    super.key,
    required this.position,
    required this.lastUpdated,
    required this.isTracking,
    required this.isBackgroundTracking,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: AppConstants.cardElevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.padding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with title
            Text(
              'Location Details',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            // Status indicators row - separate row to prevent overflow
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                _StatusIndicator(
                  isActive: isTracking,
                  label: 'Foreground',
                ),
                const SizedBox(width: 8),
                _StatusIndicator(
                  isActive: isBackgroundTracking,
                  label: 'Background',
                ),
              ],
            ),

            const SizedBox(height: 12),

            if (position != null) ...[
              _InfoRow(
                icon: Icons.location_on,
                label: 'Latitude',
                value: LocationUtils.formatCoordinates(position!.latitude),
              ),
              const SizedBox(height: 8),
              _InfoRow(
                icon: Icons.location_on,
                label: 'Longitude',
                value: LocationUtils.formatCoordinates(
                  position!.longitude,
                  isLatitude: false,
                ),
              ),
              const SizedBox(height: 8),
              _InfoRow(
                icon: Icons.timer,
                label: 'Updated',
                value: lastUpdated != null
                    ? DateFormat('HH:mm:ss').format(lastUpdated!)
                    : 'N/A',
              ),
              const SizedBox(height: 8),
              _InfoRow(
                icon: Icons.speed,
                label: 'Speed',
                value: '${position!.speed.toStringAsFixed(2)} m/s',
              ),
              const SizedBox(height: 8),
              _InfoRow(
                icon: Icons.vertical_align_center,
                label: 'Altitude',
                value: '${position!.altitude.toStringAsFixed(2)} m',
              ),
            ] else
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: Text('Waiting for location...'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w400),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
      ],
    );
  }
}

class _StatusIndicator extends StatelessWidget {
  final bool isActive;
  final String label;

  const _StatusIndicator({
    required this.isActive,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isActive ? Colors.green.withOpacity(0.2) : Colors.grey.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive ? Colors.green.withOpacity(0.5) : Colors.grey.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive ? Colors.green : Colors.grey,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: isActive ? Colors.green.shade700 : Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}