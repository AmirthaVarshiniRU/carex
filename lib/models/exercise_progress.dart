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
    };
  }

  factory ExerciseProgress.fromMap(Map<String, dynamic> map, String id) {
    return ExerciseProgress(
      id: id,
      userId: map['userId'] ?? '',
      exerciseId: map['exerciseId'] ?? '',
      exerciseName: map['exerciseName'] ?? '',
      completedReps: map['completedReps'] ?? 0,
      targetReps: map['targetReps'] ?? 0,
      completedDuration: Duration(seconds: map['completedDuration'] ?? 0),
      targetDuration: Duration(seconds: map['targetDuration'] ?? 0),
      date: (map['date'] as Timestamp).toDate(),
      isCompleted: map['isCompleted'] ?? false,
      notes: map['notes'],
      mood: map['mood'] ?? 'Neutral',
    );
  }

  double get completionPercentage {
    if (targetReps > 0) {
      return (completedReps / targetReps) * 100;
    } else if (targetDuration.inSeconds > 0) {
      return (completedDuration.inSeconds / targetDuration.inSeconds) * 100;
    }
    return 0;
  }

  ExerciseProgress copyWith({
    String? id,
    String? userId,
    String? exerciseId,
    String? exerciseName,
    int? completedReps,
    int? targetReps,
    Duration? completedDuration,
    Duration? targetDuration,
    DateTime? date,
    bool? isCompleted,
    Map<String, dynamic>? notes,
    String? mood,
  }) {
    return ExerciseProgress(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      exerciseId: exerciseId ?? this.exerciseId,
      exerciseName: exerciseName ?? this.exerciseName,
      completedReps: completedReps ?? this.completedReps,
      targetReps: targetReps ?? this.targetReps,
      completedDuration: completedDuration ?? this.completedDuration,
      targetDuration: targetDuration ?? this.targetDuration,
      date: date ?? this.date,
      isCompleted: isCompleted ?? this.isCompleted,
      notes: notes ?? this.notes,
      mood: mood ?? this.mood,
    );
  }
} 