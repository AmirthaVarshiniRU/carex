import 'dart:math' as math;
import 'dart:ui';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'shoulder_roll_analyzer.dart';

enum RepState { down, up }

class PostureFeedback {
  final bool isGood;
  final String statusText;
  final String guidanceText;
  final double shoulderTilt;
  final double spineDeviation;
  final double primaryAngle;
  final int formScore; // 0 to 100
  final String phaseName;
  final String diagnosticText;
  final bool isPoseDetected;
  final bool areShouldersDetected;
  final Offset? leftShoulderPos;
  final Offset? rightShoulderPos;

  const PostureFeedback({
    required this.isGood,
    required this.statusText,
    required this.guidanceText,
    required this.shoulderTilt,
    required this.spineDeviation,
    required this.primaryAngle,
    required this.formScore,
    this.phaseName = 'READY',
    this.diagnosticText = 'Scanning for body landmarks...',
    this.isPoseDetected = false,
    this.areShouldersDetected = false,
    this.leftShoulderPos,
    this.rightShoulderPos,
  });
}

class RepCounterService {
  int _repCount = 0;
  RepState _currentState = RepState.down;
  double _lastAngle = 0.0;
  final ShoulderRollAnalyzer _shoulderRollAnalyzer = ShoulderRollAnalyzer();

  PostureFeedback _lastFeedback = const PostureFeedback(
    isGood: false,
    statusText: 'SCANNING POSE',
    guidanceText: 'Align upper body in camera view',
    shoulderTilt: 0.0,
    spineDeviation: 0.0,
    primaryAngle: 0.0,
    formScore: 0,
    phaseName: 'READY',
    diagnosticText: 'Scanning for body landmarks...',
    isPoseDetected: false,
    areShouldersDetected: false,
  );

  int get repCount => _repCount;
  RepState get currentState => _currentState;
  double get lastAngle => _lastAngle;
  PostureFeedback get lastFeedback => _lastFeedback;

  void reset() {
    _repCount = 0;
    _currentState = RepState.down;
    _lastAngle = 0.0;
    _shoulderRollAnalyzer.reset();
    _lastFeedback = const PostureFeedback(
      isGood: false,
      statusText: 'SCANNING POSE',
      guidanceText: 'Align upper body in camera view',
      shoulderTilt: 0.0,
      spineDeviation: 0.0,
      primaryAngle: 0.0,
      formScore: 0,
      phaseName: 'READY',
      diagnosticText: 'Scanning for body landmarks...',
      isPoseDetected: false,
      areShouldersDetected: false,
    );
  }

