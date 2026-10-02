import 'package:flutter_test/flutter_test.dart';
import 'package:carex/services/ml_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('XGBoost ML Inference Engine Tests', () {
    final mlService = MLService();

    test('Rule-based fallback generates valid prediction result', () async {
      final answers = [0, 0, 1, 0, 1]; // Energetic answers
      final result = await mlService.predictMoodWithXGBoost(answers);
      
      expect(result.predictedMood, isNotNull);
      expect(result.recommendedIntensity, isNotNull);
      expect(result.confidenceScore, greaterThan(0.0));
      expect(result.confidenceScore, lessThanOrEqualTo(1.0));
    });

    test('XGBoost handles all answer ranges (0 to 3)', () async {
      final tiredAnswers = [3, 3, 3, 3, 3]; // Exhausted answers
      final result = await mlService.predictMoodWithXGBoost(tiredAnswers);

      expect(result.predictedMood, isNotNull);
      expect(['Tired', 'Exhausted', 'Neutral', 'Motivated', 'Energetic'], contains(result.predictedMood));
    });
  });
}
