// lib/ui/dashboard_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:olajfolt_web/providers.dart';
import 'package:olajfolt_web/theme_provider.dart';
import 'package:olajfolt_web/ui/home_page.dart';
import 'package:olajfolt_web/ui/calculators/transfer_cost_page.dart';
import 'package:olajfolt_web/ui/notification_settings_page.dart';
import 'package:url_launcher/url_launcher.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authStateProvider).value;
    final authService = ref.watch(authServiceProvider);
    final themeMode = ref.watch(themeProvider);
    final theme = Theme.of(context);

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
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Üdvözöljük az Olajfolt Web felületén!',
                    style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Válasszon az alábbi modulok közül:',
                    style: theme.textTheme.titleMedium?.copyWith(color: Colors.grey),
                  ),
                  const SizedBox(height: 50),
                  
                  // MENÜ KÁRTYÁK
                  Wrap(
                    spacing: 40,
                    runSpacing: 40,
                    alignment: WrapAlignment.center,
                    children: [
                      _MenuCard(
                        title: 'JÁRMŰVEK',
                        subtitle: 'Szerviznapló és karbantartás',
                        icon: Icons.directions_car,
                        color: Colors.orange,
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HomePage())),
                      ),
                      _MenuCard(
                        title: 'KALKULÁTOR',
                        subtitle: 'Átírási költségek számítása',
                        icon: Icons.calculate,
                        color: Colors.blue,
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TransferCostCalculatorPage())),
                      ),
                      _MenuCard(
                        title: 'ÉRTESÍTÉSEK',
                        subtitle: 'E-mail emlékeztetők beállítása',
                        icon: Icons.notifications_active,
                        color: Colors.green,
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationSettingsPage())),
                      ),
                    ],
                  ),

                  const SizedBox(height: 60),

                  // ANDROID PROMÓ BANNER - TISZTÁBB VERZIÓ
                  _buildAndroidBanner(context),
                ],
              ),
            ),
          ),
          
          // LÁBLÉC (FOOTER)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: const Color(0xFF1E1E1E),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Készítette: ', style: TextStyle(color: Colors.white54, fontSize: 12)),
                    InkWell(
                      onTap: () async {
                        final url = Uri.parse('https://nj-creative.hu');
                        if (await canLaunchUrl(url)) await launchUrl(url);
                      },
                      child: const Text('NJ-CREATIVE (NJ-creative.hu)', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text('Elérhetőség: info@olajfolt.hu  |  Verzió: 1.0', style: TextStyle(color: Colors.white54, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAndroidBanner(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 700),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF00C853), Color(0xFF1B5E20)], 
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00C853).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: Row(
        children: [
          // Android Ikon visszakerült
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.android, size: 32, color: Colors.white),
          ),
          const SizedBox(width: 20),
          
          // Szöveg - Tárgyilagosabb
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Teljes szinkronizáció web és app között',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Az adatok automatikusan frissülnek mindkét felületen.',
                  style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),

          // Letöltés Gomb
          ElevatedButton.icon(
            onPressed: () async {
              final url = Uri.parse('https://olajfolt.hu/app');
              if (await canLaunchUrl(url)) await launchUrl(url);
            },
            icon: const Icon(Icons.download, size: 18, color: Color(0xFF1B5E20)),
            label: const Text('LETÖLTÉS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1B5E20))),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 2,
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _MenuCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  State<_MenuCard> createState() => _MenuCardState();
}

class _MenuCardState extends State<_MenuCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: widget.onTap,
      onHover: (val) => setState(() => _isHovered = val),
      borderRadius: BorderRadius.circular(24),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 300,
        height: 200,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(24),
          border: _isHovered ? Border.all(color: widget.color, width: 2) : Border.all(color: Colors.transparent, width: 2),
          boxShadow: [
            BoxShadow(
              color: _isHovered ? widget.color.withOpacity(0.3) : Colors.black.withOpacity(0.1),
              blurRadius: _isHovered ? 20 : 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: widget.color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(widget.icon, size: 40, color: widget.color),
            ),
            const SizedBox(height: 20),
            Text(
              widget.title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 1.5),
            ),
            const SizedBox(height: 8),
            Text(
              widget.subtitle,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
