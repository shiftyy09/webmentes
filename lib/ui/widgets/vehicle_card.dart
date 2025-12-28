// lib/ui/widgets/vehicle_card.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:olajfolt_web/modellek/jarmu.dart';

class VehicleCard extends StatelessWidget {
  final Jarmu vehicle;
  final bool isSelected;
  final VoidCallback onTap;

  const VehicleCard({
    super.key,
    required this.vehicle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final numberFormatter = NumberFormat.decimalPattern('hu_HU');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      elevation: isSelected ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: isSelected
            ? BorderSide(color: theme.colorScheme.primary, width: 2)
            : BorderSide.none,
      ),
      child: ListTile(
        onTap: onTap,
        selected: isSelected,
        selectedTileColor: theme.colorScheme.primary.withOpacity(0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        title: Text(
          vehicle.licensePlate,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${vehicle.make} ${vehicle.model} (${vehicle.year})'),
            const SizedBox(height: 4),
            Text(
              '${numberFormatter.format(vehicle.mileage)} km',
              style: TextStyle(color: theme.textTheme.bodySmall?.color),
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
