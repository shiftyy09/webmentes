// lib/ui/login_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers.dart';

class LoginPage extends ConsumerWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authService = ref.watch(authServiceProvider);
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.grey[900]!,
              const Color(0xFF101016),
            ],
          ),
        ),
        child: Center(
          child: Column(
            // MainAxisAlignment.center helyett Spacer-eket használunk
            children: [
              const Spacer(flex: 2), // Felső rugalmas tér

              // 1. A logó, fent, ésszerűbb méretben
              SizedBox(
                width: 300,
                height: 300,
                child: Image.asset('assets/olajfoltweb.png', fit: BoxFit.contain),
              ),
              const SizedBox(height: 24), // Távolság a logó és a kártya között

              // 2. A bejelentkező kártya
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
                        const Text(
                          'Üdvözöl az Olajfolt!',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Jelentkezz be Google fiókkal a járműveid és szerviznaplód eléréséhez.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white70, height: 1.5),
                        ),
                        const SizedBox(height: 32),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            icon: const Icon(Icons.login), 
                            label: const Text('Bejelentkezés Google fiókkal'),
                            style: FilledButton.styleFrom(
                              backgroundColor: theme.colorScheme.primary,
                              foregroundColor: theme.colorScheme.onPrimary,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            onPressed: () async {
                              try {
                                await authService.signInWithGoogleWeb();
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Sikertelen bejelentkezés: $e'),
                                      backgroundColor: Colors.redAccent,
                                    ),
                                  );
                                }
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const Spacer(flex: 3), // Alsó rugalmas tér
            ],
          ),
        ),
      ),
    );
  }
}
