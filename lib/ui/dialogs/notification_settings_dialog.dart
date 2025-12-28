// lib/ui/dialogs/notification_settings_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:olajfolt_web/alap/konstansok.dart';
import 'package:olajfolt_web/providers.dart';

class NotificationSettingsDialog extends ConsumerStatefulWidget {
  const NotificationSettingsDialog({super.key});

  @override
  ConsumerState<NotificationSettingsDialog> createState() => _NotificationSettingsDialogState();
}

class _NotificationSettingsDialogState extends ConsumerState<NotificationSettingsDialog> {
  // Itt tároljuk ideiglenesen a beállításokat (Jármű ID -> {Szerviztípus -> Engedélyezve})
  final Map<String, Map<String, bool>> _settings = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    // TODO: Itt kellene betölteni a Firestore-ból a mentett beállításokat.
    // Egyelőre mindenhol "hamis" (kikapcsolva) értéket használunk, amíg nincs backend támogatás.
    final vehicles = await ref.read(vehiclesProvider.future);
    
    for (var vehicle in vehicles) {
      if (vehicle.id != null) {
        _settings[vehicle.id!] = {};
        for (var type in ALL_REMINDER_SERVICE_TYPES) {
          // Itt kellene a valós adatot betölteni: _settings[vehicle.id]![type] = loadedValue;
          _settings[vehicle.id!]![type] = false; 
        }
      }
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  void _onSave() {
    // TODO: Itt mentjük el a beállításokat a Firestore-ba (pl. users/{uid}/notification_settings).
    // Mivel a backend (Cloud Functions) még nincs kész, ez most csak egy "demo" mentés.
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Értesítési beállítások mentve (Backend szükséges a küldéshez)!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vehiclesAsync = ref.watch(vehiclesProvider);
    final theme = Theme.of(context);

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.notifications_active, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          const Text('E-mail Értesítések'),
        ],
      ),
      content: SizedBox(
        width: 600,
        height: 500,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : vehiclesAsync.when(
                data: (vehicles) {
                  if (vehicles.isEmpty) {
                    return const Center(child: Text('Nincsenek járművek az értesítések beállításához.'));
                  }
                  return ListView.builder(
                    itemCount: vehicles.length,
                    itemBuilder: (context, index) {
                      final vehicle = vehicles[index];
                      if (vehicle.id == null) return const SizedBox.shrink();

                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        child: ExpansionTile(
                          title: Text(
                            '${vehicle.licensePlate} - ${vehicle.make} ${vehicle.model}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: const Text('Kattints a lenyitáshoz'),
                          children: ALL_REMINDER_SERVICE_TYPES.map((type) {
                            return SwitchListTile(
                              title: Text(type),
                              subtitle: Text(DATE_BASED_SERVICE_TYPES.contains(type) 
                                  ? 'Értesítés lejárat előtt 30 nappal' 
                                  : 'Értesítés a km limit közeledtével'),
                              value: _settings[vehicle.id]?[type] ?? false,
                              onChanged: (val) {
                                setState(() {
                                  _settings[vehicle.id]![type] = val;
                                });
                              },
                              activeColor: theme.colorScheme.primary,
                            );
                          }).toList(),
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, st) => Center(child: Text('Hiba: $e')),
              ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Mégse')),
        ElevatedButton(
          onPressed: _onSave,
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: theme.colorScheme.onPrimary,
          ),
          child: const Text('Mentés'),
        ),
      ],
    );
  }
}
