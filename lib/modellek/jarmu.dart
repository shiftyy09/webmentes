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
  final String? radioCode;
  final Map<String, int>? customIntervals;
  
  // ÚJ: Extra adatok az értékbecsléshez és egyéb funkciókhoz
  // Így nem törjük meg a mobil appot, mert ismeretlen mezőként kezeli
  final Map<String, dynamic>? extraData;

  Jarmu({
    this.id,
    required this.licensePlate,
    required this.make,
    required this.model,
    required this.year,
    required this.mileage,
    this.vin,
    this.vezerlesTipusa,
    this.radioCode,
    this.customIntervals,
    this.extraData,
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
    String? radioCode,
    Map<String, int>? customIntervals,
    Map<String, dynamic>? extraData,
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
      radioCode: radioCode ?? this.radioCode,
      customIntervals: customIntervals ?? this.customIntervals,
      extraData: extraData ?? this.extraData,
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
      radioCode: null,
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
      radioCode: data['radioCode'] as String?,
      customIntervals: data['customIntervals'] != null 
          ? Map<String, int>.from(data['customIntervals']) 
          : null,
      extraData: data['extraData'] != null 
          ? Map<String, dynamic>.from(data['extraData']) 
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    final Map<String, dynamic> data = {
      'licensePlate': licensePlate,
      'make': make,
      'model': model,
      'year': year,
      'mileage': mileage,
      'vin': vin == '' ? null : vin,
      'vezerlesTipusa': vezerlesTipusa,
      'radioCode': radioCode,
    };

    if (customIntervals != null) {
      data['customIntervals'] = customIntervals;
    }
    
    if (extraData != null) {
      data['extraData'] = extraData;
    }

    return data;
  }
}
