// lib/providers.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:olajfolt_web/modellek/jarmu.dart';
import 'package:olajfolt_web/modellek/karbantartas_bejegyzes.dart';
import 'package:olajfolt_web/services/firestore_service.dart';

// --- AUTHENTICATION ---

final authServiceProvider = Provider<AuthService>((ref) => AuthService());
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<void> signInWithGoogleWeb() async {
    final GoogleAuthProvider googleProvider = GoogleAuthProvider();
    await _auth.signInWithRedirect(googleProvider);
  }

  Future<UserCredential> signUpWithEmail(String email, String password) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    await credential.user?.sendEmailVerification();
    return credential;
  }

  Future<UserCredential> signInWithEmail(String email, String password) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}

// --- FIRESTORE & DATA PROVIDERS ---

final firestoreServiceProvider = Provider<FirestoreService>((ref) => FirestoreService());

// A bejelentkezett felhasználó járműveinek stream-je
final vehiclesProvider = StreamProvider<List<Jarmu>>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user != null) {
    return ref.watch(firestoreServiceProvider).watchVehicles(user.uid);
  }
  return Stream.value([]);
});

// Az aktuálisan kiválasztott jármű ID-jának állapota
final selectedVehicleIdProvider = StateProvider<String?>((ref) => null);

// A kiválasztott járműhöz tartozó szervizek stream-je
final servicesForSelectedVehicleProvider = StreamProvider<List<Szerviz>>((ref) {
  final user = ref.watch(authStateProvider).value;
  final selectedVehicleId = ref.watch(selectedVehicleIdProvider);

  if (user != null && selectedVehicleId != null) {
    return ref.watch(firestoreServiceProvider).watchServices(user.uid, selectedVehicleId);
  }
  return Stream.value([]);
});
