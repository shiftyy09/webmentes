// lib/ui/notification_settings_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:olajfolt_web/alap/konstansok.dart';
import 'package:olajfolt_web/modellek/jarmu.dart';
import 'package:olajfolt_web/providers.dart';
import 'package:olajfolt_web/ui/vehicle_notification_details_page.dart';

class NotificationSettingsPage extends ConsumerStatefulWidget {
  const NotificationSettingsPage({super.key});

  @override
  ConsumerState<NotificationSettingsPage> createState() => _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends ConsumerState<NotificationSettingsPage> {
  // Adatszerkezet: Jármű ID -> { 'emails': List<String>, 'services': Map<String, Map> }
  final Map<String, dynamic> _settings = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final vehicles = await ref.read(vehiclesProvider.future);
    final user = ref.read(authStateProvider).value;

    for (var vehicle in vehicles) {
      if (vehicle.id != null) {
        // Itt kellene betölteni a valós mentett adatokat.
        // Most alapértelmezett értékekkel töltjük fel.
        _settings[vehicle.id!] = {
          'emails': <String>[if (user?.email != null) user!.email!],
          'services': <String, Map<String, dynamic>>{}
        };
        
        for (var type in ALL_REMINDER_SERVICE_TYPES) {
          _settings[vehicle.id!]['services'][type] = {
            'enabled': false,
            'daysBefore': 30,
            'kmBefore': 1000,
          };
        }
      }
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  void _openVehicleDetails(Jarmu vehicle) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => VehicleNotificationDetailsPage(
          vehicle: vehicle,
          initialSettings: _settings[vehicle.id!]!,
        ),
      ),
    );

    // Ha történt mentés, frissítjük a helyi állapotot
    if (result != null) {
      setState(() {
        _settings[vehicle.id!] = result;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final vehiclesAsync = ref.watch(vehiclesProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Értesítési Központ'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : vehiclesAsync.when(
              data: (vehicles) {
                if (vehicles.isEmpty) {
                  return const Center(child: Text('Nincsenek járművek.'));
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(24.0),
                  itemCount: vehicles.length,
                  itemBuilder: (context, index) {
                    final vehicle = vehicles[index];
                    return Card(
                      elevation: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: CircleAvatar(
                          backgroundColor: theme.colorScheme.primaryContainer,
                          child: Icon(Icons.directions_car, color: theme.colorScheme.primary),
                        ),
                        title: Text(
                          vehicle.licensePlate,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                        subtitle: Text('${vehicle.make} ${vehicle.model}'),
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: () => _openVehicleDetails(vehicle),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => Center(child: Text('Hiba: $e')),
            ),
    );
  }
}
