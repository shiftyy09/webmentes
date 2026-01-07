// lib/ui/widgets/vehicle_list_view.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:olajfolt_web/modellek/jarmu.dart';
import 'package:olajfolt_web/modellek/karbantartas_bejegyzes.dart';
import 'package:olajfolt_web/providers.dart';
import 'package:olajfolt_web/ui/dialogs/vehicle_editor_dialog.dart';
import 'package:olajfolt_web/ui/widgets/success_overlay.dart'; // ÚJ IMPORT

class VehicleListView extends ConsumerWidget {
  final VoidCallback onAddVehicle;

  const VehicleListView({super.key, required this.onAddVehicle});

  Future<void> _addNewVehicle(BuildContext context, WidgetRef ref) async {
    final firestoreService = ref.read(firestoreServiceProvider);
    final user = ref.read(authStateProvider).value;

    if (user == null) return;

    final result = await showDialog<Map<String, dynamic>?>(
      context: context,
      builder: (context) => const VehicleEditorDialog(),
    );

    if (result != null) {
      final Jarmu vehicleToSave = result['vehicle'];
      final List<Szerviz> initialServices = result['services'];
      
      final vehicleNumericId = await firestoreService.upsertVehicle(user.uid, vehicleToSave);

      if (initialServices.isNotEmpty) {
        for (var service in initialServices) {
          await firestoreService.upsertService(user.uid, vehicleToSave.licensePlate, vehicleNumericId, service);
        }
      }
      
      if (context.mounted) {
         SuccessOverlay.show(context: context, message: 'Jármű sikeresen hozzáadva!');
      }

      ref.read(selectedVehicleIdProvider.notifier).state = vehicleToSave.licensePlate;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vehiclesAsync = ref.watch(vehiclesProvider);
    final theme = Theme.of(context);
    final selectedVehicleId = ref.watch(selectedVehicleIdProvider);

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            border: Border(bottom: BorderSide(color: Colors.grey.withOpacity(0.2))),
          ),
          child: SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: () => _addNewVehicle(context, ref),
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('ÚJ JÁRMŰ FELVÉTELE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: Colors.white,
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ),
        Expanded(
          child: vehiclesAsync.when(
            data: (vehicles) {
              if (vehicles.isEmpty) {
                return const Center(child: Text('Nincs rögzített jármű.'));
              }
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: vehicles.length,
                itemBuilder: (context, index) {
                  final vehicle = vehicles[index];
                  final isSelected = vehicle.id == selectedVehicleId;
                  
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                           ref.read(selectedVehicleIdProvider.notifier).state = vehicle.id;
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isSelected ? theme.colorScheme.primary.withOpacity(0.1) : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? theme.colorScheme.primary : Colors.transparent,
                              width: 2,
                            ),
                            boxShadow: isSelected 
                                ? [] 
                                : [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))],
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: isSelected ? theme.colorScheme.primary : Colors.grey[200],
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.directions_car, color: isSelected ? Colors.white : Colors.grey, size: 24),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      vehicle.licensePlate,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: isSelected ? theme.colorScheme.primary : Colors.black87,
                                      ),
                                    ),
                                    Text(
                                      '${vehicle.make} ${vehicle.model}',
                                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                                    ),
                                  ],
                                ),
                              ),
                              if (isSelected)
                                Icon(Icons.arrow_forward_ios, size: 16, color: theme.colorScheme.primary),
                            ],
                          ),
                        ),
                      ),
                    ),
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
