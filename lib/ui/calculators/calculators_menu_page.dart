import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'transfer_cost_page.dart';
import 'used_car_value_page.dart';
import '../../providers.dart';
import '../../modellek/jarmu.dart';

class CalculatorsMenuPage extends ConsumerWidget {
  const CalculatorsMenuPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final vehiclesAsync = ref.watch(vehiclesProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Color(0xFFE69500)),
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.2,
            colors: [
              const Color(0xFFE69500).withOpacity(0.08),
              const Color(0xFF121212),
            ],
          ),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 120, 24, 40),
              child: Column(
                children: [
                  const Text(
                    'PRÉMIUM KALKULÁTOROK',
                    style: TextStyle(
                      fontSize: 14, 
                      fontWeight: FontWeight.w900, 
                      letterSpacing: 4, 
                      color: Color(0xFFE69500),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Minden, amire az adásvételhez szükséged lehet',
                    style: TextStyle(color: Color(0xFFE69500), fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 60),
                  
                  LayoutBuilder(builder: (context, constraints) {
                    bool isWide = constraints.maxWidth > 900;
                    return Flex(
                      direction: isWide ? Axis.horizontal : Axis.vertical,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildMainOption(
                          context,
                          title: 'Átírás Kalkulátor',
                          description: 'Pontos számítás az aktuális illetékek és okmánydíjak alapján.',
                          icon: Icons.account_balance_wallet_outlined,
                          color: const Color(0xFFE69500),
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TransferCostCalculatorPage())),
                          isWide: isWide,
                        ),
                        if (isWide) const SizedBox(width: 40) else const SizedBox(height: 32),
                        _buildMainOption(
                          context,
                          title: 'AI Értékbecslő',
                          description: 'Valós piaci hirdetések és szerviztörténet alapú elemzés.',
                          icon: Icons.auto_awesome,
                          color: const Color(0xFFE69500),
                          onTap: () {
                            vehiclesAsync.when(
                              data: (vehicles) {
                                if (vehicles.isEmpty) {
                                  _showError(context, 'Nincs rögzített járműved az értékbecsléshez!');
                                } else {
                                  _showCompactVehiclePicker(context, ref, vehicles);
                                }
                              },
                              loading: () {},
                              error: (_, __) {},
                            );
                          },
                          isWide: isWide,
                          isHot: true,
                        ),
                      ],
                    );
                  }),
                  
                  const SizedBox(height: 80),
                  _buildMobileAppPromo(context),
                  const SizedBox(height: 40),
                  _buildMarketInsight(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMainOption(BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required bool isWide,
    bool isHot = false,
  }) {
    return Expanded(
      flex: isWide ? 1 : 0,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            height: 280,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: color.withOpacity(0.3), width: 1.5),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 40, offset: const Offset(0, 10)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Icon(icon, size: 48, color: color),
                    if (isHot)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)),
                        child: const Text('AI POWERED', style: TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                  ],
                ),
                const Spacer(),
                Text(title, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 12),
                Text(description, style: const TextStyle(color: Colors.white60, fontSize: 14, height: 1.4)),
                const Spacer(),
                Row(
                  children: [
                    const Text('HASZNÁLAT', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.2)),
                    const SizedBox(width: 8),
                    Icon(Icons.arrow_forward_rounded, size: 16, color: color),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showCompactVehiclePicker(BuildContext context, WidgetRef ref, List<Jarmu> vehicles) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: const BorderSide(color: Color(0xFFE69500), width: 0.5)),
        title: const Text('Melyik járművet értékeljük?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: 500,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.5),
            child: GridView.builder(
              shrinkWrap: true,
              itemCount: vehicles.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisExtent: 80,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemBuilder: (context, index) {
                final v = vehicles[index];
                return InkWell(
                  onTap: () {
                    ref.read(selectedVehicleIdProvider.notifier).state = v.licensePlate;
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => UsedCarValuePage(vehicle: v)));
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.directions_car, color: Color(0xFFE69500), size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${v.make} ${v.model}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13, overflow: TextOverflow.ellipsis)),
                              Text(v.licensePlate, style: const TextStyle(color: Colors.white54, fontSize: 11)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Mégse', style: TextStyle(color: Colors.white38)))
        ],
      ),
    );
  }

  Widget _buildMobileAppPromo(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFFE69500), Color(0xFFB37700)]),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [BoxShadow(color: const Color(0xFFE69500).withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Row(
        children: [
          const Icon(Icons.phone_android_rounded, size: 60, color: Colors.black87),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('Olajfolt a zsebedben is!', style: TextStyle(color: Colors.black, fontSize: 22, fontWeight: FontWeight.bold)),
                SizedBox(height: 4),
                Text('Vidd magaddal a szerviznaplót. Töltsd le az Android appot a teljes szinkronizációhoz!', style: TextStyle(color: Colors.black87, fontSize: 14)),
              ],
            ),
          ),
          const SizedBox(width: 24),
          ElevatedButton(
            onPressed: () => launchUrl(Uri.parse('https://play.google.com/store/apps/details?id=hu.olajfolt.app')),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text('LETÖLTÉS', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildMarketInsight() {
    return Row(
      children: [
        Expanded(
          child: _buildMiniStat(Icons.trending_up, 'Piaci Trendek', 'A használt autó árak stabilizálódni látszanak az idei negyedévben.'),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: _buildMiniStat(Icons.security, 'Vezetett Napló', 'A vezetett szervizkönyv átlagosan 12%-kal növeli az autó eladhatóságát.'),
        ),
      ],
    );
  }

  Widget _buildMiniStat(IconData icon, String title, String text) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFFE69500), size: 20),
              const SizedBox(width: 12),
              Text(title, style: const TextStyle(color: Color(0xFFE69500), fontWeight: FontWeight.bold, fontSize: 15)),
            ],
          ),
          const SizedBox(height: 12),
          Text(text, style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.5)),
        ],
      ),
    );
  }

  void _showError(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.redAccent));
  }
}
