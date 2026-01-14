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
    final Map<String, dynamic> data = jarmu.toFirestore();
    
    data['lastUpdated'] = FieldValue.serverTimestamp();
    
    if (jarmu.customIntervals == null) {
      data['customIntervals'] = {};
    }

    int newId;
    if (jarmu.id == null) {
      // Új jármű esetén is használjunk időbélyeget, hogy véletlenül se ütközzön semmivel
      newId = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      data['id'] = newId;
    } else {
      newId = int.tryParse(jarmu.id!) ?? 0;
      data['id'] = newId;
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
    
    if (szerviz.id != null && szerviz.id!.isNotEmpty) {
      await _servicesRef(userId, vehicleId).doc(szerviz.id!).set(data, SetOptions(merge: true));
    } else {
      // JAVÍTVA: length+1 helyett egyedi időbélyeg ID
      // Így Car A és Car B szervizei sosem fognak ütközni (nem lesz mindkettőnek "1"-es szervize)
      final String uniqueId = DateTime.now().millisecondsSinceEpoch.toString();
      data['id'] = int.parse(uniqueId.substring(uniqueId.length - 9)); // Biztonságos integer ID
      await _servicesRef(userId, vehicleId).doc(uniqueId).set(data);
    }
  }

  Future<void> deleteService(String userId, String licensePlate, String serviceId) async {
    final vehicleId = _generateVehicleId(licensePlate);
    await _servicesRef(userId, vehicleId).doc(serviceId).delete();
  }
}
