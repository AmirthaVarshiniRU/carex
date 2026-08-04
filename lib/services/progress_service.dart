import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/exercise_progress.dart';

class ProgressService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Save exercise progress
  Future<void> saveProgress(ExerciseProgress progress) async {
    try {
      await _firestore.collection('exercise_progress').doc(progress.id).set(progress.toMap());
    } catch (e) {
      print('Error saving progress: $e');
      rethrow;
    }
  }

  // Get today's progress for a user
  Stream<List<ExerciseProgress>> getTodayProgress(String userId) {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return _firestore
        .collection('exercise_progress')
        .where('userId', isEqualTo: userId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('date', isLessThan: Timestamp.fromDate(endOfDay))
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ExerciseProgress.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  // Get weekly progress for a user
  Stream<List<ExerciseProgress>> getWeeklyProgress(String userId) {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 7));

    return _firestore
        .collection('exercise_progress')
        .where('userId', isEqualTo: userId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfWeek))
        .where('date', isLessThan: Timestamp.fromDate(endOfWeek))
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ExerciseProgress.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  // Get monthly progress for a user
  Stream<List<ExerciseProgress>> getMonthlyProgress(String userId) {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0);

    return _firestore
        .collection('exercise_progress')
        .where('userId', isEqualTo: userId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
        .where('date', isLessThan: Timestamp.fromDate(endOfMonth))
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ExerciseProgress.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  // Get total completion percentage for a specific period
  Future<double> getCompletionPercentage(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final snapshot = await _firestore
        .collection('exercise_progress')
        .where('userId', isEqualTo: userId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('date', isLessThan: Timestamp.fromDate(endDate))
        .get();

    final progresses = snapshot.docs
        .map((doc) => ExerciseProgress.fromMap(doc.data(), doc.id))
        .toList();

    if (progresses.isEmpty) return 0;

    final totalPercentage = progresses.fold<double>(
      0,
      (sum, progress) => sum + progress.completionPercentage,
    );

    return totalPercentage / progresses.length;
  }

  // Delete progress
  Future<void> deleteProgress(String progressId) async {
    try {
      await _firestore.collection('exercise_progress').doc(progressId).delete();
    } catch (e) {
      print('Error deleting progress: $e');
      rethrow;
    }
  }
} 