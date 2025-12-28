// lib/main.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'firebase_options.dart';
import 'providers.dart';
import 'theme_provider.dart';
import 'ui/login_page.dart';
import 'ui/home_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await initializeDateFormatting('hu_HU', null);

  await Firebase.initializeApp(
    options: firebaseOptions,
  );

  // App Check aktiválása
  if (kIsWeb && !kDebugMode) {
     await FirebaseAppCheck.instance.activate(
      webProvider: ReCaptchaV3Provider('6LcbFTUsAAAAAADb_DSmebkFs4lYph7pgVCyBTW8'),
    );
    print("App Check élesítve éles webes környezetben.");
  } else {
    print("App Check KIHAGYVA (nem éles webes környezet).");
  }

  runApp(const ProviderScope(child: OlajfoltWebApp()));
}

class OlajfoltWebApp extends ConsumerWidget {
  const OlajfoltWebApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    const brandColor = Color(0xFFE69500); // Új, sötétebb narancs

    final darkTheme = ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: brandColor,
        brightness: Brightness.dark,
        primary: brandColor, 
      ),
      scaffoldBackgroundColor: const Color(0xFF121212),
      useMaterial3: true,
    );

    final lightTheme = ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: brandColor,
        brightness: Brightness.light,
        primary: brandColor,
      ),
      scaffoldBackgroundColor: const Color(0xFFf0f2f5),
      cardTheme: const CardThemeData(
        elevation: 1, 
        color: Colors.white,
      ),
      useMaterial3: true,
    );
    
    return MaterialApp(
      title: 'Olajfolt Web',
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: themeMode,
      home: const RootPage(),
    );
  }
}

class RootPage extends ConsumerWidget {
  const RootPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      data: (user) {
        if (user == null) {
          return const LoginPage();
        }
        return const HomePage();
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, st) => Scaffold(
        body: Center(child: Text('Hiba az autentikáció figyelésekor: $e')),
      ),
    );
  }
}
