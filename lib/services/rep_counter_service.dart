import 'dart:math' as math;
import 'dart:ui';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

enum RepState { initial, flexed, extended }

class RepCounterService {
  int _repCount = 0;
  RepState _currentState = RepState.initial;

  int get repCount => _repCount;

  void reset() {
    _repCount = 0;
    _currentState = RepState.initial;
  }

  /// Evaluates a [Pose] against the current [exerciseName] and returns true if a rep was completed.
  bool processPose(Pose? pose, String exerciseName) {
    if (pose == null) return false;

    final lm = pose.landmarks;
    final name = exerciseName.toLowerCase();

    double primaryAngle = 180.0;

    if (name.contains('knee') || name.contains('squat') || name.contains('leg')) {
      final hip = lm[PoseLandmarkType.leftHip];
      final knee = lm[PoseLandmarkType.leftKnee];
      final ankle = lm[PoseLandmarkType.leftAnkle];
      if (hip != null && knee != null && ankle != null) {
        primaryAngle = _angleBetween(
          Offset(hip.x, hip.y),
          Offset(knee.x, knee.y),
          Offset(ankle.x, ankle.y),
        );
      }
      return _evaluateCycle(primaryAngle, flexThreshold: 120.0, extendThreshold: 160.0);
    } else if (name.contains('arm') || name.contains('shoulder') || name.contains('stretch') || name.contains('circles')) {
      final shoulder = lm[PoseLandmarkType.leftShoulder];
      final elbow = lm[PoseLandmarkType.leftElbow];
      final wrist = lm[PoseLandmarkType.leftWrist];
      if (shoulder != null && elbow != null && wrist != null) {
        primaryAngle = _angleBetween(
          Offset(shoulder.x, shoulder.y),
          Offset(elbow.x, elbow.y),
          Offset(wrist.x, wrist.y),
        );
      }
      return _evaluateCycle(primaryAngle, flexThreshold: 90.0, extendThreshold: 150.0);
    } else if (name.contains('neck') || name.contains('bend') || name.contains('head')) {
      final nose = lm[PoseLandmarkType.nose];
      final lShoulder = lm[PoseLandmarkType.leftShoulder];
      final rShoulder = lm[PoseLandmarkType.rightShoulder];
      if (nose != null && lShoulder != null && rShoulder != null) {
        final midX = (lShoulder.x + rShoulder.x) / 2;
        primaryAngle = (nose.x - midX).abs();
      }
      return _evaluateCycle(primaryAngle, flexThreshold: 40.0, extendThreshold: 15.0);
    }

    return false;
  }

  bool _evaluateCycle(double val, {required double flexThreshold, required double extendThreshold}) {
    if (flexThreshold < extendThreshold) {
      if (val <= flexThreshold && _currentState != RepState.flexed) {
        _currentState = RepState.flexed;
      } else if (val >= extendThreshold && _currentState == RepState.flexed) {
        _currentState = RepState.extended;
        _repCount++;
        return true;
      }
    } else {
      if (val >= flexThreshold && _currentState != RepState.flexed) {
        _currentState = RepState.flexed;
      } else if (val <= extendThreshold && _currentState == RepState.flexed) {
        _currentState = RepState.extended;
        _repCount++;
        return true;
      }
    }
    return false;
  }

  double _angleBetween(Offset a, Offset b, Offset c) {
    final ab = a - b;
    final cb = c - b;
    final dot = ab.dx * cb.dx + ab.dy * cb.dy;
    final mag = ab.distance * cb.distance;
    if (mag == 0) return 0;
    return math.acos((dot / mag).clamp(-1.0, 1.0)) * 180 / math.pi;
  }
}
