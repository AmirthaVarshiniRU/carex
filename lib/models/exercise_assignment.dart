import 'package:cloud_firestore/cloud_firestore.dart';

class ExerciseAssignment {
  final String id;
  final String doctorId;
  final String patientId;
  final String exerciseId;
  final String exerciseName;
  final String category;
  final int targetReps;
  final int targetSets;
  final DateTime startDate;
  final DateTime? endDate;
  final String status;
  final String doctorNotes;
  final DateTime? createdAt;

  const ExerciseAssignment({
    required this.id,
    required this.doctorId,
    required this.patientId,
    required this.exerciseId,
    required this.exerciseName,
    required this.category,
    required this.targetReps,
    required this.targetSets,
    required this.startDate,
    this.endDate,
    required this.status,
    required this.doctorNotes,
    this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'doctorId': doctorId,
        'patientId': patientId,
        'exerciseId': exerciseId,
        'exerciseName': exerciseName,
        'category': category,
        'targetReps': targetReps,
        'targetSets': targetSets,
        'startDate': Timestamp.fromDate(startDate),
        'endDate': endDate == null ? null : Timestamp.fromDate(endDate!),
        'status': status,
        'doctorNotes': doctorNotes,
        'createdAt': createdAt == null
            ? FieldValue.serverTimestamp()
            : Timestamp.fromDate(createdAt!),
      };

  factory ExerciseAssignment.fromMap(Map<String, dynamic> map, String id) {
    DateTime readDate(dynamic value, DateTime fallback) {
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      if (value is String) return DateTime.tryParse(value) ?? fallback;
      return fallback;
    }

    return ExerciseAssignment(
      id: id,
      doctorId: map['doctorId'] ?? '',
      patientId: map['patientId'] ?? '',
      exerciseId: map['exerciseId'] ?? '',
      exerciseName: map['exerciseName'] ?? '',
      category: map['category'] ?? '',
      targetReps: (map['targetReps'] as num?)?.toInt() ?? 0,
      targetSets: (map['targetSets'] as num?)?.toInt() ?? 1,
      startDate: readDate(map['startDate'], DateTime.now()),
      endDate: map['endDate'] == null ? null : readDate(map['endDate'], DateTime.now()),
      status: map['status'] ?? 'active',
      doctorNotes: map['doctorNotes'] ?? '',
      createdAt: map['createdAt'] == null
          ? null
          : readDate(map['createdAt'], DateTime.now()),
    );
  }
}
