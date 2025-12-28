// lib/ui/widgets/vehicle_list_view.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:olajfolt_web/modellek/jarmu.dart';
import 'package:olajfolt_web/providers.dart';
import 'package:olajfolt_web/ui/widgets/vehicle_card.dart';

class VehicleListView extends ConsumerWidget {
  final VoidCallback onAddVehicle;

  const VehicleListView({super.key, required this.onAddVehicle});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vehiclesAsync = ref.watch(vehiclesProvider);
    final theme = Theme.of(context);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('Új jármű hozzáadása'),
            onPressed: onAddVehicle, // A HomePage-től kapott metódus hívása
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        Expanded(
          child: vehiclesAsync.when(
            data: (vehicles) {
              if (vehicles.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      'Még nincsenek járművek. Adj hozzá egyet a fenti gombbal!',
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }

              final selectedVehicleId = ref.watch(selectedVehicleIdProvider);

              return ListView.builder(
                padding: const EdgeInsets.only(bottom: 16),
                itemCount: vehicles.length,
                itemBuilder: (context, index) {
                  final vehicle = vehicles[index];
                  return VehicleCard(
                    vehicle: vehicle,
                    isSelected: selectedVehicleId == vehicle.id,
                    onTap: () {
                      ref.read(selectedVehicleIdProvider.notifier).state = vehicle.id;
                    },
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('Hiba: $err')),
          ),
        ),
      ],
    );
  }
}
