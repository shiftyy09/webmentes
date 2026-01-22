import 'package:cloud_firestore/cloud_firestore.dart';
import '../modellek/jarmu.dart';
import '../modellek/karbantartas_bejegyzes.dart';
import '../alap/konstansok.dart';

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
    
    // 1. Mentjük magát a szerviz bejegyzést
    if (szerviz.id != null && szerviz.id!.isNotEmpty) {
      await _servicesRef(userId, vehicleId).doc(szerviz.id!).set(data, SetOptions(merge: true));
    } else {
      final String uniqueId = DateTime.now().millisecondsSinceEpoch.toString();
      data['id'] = int.parse(uniqueId.substring(uniqueId.length - 9));
      await _servicesRef(userId, vehicleId).doc(uniqueId).set(data);
    }

    // 2. Ha ez egy emlékeztető alapú szerviz (pl. Olajcsere, Műszaki), frissítsük a rejtett alap rekordot is
    // Ez biztosítja, hogy a webapp TAB 1 (Emlékeztetők) és a mobilapp is azonnal frissüljön
    if (ALL_REMINDER_SERVICE_TYPES.contains(szerviz.description)) {
      final reminderDesc = REMINDER_PREFIX + szerviz.description;
      
      try {
        final query = await _servicesRef(userId, vehicleId)
            .where('description', isEqualTo: reminderDesc)
            .limit(1)
            .get();

        if (query.docs.isNotEmpty) {
          // Csak a releváns adatokat frissítjük az emlékeztető alapban
          await query.docs.first.reference.update({
            'date': data['date'],
            'mileage': data['mileage'],
            'lastUpdated': FieldValue.serverTimestamp(),
          });
          print("✅ Emlékeztető alap frissítve: $reminderDesc");
        }
      } catch (e) {
        print("❌ Hiba az emlékeztető alap frissítésekor: $e");
      }
    }
  }

  Future<void> deleteService(String userId, String licensePlate, String serviceId) async {
    final vehicleId = _generateVehicleId(licensePlate);
    await _servicesRef(userId, vehicleId).doc(serviceId).delete();
  }
}
