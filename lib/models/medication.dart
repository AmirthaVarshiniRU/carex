import 'package:flutter/material.dart';

class Medication {
  final String id;
  final String name;
  final String dosage;
  final TimeOfDay time;
  bool isTaken;
  final String category;

  Medication({
    required this.id,
    required this.name,
    required this.dosage,
    required this.time,
    this.isTaken = false,
    this.category = 'General',
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'dosage': dosage,
        'hour': time.hour,
        'minute': time.minute,
        'isTaken': isTaken,
        'category': category,
      };

  factory Medication.fromMap(Map<String, dynamic> map) => Medication(
        id: map['id'],
        name: map['name'],
        dosage: map['dosage'],
        time: TimeOfDay(hour: map['hour'], minute: map['minute']),
        isTaken: map['isTaken'] ?? false,
        category: map['category'] ?? 'General',
      );
}
