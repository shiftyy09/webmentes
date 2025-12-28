// lib/providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'services/auth_service.dart';
import 'services/firestore_service.dart';
import 'modellek/jarmu.dart';
import 'modellek/karbantartas_bejegyzes.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService();
});

final authStateProvider = StreamProvider<User?>((ref) {
  final auth = ref.watch(authServiceProvider);
  return auth.authStateChanges;
});

final selectedVehicleIdProvider = StateProvider<String?>((ref) => null);

final vehiclesProvider = StreamProvider<List<Jarmu>>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return const Stream.empty();
  final fs = ref.watch(firestoreServiceProvider);
  return fs.watchVehicles(user.uid);
});

final servicesForSelectedVehicleProvider =
    StreamProvider.autoDispose<List<Szerviz>>((ref) {
  final user = ref.watch(authStateProvider).value;
  final vehicleId = ref.watch(selectedVehicleIdProvider);
  if (user == null || vehicleId == null) return const Stream.empty();
  final fs = ref.watch(firestoreServiceProvider);
  return fs.watchServices(user.uid, vehicleId);
});
