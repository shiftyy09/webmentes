// lib/ui/widgets/vehicle_detail_panel.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:olajfolt_web/modellek/jarmu.dart';
import 'package:olajfolt_web/modellek/karbantartas_bejegyzes.dart';
import 'package:olajfolt_web/providers.dart';
import 'package:olajfolt_web/services/firestore_service.dart';
import 'package:olajfolt_web/services/pdf_service.dart';
import 'package:olajfolt_web/ui/widgets/service_list_view.dart';
import 'package:olajfolt_web/ui/widgets/vehicle_data_view.dart';
import 'package:olajfolt_web/ui/widgets/vehicle_stats_view.dart';
import 'package:olajfolt_web/ui/widgets/maintenance_reminder_view.dart';
import 'package:olajfolt_web/alap/konstansok.dart';

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

  void _showArchiveDialog(BuildContext context, List<Szerviz> allServices) {
    final reminders = allServices.where((s) => s.description.startsWith(REMINDER_PREFIX)).toList();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Row(
          children: [
            Icon(Icons.inventory_2_outlined, color: Colors.amber),
            SizedBox(width: 12),
            Text('Rendszer-archívum', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: SizedBox(
          width: 400,
          child: reminders.isEmpty 
            ? const Text('Nincsenek archivált rendszeradatok.', style: TextStyle(color: Colors.white54))
            : ListView.separated(
                shrinkWrap: true,
                itemCount: reminders.length,
                separatorBuilder: (_, __) => const Divider(color: Colors.white10),
                itemBuilder: (context, index) {
                  final r = reminders[index];
                  return ListTile(
                    dense: true,
                    leading: const Icon(Icons.lock_outline, size: 16, color: Colors.white24),
                    title: Text(r.description.replaceFirst(REMINDER_PREFIX, ''), style: const TextStyle(color: Colors.white70)),
                    subtitle: Text('${DateFormat('yyyy.MM.dd').format(r.date)} • ${NumberFormat.decimalPattern('hu_HU').format(r.mileage)} km', style: const TextStyle(color: Colors.white24)),
                  );
                },
              ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Bezárás', style: TextStyle(color: Colors.amber))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedVehicleId = ref.watch(selectedVehicleIdProvider);
    final vehiclesAsync = ref.watch(vehiclesProvider);
    final servicesAsync = ref.watch(servicesForSelectedVehicleProvider);

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
          return const Center(child: Text('A jármű nem található.'));
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
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${vehicle.make} ${vehicle.model} (${vehicle.year})',
                          style: theme.textTheme.titleMedium,
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      // RAFAKÓS: Itt a doboz ikon a fejlécben!
                      if (servicesAsync.hasValue)
                        IconButton(
                          icon: const Icon(Icons.inventory_2_outlined, color: Colors.amber),
                          tooltip: 'Rendszer-archívum (Zárt adatok)',
                          onPressed: () => _showArchiveDialog(context, servicesAsync.value!),
                        ),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        tooltip: 'Jármű szerkesztése',
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
                height: 45,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicatorSize: TabBarIndicatorSize.tab, 
                  indicator: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: isDark ? Colors.grey[800] : Colors.white,
                  ),
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
