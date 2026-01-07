// lib/ui/vehicle_notification_details_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:olajfolt_web/alap/konstansok.dart';
import 'package:olajfolt_web/modellek/jarmu.dart';
import 'package:olajfolt_web/modellek/karbantartas_bejegyzes.dart';
import 'package:olajfolt_web/providers.dart';
import 'package:olajfolt_web/services/firestore_service.dart';

class VehicleNotificationDetailsPage extends ConsumerStatefulWidget {
  final Jarmu vehicle;
  final Map<String, dynamic> initialSettings;

  const VehicleNotificationDetailsPage({
    super.key,
    required this.vehicle,
    required this.initialSettings,
  });

  @override
  ConsumerState<VehicleNotificationDetailsPage> createState() => _VehicleNotificationDetailsPageState();
}

class _VehicleNotificationDetailsPageState extends ConsumerState<VehicleNotificationDetailsPage> {
  late Map<String, dynamic> _settings;
  final TextEditingController _emailController = TextEditingController();
  final Map<String, Map<String, dynamic>> _lastServiceData = {};
  bool _isLoading = true;

  @override
  initState() {
    super.initState();
    _settings = Map<String, dynamic>.from(widget.initialSettings);
    _loadLastServices();
  }

  Future<void> _loadLastServices() async {
    final firestoreService = ref.read(firestoreServiceProvider);
    final user = ref.read(authStateProvider).value;

    if (user != null && widget.vehicle.id != null) {
      final servicesStream = firestoreService.watchServices(user.uid, widget.vehicle.id!);
      final services = await servicesStream.first;

      for (var type in ALL_REMINDER_SERVICE_TYPES) {
        _lastServiceData[type] = {'date': null, 'mileage': null};
        try {
          final lastService = services.firstWhere((s) {
            final desc = s.description.toLowerCase();
            final typeLower = type.toLowerCase();
            return desc.contains(typeLower) || desc.contains('$REMINDER_PREFIX$type'.toLowerCase());
          });
          _lastServiceData[type] = {'date': lastService.date, 'mileage': lastService.mileage};
        } catch (e) { /* Nincs adat */ }
      }
    }

    if (mounted) setState(() => _isLoading = false);
  }

  void _saveSettings() async {
    final firestoreService = ref.read(firestoreServiceProvider);
    final user = ref.read(authStateProvider).value;

    if (user != null && widget.vehicle.id != null) {
      // JAVÍTVA: A vehicle.id tartalmazza a rendszámot. A numerikus ID-t itt 0-nak vesszük,
      // mivel az upsertService-nek már nem a rendszám kell a vehicleId mezőbe.
      // NOTE: A vehicle.id a rendszám, ami a document ID! A Jarmu modellben nincs külön numeric ID.
      // Azonban a firestore_service.upsertService 4 paramétert vár.

      // A vehicle.id a rendszám, ami a document ID. A Jarmu modellben nincs külön numeric ID.
      // Azonban a firestore_service.upsertService 4 paramétert vár.
      final vehicleNumericId = int.tryParse(widget.vehicle.id!) ?? 0;
      final licensePlate = widget.vehicle.licensePlate;

      for (var type in ALL_REMINDER_SERVICE_TYPES) {
        final data = _lastServiceData[type];
        if (data != null && (data['date'] != null || (data['mileage'] != null && data['mileage'] > 0))) {
          final newBaseService = Szerviz(
            description: '$REMINDER_PREFIX$type',
            date: data['date'] ?? DateTime.now(),
            mileage: data['mileage'] ?? 0,
            cost: 0,
          );
          // 4 argumentumos hívás beillesztése
          await firestoreService.upsertService(user.uid, licensePlate, vehicleNumericId, newBaseService);
        }
      }
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Beállítások mentve!'), backgroundColor: Colors.green));
      Navigator.of(context).pop(_settings);
    }
  }

