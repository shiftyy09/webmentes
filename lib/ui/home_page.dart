// lib/ui/home_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:olajfolt_web/modellek/jarmu.dart';
import 'package:olajfolt_web/modellek/karbantartas_bejegyzes.dart';
import 'package:olajfolt_web/services/firestore_service.dart';
import 'package:olajfolt_web/ui/dialogs/vehicle_editor_dialog.dart';
import 'package:url_launcher/url_launcher.dart';

import '../providers.dart';
import '../theme_provider.dart';

// --- EZ AZ IMPORT HIÁNYZOTT NÁLAD ---
import 'widgets/vehicle_list_view.dart';
import 'widgets/vehicle_detail_panel.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  Future<void> _openVehicleEditor(BuildContext context, WidgetRef ref, {Jarmu? vehicle}) async {
    final firestoreService = ref.read(firestoreServiceProvider);
    final user = ref.read(authStateProvider).value;

    if (user == null) return;

    final result = await showDialog<Map<String, dynamic>?>(
      context: context,
      builder: (context) => VehicleEditorDialog(vehicle: vehicle),
    );

    if (result != null) {
      final Jarmu vehicleToSave = result['vehicle'];
      final List<Szerviz> initialServices = result['services'];

      final vehicleNumericId = await firestoreService.upsertVehicle(user.uid, vehicleToSave);

      if (initialServices.isNotEmpty) {
        // A mobil app szinkronizációja alapján az inicializáló szervizekhez
        // a vehicleId-nek 0-nak kell lennie.
        const vehicleNumericIdForInitialService = 0;

        for (var service in initialServices) {
          await firestoreService.upsertService(user.uid, vehicleToSave.licensePlate, vehicleNumericIdForInitialService, service);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authStateProvider).value;
    final authService = ref.watch(authServiceProvider);
    final themeMode = ref.watch(themeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Járműveim'),
        // A vissza gombot a Flutter automatikusan kezeli, ha push-olva lett az oldal
        actions: [
          IconButton(
            icon: Icon(themeMode == ThemeMode.dark ? Icons.light_mode : Icons.dark_mode),
            onPressed: () => ref.read(themeProvider.notifier).toggleTheme(),
          ),
          const SizedBox(width: 8),

          if (auth != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Center(child: Text(auth.email ?? '', style: const TextStyle(fontSize: 14))),
            ),
          TextButton(
            onPressed: () async => await authService.signOut(),
            child: const Text('Kijelentkezés'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                // ITT HASZNÁLJUK A VehicleListView-t
                SizedBox(
                  width: 350,
                  child: VehicleListView(onAddVehicle: () => _openVehicleEditor(context, ref)),
                ),
                const VerticalDivider(width: 1),
                Expanded(
                  child: VehicleDetailPanel(
                    onEditVehicle: (Jarmu vehicle) => _openVehicleEditor(context, ref, vehicle: vehicle),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
            color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E1E1E) : Colors.grey[200],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Verzió: 1.0.0',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                Row(
                  children: [
                    const Text('Elérhetőség: info@olajfolt.hu', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    const SizedBox(width: 24),
                    InkWell(
                      onTap: () async {
                        final url = Uri.parse('https://olajfolt.hu/app');
                        if (await canLaunchUrl(url)) {
                          await launchUrl(url);
                        }
                      },
                      child: const Text(
                        'Mobilalkalmazás letöltése: olajfolt.hu/app',
                        style: TextStyle(color: Color(0xFFE69500), fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}