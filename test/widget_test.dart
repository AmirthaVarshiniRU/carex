import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:carex/widgets/exercise_list.dart';

void main() {
  testWidgets('ExerciseList displays list of exercises', (WidgetTester tester) async {
    final exercises = ['Neck Pain', 'Shoulder Pain', 'Knee Pain'];
    String? tappedExercise;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ExerciseList(
            exercises: exercises,
            onExerciseTap: (exercise) {
              tappedExercise = exercise;
            },
          ),
        ),
      ),
    );

    // Verify that the exercise names are displayed
    expect(find.text('Neck Pain'), findsOneWidget);
    expect(find.text('Shoulder Pain'), findsOneWidget);
    expect(find.text('Knee Pain'), findsOneWidget);

    // Tap on the first exercise and verify the callback is triggered
    await tester.tap(find.text('Neck Pain'));
    await tester.pump();

    expect(tappedExercise, 'Neck Pain');
  });
}
