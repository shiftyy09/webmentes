// lib/services/firestore_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../modellek/jarmu.dart';
import '../modellek/karbantartas_bejegyzes.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _vehiclesRef(String userId) {
    return _db.collection('users').doc(userId).collection('vehicles');
  }

  CollectionReference<Map<String, dynamic>> _servicesRef(
    String userId,
    String vehicleId,
  ) {
    return _vehiclesRef(userId).doc(vehicleId).collection('services');
  }

  Stream<List<Jarmu>> watchVehicles(String userId) {
    return _vehiclesRef(userId).orderBy('licensePlate').snapshots().map(
      (snap) {
        return snap.docs
            .map((d) => Jarmu.fromFirestore(d.data(), documentId: d.id))
            .toList();
      },
    );
  }

  Future<String?> upsertVehicle(String userId, Jarmu jarmu) async {
    if (jarmu.id == null) {
      // Új jármű: hozzáadjuk és visszaadjuk az új ID-t.
      final docRef = await _vehiclesRef(userId).add(jarmu.toFirestore());
      return docRef.id;
    } else {
      // Meglévő jármű: frissítjük és visszaadjuk a meglévő ID-t.
      await _vehiclesRef(userId).doc(jarmu.id!).set(jarmu.toFirestore());
      return jarmu.id;
    }
  }

  Future<void> deleteVehicle(String userId, String vehicleId) async {
    final vehicleDoc = _vehiclesRef(userId).doc(vehicleId);

    final services = await vehicleDoc.collection('services').get();
    for (final doc in services.docs) {
      await doc.reference.delete();
    }

    await vehicleDoc.delete();
  }

  Stream<List<Szerviz>> watchServices(String userId, String vehicleId) {
    return _servicesRef(userId, vehicleId)
        .orderBy('date', descending: true)
        .snapshots()
        .map(
      (snap) {
        return snap.docs
            .map((d) => Szerviz.fromFirestore(d.data(), documentId: d.id))
            .toList();
      },
    );
  }

  Future<void> upsertService(
    String userId,
    String vehicleId,
    Szerviz szerviz,
  ) async {
    final data = szerviz.toFirestore();
    if (szerviz.id == null) {
      await _servicesRef(userId, vehicleId).add(data);
    } else {
      await _servicesRef(userId, vehicleId)
          .doc(szerviz.id!)
          .set(data, SetOptions(merge: true));
    }
  }

  Future<void> deleteService(
    String userId,
    String vehicleId,
    String serviceId,
  ) async {
    await _servicesRef(userId, vehicleId).doc(serviceId).delete();
  }
}
