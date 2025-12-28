// lib/ui/home_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:olajfolt_web/modellek/jarmu.dart';
import 'package:olajfolt_web/modellek/karbantartas_bejegyzes.dart';
import 'package:olajfolt_web/services/firestore_service.dart';
import 'package:olajfolt_web/ui/calculators/transfer_cost_page.dart';
import 'package:olajfolt_web/ui/dialogs/vehicle_editor_dialog.dart';
import 'package:olajfolt_web/ui/notification_settings_page.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../providers.dart';
import '../theme_provider.dart';
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
      
      final vehicleId = await firestoreService.upsertVehicle(user.uid, vehicleToSave);

      if (vehicleId != null && initialServices.isNotEmpty) {
        for (var service in initialServices) {
          await firestoreService.upsertService(user.uid, vehicleId, service);
        }
      }
    }
  }

  void _openNotificationSettings(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const NotificationSettingsPage()),
    );
  }

  void _openCalculator(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const TransferCostCalculatorPage()),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authStateProvider).value;
    final authService = ref.watch(authServiceProvider);
    final themeMode = ref.watch(themeProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E),
        foregroundColor: Colors.white,
        centerTitle: true,
        title: SizedBox(
          height: 40,
          child: Image.asset('assets/olajfoltweb.png', fit: BoxFit.contain),
        ),
        actions: [
          // KALKULÁTOR GOMB (Szöveggel)
          TextButton.icon(
            onPressed: () => _openCalculator(context),
            icon: const Icon(Icons.calculate_outlined, color: Colors.white),
            label: const Text('Kalkulátor', style: TextStyle(color: Colors.white)),
          ),
          const SizedBox(width: 8),
          
          // ÉRTESÍTÉSEK GOMB (Szöveggel)
          TextButton.icon(
            onPressed: () => _openNotificationSettings(context),
            icon: const Icon(Icons.notifications_active_outlined, color: Colors.white),
            label: const Text('Értesítések', style: TextStyle(color: Colors.white)),
          ),
          const SizedBox(width: 16), // Kis elválasztó

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
            child: const Text('Kijelentkezés', style: TextStyle(color: Colors.white)),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Row(
              children: [
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
            color: const Color(0xFF1E1E1E),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Verzió: 1.0.0',
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
                Row(
                  children: [
                    const Text('Elérhetőség: shiftyy09@gmail.com', style: TextStyle(color: Colors.white54, fontSize: 12)),
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
                        style: TextStyle(color: Color(0xFFFFA400), fontSize: 12, fontWeight: FontWeight.bold),
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
