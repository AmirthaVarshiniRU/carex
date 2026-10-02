import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/services.dart';

class XGBoostPredictionResult {
  final String predictedMood;
  final String recommendedIntensity;
  final double confidenceScore;
  final List<double> classProbabilities;
  final bool isXGBoostModelUsed;

  XGBoostPredictionResult({
    required this.predictedMood,
    required this.recommendedIntensity,
    required this.confidenceScore,
    required this.classProbabilities,
    required this.isXGBoostModelUsed,
  });
}

class MLService {
  static final MLService _instance = MLService._internal();
  factory MLService() => _instance;
  MLService._internal();

  bool _isModelLoaded = false;
  Map<String, dynamic>? _xgboostModelData;

  bool get isModelLoaded => _isModelLoaded;

  /// Loads the XGBoost model JSON asset into memory
  Future<void> loadModel() async {
    if (_isModelLoaded) return;

    try {
      print('Loading XGBoost ML model from assets...');
      final String jsonString = await rootBundle.loadString('assets/xgboost_mood_model.json');
      _xgboostModelData = json.decode(jsonString);
      _isModelLoaded = true;
      print('✅ XGBoost Model successfully loaded into CAREX inference engine!');
    } catch (e) {
      print('⚠️ Error loading XGBoost ML model asset: $e');
      _isModelLoaded = false;
    }
  }

  /// Predicts mood and recommended exercise intensity using XGBoost Decision Trees
  Future<XGBoostPredictionResult> predictMoodWithXGBoost(List<int> surveyAnswers) async {
    if (!_isModelLoaded || _xgboostModelData == null) {
      await loadModel();
    }

    if (_isModelLoaded && _xgboostModelData != null) {
      try {
        final List<dynamic> trees = _xgboostModelData!['trees'] ?? [];
        final List<dynamic> classNames = _xgboostModelData!['class_names'] ?? ['Energetic', 'Motivated', 'Neutral', 'Tired', 'Exhausted'];
        final List<dynamic> intensityLevels = _xgboostModelData!['intensity_levels'] ?? ['High', 'Moderate', 'Moderate', 'Light', 'Rest'];
        final double baseScore = (_xgboostModelData!['base_score'] ?? 0.2).toDouble();

        // 5 Classes log-odds initialization
        List<double> rawScores = List.generate(classNames.length, (index) => baseScore);

        // Evaluate input vector through each XGBoost decision tree node
        for (int i = 0; i < trees.length; i++) {
          final tree = trees[i];
          double leafVal = _evaluateTree(tree, surveyAnswers);
          int targetClassIndex = i % classNames.length;
          rawScores[targetClassIndex] += leafVal;
        }

        // Apply Softmax normalization: exp(z_i) / sum(exp(z_j))
        double maxRawScore = rawScores.reduce(math.max);
        List<double> expScores = rawScores.map((s) => math.exp(s - maxRawScore)).toList();
        double sumExp = expScores.reduce((a, b) => a + b);
        List<double> probabilities = expScores.map((e) => e / sumExp).toList();

        // Find predicted class index with highest probability
        int bestIndex = 0;
        double maxProb = probabilities[0];
        for (int c = 1; c < probabilities.length; c++) {
          if (probabilities[c] > maxProb) {
            maxProb = probabilities[c];
            bestIndex = c;
          }
        }

        return XGBoostPredictionResult(
          predictedMood: classNames[bestIndex].toString(),
          recommendedIntensity: intensityLevels[bestIndex].toString(),
          confidenceScore: maxProb,
          classProbabilities: probabilities,
          isXGBoostModelUsed: true,
        );
      } catch (e) {
        print('XGBoost inference error: $e. Falling back to rule engine.');
      }
    }

    // Fallback if model loading fails
    return _ruleBasedFallback(surveyAnswers);
  }

  /// Traverses a single XGBoost Decision Tree node recursively
  double _evaluateTree(Map<String, dynamic> node, List<int> features) {
    if (node.containsKey('leaf_value')) {
      return (node['leaf_value'] as num).toDouble();
    }

    int featureIdx = node['feature'] as int;
    double threshold = (node['threshold'] as num).toDouble();

    double featureVal = (featureIdx < features.length) ? features[featureIdx].toDouble() : 0.0;

    if (featureVal <= threshold) {
      return _evaluateTree(Map<String, dynamic>.from(node['left']), features);
    } else {
      return _evaluateTree(Map<String, dynamic>.from(node['right']), features);
    }
  }

  /// Legacy interface for backward compatibility
  Future<String> predictMood(List<int> answers) async {
    final result = await predictMoodWithXGBoost(answers);
    return result.predictedMood;
  }

  XGBoostPredictionResult _ruleBasedFallback(List<int> answers) {
    int score = answers.fold(0, (sum, val) => sum + val);
    String mood = 'Neutral';
    String intensity = 'Moderate';

    if (score <= 5) {
      mood = 'Energetic';
      intensity = 'High';
    } else if (score <= 10) {
      mood = 'Motivated';
      intensity = 'Moderate';
    } else if (score <= 15) {
      mood = 'Neutral';
      intensity = 'Moderate';
    } else if (score <= 20) {
      mood = 'Tired';
      intensity = 'Light';
    } else {
      mood = 'Exhausted';
      intensity = 'Rest';
    }

    return XGBoostPredictionResult(
      predictedMood: mood,
      recommendedIntensity: intensity,
      confidenceScore: 0.85,
      classProbabilities: [0.2, 0.2, 0.2, 0.2, 0.2],
      isXGBoostModelUsed: false,
    );
  }
}