  /// Evaluates a [Pose] against the current [exerciseName].
  /// Returns `true` if a repetition was just completed.
  bool processPose(Pose? pose, String exerciseName) {
    if (pose == null) {
      _lastFeedback = PostureFeedback(
        isGood: false,
        statusText: 'SCANNING POSE',
        guidanceText: 'Position yourself in camera view',
        shoulderTilt: 0.0,
        spineDeviation: 0.0,
        primaryAngle: 0.0,
        formScore: 0,
        phaseName: 'READY',
        diagnosticText: 'No pose detected',
        isPoseDetected: false,
        areShouldersDetected: false,
      );
      return false;
    }

    final name = exerciseName.toLowerCase();

    // ── 1. Dedicated Shoulder Rolls Pipeline ──────────────────────────────
    if (name.contains('roll')) {
      final rollResult = _shoulderRollAnalyzer.processPose(pose);
      _repCount = rollResult.repCount;
      _lastAngle = rollResult.currentElevation;

      _lastFeedback = PostureFeedback(
        isGood: rollResult.isGoodPosture,
        statusText: rollResult.statusText,
        guidanceText: rollResult.guidanceText,
        shoulderTilt: rollResult.symmetryScore / 100.0,
        spineDeviation: 0.0,
        primaryAngle: rollResult.currentElevation,
        formScore: rollResult.formScore,
        phaseName: rollResult.phaseName,
        diagnosticText: rollResult.diagnosticText,
        isPoseDetected: rollResult.isPoseDetected,
        areShouldersDetected: rollResult.areShouldersDetected,
        leftShoulderPos: rollResult.leftShoulderPos,
        rightShoulderPos: rollResult.rightShoulderPos,
      );

      return rollResult.repCompleted;
    }

    // ── 2. General Landmark & Posture Analysis for other exercises ─────────
    final lm = pose.landmarks;
    final lShoulder = lm[PoseLandmarkType.leftShoulder];
    final rShoulder = lm[PoseLandmarkType.rightShoulder];
    final lElbow = lm[PoseLandmarkType.leftElbow];
    final rElbow = lm[PoseLandmarkType.rightElbow];
    final lWrist = lm[PoseLandmarkType.leftWrist];
    final lHip = lm[PoseLandmarkType.leftHip];
    final rHip = lm[PoseLandmarkType.rightHip];
    final nose = lm[PoseLandmarkType.nose];

    if (lShoulder == null || rShoulder == null) {
      _lastFeedback = const PostureFeedback(
        isGood: false,
        statusText: 'ADJUST POSITION',
        guidanceText: 'Align shoulders in camera frame',
        shoulderTilt: 0.0,
        spineDeviation: 0.0,
        primaryAngle: 0.0,
        formScore: 40,
        phaseName: 'READY',
        diagnosticText: 'Pose found • Shoulders missing',
        isPoseDetected: true,
        areShouldersDetected: false,
      );
      return false;
    }

    final shoulderDist = (lShoulder.x - rShoulder.x).abs();
    final shoulderWidth = shoulderDist > 10 ? shoulderDist : 100.0;
    final shoulderYDiff = (lShoulder.y - rShoulder.y).abs();
    final shoulderTiltRatio = shoulderYDiff / shoulderWidth;

    double spineOffsetRatio = 0.0;
    if (nose != null) {
      final midShoulderX = (lShoulder.x + rShoulder.x) / 2;
      spineOffsetRatio = (nose.x - midShoulderX).abs() / shoulderWidth;
    }

    bool isShoulderLevel = shoulderTiltRatio < 0.22;
    bool isSpineAligned = spineOffsetRatio < 0.28;
    bool isGoodPosture = isShoulderLevel && isSpineAligned;

    String statusText = isGoodPosture ? 'OPTIMAL ALIGNMENT' : 'ADJUST POSTURE';
    String guidanceText = 'Good form! Keep moving.';
    String phaseName = _currentState == RepState.up ? 'IN MOTION' : 'HOLDING';

    if (!isShoulderLevel) {
      guidanceText = 'Level your shoulders evenly.';
    } else if (!isSpineAligned) {
      guidanceText = 'Align head & spine straight.';
    }

    double angle = 0.0;
    bool repCompleted = false;

    if (name.contains('wall') || name.contains('angel') || name.contains('circle')) {
      double leftElevation = 0.0;
      double rightElevation = 0.0;

      if (lHip != null && lElbow != null) {
        leftElevation = _angleBetween(
          Offset(lHip.x, lHip.y),
          Offset(lShoulder.x, lShoulder.y),
          Offset(lElbow.x, lElbow.y),
        );
      }
      if (rHip != null && rElbow != null) {
        rightElevation = _angleBetween(
          Offset(rHip.x, rHip.y),
          Offset(rShoulder.x, rShoulder.y),
          Offset(rElbow.x, rElbow.y),
        );
      }

      angle = math.max(leftElevation, rightElevation);
      if (angle == 0.0 && lElbow != null && lWrist != null) {
        angle = _angleBetween(Offset(lShoulder.x, lShoulder.y), Offset(lElbow.x, lElbow.y), Offset(lWrist.x, lWrist.y));
      }
      _lastAngle = angle;

      const double upThreshold = 95.0;
      const double downThreshold = 45.0;

      if (_currentState == RepState.down && angle >= upThreshold) {
        _currentState = RepState.up;
        phaseName = 'RAISING';
      } else if (_currentState == RepState.up && angle <= downThreshold) {
        _currentState = RepState.down;
        _repCount++;
        repCompleted = true;
        phaseName = 'REP COMPLETE';
      } else {
        phaseName = _currentState == RepState.up ? 'PEAK ABDUCTION' : 'READY';
      }
    } else if (name.contains('stretch')) {
      if (lElbow != null && lWrist != null) {
        angle = _angleBetween(Offset(lShoulder.x, lShoulder.y), Offset(lElbow.x, lElbow.y), Offset(lWrist.x, lWrist.y));
      }
      _lastAngle = angle;
      phaseName = 'HOLDING STRETCH';
    } else {
      if (lElbow != null && lWrist != null) {
        angle = _angleBetween(Offset(lShoulder.x, lShoulder.y), Offset(lElbow.x, lElbow.y), Offset(lWrist.x, lWrist.y));
      }
      _lastAngle = angle;
    }

    double romScore = (angle / 140.0).clamp(0.0, 1.0) * 50.0;
    if (name.contains('stretch') || (_currentState == RepState.down && angle < 50.0)) {
      romScore = 48.0;
    }
    double postureScore = (1.0 - (shoulderTiltRatio * 2.5).clamp(0.0, 1.0)) * 30.0;
    double spineScore = (1.0 - (spineOffsetRatio * 2.5).clamp(0.0, 1.0)) * 20.0;
    int totalScore = (romScore + postureScore + spineScore).round().clamp(30, 99);

    _lastFeedback = PostureFeedback(
      isGood: isGoodPosture,
      statusText: statusText,
      guidanceText: guidanceText,
      shoulderTilt: shoulderTiltRatio,
      spineDeviation: spineOffsetRatio,
      primaryAngle: angle,
      formScore: totalScore,
      phaseName: phaseName,
      diagnosticText: 'L: ${lShoulder.x.toInt()},${lShoulder.y.toInt()} | R: ${rShoulder.x.toInt()},${rShoulder.y.toInt()} | Angle: ${angle.toStringAsFixed(0)}°',
      isPoseDetected: true,
      areShouldersDetected: true,
      leftShoulderPos: Offset(lShoulder.x, lShoulder.y),
      rightShoulderPos: Offset(rShoulder.x, rShoulder.y),
    );

    return repCompleted;
  }

  double _angleBetween(Offset a, Offset b, Offset c) {
    final ab = a - b;
    final cb = c - b;
    final dot = ab.dx * cb.dx + ab.dy * cb.dy;
    final mag = ab.distance * cb.distance;
    if (mag == 0) return 0;
    final cosAngle = (dot / mag).clamp(-1.0, 1.0);
    return math.acos(cosAngle) * 180 / math.pi;
  }
}
