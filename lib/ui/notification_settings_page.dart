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
  final Map<String, bool> _notifyDate = {};
  final Map<String, bool> _notifyKm = {};
  
  bool _showSuccess = false;
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _scaleAnimation = CurvedAnimation(parent: _animController, curve: Curves.elasticOut);
  }

  @override
  void dispose() {
    _controllers.forEach((_, c) => c.dispose());
    _animController.dispose();
    super.dispose();
  }

  void _initializeDataForVehicle(String vehicleId, Map<String, dynamic>? data) {
    if (data == null) return;
    
    if (_selectedEmails[vehicleId] == null) {
      final emails = data['notificationEmails'];
      _selectedEmails[vehicleId] = emails is List ? List<String>.from(emails) : [];
    }

    if (_notifyDate[vehicleId] == null) {
      _notifyDate[vehicleId] = data['enableEmailDate'] ?? true;
    }
    if (_notifyKm[vehicleId] == null) {
      _notifyKm[vehicleId] = data['enableEmailKm'] ?? true;
    }
  }

  Future<void> _saveSettings(String vehicleId) async {
    final user = ref.read(authStateProvider).value;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('vehicles')
          .doc(vehicleId)
          .set({
            'notificationEmails': _selectedEmails[vehicleId] ?? [],
            'enableEmailDate': _notifyDate[vehicleId] ?? true,
            'enableEmailKm': _notifyKm[vehicleId] ?? true,
            'lastSettingsUpdate': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

      _triggerSuccessAnimation();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hiba a mentéskor: $e'), backgroundColor: Colors.redAccent));
    }
  }

  void _triggerSuccessAnimation() async {
    setState(() => _showSuccess = true);
    await _animController.forward(from: 0.0);
    await Future.delayed(const Duration(milliseconds: 1500));
    if (mounted) {
      await _animController.reverse();
      setState(() => _showSuccess = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final vehiclesAsync = ref.watch(vehiclesProvider);
    final user = ref.watch(authStateProvider).value;

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('ÉRTESÍTÉSI KÖZPONT', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 16)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFFE69500)),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topRight,
            radius: 1.5,
            colors: [const Color(0xFFE69500).withOpacity(0.05), const Color(0xFF121212)],
          ),
        ),
        child: Stack(
          children: [
            vehiclesAsync.when(
              data: (vehicles) {
                if (vehicles.isEmpty) return const Center(child: Text('Nincsenek járművek.', style: TextStyle(color: Colors.white54)));
                
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                  itemCount: vehicles.length,
                  itemBuilder: (context, index) {
                    final vehicle = vehicles[index];
                    final vehicleId = vehicle.id;
                    if (vehicleId == null) return const SizedBox();

                    if (!_controllers.containsKey(vehicleId)) _controllers[vehicleId] = TextEditingController();

                    return StreamBuilder<DocumentSnapshot>(
                      stream: FirebaseFirestore.instance.collection('users').doc(user!.uid).collection('vehicles').doc(vehicleId).snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.hasData && snapshot.data!.exists) {
                          _initializeDataForVehicle(vehicleId, snapshot.data!.data() as Map<String, dynamic>);
                        }

                        return _buildVehicleNotificationCard(vehicle, vehicleId);
                      },
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFFE69500))),
              error: (e, st) => Center(child: Text('Hiba: $e', style: const TextStyle(color: Colors.red))),
            ),

            if (_showSuccess) _buildSuccessOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildVehicleNotificationCard(Jarmu vehicle, String vehicleId) {
    return Container(
      margin: const EdgeInsets.only(bottom: 32),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Column(
          children: [
            // FEJLÉC
            Container(
              padding: const EdgeInsets.all(24),
              color: Colors.white.withOpacity(0.02),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: const Color(0xFFE69500).withOpacity(0.1), shape: BoxShape.circle),
                    child: const Icon(Icons.notifications_active, color: Color(0xFFE69500), size: 24),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(vehicle.licensePlate, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 1.5)),
                        Text('${vehicle.make} ${vehicle.model}', style: const TextStyle(color: Colors.white38, fontSize: 13)),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _saveSettings(vehicleId),
                    icon: const Icon(Icons.check_circle_outline, size: 18),
                    label: const Text('BEÁLLÍTÁSOK MENTÉSE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE69500),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ],
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('E-MAIL ÉRTESÍTÉSEK TÍPUSA', style: TextStyle(color: Color(0xFFE69500), fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 2)),
                  const SizedBox(height: 16),
                  _buildSwitchTile(
                    'Dátum alapú figyelmeztetések', 
                    'Műszaki vizsga, biztosítás és éves szervizek lejárata előtt.', 
                    _notifyDate[vehicleId] ?? true,
                    (v) => setState(() => _notifyDate[vehicleId] = v),
                    Icons.calendar_month,
                  ),
                  const SizedBox(height: 12),
                  _buildSwitchTile(
                    'Km alapú figyelmeztetések', 
                    'Olajcsere, vezérlés és kopó alkatrészek az aktuális futás alapján.', 
                    _notifyKm[vehicleId] ?? true,
                    (v) => setState(() => _notifyKm[vehicleId] = v),
                    Icons.speed,
                  ),
                  
                  const SizedBox(height: 40),
                  const Text('ÉRTESÍTENDŐ CÍMEK', style: TextStyle(color: Color(0xFFE69500), fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 2)),
                  const SizedBox(height: 20),
                  
                  // EMAILEK LISTÁJA
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: (_selectedEmails[vehicleId] ?? []).map((email) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white10)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(email, style: const TextStyle(color: Colors.white, fontSize: 13)),
                          const SizedBox(width: 8),
                          InkWell(
                            onTap: () => setState(() => _selectedEmails[vehicleId]?.remove(email)),
                            child: const Icon(Icons.close, size: 16, color: Colors.redAccent),
                          ),
                        ],
                      ),
                    )).toList(),
                  ),
                  
                  const SizedBox(height: 20),
                  TextField(
                    controller: _controllers[vehicleId],
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Írjon be egy e-mail címet...',
                      hintStyle: const TextStyle(color: Colors.white24),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.02),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.add_circle, color: Color(0xFFE69500)),
                        onPressed: () => _addEmail(vehicleId),
                      ),
                    ),
                    onSubmitted: (_) => _addEmail(vehicleId),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile(String title, String sub, bool value, ValueChanged<bool> onChanged, IconData icon) {
    return Container(
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.02), borderRadius: BorderRadius.circular(20)),
      child: SwitchListTile(
        title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Text(sub, style: const TextStyle(color: Colors.white38, fontSize: 12)),
        value: value,
        onChanged: onChanged,
        activeColor: const Color(0xFFE69500),
        secondary: Icon(icon, color: value ? const Color(0xFFE69500) : Colors.white24),
      ),
    );
  }

  void _addEmail(String vehicleId) {
    final email = _controllers[vehicleId]!.text.trim();
    if (email.contains('@') && email.contains('.')) {
      setState(() {
        if (_selectedEmails[vehicleId] == null) _selectedEmails[vehicleId] = [];
        if (!_selectedEmails[vehicleId]!.contains(email)) _selectedEmails[vehicleId]!.add(email);
        _controllers[vehicleId]!.clear();
      });
    }
  }

  Widget _buildSuccessOverlay() {
    return Positioned.fill(
      child: Center(
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Container(
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(color: const Color(0xFF1E1E1E), borderRadius: BorderRadius.circular(32), border: Border.all(color: Colors.greenAccent.withOpacity(0.5)), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 40)]),
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle, size: 60, color: Colors.greenAccent),
                SizedBox(height: 20),
                Text('MENTVE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20, letterSpacing: 2)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
