import 'package:firebase_ml_model_downloader/firebase_ml_model_downloader.dart';
import 'package:firebase_core/firebase_core.dart';

class MLService {
  static final MLService _instance = MLService._internal();
  factory MLService() => _instance;
  MLService._internal();

  bool _isModelLoaded = false;

  Future<void> loadModel() async {
    if (_isModelLoaded) return;

    try {
      print('Loading ML model from Firebase...');
      
      // Download the model from Firebase
      final model = await FirebaseModelDownloader.instance.getModel(
        'mood_prediction_model',
        FirebaseModelDownloadType.latestModel,
      );
      
      print('Model downloaded successfully, size: ${model.file.lengthSync()} bytes');
      _isModelLoaded = true;
      
    } catch (e) {
      print('Error loading ML model: $e');
      // Fallback to rule-based system if model loading fails
      _isModelLoaded = false;
    }
  }

  Future<String> predictMood(List<int> answers) async {
    try {
      print('Predicting mood for answers: $answers');
      
      // Use rule-based prediction for now
      return _ruleBasedPrediction(answers);
      
    } catch (e) {
      print('Error predicting mood: $e');
      return _ruleBasedPrediction(answers);
    }
  }

  String _ruleBasedPrediction(List<int> answers) {
    int score = 0;
    
    // Calculate score based on answers
    for (var answer in answers) {
      // Lower index means more positive response
      score += answer;
    }
    
    // Determine mood based on score
    if (score <= 5) {
      return 'Energetic';
    } else if (score <= 10) {
      return 'Motivated';
    } else if (score <= 15) {
      return 'Neutral';
    } else if (score <= 20) {
      return 'Tired';
    } else {
      return 'Exhausted';
    }
  }
} 