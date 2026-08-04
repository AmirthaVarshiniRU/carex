import 'package:flutter/material.dart';

class ExerciseList extends StatelessWidget {
  final List<String> exercises;
  final Function(String) onExerciseTap;

  const ExerciseList({
    super.key,
    required this.exercises,
    required this.onExerciseTap,
  });

  // Map exercise names to their respective icons
  IconData _getExerciseIcon(String exercise) {
    switch (exercise.toLowerCase()) {
      case 'shoulder pain':
        return Icons.accessibility_new;
      case 'yoga':
        return Icons.self_improvement;
      case 'knee pain':
        return Icons.airline_seat_legroom_extra;
      case 'back pain':
        return Icons.airline_seat_flat;
      case 'neck pain':
        return Icons.airline_seat_recline_normal;
      default:
        return Icons.fitness_center;
    }
  }

  // Get a color based on the exercise type
  Color _getExerciseColor(String exercise) {
    switch (exercise.toLowerCase()) {
      case 'shoulder pain':
        return Colors.orange;
      case 'yoga':
        return Colors.green;
      case 'knee pain':
        return Colors.red;
      case 'back pain':
        return Colors.purple;
      case 'neck pain':
        return Colors.blue;
      default:
        return const Color(0xFF059669);
    }
  }

  @override
  Widget build(BuildContext context) {
    return exercises.isEmpty
        ? const Center(
            child: Text(
              "No exercises found",
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          )
        : ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: exercises.length,
            itemBuilder: (context, index) {
              final exercise = exercises[index];
              final color = _getExerciseColor(exercise);
              
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: InkWell(
                  onTap: () => onExerciseTap(exercise),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                      color: Colors.white,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 80,
                          height: 100,
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.2),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(16),
                              bottomLeft: Radius.circular(16),
                            ),
                          ),
                          child: Center(
                            child: Icon(
                              _getExerciseIcon(exercise),
                              size: 36,
                              color: color,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  exercise,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  "Tap to start your ${exercise.toLowerCase()} exercise routine",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: Colors.grey[400],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
  }
}
