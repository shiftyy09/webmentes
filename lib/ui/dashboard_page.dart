// lib/ui/dashboard_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:olajfolt_web/providers.dart';
import 'package:olajfolt_web/theme_provider.dart';
import 'package:olajfolt_web/ui/home_page.dart'; // FONTOS: Ez az import kell a hiba javításához!
import 'package:olajfolt_web/ui/calculators/transfer_cost_page.dart';
import 'package:olajfolt_web/ui/notification_settings_page.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> with TickerProviderStateMixin {
  bool _showIntro = true;
  late AnimationController _iconController;
  late AnimationController _fadeController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  Timer? _safetyTimer;
  bool _isOnline = true;
  StreamSubscription? _connectivitySubscription;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();

    Connectivity().checkConnectivity().then((results) {
      _updateConnectionStatus(results);
    });

    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((results) {
      _updateConnectionStatus(results);
    });

    _iconController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));
    _scaleAnimation = CurvedAnimation(parent: _iconController, curve: Curves.elasticOut);

    _fadeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _fadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(_fadeController);

    _pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(_pulseController);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startAnimationSequence();
    });

    _safetyTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && _showIntro) {
        setState(() => _showIntro = false);
      }
    });
  }

  void _updateConnectionStatus(List<ConnectivityResult> results) {
    final isOnline = !results.contains(ConnectivityResult.none);
    if (isOnline != _isOnline && mounted) {
      setState(() => _isOnline = isOnline);
    }
  }

  Future<void> _startAnimationSequence() async {
    try {
      await _iconController.forward().orCancel;
      await Future.delayed(const Duration(milliseconds: 500));
      await _fadeController.forward().orCancel;
    } catch (e) {
      // ignore
    } finally {
      if (mounted) setState(() => _showIntro = false);
    }
  }

  Future<void> _manualRefresh() async {
    if (_isRefreshing) return;
    setState(() => _isRefreshing = true);

    ref.refresh(vehiclesProvider);
    await Future.delayed(const Duration(milliseconds: 1000));

    if (mounted) setState(() => _isRefreshing = false);
  }

  @override
  void dispose() {
    _iconController.dispose();
    _fadeController.dispose();
    _pulseController.dispose();
    _safetyTimer?.cancel();
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authStateProvider).value;
    final authService = ref.watch(authServiceProvider);
    final themeMode = ref.watch(themeProvider);
    final theme = Theme.of(context);

    return Scaffold(
      body: Stack(
        children: [
          // KÉP HOZZÁADÁSA A JOBB ALSÓ SAROKBA
          Positioned(
            bottom: 75,
            right: 0,
            child: Opacity(
              opacity: 1.0,
              child: Image.asset(
                'assets/hatterweb.png',
                width: 500,
                fit: BoxFit.contain,
              ),
            ),
          ),

          Scaffold(
            backgroundColor: Colors.transparent, // Hogy a háttérkép átlátszódjon
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
                    child: Row(
                      children: [
                        const Tooltip(message: 'Fiók szinkronizálva', child: Icon(Icons.cloud_done, color: Colors.green, size: 20)),
                        const SizedBox(width: 8),
                        Text(auth.email ?? '', style: const TextStyle(fontSize: 14)),
                      ],
                    ),
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
                        _buildAndroidBanner(context),
                      ],
                    ),
                  ),
                ),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  color: const Color(0xFF1E1E1E),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Text('Készítette: ', style: TextStyle(color: Colors.white54, fontSize: 12)),
                          InkWell(
                            onTap: () async {
                              final url = Uri.parse('https://www.facebook.com/profile.php?id=61573034549610');
                              if (await canLaunchUrl(url)) await launchUrl(url);
                            },
                            child: const Text('NJ-CREATIVE', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 12)),
                          ),
                          const SizedBox(width: 20),
                          const Text('|', style: TextStyle(color: Colors.white54, fontSize: 12)),
                          const SizedBox(width: 20),
                          TextButton.icon(
                            icon: const Icon(Icons.warning_amber, color: Colors.redAccent, size: 14),
                            label: const Text('Fiók törlése', style: TextStyle(color: Colors.redAccent, fontSize: 12)),
                            onPressed: () => _showDeleteAccountDialog(context, ref),
                            style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                alignment: Alignment.center
                            ),
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
          ),

          // --- VALÓS STÁTUSZ JELZŐ (HEARTBEAT ALAPJÁN) ---
          if (auth != null)
            Positioned(
              bottom: 24,
              right: 24,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_isOnline) ...[
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _manualRefresh,
                        borderRadius: BorderRadius.circular(30),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white24),
                          ),
                          child: _isRefreshing
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Icon(Icons.refresh, color: Colors.white, size: 20),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],

                  // HEARTBEAT FIGYELŐ
                  StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance.collection('users').doc(auth.uid).snapshots(),
                    builder: (context, snapshot) {
                      String statusText = 'Kapcsolódás...';
                      Color statusColor = Colors.grey;
                      bool isPhoneActive = false;

                      if (!_isOnline) {
                        statusText = 'Nincs internetkapcsolat';
                        statusColor = Colors.redAccent;
                      } else if (snapshot.hasData && snapshot.data!.exists) {
                        final data = snapshot.data!.data() as Map<String, dynamic>?;
                        final lastSync = data?['lastAppSync'] as Timestamp?;

                        if (lastSync != null) {
                          final diff = DateTime.now().difference(lastSync.toDate());
                          if (diff.inMinutes < 15) {
                            statusText = 'Mobilapp szinkronizálva';
                            statusColor = Colors.greenAccent;
                            isPhoneActive = true;
                          } else if (diff.inHours < 24) {
                            statusText = 'Mobil utoljára aktív: ${diff.inHours} órája';
                            statusColor = Colors.orangeAccent;
                          } else {
                            statusText = 'Mobil inaktív (>1 napja)';
                            statusColor = Colors.grey;
                          }
                        } else {
                          statusText = 'Mobilapp még nem csatlakozott';
                          statusColor = Colors.orangeAccent;
                        }
                      }

                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(color: statusColor.withOpacity(0.2), blurRadius: 10, spreadRadius: 2),
                          ],
                          border: Border.all(color: Colors.white10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isPhoneActive)
                              FadeTransition(
                                opacity: _pulseAnimation,
                                child: Container(width: 10, height: 10, decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle, boxShadow: [BoxShadow(color: statusColor, blurRadius: 6, spreadRadius: 1)])),
                              )
                            else
                              Container(width: 10, height: 10, decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle)),
                            const SizedBox(width: 12),
                            Text(statusText, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                            const SizedBox(width: 4),
                            Icon(isPhoneActive ? Icons.phonelink_ring : Icons.phonelink_off, color: Colors.white54, size: 16),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

          if (_showIntro)
            Positioned.fill(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Container(
                  color: const Color(0xFF101010),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ScaleTransition(
                          scale: _scaleAnimation,
                          child: Container(
                            padding: const EdgeInsets.all(30),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              shape: BoxShape.circle,
                              boxShadow: [BoxShadow(color: Colors.green.withOpacity(0.5), blurRadius: 50, spreadRadius: 10)],
                              border: Border.all(color: Colors.green, width: 2),
                            ),
                            child: const Icon(Icons.check, size: 80, color: Colors.greenAccent),
                          ),
                        ),
                        const SizedBox(height: 40),
                        const Text('Sikeres bejelentkezés', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                        const SizedBox(height: 16),
                        const Text('Adatok szinkronizálása...', style: TextStyle(color: Colors.white54, fontSize: 16)),
                        const SizedBox(height: 30),
                        const SizedBox(width: 200, child: LinearProgressIndicator(color: Colors.green, backgroundColor: Colors.white10)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _showInfoDialog(BuildContext context, {required String title, required String content, required IconData icon, required Color color}) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: color),
          ),
          title: Row(
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 10),
              Text(title, style: const TextStyle(color: Colors.white)),
            ],
          ),
          content: Text(content, style: const TextStyle(color: Colors.white70)),
          actions: <Widget>[
            TextButton(
              child: Text('OK', style: TextStyle(color: color)),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _showDeleteAccountDialog(BuildContext context, WidgetRef ref) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // User must tap a button to dismiss
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Colors.redAccent),
          ),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
              SizedBox(width: 10),
              Text('Fiók törlése', style: TextStyle(color: Colors.white)),
            ],
          ),
          content: const SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(
                  'Biztosan törölni szeretné a fiókját?',
                  style: TextStyle(color: Colors.white70),
                ),
                SizedBox(height: 10),
                Text(
                  'Ez a művelet nem vonható vissza. Minden adata véglegesen törlődik.',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Mégse', style: TextStyle(color: Colors.white70)),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.delete_forever, size: 18),
              label: const Text('Törlés'),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.redAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () async {
                final authService = ref.read(authServiceProvider);
                try {
                  Navigator.of(dialogContext).pop();
                  await authService.deleteAccount();
                  if (mounted) {
                    _showInfoDialog(context,
                        title: 'Sikeres törlés',
                        content: 'A fiók és a hozzá tartozó adatok sikeresen törölve lettek.',
                        icon: Icons.check_circle,
                        color: Colors.green);
                  }
                } catch (e) {
                  if (mounted) {
                    _showInfoDialog(context,
                        title: 'Hiba a törlés során',
                        content: 'Hiba történt a fiók törlése közben. Kérjük, próbálja újra később. Hiba: ${e.toString()}',
                        icon: Icons.error,
                        color: Colors.red);
                  }
                }
              },
            ),
          ],
        );
      },
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
        boxShadow: [BoxShadow(color: const Color(0xFF00C853).withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: Row(
        children: [
          Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle), child: const Icon(Icons.android, size: 32, color: Colors.white)),
          const SizedBox(width: 20),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Teljes szinkronizáció web és app között', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)), const SizedBox(height: 4), Text('Az adatok automatikusan frissülnek mindkét felületen.', style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14))])),
          const SizedBox(width: 20),
          ElevatedButton.icon(
            onPressed: () async {
              final url = Uri.parse('https://olajfolt.hu/app');
              if (await canLaunchUrl(url)) await launchUrl(url);
            },
            icon: const Icon(Icons.download, size: 18, color: Color(0xFF1B5E20)),
            label: const Text('LETÖLTÉS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1B5E20))),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 2),
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

  const _MenuCard({required this.title, required this.subtitle, required this.icon, required this.color, required this.onTap});

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
          boxShadow: [BoxShadow(color: _isHovered ? widget.color.withOpacity(0.3) : Colors.black.withOpacity(0.1), blurRadius: _isHovered ? 20 : 10, offset: const Offset(0, 5))],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: widget.color.withOpacity(0.1), shape: BoxShape.circle), child: Icon(widget.icon, size: 40, color: widget.color)),
            const SizedBox(height: 20),
            Text(widget.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
            const SizedBox(height: 8),
            Text(widget.subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}