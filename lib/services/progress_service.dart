import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/exercise_progress.dart';

class ProgressService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('exercise_progress');

  Future<void> saveProgress(ExerciseProgress progress) async {
    await _collection.doc(progress.id).set({
      ...progress.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Stream<List<ExerciseProgress>> getTodayProgress(String userId) =>
      _watchPeriod(userId, _startOfDay(DateTime.now()), _startOfDay(DateTime.now()).add(const Duration(days: 1)));

  Stream<List<ExerciseProgress>> getWeeklyProgress(String userId) {
    final now = DateTime.now();
    final start = _startOfDay(now.subtract(Duration(days: now.weekday - 1)));
    return _watchPeriod(userId, start, start.add(const Duration(days: 7)));
  }

  Stream<List<ExerciseProgress>> getMonthlyProgress(String userId) {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    final end = DateTime(now.year, now.month + 1, 1);
    return _watchPeriod(userId, start, end);
  }

  Stream<List<ExerciseProgress>> watchUserProgress(String userId) {
    return _collection.where('userId', isEqualTo: userId).snapshots().map((snapshot) {
      final list = snapshot.docs.map((doc) => ExerciseProgress.fromMap(doc.data(), doc.id)).toList();
      list.sort((a, b) => b.date.compareTo(a.date));
      return list;
    });
  }

  Stream<List<ExerciseProgress>> _watchPeriod(String userId, DateTime start, DateTime end) {
    return _collection
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => ExerciseProgress.fromMap(doc.data(), doc.id))
          .where((progress) => !progress.date.isBefore(start) && progress.date.isBefore(end))
          .toList();
      list.sort((a, b) => b.date.compareTo(a.date));
      return list;
    });
  }

  Future<List<ExerciseProgress>> getUserProgress(String userId) async {
    final snapshot = await _collection.where('userId', isEqualTo: userId).get();
    final list = snapshot.docs.map((doc) => ExerciseProgress.fromMap(doc.data(), doc.id)).toList();
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  Future<double> getCompletionPercentage(String userId, DateTime startDate, DateTime endDate) async {
    final snapshot = await _collection.where('userId', isEqualTo: userId).get();
    final progresses = snapshot.docs
        .map((doc) => ExerciseProgress.fromMap(doc.data(), doc.id))
        .where((progress) => !progress.date.isBefore(startDate) && progress.date.isBefore(endDate))
        .toList();
    if (progresses.isEmpty) return 0;
    return progresses.map((p) => p.completionPercentage).reduce((a, b) => a + b) / progresses.length;
  }

  Future<void> deleteProgress(String progressId) => _collection.doc(progressId).delete();

  DateTime _startOfDay(DateTime date) => DateTime(date.year, date.month, date.day);
}
