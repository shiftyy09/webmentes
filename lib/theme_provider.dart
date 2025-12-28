// lib/theme_provider.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// 1. A provider, ami globálisan elérhetővé teszi a téma kezelőnket.
final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) {
  return ThemeNotifier();
});

// 2. A "kezelő" (StateNotifier), ami a téma állapotát tárolja és a logikát tartalmazza.
class ThemeNotifier extends StateNotifier<ThemeMode> {
  // Alapértelmezetten a világos témával indulunk.
  ThemeNotifier() : super(ThemeMode.light);

  // Metódus a téma megváltoztatására.
  void toggleTheme() {
    // Ha az állapot jelenleg világos, válts sötétre, egyébként pedig világosra.
    state = state == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
  }
}
