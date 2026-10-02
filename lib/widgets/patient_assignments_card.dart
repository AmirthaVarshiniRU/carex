import 'package:flutter/material.dart';
import '../models/exercise_assignment.dart';
import '../models/exercise.dart';
import '../services/assignment_service.dart';
import '../screens/exercise_page.dart';

class PatientAssignmentsCard extends StatelessWidget {
  final String patientId;

  const PatientAssignmentsCard({super.key, required this.patientId});

  @override
  Widget build(BuildContext context) {
    final service = AssignmentService();
    return StreamBuilder<List<ExerciseAssignment>>(
      stream: service.watchPatientAssignments(patientId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator()));
        }
        final assignments = snapshot.data ?? [];
        return Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 14, offset: const Offset(0, 6))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                const Expanded(child: Text('Doctor Assigned Exercises', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1E293B)))),
                if (assignments.isNotEmpty) Text('${assignments.length}', style: const TextStyle(color: Color(0xFF059669), fontWeight: FontWeight.w800)),
              ]),
              const SizedBox(height: 12),
              if (assignments.isEmpty)
                const Text('No active exercises assigned by your doctor yet.', style: TextStyle(color: Colors.grey))
              else
                ...assignments.map((assignment) => _assignmentTile(context, assignment)),
            ],
          ),
        );
      },
    );
  }

  Widget _assignmentTile(BuildContext context, ExerciseAssignment assignment) {
    Exercise? exercise;
    for (final item in ExercisePage.exerciseCatalog) {
      if (item.id == assignment.exerciseId) {
        exercise = item;
        break;
      }
    }

    final selectedExercise = exercise;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: const CircleAvatar(backgroundColor: Color(0xFFE8F5F1), child: Icon(Icons.fitness_center_rounded, color: Color(0xFF059669))),
        title: Text(assignment.exerciseName, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text('${assignment.targetReps} reps × ${assignment.targetSets} set${assignment.targetSets == 1 ? '' : 's'}${assignment.doctorNotes.isEmpty ? '' : ' • ${assignment.doctorNotes}'}'),
        trailing: FilledButton(
          onPressed: selectedExercise == null
              ? null
              : () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => ExercisePage(
                    userId: patientId,
                    exerciseType: assignment.category,
                    healthCondition: assignment.category,
                    initialExercise: selectedExercise,
                    assignmentId: assignment.id,
                    targetReps: assignment.targetReps,
                    initialExerciseIndex: 0,
                  )));
                },
          style: FilledButton.styleFrom(backgroundColor: const Color(0xFF059669), foregroundColor: Colors.white),
          child: const Text('Start'),
        ),
      ),
    );
  }
}
