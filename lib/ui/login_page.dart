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
      case 'user-not-found':
        return 'Nincs ilyen felhasználó ezzel az e-mail címmel.';
      case 'wrong-password':
        return 'Hibás jelszó. Próbáld újra!';
      case 'email-already-in-use':
        return 'Ez az e-mail cím már regisztrálva van.';
      case 'invalid-email':
        return 'Érvénytelen e-mail formátum.';
      case 'weak-password':
        return 'Túl gyenge jelszó (min. 6 karakter).';
      case 'network-request-failed':
        return 'Hálózati hiba. Ellenőrizd az internetkapcsolatot!';
      case 'too-many-requests':
        return 'Túl sok sikertelen próbálkozás. Próbáld újra később.';
      case 'user-disabled':
        return 'Ezt a felhasználói fiókot letiltották.';
      default:
        return 'Hiba történt: ${e.message}';
    }
  }

  Future<void> _submit() async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    try {
      final authService = ref.read(authServiceProvider);
      if (_isLogin) {
        await authService.signInWithEmail(_emailController.text, _passwordController.text);
      } else {
        await authService.signUpWithEmail(_emailController.text, _passwordController.text);
        _showInfoDialog(
          'Sikeres regisztráció',
          'Egy megerősítő linket küldtünk az e-mail címedre. Kérjük, kattints rá a bejelentkezés előtt!',
          Icons.check_circle,
          Colors.green,
        );
        setState(() => _isLogin = true);
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _errorText = _getErrorMessage(e));
    } catch (e) {
      setState(() => _errorText = 'Ismeretlen hiba történt.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _showInfoDialog(String title, String content, IconData icon, Color color) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
        actions: [
          TextButton(
            child: Text('OK', style: TextStyle(color: color)),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
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
        builder: (context) {
          return AlertDialog(
              backgroundColor: const Color(0xFF1E1E1E),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: Colors.orange),
              ),
              title: const Row(
                children: [
                  Icon(Icons.help_outline, color: Colors.orange),
                  SizedBox(width: 10),
                  Text('Elfelejtett jelszó', style: TextStyle(color: Colors.white)),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                      'Add meg az e-mail címedet, és küldünk egy linket a jelszó visszaállításához.', 
                      style: TextStyle(color: Colors.white70)),
                  const SizedBox(height: 20),
                  TextField(
                    controller: resetEmailController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'E-mail cím',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.email),
                      filled: true,
                      fillColor: Colors.grey[900],
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  child: const Text('Mégse', style: TextStyle(color: Colors.white70)),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.send, size: 18),
                  label: const Text('Link küldése'),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.orange,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () async {
                    final authService = ref.read(authServiceProvider);
                    try {
                      await authService.sendPasswordResetEmail(resetEmailController.text);
                      Navigator.of(context).pop();
                      _showInfoDialog(
                        'Link elküldve',
                        'A jelszó-visszaállító linket elküldtük az e-mail címedre!',
                        Icons.check_circle,
                        Colors.green,
                      );
                    } catch (e) {
                      Navigator.of(context).pop();
                       _showInfoDialog(
                        'Hiba',
                        (e as FirebaseAuthException).message ?? 'Ismeretlen hiba.',
                        Icons.error,
                        Colors.red,
                      );
                    }
                  },
                ),
              ]);
        });
  }

  @override
  Widget build(BuildContext context) {
    final authService = ref.watch(authServiceProvider);
    final theme = Theme.of(context);
    final isLargeScreen = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      body: Row(
        children: [
          // BAL OLDAL - BEJELENTKEZÉS
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
                        if (!isLargeScreen) ...[
                          Center(
                            child: Image.asset('assets/olajfoltweb.png', width: 120, height: 120),
                          ),
                          const SizedBox(height: 32),
                        ],
                        
                        Text(
                          _isLogin ? 'Üdvözöljük újra!' : 'Fiók létrehozása',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _isLogin ? 'Jelentkezz be a folytatáshoz.' : 'Regisztrálj az adatok szinkronizálásához.',
                          style: TextStyle(color: Colors.grey[400]),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),

                        TextField(
                          controller: _emailController,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'E-mail cím',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            prefixIcon: const Icon(Icons.email),
                            filled: true,
                            fillColor: Colors.grey[900],
                          ),
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _passwordController,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'Jelszó',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            prefixIcon: const Icon(Icons.lock),
                            filled: true,
                            fillColor: Colors.grey[900],
                          ),
                          obscureText: true,
                        ),

                        if (_isLogin)
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: _showPasswordResetDialog,
                              child: const Text('Elfelejtett jelszó?'),
                            ),
                          ),

                        if (_errorText != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(_errorText!, style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                          ),

                        const SizedBox(height: 24),

                        SizedBox(
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.colorScheme.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: _isLoading 
                                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) 
                                : Text(_isLogin ? 'BEJELENTKEZÉS' : 'REGISZTRÁCIÓ', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                        ),

                        const SizedBox(height: 16),
                        
                        TextButton(
                          onPressed: () => setState(() => _isLogin = !_isLogin),
                          child: Text(_isLogin ? 'Nincs még fiókod? Regisztrálj!' : 'Van már fiókod? Jelentkezz be!'),
                        ),

                        const SizedBox(height: 24),
                        const Row(children: [Expanded(child: Divider(color: Colors.white24)), Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('VAGY', style: TextStyle(color: Colors.white54))), Expanded(child: Divider(color: Colors.white24))]),
                        const SizedBox(height: 24),

                        SizedBox(
                          height: 50,
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.login),
                            label: const Text('Folytatás Google fiókkal'),
                            onPressed: () async => await authService.signInWithGoogleWeb(),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: Colors.white24),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
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
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                    colors: [Colors.orange.shade900, const Color(0xFF2C2C2C)],
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(60.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Image.asset('assets/olajfoltweb.png', width: 250, fit: BoxFit.contain),
                      const SizedBox(height: 40),
                      
                      const Text(
                        'A jövő szerviznaplója.',
                        style: TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Kezeld járműveidet profin, szinkronizáld adataidat valós időben a mobiloddal, és soha ne maradj le egyetlen karbantartásról sem.',
                        style: TextStyle(color: Colors.white70, fontSize: 18, height: 1.5),
                      ),
                      
                      const SizedBox(height: 60),

                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withOpacity(0.2)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.android, size: 48, color: Colors.greenAccent),
                            const SizedBox(width: 20),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Olajfolt Mobilalkalmazás', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 4),
                                  Text('Töltsd le Androidra és vidd magaddal az adataidat!', style: TextStyle(color: Colors.white.withOpacity(0.7))),
                                ],
                              ),
                            ),
                            const SizedBox(width: 20),
                            ElevatedButton(
                              onPressed: () => _launchURL('https://olajfolt.hu/app'),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black),
                              child: const Text('LETÖLTÉS'),
                            ),
                          ],
                        ),
                      ),

                      const Spacer(),

                      const Divider(color: Colors.white24),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              InkWell(
                                onTap: () => _launchURL('https://nj-creative.hu'),
                                child: const Text('Fejlesztette: NJ-CREATIVE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              ),
                              const SizedBox(height: 4),
                              const Text('info@olajfolt.hu', style: TextStyle(color: Colors.white54)),
                            ],
                          ),
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
