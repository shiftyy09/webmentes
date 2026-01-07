// lib/services/firestore_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../modellek/jarmu.dart';
import '../modellek/karbantartas_bejegyzes.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --- HELPER METÓDUSOK ---

  String _generateVehicleId(String licensePlate) {
    return licensePlate.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toUpperCase();
  }

  CollectionReference<Map<String, dynamic>> _vehiclesRef(String userId) {
    return _db.collection('users').doc(userId).collection('vehicles');
  }

  CollectionReference<Map<String, dynamic>> _servicesRef(String userId, String vehicleId) {
    return _vehiclesRef(userId).doc(vehicleId).collection('services');
  }

  // --- JÁRMŰ MŰVELETEK ---

  Stream<List<Jarmu>> watchVehicles(String userId) {
    return _vehiclesRef(userId).snapshots().map((snap) {
      return snap.docs.map((d) => Jarmu.fromFirestore(d.data(), documentId: d.id)).toList();
    });
  }

  Future<int> upsertVehicle(String userId, Jarmu jarmu) async {
    final vehicleId = _generateVehicleId(jarmu.licensePlate);
    
    final Map<String, dynamic> data = {
      'licensePlate': jarmu.licensePlate,
      'make': jarmu.make,
      'model': jarmu.model,
      'year': jarmu.year,
      'mileage': jarmu.mileage,
      'vin': jarmu.vin == '' ? null : jarmu.vin,
      'vezerlesTipusa': jarmu.vezerlesTipusa,
      'lastUpdated': FieldValue.serverTimestamp(),
      'customIntervals': {},
      'imagePath': null,
    };

    int newId;
    if (jarmu.id == null) {
      final snapshot = await _vehiclesRef(userId).get();
      newId = snapshot.docs.length + 1;
      data['id'] = newId;
    } else {
      newId = int.tryParse(jarmu.id!) ?? 0;
    }

    await _vehiclesRef(userId).doc(vehicleId).set(data, SetOptions(merge: true));
    return newId;
  }

  Future<void> deleteVehicle(String userId, String vehicleId) async {
    final vehicleDoc = _vehiclesRef(userId).doc(vehicleId);
    final services = await vehicleDoc.collection('services').get();
    for (final doc in services.docs) {
      await doc.reference.delete();
    }
    await vehicleDoc.delete();
  }

  // --- SZERVIZ MŰVELETEK ---

  Stream<List<Szerviz>> watchServices(String userId, String vehicleId) {
    return _servicesRef(userId, vehicleId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snap) {
      return snap.docs.map((d) => Szerviz.fromFirestore(d.data(), documentId: d.id)).toList();
    });
  }

  Future<void> upsertService(String userId, String licensePlate, int vehicleNumericId, Szerviz szerviz) async {
    final vehicleId = _generateVehicleId(licensePlate);
    final data = szerviz.toFirestore();

    data['lastUpdated'] = FieldValue.serverTimestamp();
    data['cost'] = szerviz.cost;
    data['vehicleId'] = vehicleNumericId;
    data['date'] = szerviz.date.toIso8601String();

    if (szerviz.id != null) {
      await _servicesRef(userId, vehicleId).doc(szerviz.id).set(data, SetOptions(merge: true));
    } else {
      final snapshot = await _servicesRef(userId, vehicleId).get();
      final newId = (snapshot.docs.length + 1).toString();
      data['id'] = int.parse(newId);
      await _servicesRef(userId, vehicleId).doc(newId).set(data);
    }
  }

  Future<void> deleteService(String userId, String licensePlate, String serviceId) async {
    final vehicleId = _generateVehicleId(licensePlate);
    await _servicesRef(userId, vehicleId).doc(serviceId).delete();
  }
}
