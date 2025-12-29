// lib/ui/login_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart'; // HIÁNYZÓ IMPORT
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
        setState(() => _isLogin = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sikeres regisztráció! Kérlek, erősítsd meg az e-mail címedet a kiküldött levélben.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _errorText = e.message ?? 'Ismeretlen hiba');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = ref.watch(authServiceProvider);
    final theme = Theme.of(context);

    return Scaffold(
      body: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.grey[900]!, const Color(0xFF101016)],
              ),
            ),
          ),
          SizedBox(
            width: 500,
            height: 500,
            child: Opacity(
              opacity: 0.05,
              child: Image.asset('assets/olajfoltweb.png', fit: BoxFit.contain),
            ),
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              color: const Color(0xFF1E1E1E).withOpacity(0.9),
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_isLogin ? 'Bejelentkezés' : 'Regisztráció', style: theme.textTheme.headlineSmall?.copyWith(color: Colors.white)),
                    const SizedBox(height: 24),
                    
                    TextField(
                      controller: _emailController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(labelText: 'E-mail cím', border: OutlineInputBorder(), prefixIcon: Icon(Icons.email)),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _passwordController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(labelText: 'Jelszó', border: OutlineInputBorder(), prefixIcon: Icon(Icons.lock)),
                      obscureText: true,
                    ),
                    
                    if (_errorText != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 16.0),
                        child: Text(_errorText!, style: const TextStyle(color: Colors.redAccent)),
                      ),
                    
                    const SizedBox(height: 24),
                    
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _submit,
                        child: _isLoading ? const CircularProgressIndicator() : Text(_isLogin ? 'BEJELENTKEZÉS' : 'REGISZTRÁCIÓ'),
                      ),
                    ),
                    
                    TextButton(
                      onPressed: () => setState(() => _isLogin = !_isLogin),
                      child: Text(_isLogin ? 'Nincs fiókod? Regisztrálj!' : 'Van már fiókod? Jelentkezz be!'),
                    ),

                    const Divider(height: 24, color: Colors.white24),
                    
                    FilledButton.icon(
                      icon: const Icon(Icons.login),
                      label: const Text('Bejelentkezés Google fiókkal'),
                      onPressed: () async => await authService.signInWithGoogleWeb(),
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
