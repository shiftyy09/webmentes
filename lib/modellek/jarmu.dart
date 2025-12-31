// lib/modellek/jarmu.dart
class Jarmu {
  final String? id; // Firestore dokumentum ID
  final String licensePlate;
  final String make;
  final String model;
  final int year;
  final int mileage;
  final String? vin;
  final String? vezerlesTipusa;
  // ÚJ: Egyedi intervallumok a webes szinkronhoz
  final Map<String, int>? customIntervals;

  Jarmu({
    this.id,
    required this.licensePlate,
    required this.make,
    required this.model,
    required this.year,
    required this.mileage,
    this.vin,
    this.vezerlesTipusa,
    this.customIntervals,
  });

  Jarmu copyWith({
    String? id,
    String? licensePlate,
    String? make,
    String? model,
    int? year,
    int? mileage,
    String? vin,
    String? vezerlesTipusa,
    Map<String, int>? customIntervals,
  }) {
    return Jarmu(
      id: id ?? this.id,
      licensePlate: licensePlate ?? this.licensePlate,
      make: make ?? this.make,
      model: model ?? this.model,
      year: year ?? this.year,
      mileage: mileage ?? this.mileage,
      vin: vin ?? this.vin,
      vezerlesTipusa: vezerlesTipusa ?? this.vezerlesTipusa,
      customIntervals: customIntervals ?? this.customIntervals,
    );
  }

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
      customIntervals: data['customIntervals'] != null 
          ? Map<String, int>.from(data['customIntervals']) 
          : null,
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
      if (customIntervals != null) 'customIntervals': customIntervals,
    };
  }
}
