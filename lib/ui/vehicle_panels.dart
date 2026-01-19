// lib/ui/vehicle_panels.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../providers.dart';
import '../modellek/jarmu.dart';
import '../modellek/karbantartas_bejegyzes.dart';
import '../services/firestore_service.dart';
import '../alap/konstansok.dart';

// --- BAL OLDALI JÁRMŰLISTA ---
class VehicleListPanel extends ConsumerWidget {
  const VehicleListPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vehiclesAsync = ref.watch(vehiclesProvider);
    final user = ref.watch(authStateProvider).value;
    final fs = ref.watch(firestoreServiceProvider);
    final selectedId = ref.watch(selectedVehicleIdProvider);

    return Container(
      color: const Color(0xFF151521),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.directions_car, color: Colors.white70),
                const SizedBox(width: 8),
                const Text(
                  'Járműveim',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const Spacer(),
                IconButton(
                  tooltip: 'Új jármű',
                  icon: const Icon(Icons.add_circle, color: Colors.orange),
                  onPressed: user == null
                      ? null
                      : () async {
                          final result = await showDialog<Jarmu>(
                            context: context,
                            builder: (context) => const VehicleDialog(),
                          );
                          if (result != null && user.uid.isNotEmpty) {
                            await fs.upsertVehicle(user.uid, result);
                          }
                        },
                ),
              ],
            ),
            const Divider(height: 24),
            Expanded(
              child: vehiclesAsync.when(
                data: (vehicles) {
                  if (vehicles.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                           Icon(Icons.search_off, size: 40, color: Colors.white30),
                           SizedBox(height: 16),
                           Text(
                            'Még nincs jármű felvéve.\nKattints a + gombra!',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                    );
                  }
                  return ListView.builder(
                    itemCount: vehicles.length,
                    itemBuilder: (context, index) {
                      final v = vehicles[index];
                      final selected = v.id == selectedId;
                      return Card(
                        elevation: selected ? 4 : 0,
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        color: selected ? Colors.orange.withOpacity(0.2) : Colors.grey.withOpacity(0.1),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: selected ? Colors.orange : Colors.grey.shade700,
                            child: Text(v.make.isNotEmpty ? v.make[0] : '?', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                          title: Text('${v.make} ${v.model}'),
                          subtitle: Text(v.licensePlate),
                          onTap: () {
                            ref.read(selectedVehicleIdProvider.notifier).state = v.id;
                          },
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, st) => Center(child: Text('Hiba a járművek betöltésekor: $e')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- JOBB OLDALI RÉSZLETEZŐ/DASHBOARD ---
class VehicleDetailPanel extends ConsumerWidget {
  const VehicleDetailPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).value;
    final vehiclesAsync = ref.watch(vehiclesProvider);
    final selectedId = ref.watch(selectedVehicleIdProvider);

    if (user == null) return const Center(child: Text('Nincs bejelentkezett felhasználó.'));
    if (selectedId == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.arrow_back, size: 40, color: Colors.white30),
            SizedBox(height: 16),
            Text(
              'Üdv az Olajfolt Web felületén!\nVálassz egy járművet bal oldalt,\nvagy hozz létre egy újat.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.white70),
            ),
          ],
        ),
      );
    }
    
    final vehicles = vehiclesAsync.asData?.value ?? [];
    final selectedVehicle = vehicles.firstWhere((v) => v.id == selectedId, orElse: () => Jarmu(licensePlate: '', make: '', model: '', year: 0, mileage: 0));
    if(selectedVehicle.id == null) return const Center(child: CircularProgressIndicator());


    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _VehicleHeader(selectedVehicle),
          const SizedBox(height: 24),
          _StatisticsSection(selectedVehicle.id!),
          const SizedBox(height: 32),
          _ServiceLogSection(selectedVehicle),
        ],
      ),
    );
  }
}


// --- FŐBB SZEKCIÓK WIDGETJEI ---

