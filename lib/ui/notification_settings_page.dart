// lib/ui/notification_settings_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:olajfolt_web/modellek/jarmu.dart';
import 'package:olajfolt_web/providers.dart';

class NotificationSettingsPage extends ConsumerStatefulWidget {
  const NotificationSettingsPage({super.key});

  @override
  ConsumerState<NotificationSettingsPage> createState() => _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends ConsumerState<NotificationSettingsPage> with SingleTickerProviderStateMixin {
  final Map<String, List<String>> _selectedEmails = {}; 
  final Map<String, TextEditingController> _controllers = {};
  
  // ÚJ: Kapcsolók állapota
  final Map<String, bool> _notifyDate = {};
  final Map<String, bool> _notifyKm = {};
  
  bool _isLoading = false;
  
  // ANIMÁCIÓHOZ
  bool _showSuccess = false;
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _scaleAnimation = CurvedAnimation(parent: _animController, curve: Curves.elasticOut);
    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _animController, curve: Curves.easeIn));
    // A betöltést a build-ben lévő stream végzi, de inicializálhatunk alapértelmezéseket
  }

  @override
  void dispose() {
    _controllers.forEach((_, c) => c.dispose());
    _animController.dispose();
    super.dispose();
  }

  // Segédfüggvény az adatok betöltéséhez a Firestore snapshotból
  void _initializeDataForVehicle(String vehicleId, Map<String, dynamic>? data) {
    if (data == null) return;
    
    // E-mailek
    if (_selectedEmails[vehicleId] == null) {
      final emails = data['notificationEmails'];
      if (emails is List) {
        _selectedEmails[vehicleId] = List<String>.from(emails);
      } else {
        _selectedEmails[vehicleId] = [];
      }
    }

    // Kapcsolók
    if (_notifyDate[vehicleId] == null) {
      _notifyDate[vehicleId] = data['enableEmailDate'] ?? true; // Alapértelmezetten bekapcsolva
    }
    if (_notifyKm[vehicleId] == null) {
      _notifyKm[vehicleId] = data['enableEmailKm'] ?? true;
    }
  }

  Future<void> _saveSettings(String vehicleId) async {
    final user = ref.read(authStateProvider).value;
    if (user == null) return;

    final emails = _selectedEmails[vehicleId] ?? [];
    final enableDate = _notifyDate[vehicleId] ?? true;
    final enableKm = _notifyKm[vehicleId] ?? true;
    
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('vehicles')
          .doc(vehicleId)
          .set({
            'notificationEmails': emails,
            'enableEmailDate': enableDate,
            'enableEmailKm': enableKm,
          }, SetOptions(merge: true));

      _triggerSuccessAnimation();

    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hiba a mentéskor: $e')));
    }
  }

  void _triggerSuccessAnimation() async {
    if (!mounted) return;
    setState(() => _showSuccess = true);
    await _animController.forward(from: 0.0);
    await Future.delayed(const Duration(milliseconds: 1500));
    await _animController.reverse();
    if (mounted) setState(() => _showSuccess = false);
  }

  void _addEmail(String vehicleId) {
    final controller = _controllers[vehicleId];
    if (controller != null && controller.text.isNotEmpty) {
      final email = controller.text.trim();
      if (email.contains('@') && email.contains('.')) {
        setState(() {
          if (_selectedEmails[vehicleId] == null) _selectedEmails[vehicleId] = [];
          if (!_selectedEmails[vehicleId]!.contains(email)) {
            _selectedEmails[vehicleId]!.add(email);
          }
          controller.clear();
        });
      }
    }
  }

  void _removeEmail(String vehicleId, String email) {
    setState(() {
      _selectedEmails[vehicleId]?.remove(email);
    });
  }

  @override
  Widget build(BuildContext context) {
    final vehiclesAsync = ref.watch(vehiclesProvider);
    final theme = Theme.of(context);
    final user = ref.watch(authStateProvider).value;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Értesítési Központ'),
        centerTitle: true,
        backgroundColor: const Color(0xFF1E1E1E),
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          vehiclesAsync.when(
            data: (vehicles) {
              if (vehicles.isEmpty) return const Center(child: Text('Nincsenek járművek.'));
              
              return ListView.builder(
                padding: const EdgeInsets.all(40),
                itemCount: vehicles.length,
                itemBuilder: (context, index) {
                  final vehicle = vehicles[index];
                  final vehicleId = vehicle.id;
                  
                  if (vehicleId == null) return const SizedBox();

                  // Kontroller init
                  if (!_controllers.containsKey(vehicleId)) {
                    _controllers[vehicleId] = TextEditingController();
                  }

                  // Adatok betöltése Firestore-ból (StreamBuilderrel, hogy mindig friss legyen)
                  return StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .doc(user!.uid)
                        .collection('vehicles')
                        .doc(vehicleId)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasData && snapshot.data!.exists) {
                        _initializeDataForVehicle(vehicleId, snapshot.data!.data() as Map<String, dynamic>);
                      }

                      return Card(
                        margin: const EdgeInsets.only(bottom: 24),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 4,
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), shape: BoxShape.circle),
                                    child: const Icon(Icons.directions_car, color: Colors.orange, size: 32),
                                  ),
                                  const SizedBox(width: 16),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(vehicle.licensePlate, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                                      Text('${vehicle.make} ${vehicle.model}', style: theme.textTheme.bodyLarge?.copyWith(color: Colors.grey)),
                                    ],
                                  ),
                                  const Spacer(),
                                  ElevatedButton.icon(
                                    icon: const Icon(Icons.save),
                                    label: const Text('MENTÉS'),
                                    onPressed: () => _saveSettings(vehicleId),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: 32),
                              
                              // KAPCSOLÓK VISSZATÉRTÉK
                              const Text('Értesítési típusok:', style: TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              SwitchListTile(
                                title: const Text('Dátum alapú figyelmeztetések'),
                                subtitle: const Text('Pl. Műszaki vizsga, éves szerviz, biztosítás lejárata.'),
                                value: _notifyDate[vehicleId] ?? true,
                                onChanged: (val) => setState(() => _notifyDate[vehicleId] = val),
                                secondary: const Icon(Icons.calendar_today, color: Colors.blue),
                              ),
                              SwitchListTile(
                                title: const Text('Km alapú figyelmeztetések'),
                                subtitle: const Text('Pl. Olajcsere, vezérlés, fékbetétek.'),
                                value: _notifyKm[vehicleId] ?? true,
                                onChanged: (val) => setState(() => _notifyKm[vehicleId] = val),
                                secondary: const Icon(Icons.speed, color: Colors.orange),
                              ),
                              
                              const Divider(height: 24),

                              const Text('Értesítendő e-mail címek:', style: TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 16),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: (_selectedEmails[vehicleId] ?? []).map((email) => Chip(
                                  label: Text(email),
                                  deleteIcon: const Icon(Icons.close, size: 18),
                                  onDeleted: () => _removeEmail(vehicleId, email),
                                  backgroundColor: theme.colorScheme.primaryContainer,
                                )).toList(),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _controllers[vehicleId],
                                      decoration: InputDecoration(
                                        labelText: 'Új e-mail hozzáadása',
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                        suffixIcon: IconButton(
                                          icon: const Icon(Icons.add_circle, color: Colors.blue),
                                          onPressed: () => _addEmail(vehicleId),
                                        ),
                                      ),
                                      onSubmitted: (_) => _addEmail(vehicleId),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, st) => Center(child: Text('Hiba: $e')),
          ),

          // --- SIKERES MENTÉS ANIMÁCIÓ ---
          if (_showSuccess)
            Positioned.fill(
              child: Center(
                child: FadeTransition(
                  opacity: _opacityAnimation,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: Container(
                      width: 300,
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          )
                        ],
                      ),
                      child: const Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle, size: 80, color: Colors.green),
                          SizedBox(height: 24),
                          Text(
                            'Sikeres Mentés!',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Az értesítési beállításokat frissítettük.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
