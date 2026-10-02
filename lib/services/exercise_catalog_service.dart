import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/exercise.dart';

class ExerciseCatalogService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> syncCatalog(List<Exercise> exercises) async {
    final batch = _firestore.batch();
    for (final exercise in exercises) {
      final ref = _firestore.collection('exercises').doc(exercise.id);
      batch.set(ref, {
        ...exercise.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
    await batch.commit();
  }

  Stream<List<Exercise>> watchCatalog() {
    return _firestore.collection('exercises').snapshots().map((snapshot) {
      final items = snapshot.docs.map((doc) => Exercise.fromMap(doc.data())).toList();
      items.sort((a, b) => int.tryParse(a.id)?.compareTo(int.tryParse(b.id) ?? 0) ?? a.name.compareTo(b.name));
      return items;
    });
  }
}
