// lib/modellek/karbantartas_bejegyzes.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Szerviz {
  final String? id; // Firestore dokumentum ID
  final String description;
  final DateTime date;
  final num cost;
  final int mileage;

  Szerviz({
    this.id,
    required this.description,
    required this.date,
    required this.cost,
    required this.mileage,
  });

  // ÚJ: copyWith metódus
  Szerviz copyWith({
    String? id,
    String? description,
    DateTime? date,
    num? cost,
    int? mileage,
  }) {
    return Szerviz(
      id: id ?? this.id,
      description: description ?? this.description,
      date: date ?? this.date,
      cost: cost ?? this.cost,
      mileage: mileage ?? this.mileage,
    );
  }

  factory Szerviz.fromFirestore(
    Map<String, dynamic> data, {
    String? documentId,
  }) {
    final timestamp = data['date'];
    DateTime dateTime;

    if (timestamp is Timestamp) {
      dateTime = timestamp.toDate();
    } else if (timestamp is DateTime) {
      dateTime = timestamp;
    } else if (timestamp is String) {
      dateTime = DateTime.tryParse(timestamp) ?? DateTime.now();
    } else {
      dateTime = DateTime.now();
    }

    return Szerviz(
      id: documentId,
      description: data['description'] as String? ?? '',
      date: dateTime,
      cost: (data['cost'] as num?) ?? 0,
      mileage: (data['mileage'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'description': description,
      'date': Timestamp.fromDate(date),
      'cost': cost,
      'mileage': mileage,
    };
  }
}
