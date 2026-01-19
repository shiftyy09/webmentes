// lib/ui/widgets/service_list_view.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:olajfolt_web/modellek/jarmu.dart';
import 'package:olajfolt_web/modellek/karbantartas_bejegyzes.dart';
import 'package:olajfolt_web/providers.dart';
import 'package:olajfolt_web/ui/dialogs/service_editor_dialog.dart';
import 'package:olajfolt_web/ui/dialogs/fueling_dialog.dart';
import 'package:olajfolt_web/ui/widgets/service_list_item.dart';
import 'package:olajfolt_web/ui/widgets/success_overlay.dart';
import 'package:olajfolt_web/alap/konstansok.dart';

class ServiceListView extends ConsumerWidget {
  final Jarmu? vehicle;

  const ServiceListView({super.key, this.vehicle});

  Future<void> _openEditor(BuildContext context, WidgetRef ref, {Szerviz? service}) async {
    final firestoreService = ref.read(firestoreServiceProvider);
    final user = ref.read(authStateProvider).value;
    final selectedVehicleId = ref.read(selectedVehicleIdProvider);
    const vehicleNumericId = 0; 

    if (user == null || selectedVehicleId == null) return;

    final result = await showDialog<Szerviz?>(
      context: context,
      builder: (context) => ServiceEditorDialog(service: service),
    );

    if (result != null) {
      await firestoreService.upsertService(user.uid, selectedVehicleId, vehicleNumericId, result);
      if (context.mounted) {
        SuccessOverlay.show(context: context, message: service == null ? 'Szerviz hozzáadva!' : 'Szerviz frissítve!');
      }
    }
  }

  Future<void> _openFuelingDialog(BuildContext context, WidgetRef ref, List<Szerviz> allServices) async {
    final firestoreService = ref.read(firestoreServiceProvider);
    final user = ref.read(authStateProvider).value;
    final selectedVehicleId = ref.read(selectedVehicleIdProvider);
    const vehicleNumericId = 0; 

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
      await firestoreService.upsertService(user.uid, selectedVehicleId, vehicleNumericId, result);
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
        content: const Text('Biztosan törölni szeretnéd ezt a bejegyzést?'),
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
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final servicesAsync = ref.watch(servicesForSelectedVehicleProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            color: theme.scaffoldBackgroundColor,
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 45,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey[900] : Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TabBar(
                      indicatorSize: TabBarIndicatorSize.tab,
                      indicator: BoxDecoration(
                        color: theme.colorScheme.primary, 
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2))
                        ]
                      ),
                      labelColor: Colors.white,
                      unselectedLabelColor: Colors.grey,
                      labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                      dividerColor: Colors.transparent,
                      tabs: const [
                        Tab(text: 'SZERVIZNAPLÓ', icon: Icon(Icons.build)),
                        Tab(text: 'TANKOLÁSI NAPLÓ', icon: Icon(Icons.local_gas_station)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 24),
                
                Wrap(
                  spacing: 16,
                  children: [
                    ElevatedButton.icon(
                      icon: const Icon(Icons.local_gas_station),
                      label: const Text('Tankolás hozzáadása'),
                      onPressed: () {
                        final services = servicesAsync.value ?? [];
                        _openFuelingDialog(context, ref, services);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark ? Colors.grey[800] : Colors.white,
                        foregroundColor: isDark ? Colors.white : Colors.black,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text('Szerviz hozzáadása'),
                      onPressed: () => _openEditor(context, ref),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          Expanded(
            child: servicesAsync.when(
              data: (allServices) {
                // JAVÍTÁS: Kőkemény szűrés az emlékeztető alapokra!
                final services = allServices.where((s) => 
                  !s.description.toLowerCase().contains('tankolás') && 
                  !s.description.startsWith(REMINDER_PREFIX)
                ).toList();
                
                final refuelings = allServices.where((s) => s.description.toLowerCase().contains('tankolás')).toList();

                return TabBarView(
                  children: [
                    services.isEmpty
                        ? const Center(child: Text('Nincsenek szervizbejegyzések.'))
                        : GridView.builder(
                            padding: const EdgeInsets.all(16.0),
                            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                              maxCrossAxisExtent: 300, 
                              childAspectRatio: 1.4,   
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                            ),
                            itemCount: services.length,
                            itemBuilder: (context, index) {
                              return ServiceListItem(
                                service: services[index],
                                onEdit: (s) => _openEditor(context, ref, service: s),
                                onDelete: (s) => _deleteService(context, ref, s),
                              );
                            },
                          ),

                    refuelings.isEmpty
                        ? const Center(child: Text('Nincsenek tankolási adatok.'))
                        : GridView.builder(
                            padding: const EdgeInsets.all(16.0),
                            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                              maxCrossAxisExtent: 300, 
                              childAspectRatio: 1.4,   
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                            ),
                            itemCount: refuelings.length,
                            itemBuilder: (context, index) {
                              return ServiceListItem(
                                service: refuelings[index],
                                onEdit: (s) => _openEditor(context, ref, service: s),
                                onDelete: (s) => _deleteService(context, ref, s),
                                isRefueling: true,
                              );
                            },
                          ),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Hiba: $err')),
            ),
          ),
        ],
      ),
    );
  }
}
