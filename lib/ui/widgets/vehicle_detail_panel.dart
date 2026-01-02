// lib/ui/widgets/vehicle_detail_panel.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:olajfolt_web/modellek/jarmu.dart';
import 'package:olajfolt_web/providers.dart';
import 'package:olajfolt_web/services/firestore_service.dart';
import 'package:olajfolt_web/services/pdf_service.dart';
import 'package:olajfolt_web/ui/widgets/service_list_view.dart';
import 'package:olajfolt_web/ui/widgets/vehicle_data_view.dart';
import 'package:olajfolt_web/ui/widgets/vehicle_stats_view.dart';
import 'package:olajfolt_web/ui/widgets/maintenance_reminder_view.dart';

class VehicleDetailPanel extends ConsumerStatefulWidget {
  final Function(Jarmu) onEditVehicle;

  const VehicleDetailPanel({super.key, required this.onEditVehicle});

  @override
  ConsumerState<VehicleDetailPanel> createState() => _VehicleDetailPanelState();
}

class _VehicleDetailPanelState extends ConsumerState<VehicleDetailPanel>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  Future<void> _deleteVehicle(BuildContext context, WidgetRef ref, Jarmu vehicle) async {
     final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Jármű törlése'),
        content: Text('Biztosan törölni szeretnéd a(z) ${vehicle.licensePlate} rendszámú járművet és annak minden adatát? A művelet nem vonható vissza.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Mégse')),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true), 
            child: Text('Törlés', style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        ],
      ),
    );

    if (confirmed ?? false) {
      final firestoreService = ref.read(firestoreServiceProvider);
      final user = ref.read(authStateProvider).value;
      if (user != null && vehicle.id != null) {
        ref.read(selectedVehicleIdProvider.notifier).state = null;
        await firestoreService.deleteVehicle(user.uid, vehicle.id!);
      }
    }
  }

  Future<void> _exportPdf(Jarmu vehicle) async {
    final firestoreService = ref.read(firestoreServiceProvider);
    final user = ref.read(authStateProvider).value;
    
    if (user != null && vehicle.id != null) {
      final services = await firestoreService.watchServices(user.uid, vehicle.id!).first;
      final pdfService = PdfService();
      await pdfService.generateAndDownloadPdf(vehicle, services);
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedVehicleId = ref.watch(selectedVehicleIdProvider);
    final vehiclesAsync = ref.watch(vehiclesProvider);

    if (selectedVehicleId == null) {
      return const Center(child: Text('Válassz egy járművet a listából.'));
    }

    return vehiclesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Hiba a jármű betöltésekor: $err')),
      data: (vehicles) {
        final vehicle = vehicles.firstWhere(
          (v) => v.id == selectedVehicleId,
          orElse: () => Jarmu.empty(),
        );

        if (vehicle.id == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ref.read(selectedVehicleIdProvider.notifier).state = null;
          });
          return const Center(child: Text('A jármű nem található. Lehet, hogy törölték.'));
        }

        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          vehicle.licensePlate,
                          style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${vehicle.make} ${vehicle.model} (${vehicle.year})',
                          style: theme.textTheme.titleMedium,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        tooltip: 'Jármű adatainak szerkesztése',
                        onPressed: () => widget.onEditVehicle(vehicle),
                      ),
                      IconButton(
                        icon: Icon(Icons.delete_outline, color: theme.colorScheme.error),
                        tooltip: 'Jármű törlése',
                        onPressed: () => _deleteVehicle(context, ref, vehicle),
                      ),
                    ],
                  )
                ],
              ),
            ),
            const Divider(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Container(
                height: 45, // Kicsit magasabb a kényelemért
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: TabBar(
                  controller: _tabController,
                  // JAVÍTVA: A teljes tabot kitöltő indicator
                  indicatorSize: TabBarIndicatorSize.tab, 
                  indicator: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: isDark ? Colors.grey[800] : Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      )
                    ]
                  ),
                  // JAVÍTVA: Kontrasztos fekete/fehér szöveg
                  labelColor: isDark ? Colors.white : Colors.black,
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                  unselectedLabelColor: isDark ? Colors.grey[400] : Colors.grey[700],
                  dividerColor: Colors.transparent,
                  tabs: const [
                    Tab(text: 'EMLÉKEZTETŐK'),
                    Tab(text: 'NAPLÓ'),
                    Tab(text: 'ADATLAP'),
                    Tab(text: 'STATISZTIKA'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  MaintenanceReminderView(vehicle: vehicle),
                  const ServiceListView(),
                  VehicleDataView(
                    vehicle: vehicle, 
                    onExportPdf: () => _exportPdf(vehicle),
                  ),
                  const VehicleStatsView(),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
