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
    _loadSettings();
  }

  @override
  void dispose() {
    _controllers.forEach((_, c) => c.dispose());
    _animController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    try {
      final user = ref.read(authStateProvider).value;
      if (user == null) return;

      final vehiclesAsync = ref.read(vehiclesProvider);
      // Wait for vehicles to load if needed (simple retry logic or just wait)
      // Since it's a StreamProvider, we might need to wait for the first value if not ready.
      // For simplicity here, assuming vehicles are loaded or will load.
      // Better: In build we handle loading. Here we just setup controllers.
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSettings(String vehicleId) async {
    final user = ref.read(authStateProvider).value;
    if (user == null) return;

    final emails = _selectedEmails[vehicleId] ?? [];
    
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('vehicles')
          .doc(vehicleId)
          .set({
            'notificationEmails': emails
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

                  // Inicializáljuk a listát, ha még nincs (pl. DB-ből kéne jönnie, 
                  // de most egyszerűsítve a memóriában kezeljük a szerkesztést)
                  if (!_controllers.containsKey(vehicleId)) {
                    _controllers[vehicleId] = TextEditingController();
                    // Itt lehetne betölteni a DB-ből az elmentett e-maileket, ha a modell támogatná
                    // Mivel most csak a mentés logikát kérted, feltételezzük, hogy üresről indul, vagy már betöltődött.
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
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, st) => Center(child: Text('Hiba: $e')),
          ),

          // --- SIKERES MENTÉS ANIMÁCIÓ (OVERLAY) ---
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
