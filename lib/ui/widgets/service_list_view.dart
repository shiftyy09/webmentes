// lib/ui/widgets/service_list_view.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:olajfolt_web/modellek/jarmu.dart';
import 'package:olajfolt_web/modellek/karbantartas_bejegyzes.dart';
import 'package:olajfolt_web/providers.dart';
import 'package:olajfolt_web/ui/dialogs/service_editor_dialog.dart';
import 'package:olajfolt_web/ui/dialogs/fueling_dialog.dart';
import 'package:olajfolt_web/ui/widgets/service_list_item.dart';
import 'package:olajfolt_web/ui/widgets/success_overlay.dart'; // ÚJ IMPORT

class ServiceListView extends ConsumerWidget {
  final Jarmu? vehicle;

  const ServiceListView({super.key, this.vehicle});

  Future<void> _openEditor(BuildContext context, WidgetRef ref, {Szerviz? service}) async {
    final firestoreService = ref.read(firestoreServiceProvider);
    final user = ref.read(authStateProvider).value;
    final selectedVehicleId = ref.read(selectedVehicleIdProvider);

    if (user == null || selectedVehicleId == null) return;

    final result = await showDialog<Szerviz?>(
      context: context,
      builder: (context) => ServiceEditorDialog(service: service),
    );

    if (result != null) {
      await firestoreService.upsertService(user.uid, selectedVehicleId, result);
      if (context.mounted) {
        SuccessOverlay.show(context: context, message: service == null ? 'Szerviz hozzáadva!' : 'Szerviz frissítve!');
      }
    }
  }

  Future<void> _openFuelingDialog(BuildContext context, WidgetRef ref, List<Szerviz> allServices) async {
    final firestoreService = ref.read(firestoreServiceProvider);
    final user = ref.read(authStateProvider).value;
    final selectedVehicleId = ref.read(selectedVehicleIdProvider);

    if (user == null || selectedVehicleId == null) return;

    int? lastOdometer;
    final sortedServices = List<Szerviz>.from(allServices);
    sortedServices.sort((a, b) => b.date.compareTo(a.date));

    for (var s in sortedServices) {
      if (s.description.toLowerCase().contains('tankolás')) {
        lastOdometer = s.mileage;
        break;
      }
    }

    final result = await showDialog<Szerviz?>(
      context: context,
      builder: (context) => FuelingDialog(lastOdometer: lastOdometer),
    );

    if (result != null) {
      await firestoreService.upsertService(user.uid, selectedVehicleId, result);
      if (context.mounted) {
        SuccessOverlay.show(context: context, message: 'Tankolás rögzítve!');
      }
    }
  }

  Future<void> _deleteService(BuildContext context, WidgetRef ref, Szerviz service) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Törlés megerősítése'),
        content: const Text('Biztosan törölni szeretnéd ezt a szervizbejegyzést?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Mégse')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Törlés')),
        ],
      ),
    );

    if (confirmed ?? false) {
      final firestoreService = ref.read(firestoreServiceProvider);
      final user = ref.read(authStateProvider).value;
      final selectedVehicleId = ref.read(selectedVehicleIdProvider);
      if (user != null && selectedVehicleId != null && service.id != null) {
        await firestoreService.deleteService(user.uid, selectedVehicleId, service.id!);
        // Törlésnél nem szokás ekkora animációt, de egy SnackBar jól jöhet, vagy hagyjuk némán.
        // A kérés "mentésnél hozzáadásnál" volt, így a törlést hagyom.
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final servicesAsync = ref.watch(servicesForSelectedVehicleProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Wrap(
            spacing: 16,
            runSpacing: 12,
            alignment: WrapAlignment.start,
            children: [
              SizedBox(
                width: 250,
                height: 50,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.local_gas_station, size: 24),
                  label: const Text('Tankolás hozzáadása', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  onPressed: () {
                    final services = servicesAsync.value ?? [];
                    _openFuelingDialog(context, ref, services);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              SizedBox(
                width: 250,
                height: 50,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.add, size: 28),
                  label: const Text('Szerviz hozzáadása', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  onPressed: () => _openEditor(context, ref),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? Colors.grey[800] : Colors.white,
                    foregroundColor: isDark ? Colors.white : Colors.black,
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ),
        
        Expanded(
          child: servicesAsync.when(
            data: (services) {
              if (services.isEmpty) {
                return const Center(child: Text('Ehhez a járműhöz még nincsenek szervizbejegyzések.'));
              }
              return GridView.builder(
                padding: const EdgeInsets.all(16.0),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 300, 
                  childAspectRatio: 1.4,   
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: services.length,
                itemBuilder: (context, index) {
                  final service = services[index];
                  return ServiceListItem(
                    service: service,
                    onEdit: (s) => _openEditor(context, ref, service: s),
                    onDelete: (s) => _deleteService(context, ref, s),
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