class _VehicleHeader extends ConsumerWidget {
  final Jarmu vehicle;
  const _VehicleHeader(this.vehicle, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).value!;
    final fs = ref.watch(firestoreServiceProvider);
    final servicesAsync = ref.watch(servicesForSelectedVehicleProvider);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${vehicle.make} ${vehicle.model}',
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              '${vehicle.licensePlate} • ${vehicle.year} • ${NumberFormat('#,###', 'hu_HU').format(vehicle.mileage)} km',
              style: const TextStyle(fontSize: 16, color: Colors.white70),
            ),
          ],
        ),
        const Spacer(),
        // RAFAKÓS MEGOLDÁS: Rendszer-archívum gomb a fejlécben
        servicesAsync.when(
          data: (services) {
            final reminders = services.where((s) => s.description.startsWith(REMINDER_PREFIX)).toList();
            if (reminders.isEmpty) return const SizedBox.shrink();
            return IconButton(
              tooltip: 'Rendszer-archívum & Szinkron adatok',
              icon: const Icon(Icons.inventory_2_outlined, color: Colors.white24),
              onPressed: () => _showSystemRecordsDialog(context, reminders),
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        ),
        const SizedBox(width: 8),
        TextButton.icon(
          icon: const Icon(Icons.edit, size: 16),
          label: const Text('Szerkesztés'),
          onPressed: () async {
            final result = await showDialog<Jarmu>(
              context: context,
              builder: (context) => VehicleDialog(initial: vehicle),
            );
            if (result != null) await fs.upsertVehicle(user.uid, result);
          },
        ),
        const SizedBox(width: 8),
        TextButton.icon(
          icon: const Icon(Icons.delete, size: 16),
          label: const Text('Törlés'),
          style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
          onPressed: () async {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Jármű törlése'),
                content: const Text('Biztosan törlöd a járművet és az összes szervizbejegyzést?'),
                actions: [
                  TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Mégse')),
                  FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Törlés')),
                ],
              ),
            );
            if (confirm == true) {
              await fs.deleteVehicle(user.uid, vehicle.id!);
              ref.read(selectedVehicleIdProvider.notifier).state = null;
            }
          },
        ),
      ],
    );
  }

  void _showSystemRecordsDialog(BuildContext context, List<Szerviz> reminders) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Row(
          children: [
            Icon(Icons.lock_outline, color: Colors.amber, size: 20),
            SizedBox(width: 10),
            Text('Rendszer-archívum', style: TextStyle(color: Colors.white, fontSize: 18)),
          ],
        ),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Ezek az adatok a mobil app emlékeztetőinek alapjai. Itt nem szerkeszthetők.', 
                style: TextStyle(color: Colors.white38, fontSize: 12)),
              const SizedBox(height: 16),
              ...reminders.map((r) => ListTile(
                dense: true,
                title: Text(r.description.replaceFirst(REMINDER_PREFIX, ''), style: const TextStyle(color: Colors.white70)),
                subtitle: Text('${DateFormat('yyyy.MM.dd').format(r.date)} • ${NumberFormat('#,###', 'hu_HU').format(r.mileage)} km', 
                  style: const TextStyle(color: Colors.white24, fontSize: 11)),
                trailing: const Icon(Icons.check_circle_outline, color: Colors.green, size: 16),
              )).toList(),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Bezárás', style: TextStyle(color: Colors.amber))),
        ],
      ),
    );
  }
}

class _StatisticsSection extends ConsumerWidget {
  final String vehicleId;
  const _StatisticsSection(this.vehicleId, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final servicesAsync = ref.watch(servicesForSelectedVehicleProvider);

    return servicesAsync.when(
      data: (services) {
        if (services.isEmpty) return const SizedBox.shrink();

        double totalCost = 0;
        double fuelCost = 0;
        int actualServiceCount = 0;

        for (final s in services) {
          final isReminder = s.description.startsWith(REMINDER_PREFIX);
          if (isReminder) continue;

          totalCost += s.cost;
          actualServiceCount++;
          if (s.description.toLowerCase().contains('tankolás')) {
            fuelCost += s.cost;
          }
        }

        return Wrap(
          spacing: 24,
          runSpacing: 24,
          children: [
            _StatCard(
              icon: Icons.attach_money,
              label: 'Összes Költség',
              value: '${NumberFormat.currency(locale: 'hu_HU', symbol: 'Ft', decimalDigits: 0).format(totalCost)}',
              color: Colors.green,
            ),
            _StatCard(
              icon: Icons.build,
              label: 'Szervizek Száma',
              value: '$actualServiceCount db',
              color: Colors.blue,
            ),
            _StatCard(
              icon: Icons.local_gas_station,
              label: 'Üzemanyagra Költve',
              value: '${NumberFormat.currency(locale: 'hu_HU', symbol: 'Ft', decimalDigits: 0).format(fuelCost)}',
              color: Colors.orange,
            ),
          ],
        );
      },
      loading: () => const Center(child: Text('Statisztika töltése...', style: TextStyle(color: Colors.white30))),
      error: (e, st) => const SizedBox.shrink(),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({required this.icon, required this.label, required this.value, required this.color, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF181824),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            backgroundColor: color.withOpacity(0.2),
            foregroundColor: color,
            child: Icon(icon),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: Colors.white70, fontSize: 14)),
              Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }
}

