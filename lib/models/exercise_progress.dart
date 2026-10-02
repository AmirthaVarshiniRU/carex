import 'package:cloud_firestore/cloud_firestore.dart';

class ExerciseProgress {
  final String id;
  final String userId;
  final String exerciseId;
  final String exerciseName;
  final int completedReps;
  final int targetReps;
  final Duration completedDuration;
  final Duration targetDuration;
  final DateTime date;
  final bool isCompleted;
  final Map<String, dynamic>? notes;
  final String mood;
  final String? assignmentId;
  final int formScore;

  ExerciseProgress({
    required this.id,
    required this.userId,
    required this.exerciseId,
    required this.exerciseName,
    required this.completedReps,
    required this.targetReps,
    required this.completedDuration,
    required this.targetDuration,
    required this.date,
    required this.isCompleted,
    this.notes,
    this.mood = 'Neutral',
    this.assignmentId,
    this.formScore = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'exerciseId': exerciseId,
      'exerciseName': exerciseName,
      'completedReps': completedReps,
      'targetReps': targetReps,
      'completedDuration': completedDuration.inSeconds,
      'targetDuration': targetDuration.inSeconds,
      'date': Timestamp.fromDate(date),
      'isCompleted': isCompleted,
      'notes': notes,
      'mood': mood,
      'assignmentId': assignmentId,
      'formScore': formScore,
    };
  }

  factory ExerciseProgress.fromMap(Map<String, dynamic> map, String id) {
    DateTime readDate(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
      return DateTime.now();
    }

    return ExerciseProgress(
      id: id,
      userId: map['userId'] ?? '',
      exerciseId: map['exerciseId'] ?? '',
      exerciseName: map['exerciseName'] ?? '',
      completedReps: (map['completedReps'] as num?)?.toInt() ?? 0,
      targetReps: (map['targetReps'] as num?)?.toInt() ?? 0,
      completedDuration: Duration(seconds: (map['completedDuration'] as num?)?.toInt() ?? 0),
      targetDuration: Duration(seconds: (map['targetDuration'] as num?)?.toInt() ?? 0),
      date: readDate(map['date']),
      isCompleted: map['isCompleted'] ?? false,
      notes: map['notes'] is Map ? Map<String, dynamic>.from(map['notes']) : null,
      mood: map['mood'] ?? 'Neutral',
      assignmentId: map['assignmentId'],
      formScore: (map['formScore'] as num?)?.toInt() ??
          ((map['notes'] is Map && (map['notes']['qualityScore'] is num))
              ? (map['notes']['qualityScore'] as num).toInt()
              : 0),
    );
  }

  double get completionPercentage {
    if (targetReps > 0) return (completedReps / targetReps * 100).clamp(0, 100);
    if (targetDuration.inSeconds > 0) {
      return (completedDuration.inSeconds / targetDuration.inSeconds * 100).clamp(0, 100);
    }
    return isCompleted ? 100 : 0;
  }
}
