// lib/ui/widgets/maintenance_reminder_view.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:olajfolt_web/alap/konstansok.dart';
import 'package:olajfolt_web/modellek/jarmu.dart';
import 'package:olajfolt_web/modellek/karbantartas_bejegyzes.dart';
import 'package:olajfolt_web/providers.dart';
import 'package:olajfolt_web/services/firestore_service.dart';

class MaintenanceReminderView extends ConsumerStatefulWidget {
  final Jarmu vehicle;

  const MaintenanceReminderView({super.key, required this.vehicle});

  @override
  ConsumerState<MaintenanceReminderView> createState() => _MaintenanceReminderViewState();
}

class _MaintenanceReminderViewState extends ConsumerState<MaintenanceReminderView> {
  final TextEditingController _mileageController = TextEditingController();
  bool _isUpdating = false;
  bool _isSuccess = false;

  @override
  void initState() {
    super.initState();
    _mileageController.text = widget.vehicle.mileage.toString();
  }

  @override
  void didUpdateWidget(covariant MaintenanceReminderView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.vehicle.mileage != widget.vehicle.mileage && !_isUpdating) {
      _mileageController.text = widget.vehicle.mileage.toString();
    }
  }

  @override
  void dispose() {
    _mileageController.dispose();
    super.dispose();
  }

  Future<void> _updateMileage() async {
    final newMileage = int.tryParse(_mileageController.text.replaceAll(RegExp(r'[^0-9]'), ''));
    if (newMileage == null) return;

    if (newMileage < widget.vehicle.mileage) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Az új km nem lehet kevesebb a réginél!'), backgroundColor: Colors.red));
      return;
    }

    setState(() => _isUpdating = true);
    try {
      final firestoreService = ref.read(firestoreServiceProvider);
      final user = ref.read(authStateProvider).value;
      
      if (user != null && widget.vehicle.id != null) {
        final updatedVehicle = widget.vehicle.copyWith(mileage: newMileage);
        await firestoreService.upsertVehicle(user.uid, updatedVehicle);
        
        if (mounted) {
          setState(() {
            _isUpdating = false;
            _isSuccess = true;
          });
          
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) setState(() => _isSuccess = false);
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hiba: $e'), backgroundColor: Colors.red));
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final servicesAsync = ref.watch(servicesForSelectedVehicleProvider);
    final theme = Theme.of(context);
    final numberFormat = NumberFormat.decimalPattern('hu_HU');

    return Column(
      children: [
        Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 400,
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(50),
              boxShadow: [
                BoxShadow(
                  color: _isSuccess ? Colors.green.withOpacity(0.3) : Colors.black.withOpacity(0.05), 
                  blurRadius: _isSuccess ? 20 : 10, 
                  offset: const Offset(0, 4)
                )
              ],
              border: Border.all(
                color: _isSuccess ? Colors.green : theme.colorScheme.primary.withOpacity(0.2), 
                width: _isSuccess ? 2 : 1
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _isSuccess ? Colors.green.withOpacity(0.1) : theme.colorScheme.primary.withOpacity(0.1), 
                    shape: BoxShape.circle
                  ),
                  child: Icon(Icons.speed, size: 24, color: _isSuccess ? Colors.green : theme.colorScheme.primary),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _mileageController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                      border: InputBorder.none,
                      hintText: 'Km állás',
                      suffixText: 'km',
                    ),
                    onSubmitted: (_) => _updateMileage(),
                  ),
                ),
                const SizedBox(width: 8),
                // MODERNIZÁLT MENTÉS GOMB (NINCS FLOPI!)
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _isUpdating
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                      : IconButton(
                          key: ValueKey(_isSuccess),
                          onPressed: _updateMileage,
                          // Ha siker, akkor pipa, egyébként FELHŐ ikon (modernebb, mint a save)
                          icon: Icon(
                            _isSuccess ? Icons.check_circle : Icons.cloud_upload_outlined, 
                            size: 32
                          ),
                          color: _isSuccess ? Colors.green : theme.colorScheme.primary,
                          tooltip: 'Frissítés mentése',
                        ),
                ),
              ],
            ),
          ),
        ),

        Expanded(
          child: servicesAsync.when(
            data: (services) => GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 300,
                childAspectRatio: 1.4,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: ALL_REMINDER_SERVICE_TYPES.length,
              itemBuilder: (context, index) {
                return _buildReminderCard(context, ALL_REMINDER_SERVICE_TYPES[index], services, widget.vehicle.mileage);
              },
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, st) => const Center(child: Text('Hiba az adatok betöltésekor.')),
          ),
        ),
      ],
    );
  }

  Widget _buildReminderCard(BuildContext context, String type, List<Szerviz> services, int currentKm) {
    final theme = Theme.of(context);
    final numberFormat = NumberFormat.decimalPattern('hu_HU');
    final dateFormat = DateFormat('yyyy.MM.dd');

    Szerviz? lastService;
    try {
      final relevantServices = services.where((s) {
        final desc = s.description.toLowerCase();
        return desc.contains(type.toLowerCase()) || desc.contains('$REMINDER_PREFIX$type'.toLowerCase());
      }).toList();
      relevantServices.sort((a, b) => b.date.compareTo(a.date));
      if (relevantServices.isNotEmpty) lastService = relevantServices.first;
    } catch (e) { /* Nincs adat */ }

    final defs = SERVICE_DEFINITIONS[type] ?? {};
    final int? intervalKm = defs['intervalKm'];
    final int? intervalMonths = defs['intervalHonap'];

    double progress = 0.0;
    Color statusColor = Colors.grey;
    String statusText = 'Nincs adat';
    String detailText = 'Rögzíts szervizt';

    if (lastService != null) {
      if (intervalKm != null) {
        final kmSince = currentKm - lastService.mileage;
        final kmLeft = intervalKm - kmSince;
        progress = (kmSince / intervalKm).clamp(0.0, 1.0);
        
        if (kmLeft <= 0) { statusColor = Colors.red; statusText = 'ESEDÉKES!'; detailText = '${numberFormat.format(kmLeft.abs())} km túlcsúszás'; }
        else if (kmLeft < 2000) { statusColor = Colors.orange; statusText = 'Hamarosan'; detailText = '${numberFormat.format(kmLeft)} km van hátra'; }
        else { statusColor = Colors.green; statusText = 'Rendben'; detailText = '${numberFormat.format(kmLeft)} km van hátra'; }
      } 
      else if (intervalMonths != null) {
        final nextDate = lastService.date.add(Duration(days: intervalMonths * 30));
        final daysLeft = nextDate.difference(DateTime.now()).inDays;
        final totalDays = intervalMonths * 30;
        final daysPassed = totalDays - daysLeft;
        progress = (daysPassed / totalDays).clamp(0.0, 1.0);

        if (daysLeft <= 0) { statusColor = Colors.red; statusText = 'LEJÁRT!'; detailText = '${daysLeft.abs()} napja lejárt'; }
        else if (daysLeft < 30) { statusColor = Colors.orange; statusText = 'Hamarosan'; detailText = '$daysLeft nap van hátra'; }
        else { statusColor = Colors.green; statusText = 'Rendben'; detailText = '$daysLeft nap van hátra'; }
      }
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: statusColor.withOpacity(0.3), width: 1)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                  child: Icon(_getIconForType(type), color: statusColor, size: 24),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: statusColor, borderRadius: BorderRadius.circular(12)),
                  child: Text(statusText, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const Spacer(),
            Text(type, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), maxLines: 1, overflow: TextOverflow.ellipsis),
            if (lastService != null)
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text('Utolsó: ${dateFormat.format(lastService.date)}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ),
            const Spacer(),
            if (lastService != null) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: Text(detailText, style: TextStyle(fontSize: 12, color: statusColor, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis)),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 6,
                  backgroundColor: Colors.grey.withOpacity(0.1),
                  valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                ),
              ),
            ] else 
              const Text('Nincs rögzített adat', style: TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic)),
          ],
        ),
      ),
    );
  }

  IconData _getIconForType(String type) {
    if (type.contains('Olaj')) return Icons.oil_barrel;
    if (type.contains('Fék')) return Icons.disc_full;
    if (type.contains('szűrő')) return Icons.filter_alt;
    if (type.contains('Műszaki')) return Icons.verified;
    if (type.contains('biztosítás') || type.contains('CASCO')) return Icons.security;
    if (type.contains('matrica')) return Icons.confirmation_number;
    if (type.contains('Gyújtás')) return Icons.flash_on;
    if (type.contains('Akkumulátor')) return Icons.battery_charging_full;
    if (type.contains('Gumi')) return Icons.tire_repair;
    return Icons.build;
  }
}
