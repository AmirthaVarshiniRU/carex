import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/exercise_assignment.dart';

class AssignmentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();

  CollectionReference<Map<String, dynamic>> get _assignments =>
      _firestore.collection('exerciseAssignments');

  Stream<List<Map<String, dynamic>>> watchPatients(String doctorId) {
    return _firestore
        .collection('users')
        .where('accountInfo.role', isEqualTo: 'Patient')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .where((doc) => doc.data()['doctorId'] == doctorId)
            .map((doc) => {'id': doc.id, ...doc.data()})
            .toList());
  }

  Future<List<Map<String, dynamic>>> getAllPatients() async {
    final snapshot = await _firestore
        .collection('users')
        .where('accountInfo.role', isEqualTo: 'Patient')
        .get();
    return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
  }

  Future<Map<String, dynamic>?> getUser(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    return doc.exists ? {'id': doc.id, ...doc.data()!} : null;
  }

  Future<void> mapPatientToDoctor({
    required String patientId,
    required String doctorId,
  }) async {
    await _firestore.collection('users').doc(patientId).set({
      'doctorId': doctorId,
      'doctorMappedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> unmapPatient(String patientId) async {
    await _firestore.collection('users').doc(patientId).update({
      'doctorId': FieldValue.delete(),
    });
  }

  Stream<List<ExerciseAssignment>> watchPatientAssignments(String patientId) {
    return _assignments
        .where('patientId', isEqualTo: patientId)
        .snapshots()
        .map((snapshot) {
      final now = DateTime.now();
      return snapshot.docs
          .map((doc) => ExerciseAssignment.fromMap(doc.data(), doc.id))
          .where((assignment) => assignment.status == 'active')
          .where((assignment) => !assignment.startDate.isAfter(now))
          .where((assignment) => assignment.endDate == null || !assignment.endDate!.isBefore(now))
          .toList();
    });
  }

  Stream<List<ExerciseAssignment>> watchDoctorAssignments(String doctorId) {
    return _assignments
        .where('doctorId', isEqualTo: doctorId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ExerciseAssignment.fromMap(doc.data(), doc.id))
            .toList());
  }

  Future<String> createAssignment({
    required String doctorId,
    required String patientId,
    required String exerciseId,
    required String exerciseName,
    required String category,
    required int targetReps,
    required int targetSets,
    required DateTime startDate,
    DateTime? endDate,
    required String doctorNotes,
  }) async {
    final id = _uuid.v4();
    final assignment = ExerciseAssignment(
      id: id,
      doctorId: doctorId,
      patientId: patientId,
      exerciseId: exerciseId,
      exerciseName: exerciseName,
      category: category,
      targetReps: targetReps,
      targetSets: targetSets,
      startDate: startDate,
      endDate: endDate,
      status: 'active',
      doctorNotes: doctorNotes,
    );
    await _assignments.doc(id).set(assignment.toMap());
    return id;
  }

  Future<void> completeAssignment(String assignmentId) async {
    await _assignments.doc(assignmentId).update({'status': 'completed'});
  }

  Future<void> cancelAssignment(String assignmentId) async {
    await _assignments.doc(assignmentId).update({'status': 'cancelled'});
  }
}
