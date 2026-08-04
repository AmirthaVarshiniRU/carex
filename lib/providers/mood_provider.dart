import 'package:flutter/material.dart';

class MoodProvider extends ChangeNotifier {
  String? _currentMood;
  DateTime? _lastUpdated;
  Map<String, dynamic>? _moodAssessment;

  String? get currentMood => _currentMood;
  DateTime? get lastUpdated => _lastUpdated;
  Map<String, dynamic>? get moodAssessment => _moodAssessment;

  void setMood(String mood) {
    _currentMood = mood;
    _lastUpdated = DateTime.now();
    notifyListeners();
  }

  void setMoodAssessment(Map<String, dynamic> assessment) {
    _moodAssessment = assessment;
    
    // Determine the mood based on assessment
    int score = 0;
    
    // Calculate score based on answers
    assessment.forEach((question, answer) {
      final answerIndex = answer['answerIndex'] as int;
      // Lower index means more positive response
      score += answerIndex;
    });
    
    // Determine mood based on score
    if (score <= 5) {
      _currentMood = 'Energetic';
    } else if (score <= 10) {
      _currentMood = 'Motivated';
    } else if (score <= 15) {
      _currentMood = 'Neutral';
    } else if (score <= 20) {
      _currentMood = 'Tired';
    } else {
      _currentMood = 'Exhausted';
    }
    
    _lastUpdated = DateTime.now();
    notifyListeners();
  }

  void clearMood() {
    _currentMood = null;
    _lastUpdated = null;
    _moodAssessment = null;
    notifyListeners();
  }
}
