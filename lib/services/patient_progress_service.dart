import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/exercise_assignment.dart';
import '../models/exercise_progress.dart';
import '../models/patient_progress.dart';

class PatientProgressService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<PatientProgressSummary> getSummary(String patientId) async {
    final assignmentSnapshot = await _firestore
        .collection('exerciseAssignments')
        .where('patientId', isEqualTo: patientId)
        .get();

    final now = DateTime.now();
    final assignments = assignmentSnapshot.docs
        .map((doc) => ExerciseAssignment.fromMap(doc.data(), doc.id))
        .where((assignment) => assignment.status != 'cancelled')
        .where((assignment) => assignment.status == 'completed' ||
            (!assignment.startDate.isAfter(now) &&
                (assignment.endDate == null || !assignment.endDate!.isBefore(now))))
        .toList();

    final progressSnapshot = await _firestore
        .collection('exercise_progress')
        .where('userId', isEqualTo: patientId)
        .get();

    final progresses = progressSnapshot.docs
        .map((doc) => ExerciseProgress.fromMap(doc.data(), doc.id))
        .toList();

    if (assignments.isEmpty) {
      return _summaryWithoutAssignments(progresses);
    }

    double totalAssignmentProgress = 0;
    int completedAssignments = 0;

    for (final assignment in assignments) {
      final matching = progresses
          .where((p) => p.assignmentId == assignment.id)
          .toList();
      if (matching.isEmpty) continue;

      matching.sort((a, b) => b.date.compareTo(a.date));
      final latest = matching.first;
      final target = assignment.targetReps > 0
          ? assignment.targetReps
          : latest.targetDuration.inSeconds;
      final completed = assignment.targetReps > 0
          ? latest.completedReps
          : latest.completedDuration.inSeconds;
      final percentage = target > 0
          ? (completed / target * 100).clamp(0, 100).toDouble()
          : (latest.isCompleted ? 100.0 : 0.0);
      totalAssignmentProgress += percentage;
      if (percentage >= 100 || latest.isCompleted) completedAssignments++;
    }

    final formScores = progresses
        .map((p) => p.formScore)
        .where((score) => score > 0)
        .toList();
    final averageForm = formScores.isEmpty
        ? 0.0
        : formScores.reduce((a, b) => a + b) / formScores.length;

    final lastDate = progresses.isEmpty
        ? null
        : (progresses.map((p) => p.date).toList()..sort()).last;

    final overallProgress = assignments.isEmpty
        ? 0.0
        : totalAssignmentProgress / assignments.length;
    final compliancePercentage = assignments.isEmpty
        ? 0.0
        : (completedAssignments / assignments.length * 100)
            .clamp(0, 100)
            .toDouble();

    return PatientProgressSummary(
      overallProgress: overallProgress,
      compliancePercentage: compliancePercentage,
      totalAssignedExercises: assignments.length,
      completedAssignedExercises: completedAssignments,
      totalSessions: progresses.where((p) => p.isCompleted).length,
      averageFormScore: averageForm,
      lastExerciseDate: lastDate,
      currentStreak: _calculateStreak(progresses),
    );
  }

  PatientProgressSummary _summaryWithoutAssignments(List<ExerciseProgress> progresses) {
    if (progresses.isEmpty) return PatientProgressSummary.empty;

    final scores = progresses.map((p) => p.formScore).where((s) => s > 0).toList();
    final form = scores.isEmpty ? 0.0 : scores.reduce((a, b) => a + b) / scores.length;
    final dates = progresses.map((p) => p.date).toList()..sort();
    final overall = progresses
            .map((p) => p.completionPercentage)
            .fold<double>(0, (sum, value) => sum + value) /
        progresses.length;

    return PatientProgressSummary(
      // When no doctor assignments exist, overall progress is derived from
      // the patient's recorded exercise sessions instead of staying at 0%.
      overallProgress: overall.clamp(0, 100).toDouble(),
      compliancePercentage: 0,
      totalAssignedExercises: 0,
      completedAssignedExercises: 0,
      totalSessions: progresses.where((p) => p.isCompleted).length,
      averageFormScore: form,
      lastExerciseDate: dates.last,
      currentStreak: _calculateStreak(progresses),
    );
  }

  int _calculateStreak(List<ExerciseProgress> progresses) {
    final completedDates = progresses
        .where((p) => p.isCompleted)
        .map((p) => DateTime(p.date.year, p.date.month, p.date.day))
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a));
    if (completedDates.isEmpty) return 0;

    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final yesterday = todayDate.subtract(const Duration(days: 1));
    if (completedDates.first != todayDate && completedDates.first != yesterday) {
      return 0;
    }

    int streak = 1;
    for (var i = 1; i < completedDates.length; i++) {
      if (completedDates[i - 1].difference(completedDates[i]).inDays == 1) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }
}