  Future<void> _pickLastDate(String type) async {
    final initialDate = _lastServiceData[type]?['date'] as DateTime? ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _lastServiceData[type]!['date'] = picked);
    }
  }

  Future<void> _editLastMileage(String type) async {
    final initialKm = _lastServiceData[type]?['mileage'] as int? ?? 0;
    final controller = TextEditingController(text: initialKm > 0 ? initialKm.toString() : '');
    final km = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$type - Utolsó km állás'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(suffixText: 'km'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Mégse')),
          ElevatedButton(onPressed: () => Navigator.pop(context, int.tryParse(controller.text) ?? 0), child: const Text('Mentés')),
        ],
      ),
    );
    if (km != null) setState(() => _lastServiceData[type]!['mileage'] = km);
  }

  void _addEmail() {
    final email = _emailController.text.trim();
    final emails = _settings['emails'] as List<String>;
    if (email.isNotEmpty && email.contains('@') && !emails.contains(email)) {
      setState(() { emails.add(email); _emailController.clear(); });
    }
  }

  void _removeEmail(String email) {
    setState(() => (_settings['emails'] as List<String>).remove(email));
  }

  // Segédfüggvény a címke meghatározásához
  String _getDateLabel(String serviceType) {
    if (serviceType.contains('Műszaki')) return 'Utolsó vizsga: ';
    if (serviceType.contains('biztosítás') || serviceType.contains('CASCO')) return 'Évforduló: ';
    if (serviceType.contains('matrica')) return 'Kezdet: ';
    return 'Utolsó: ';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.vehicle.licensePlate} beállításai'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: FilledButton.icon(
              onPressed: _saveSettings,
              icon: const Icon(Icons.save),
              label: const Text('Mentés'),
              style: FilledButton.styleFrom(backgroundColor: theme.colorScheme.primary, foregroundColor: theme.colorScheme.onPrimary),
            ),
          ),
        ],
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('ÉRTESÍTÉSI CÍMEK', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 12,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        ...(_settings['emails'] as List<String>).map((email) => Chip(label: Text(email), onDeleted: () => _removeEmail(email))),
                        SizedBox(
                          width: 250,
                          child: TextField(
                            controller: _emailController,
                            decoration: InputDecoration(
                              hintText: 'Új e-mail...',
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
                              suffixIcon: IconButton(icon: const Icon(Icons.check, size: 20), onPressed: _addEmail),
                            ),
                            onSubmitted: (_) => _addEmail(),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text('ESEMÉNYEK ÉS EMLÉKEZTETŐK', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 16),
            ...ALL_REMINDER_SERVICE_TYPES.map((type) => _buildServiceRow(type, theme)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceRow(String type, ThemeData theme) {
    final serviceSettings = _settings['services'][type] as Map<String, dynamic>;
    final isEnabled = serviceSettings['enabled'] as bool;
    final isDateBased = DATE_BASED_SERVICE_TYPES.contains(type);
    final isKmBased = KM_BASED_SERVICE_TYPES.contains(type);
    
    final lastDate = _lastServiceData[type]?['date'] as DateTime?;
    final lastKm = _lastServiceData[type]?['mileage'] as int?;
    final dateFormat = DateFormat('yyyy.MM.dd');
    final dateLabel = _getDateLabel(type);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        type,
                        style: TextStyle(fontWeight: isEnabled ? FontWeight.bold : FontWeight.normal, fontSize: 16, color: isEnabled ? theme.colorScheme.primary : null),
                      ),
                      if (isEnabled) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            if (isDateBased)
                              InkWell(
                                onTap: () => _pickLastDate(type),
                                child: Text(
                                  '$dateLabel${lastDate != null ? dateFormat.format(lastDate) : "Nincs megadva"}',
                                  style: TextStyle(color: lastDate == null ? Colors.red : Colors.grey, fontSize: 12, decoration: TextDecoration.underline),
                                ),
                              ),
                            if (isDateBased && isKmBased)
                              const Text(' | ', style: TextStyle(color: Colors.grey, fontSize: 12)),
                            if (isKmBased)
                              InkWell(
                                onTap: () => _editLastMileage(type),
                                child: Text(
                                  lastKm != null && lastKm > 0 ? '$lastKm km' : "Km nincs megadva",
                                  style: TextStyle(color: (lastKm == null || lastKm == 0) ? Colors.red : Colors.grey, fontSize: 12, decoration: TextDecoration.underline),
                                ),
                              ),
                          ],
                        )
                      ]
                    ],
                  ),
                ),
                Switch(
                  value: isEnabled,
                  activeColor: theme.colorScheme.primary,
                  onChanged: (val) => setState(() => serviceSettings['enabled'] = val),
                ),
              ],
            ),
            if (isEnabled) ...[
              const Divider(),
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  children: [
                    const Text('Értesítés:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(width: 8),
                    if (isDateBased)
                      _buildInputChip(
                        icon: Icons.notifications_active,
                        label: 'nappal előtte',
                        value: serviceSettings['daysBefore'].toString(),
                        onChanged: (val) => serviceSettings['daysBefore'] = int.tryParse(val) ?? 30,
                      ),
                    if (isDateBased && isKmBased) const SizedBox(width: 8),
                    if (isKmBased)
                      _buildInputChip(
                        icon: Icons.notifications_active,
                        label: 'km-rel előtte',
                        value: serviceSettings['kmBefore'].toString(),
                        onChanged: (val) => serviceSettings['kmBefore'] = int.tryParse(val) ?? 1000,
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInputChip({required IconData icon, required String label, required String value, required Function(String) onChanged}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(color: Colors.grey.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
        child: Row(
          children: [
            Icon(icon, size: 18, color: Colors.grey),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                initialValue: value,
                keyboardType: TextInputType.number,
                style: const TextStyle(fontSize: 14),
                decoration: const InputDecoration(isDense: true, border: InputBorder.none, contentPadding: EdgeInsets.zero),
                onChanged: onChanged,
              ),
            ),
            Text(label, style: const TextStyle(fontSize: 14, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
