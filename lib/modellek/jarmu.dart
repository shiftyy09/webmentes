// lib/modellek/jarmu.dart
class Jarmu {
  final String? id; // Firestore dokumentum ID
  final String licensePlate;
  final String make;
  final String model;
  final int year;
  final int mileage;
  final String? vin; // Hozzáadva
  final String? vezerlesTipusa; // Hozzáadva

  Jarmu({
    this.id,
    required this.licensePlate,
    required this.make,
    required this.model,
    required this.year,
    required this.mileage,
    this.vin,
    this.vezerlesTipusa,
  });

  factory Jarmu.empty() {
    return Jarmu(
      id: null,
      licensePlate: '',
      make: '',
      model: '',
      year: 0,
      mileage: 0,
      vin: null,
      vezerlesTipusa: null,
    );
  }

  factory Jarmu.fromFirestore(
    Map<String, dynamic> data, {
    String? documentId,
  }) {
    return Jarmu(
      id: documentId,
      licensePlate: data['licensePlate'] as String? ?? '',
      make: data['make'] as String? ?? '',
      model: data['model'] as String? ?? '',
      year: (data['year'] as num?)?.toInt() ?? 0,
      mileage: (data['mileage'] as num?)?.toInt() ?? 0,
      vin: data['vin'] as String?,
      vezerlesTipusa: data['vezerlesTipusa'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'licensePlate': licensePlate,
      'make': make,
      'model': model,
      'year': year,
      'mileage': mileage,
      'vin': vin,
      'vezerlesTipusa': vezerlesTipusa,
    };
  }
}
