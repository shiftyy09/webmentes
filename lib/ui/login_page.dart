// lib/ui/login_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLogin = true;
  bool _isLoading = false;
  String? _errorText;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String _getErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found': return 'Nincs ilyen felhasználó ezzel az e-mail címmel.';
      case 'wrong-password': return 'Hibás jelszó. Próbáld újra!';
      case 'email-already-in-use': return 'Ez az e-mail cím már regisztrálva van.';
      case 'invalid-email': return 'Érvénytelen e-mail formátum.';
      case 'weak-password': return 'Túl gyenge jelszó (min. 6 karakter).';
      case 'network-request-failed': return 'Hálózati hiba. Ellenőrizd az internetet!';
      case 'too-many-requests': return 'Túl sok próbálkozás. Várj egy kicsit!';
      case 'user-disabled': return 'Ezt a fiókot letiltották.';
      default: return 'Hiba történt: ${e.message}';
    }
  }

  Future<void> _submit() async {
    if (_isLoading) return;
    setState(() { _isLoading = true; _errorText = null; });

    try {
      final authService = ref.read(authServiceProvider);

      if (_isLogin) {
        // --- BELÉPÉS ---
        final credential = await authService.signInWithEmail(_emailController.text, _passwordController.text);
        final user = credential.user;

        if (user != null) {
          await user.reload();
          if (!mounted) return;

          if (!user.emailVerified) {
            // 1. Üzenet megjelenítése
            setState(() => _errorText = 'Az e-mail cím nincs megerősítve!');

            // 2. Felajánljuk az újraküldést (és megvárjuk, amíg bezárja az ablakot)
            // Fontos: Itt még be van jelentkezve, ezért tud emailt küldeni!
            await _showResendDialog(user);

            // 3. CSAK EZUTÁN léptetjük ki
            await authService.signOut();
          }
          // Ha minden rendben, a main.dart automatikusan beenged.
        }

      } else {
        // --- REGISZTRÁCIÓ ---
        final credential = await authService.signUpWithEmail(_emailController.text, _passwordController.text);
        final user = credential.user;

        if (user != null) {
          try {
            await user.sendEmailVerification();
          } catch (e) {
            print("Hiba az email küldésekor: $e");
          }

          await authService.signOut();
        }

        if (!mounted) return;

        _showInfoDialog(
          'Sikeres regisztráció',
          'Egy megerősítő linket küldtünk a(z) ${_emailController.text} címre.\nKérjük, kattints rá a linkre, majd jelentkezz be!',
          Icons.mark_email_read,
          Colors.green,
        );

        setState(() {
          _isLogin = true;
          _passwordController.clear();
        });
      }

    } on FirebaseAuthException catch (e) {
      if (mounted) setState(() => _errorText = _getErrorMessage(e));
    } catch (e) {
      if (mounted) setState(() => _errorText = 'Ismeretlen hiba történt: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _showResendDialog(User user) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('Megerősítés szükséges', style: TextStyle(color: Colors.white)),
        content: const Text(
            'A belépéshez meg kell erősítened az e-mail címedet.\n\nHa nem kaptad meg az e-mailt, küldhetünk egy újat.',
            style: TextStyle(color: Colors.white70)
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Rendben, kilépés'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
            onPressed: () async {
              try {
                await user.sendEmailVerification();
                if (mounted) {
                  Navigator.pop(context); // Bezárjuk az ablakot
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('E-mail sikeresen elküldve!'), backgroundColor: Colors.green)
                  );
                }
              } on FirebaseAuthException catch (e) {
                String errorMsg = 'Hiba történt.';
                if (e.code == 'too-many-requests') {
                  errorMsg = 'Túl sok kérés! Várj pár percet.';
                }
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(errorMsg), backgroundColor: Colors.red)
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Hiba: $e'), backgroundColor: Colors.red)
                  );
                }
              }
            },
            child: const Text('E-mail újraküldése'),
          ),
        ],
      ),
    );
  }

  Future<void> _showInfoDialog(String title, String content, IconData icon, Color color) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: color)),
        title: Row(children: [Icon(icon, color: color), const SizedBox(width: 10), Text(title, style: const TextStyle(color: Colors.white))]),
        content: Text(content, style: const TextStyle(color: Colors.white70)),
        actions: [TextButton(child: Text('OK', style: TextStyle(color: color)), onPressed: () => Navigator.of(context).pop())],
      ),
    );
  }

  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri)) {
      if (mounted) _showInfoDialog('Hiba', 'A link megnyitása sikertelen.', Icons.error, Colors.red);
    }
  }

  Future<void> _showPasswordResetDialog() async {
    final resetEmailController = TextEditingController();
    return showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Colors.orange)),
          title: const Row(children: [Icon(Icons.help_outline, color: Colors.orange), SizedBox(width: 10), Text('Elfelejtett jelszó', style: TextStyle(color: Colors.white))]),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Add meg az e-mail címedet, és küldünk egy linket.', style: TextStyle(color: Colors.white70)),
              const SizedBox(height: 20),
              TextField(
                controller: resetEmailController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(labelText: 'E-mail cím', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), prefixIcon: const Icon(Icons.email), filled: true, fillColor: Colors.grey[900]),
              ),
            ],
          ),
          actions: [
            TextButton(child: const Text('Mégse', style: TextStyle(color: Colors.white70)), onPressed: () => Navigator.pop(context)),
            ElevatedButton(
              onPressed: () async {
                try {
                  await ref.read(authServiceProvider).sendPasswordResetEmail(resetEmailController.text);
                  if (context.mounted) {
                    Navigator.pop(context);
                    _showInfoDialog('Siker', 'Link elküldve!', Icons.check_circle, Colors.green);
                  }
                } catch (e) {
                  if (context.mounted) {
                    Navigator.pop(context);
                    _showInfoDialog('Hiba', 'Nem sikerült elküldeni.', Icons.error, Colors.red);
                  }
                }
              },
              child: const Text('Küldés'),
            ),
          ],
        ));
  }

  @override
  Widget build(BuildContext context) {
    final authService = ref.watch(authServiceProvider);
    final theme = Theme.of(context);
    final isLargeScreen = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      body: Row(
        children: [
          Expanded(
            flex: 2,
            child: Container(
              color: const Color(0xFF101016),
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(32),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (!isLargeScreen) ...[Center(child: Image.asset('assets/olajfoltweb.png', width: 120, height: 120)), const SizedBox(height: 32)],
                        Text(_isLogin ? 'Üdvözöljük újra!' : 'Fiók létrehozása', style: theme.textTheme.headlineMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                        const SizedBox(height: 8),
                        Text(_isLogin ? 'Jelentkezz be a folytatáshoz.' : 'Regisztrálj az adatok szinkronizálásához.', style: TextStyle(color: Colors.grey[400]), textAlign: TextAlign.center),
                        const SizedBox(height: 32),
                        TextField(controller: _emailController, style: const TextStyle(color: Colors.white), decoration: InputDecoration(labelText: 'E-mail cím', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), prefixIcon: const Icon(Icons.email), filled: true, fillColor: Colors.grey[900]), keyboardType: TextInputType.emailAddress),
                        const SizedBox(height: 16),
                        TextField(controller: _passwordController, style: const TextStyle(color: Colors.white), decoration: InputDecoration(labelText: 'Jelszó', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), prefixIcon: const Icon(Icons.lock), filled: true, fillColor: Colors.grey[900]), obscureText: true),
                        if (_isLogin) Align(alignment: Alignment.centerRight, child: TextButton(onPressed: _showPasswordResetDialog, child: const Text('Elfelejtett jelszó?'))),
                        if (_errorText != null) Padding(padding: const EdgeInsets.only(top: 8.0), child: Text(_errorText!, style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold))),
                        const SizedBox(height: 24),
                        SizedBox(height: 50, child: ElevatedButton(onPressed: _submit, style: ElevatedButton.styleFrom(backgroundColor: theme.colorScheme.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: _isLoading ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Text(_isLogin ? 'BEJELENTKEZÉS' : 'REGISZTRÁCIÓ', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)))),
                        const SizedBox(height: 16),
                        TextButton(onPressed: () => setState(() => _isLogin = !_isLogin), child: Text(_isLogin ? 'Nincs még fiókod? Regisztrálj!' : 'Van már fiókod? Jelentkezz be!')),
                        const SizedBox(height: 24),
                        const Row(children: [Expanded(child: Divider(color: Colors.white24)), Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('VAGY', style: TextStyle(color: Colors.white54))), Expanded(child: Divider(color: Colors.white24))]),
                        const SizedBox(height: 24),
                        SizedBox(height: 50, child: OutlinedButton.icon(icon: const Icon(Icons.login), label: const Text('Folytatás Google fiókkal'), onPressed: () async => await authService.signInWithGoogleWeb(), style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Colors.white24), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))))),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (isLargeScreen)
            Expanded(
              flex: 3,
              child: Container(
                decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topRight, end: Alignment.bottomLeft, colors: [Colors.orange.shade900, const Color(0xFF2C2C2C)])),
                child: Padding(
                  padding: const EdgeInsets.all(60.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Image.asset('assets/olajfoltweb.png', width: 250, fit: BoxFit.contain),
                      const SizedBox(height: 40),
                      const Text('A jövő szerviznaplója.', style: TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      const Text('Kezeld járműveidet profin, szinkronizáld adataidat valós időben a mobiloddal, és soha ne maradj le egyetlen karbantartásról sem.', style: TextStyle(color: Colors.white70, fontSize: 18, height: 1.5)),
                      const SizedBox(height: 60),
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white.withOpacity(0.2))),
                        child: Row(
                          children: [
                            const Icon(Icons.android, size: 48, color: Colors.greenAccent),
                            const SizedBox(width: 20),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Olajfolt Mobilalkalmazás', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)), const SizedBox(height: 4), Text('Töltsd le Androidra és vidd magaddal az adataidat!', style: TextStyle(color: Colors.white.withOpacity(0.7)))])),
                            const SizedBox(width: 20),
                            ElevatedButton(onPressed: () => _launchURL('https://olajfolt.hu/app'), style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black), child: const Text('LETÖLTÉS')),
                          ],
                        ),
                      ),
                      const Spacer(),
                      const Divider(color: Colors.white24),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [InkWell(onTap: () => _launchURL('https://nj-creative.hu'), child: const Text('Fejlesztette: NJ-CREATIVE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))), const SizedBox(height: 4), const Text('info@olajfolt.hu', style: TextStyle(color: Colors.white54))]),
                          const Text('v1.0', style: TextStyle(color: Colors.white54)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}