class _ServiceLogSection extends ConsumerWidget {
  final Jarmu vehicle;
  const _ServiceLogSection(this.vehicle, {super.key});
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).value!;
    final fs = ref.watch(firestoreServiceProvider);
    final servicesAsync = ref.watch(servicesForSelectedVehicleProvider);
    final vehicleNumericId = int.tryParse(vehicle.id ?? '') ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('Szerviznapló', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
            const Spacer(),
            FilledButton.icon(
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Új Bejegyzés'),
              onPressed: () async {
                final result = await showDialog<Szerviz>(context: context, builder: (context) => const ServiceDialog());
                if (result != null) {
                  await fs.upsertService(user.uid, vehicle.licensePlate, vehicleNumericId, result);
                }
              },
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF181824),
            borderRadius: BorderRadius.circular(12),
          ),
          child: servicesAsync.when(
            data: (services) {
              final userServices = services.where((s) => !s.description.startsWith(REMINDER_PREFIX)).toList();

              if (userServices.isEmpty) {
                return const SizedBox(
                  height: 150,
                  child: Center(child: Text('Még nincs szervizbejegyzés ehhez a járműhöz.', style: TextStyle(color: Colors.white70))),
                );
              }
              final dateFormat = DateFormat('yyyy.MM.dd');
              
              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: userServices.length,
                separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFF2a2a3a)),
                itemBuilder: (context, index) {
                  final s = userServices[index];
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    title: Text(s.description, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('${dateFormat.format(s.date)} • ${NumberFormat('#,###', 'hu_HU').format(s.mileage)} km • ${NumberFormat.currency(locale: 'hu_HU', symbol: 'Ft', decimalDigits: 0).format(s.cost)}', style: const TextStyle(color: Colors.white70)),
                    trailing: Wrap(
                      spacing: 0,
                      children: [
                        IconButton(
                          tooltip: 'Szerkesztés',
                          icon: const Icon(Icons.edit, size: 20, color: Colors.white70),
                          onPressed: () async {
                            final result = await showDialog<Szerviz>(context: context, builder: (context) => ServiceDialog(initial: s));
                            if (result != null) await fs.upsertService(user.uid, vehicle.licensePlate, vehicleNumericId, result);
                          },
                        ),
                        IconButton(
                          tooltip: 'Törlés',
                          icon: const Icon(Icons.delete, size: 20, color: Colors.redAccent),
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Szerviz törlése'),
                                content: const Text('Biztosan törlöd ezt a szervizbejegyzést?'),
                                actions: [
                                  TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Mégse')),
                                  FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Törlés')),
                                ],
                              ),
                            );
                            if (confirm == true) await fs.deleteService(user.uid, vehicle.id!, s.id!);
                          },
                        ),
                      ],
                    ),
                  );
                },
              );
            },
            loading: () => const SizedBox(height: 150, child: Center(child: CircularProgressIndicator())),
            error: (e, st) => SizedBox(height: 150, child: Center(child: Text('Hiba a szervizlista betöltésekor: $e'))),
          ),
        ),
      ],
    );
  }
}


// --- DIALÓGUSOK (MODÁLIS ABLAKOK) ---

