class PatientProgressSummary {
  final double overallProgress;
  final double compliancePercentage;
  final int totalAssignedExercises;
  final int completedAssignedExercises;
  final int totalSessions;
  final double averageFormScore;
  final DateTime? lastExerciseDate;
  final int currentStreak;

  const PatientProgressSummary({
    required this.overallProgress,
    required this.compliancePercentage,
    required this.totalAssignedExercises,
    required this.completedAssignedExercises,
    required this.totalSessions,
    required this.averageFormScore,
    required this.lastExerciseDate,
    required this.currentStreak,
  });

  static const empty = PatientProgressSummary(
    overallProgress: 0,
    compliancePercentage: 0,
    totalAssignedExercises: 0,
    completedAssignedExercises: 0,
    totalSessions: 0,
    averageFormScore: 0,
    lastExerciseDate: null,
    currentStreak: 0,
  );
}
