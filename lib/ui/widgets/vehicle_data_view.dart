import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:olajfolt_web/modellek/jarmu.dart';
import 'package:olajfolt_web/providers.dart';
import 'package:olajfolt_web/ui/calculators/used_car_value_page.dart';
import 'package:olajfolt_web/ui/widgets/success_overlay.dart';

class VehicleDataView extends ConsumerWidget {
  final Jarmu vehicle;
  final VoidCallback onExportPdf;

  const VehicleDataView({
    super.key,
    required this.vehicle,
    required this.onExportPdf,
  });

  // JAVÍTOTT ADATSZERKESZTŐ DIALÓGUS
  Future<void> _showTechEditDialog(BuildContext context, WidgetRef ref) async {
    final engineController = TextEditingController(text: vehicle.extraData?['engineSize']?.toString() ?? '');
    final powerController = TextEditingController(text: vehicle.extraData?['power']?.toString() ?? '');
    String selectedFuel = vehicle.extraData?['fuelType'] ?? 'Benzin';
    String selectedPowerUnit = vehicle.extraData?['powerUnit'] ?? 'LE';
    
    final List<String> fuelTypes = ['Benzin', 'Dízel', 'Hibrid', 'Elektromos', 'LPG'];

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder( // Hogy a váltógomb működjön a dialóguson belül
        builder: (context, setState) => AlertDialog(
          title: const Text('Technikai adatok frissítése'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: fuelTypes.contains(selectedFuel) ? selectedFuel : 'Benzin',
                  decoration: const InputDecoration(labelText: 'Üzemanyag típus', border: OutlineInputBorder()),
                  items: fuelTypes.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                  onChanged: (v) => selectedFuel = v!,
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: engineController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Hengerűrtartalom', suffixText: 'cm³', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 20),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: powerController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Teljesítmény', border: OutlineInputBorder()),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ToggleButtons(
                      isSelected: [selectedPowerUnit == 'LE', selectedPowerUnit == 'kW'],
                      onPressed: (i) => setState(() => selectedPowerUnit = i == 0 ? 'LE' : 'kW'),
                      borderRadius: BorderRadius.circular(8),
                      constraints: const BoxConstraints(minHeight: 50, minWidth: 45),
                      children: const [Text('LE'), Text('kW')],
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Mégse')),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
              child: const Text('Mentés'),
            ),
          ],
        ),
      ),
    );

    if (result == true) {
      final user = ref.read(authStateProvider).value;
      if (user != null) {
        final updatedVehicle = vehicle.copyWith(
          extraData: {
            ...vehicle.extraData ?? {},
            'fuelType': selectedFuel,
            'engineSize': engineController.text,
            'power': powerController.text,
            'powerUnit': selectedPowerUnit,
          }
        );
        await ref.read(firestoreServiceProvider).upsertVehicle(user.uid, updatedVehicle);
        if (context.mounted) SuccessOverlay.show(context: context, message: 'Adatok frissítve!');
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final nf = NumberFormat.decimalPattern('hu_HU');
    
    final int? lastPrice = vehicle.extraData?['lastPredictedValue'];
    final String? fuelType = vehicle.extraData?['fuelType'];
    final String? engineSize = vehicle.extraData?['engineSize'];
    final String? power = vehicle.extraData?['power'];
    final String? powerUnit = vehicle.extraData?['powerUnit'] ?? 'LE';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 850),
          child: Column(
            children: [
              _buildModernHeader(context, theme, nf, lastPrice),
              const SizedBox(height: 24),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildDataCard(
                      title: 'ALAPADATOK',
                      icon: Icons.info_outline,
                      color: Colors.blue,
                      children: [
                        _buildRow('Rendszám', vehicle.licensePlate, Icons.badge),
                        _buildRow('Gyártási év', vehicle.year.toString(), Icons.calendar_today),
                        _buildRow('Kilométer', '${nf.format(vehicle.mileage)} km', Icons.speed),
                        _buildRow('Alvázszám', (vehicle.vin != null && vehicle.vin!.isNotEmpty) ? vehicle.vin! : '-', Icons.fingerprint),
                      ],
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: _buildDataCard(
                      title: 'TECHNIKAI ADATOK',
                      icon: Icons.settings_outlined,
                      color: Colors.orange,
                      onEdit: () => _showTechEditDialog(context, ref),
                      children: [
                        _buildRow('Üzemanyag', fuelType ?? 'Nincs megadva', Icons.local_gas_station, isMissing: fuelType == null),
                        _buildRow('Motor', engineSize != null && engineSize.isNotEmpty ? '$engineSize cm³' : 'Nincs megadva', Icons.settings_input_component, isMissing: engineSize == null || engineSize.isEmpty),
                        _buildRow('Teljesítmény', power != null && power.isNotEmpty ? '$power $powerUnit' : 'Nincs megadva', Icons.bolt, isMissing: power == null || power.isEmpty),
                        _buildRow('Vezérlés', (vehicle.vezerlesTipusa != null && vehicle.vezerlesTipusa!.isNotEmpty) ? vehicle.vezerlesTipusa! : '-', Icons.settings),
                        _buildRow('Rádió kód', (vehicle.radioCode != null && vehicle.radioCode!.isNotEmpty) ? vehicle.radioCode! : '-', Icons.radio),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              _buildActionButton(
                label: 'PDF JÁRMŰTÖRTÉNET EXPORTÁLÁSA',
                icon: Icons.picture_as_pdf,
                color: Colors.red.shade700,
                onTap: onExportPdf,
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernHeader(BuildContext context, ThemeData theme, NumberFormat nf, int? lastPrice) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: theme.colorScheme.primary.withOpacity(0.1), shape: BoxShape.circle),
                child: Icon(Icons.directions_car_filled, size: 40, color: theme.colorScheme.primary),
              ),
              const SizedBox(width: 24),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${vehicle.make} ${vehicle.model}', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
                  Text(vehicle.licensePlate, style: TextStyle(fontSize: 18, color: Colors.grey.shade500, letterSpacing: 2, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
          if (lastPrice != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [Colors.green.shade700, Colors.green.shade500]),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.green.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 5))],
              ),
              child: Column(
                children: [
                  const Text('BECSÜLT ÉRTÉK', style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                  Text('${nf.format(lastPrice)} Ft', style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
                ],
              ),
            )
          else
            ElevatedButton.icon(
              onPressed: () {
                // KÉZZEL KÉNYSZERÍTETT NAVIGÁCIÓ
                Navigator.push(context, MaterialPageRoute(builder: (context) => UsedCarValuePage(vehicle: vehicle)));
              },
              icon: const Icon(Icons.auto_awesome, size: 18),
              label: const Text('ÉRTÉKBECSLÉS INDÍTÁSA'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                elevation: 4,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDataCard({required String title, required IconData icon, required Color color, required List<Widget> children, VoidCallback? onEdit}) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: BorderSide(color: Colors.grey.withOpacity(0.1))),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(icon, color: color, size: 20),
                    const SizedBox(width: 12),
                    Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.2)),
                  ],
                ),
                if (onEdit != null)
                  IconButton(
                    icon: const Icon(Icons.edit, size: 18, color: Colors.grey),
                    onPressed: onEdit,
                    tooltip: 'Adatok szerkesztése',
                  ),
              ],
            ),
            const Divider(height: 32),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value, IconData icon, {bool isMissing = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icon, size: 16, color: isMissing ? Colors.orange.withOpacity(0.5) : Colors.grey.shade400),
          const SizedBox(width: 12),
          Text(label, style: TextStyle(color: isMissing ? Colors.orange : Colors.grey.shade600, fontSize: 14)),
          const Spacer(),
          Text(
            value, 
            style: TextStyle(
              fontWeight: FontWeight.bold, 
              fontSize: 14,
              color: isMissing ? Colors.orange : null,
              fontStyle: isMissing ? FontStyle.italic : null,
            )
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({required String label, required IconData icon, required Color color, required VoidCallback onTap}) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon),
        label: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 4,
        ),
      ),
    );
  }
}