class VehicleDialog extends StatefulWidget {
  final Jarmu? initial;
  const VehicleDialog({super.key, this.initial});
  @override
  State<VehicleDialog> createState() => _VehicleDialogState();
}
class _VehicleDialogState extends State<VehicleDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _licenseCtrl, _makeCtrl, _modelCtrl, _yearCtrl, _mileageCtrl;

  @override
  void initState() {
    super.initState();
    final i = widget.initial;
    _licenseCtrl = TextEditingController(text: i?.licensePlate ?? '');
    _makeCtrl = TextEditingController(text: i?.make ?? '');
    _modelCtrl = TextEditingController(text: i?.model ?? '');
    _yearCtrl = TextEditingController(text: i?.year != null && i!.year != 0 ? '${i.year}' : '');
    _mileageCtrl = TextEditingController(text: i?.mileage != null && i!.mileage != 0 ? '${i.mileage}' : '');
  }

  @override
  void dispose() {
    _licenseCtrl.dispose(); _makeCtrl.dispose(); _modelCtrl.dispose(); _yearCtrl.dispose(); _mileageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.initial != null;
    return AlertDialog(
      title: Text(isEdit ? 'Jármű szerkesztése' : 'Új jármű hozzáadása'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(controller: _licenseCtrl, decoration: const InputDecoration(labelText: 'Rendszám'), validator: (v) => v==null||v.trim().isEmpty ? 'Kötelező mező':null),
                TextFormField(controller: _makeCtrl, decoration: const InputDecoration(labelText: 'Gyártmány'), validator: (v) => v==null||v.trim().isEmpty ? 'Kötelező mező':null),
                TextFormField(controller: _modelCtrl, decoration: const InputDecoration(labelText: 'Modell'), validator: (v) => v==null||v.trim().isEmpty ? 'Kötelező mező':null),
                TextFormField(controller: _yearCtrl, decoration: const InputDecoration(labelText: 'Évjárat'), keyboardType: TextInputType.number, validator: (v) => (v==null||v.trim().isEmpty)?'Kötelező mező':(int.tryParse(v)==null||int.parse(v)<1900)?'Érvénytelen évjárat':null),
                TextFormField(controller: _mileageCtrl, decoration: const InputDecoration(labelText: 'Kilométeróra állás'), keyboardType: TextInputType.number, validator: (v) => (v==null||v.trim().isEmpty)?'Kötelező mező':(int.tryParse(v)==null||int.parse(v)<0)?'Érvénytelen km érték':null),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(child: const Text('Mégse'), onPressed: () => Navigator.of(context).pop()),
        FilledButton(
          child: Text(isEdit ? 'Mentés' : 'Hozzáadás'),
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            final j = Jarmu(id: widget.initial?.id, licensePlate: _licenseCtrl.text.trim(), make: _makeCtrl.text.trim(), model: _modelCtrl.text.trim(), year: int.parse(_yearCtrl.text.trim()), mileage: int.parse(_mileageCtrl.text.trim()));
            Navigator.of(context).pop(j);
          },
        ),
      ],
    );
  }
}

class ServiceDialog extends StatefulWidget {
  final Szerviz? initial;
  const ServiceDialog({super.key, this.initial});
  @override
  State<ServiceDialog> createState() => _ServiceDialogState();
}
class _ServiceDialogState extends State<ServiceDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _descCtrl, _dateCtrl, _costCtrl, _mileageCtrl;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    final i = widget.initial;
    _selectedDate = i?.date ?? DateTime.now();
    _descCtrl = TextEditingController(text: i?.description ?? '');
    _costCtrl = TextEditingController(text: i?.cost != null ? '${i!.cost}' : '');
    _mileageCtrl = TextEditingController(text: i?.mileage != null && i!.mileage != 0 ? '${i.mileage}' : '');
    _dateCtrl = TextEditingController(text: DateFormat('yyyy.MM.dd').format(_selectedDate!));
  }
  
  @override
  void dispose() {
    _descCtrl.dispose(); _dateCtrl.dispose(); _costCtrl.dispose(); _mileageCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(context: context, initialDate: _selectedDate ?? now, firstDate: DateTime(now.year - 20), lastDate: now);
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _dateCtrl.text = DateFormat('yyyy.MM.dd').format(picked);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.initial != null;
    return AlertDialog(
      title: Text(isEdit ? 'Szerviz szerkesztése' : 'Új szervizbejegyzés'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(controller: _descCtrl, decoration: const InputDecoration(labelText: 'Leírás (pl. olajcsere)'), validator: (v) => v==null||v.trim().isEmpty ? 'Kötelező mező':null),
                TextFormField(controller: _dateCtrl, readOnly: true, decoration: const InputDecoration(labelText: 'Dátum', suffixIcon: Icon(Icons.calendar_today)), onTap: _pickDate),
                TextFormField(controller: _costCtrl, decoration: const InputDecoration(labelText: 'Költség (Ft)'), keyboardType: TextInputType.number, validator: (v) => (v==null||v.trim().isEmpty)?'Kötelező mező':(num.tryParse(v)==null||num.parse(v)<0)?'Érvénytelen összeg':null),
                TextFormField(controller: _mileageCtrl, decoration: const InputDecoration(labelText: 'Kilométeróra állás'), keyboardType: TextInputType.number, validator: (v) => (v==null||v.trim().isEmpty)?'Kötelező mező':(int.tryParse(v)==null||int.parse(v)<0)?'Érvénytelen km érték':null),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(child: const Text('Mégse'), onPressed: () => Navigator.of(context).pop()),
        FilledButton(
          child: Text(isEdit ? 'Mentés' : 'Hozzáadás'),
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            if (_selectedDate == null) return;
            final s = Szerviz(
              id: widget.initial?.id, 
              description: _descCtrl.text.trim(), 
              date: _selectedDate!, 
              cost: num.parse(_costCtrl.text.trim()), 
              mileage: int.parse(_mileageCtrl.text.trim()),
            );
            Navigator.of(context).pop(s);
          },
        ),
      ],
    );
  }
}
