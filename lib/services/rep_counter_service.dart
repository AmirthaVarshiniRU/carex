import 'dart:math' as math;
import 'dart:ui';

import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'shoulder_roll_analyzer.dart';

enum RepState {
  down,
  up,
}

class PostureFeedback {
  final bool isGood;
  final String statusText;
  final String guidanceText;
  final double shoulderTilt;
  final double spineDeviation;
  final double primaryAngle;
  final int formScore;
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

  final ShoulderRollAnalyzer _shoulderRollAnalyzer =
      ShoulderRollAnalyzer();

  String _lastExercise = '';

  PostureFeedback _lastFeedback = const PostureFeedback(
    isGood: false,
    statusText: 'SCANNING POSE',
    guidanceText: 'Align your body in the camera',
    shoulderTilt: 0,
    spineDeviation: 0,
    primaryAngle: 0,
    formScore: 0,
    phaseName: 'READY',
    diagnosticText: 'Scanning for body landmarks...',
    isPoseDetected: false,
    areShouldersDetected: false,
  );

  // Movement memory
  double _previousMetric = 0;
  double _previousMetric2 = 0;

  // Temporal validation prevents a single noisy ML Kit frame (or a
  // small phone/camera shake) from changing the rep state.
  String _transitionCandidate = '';
  int _transitionFrames = 0;
  int _lastTransitionMs = 0;

  // A transition must be present for several consecutive pose frames.
  static const int _requiredStableFrames = 3;
  static const int _minimumTransitionGapMs = 200;

  int get repCount => _repCount;
  RepState get currentState => _currentState;
  double get lastAngle => _lastAngle;
  PostureFeedback get lastFeedback => _lastFeedback;

  void reset() {
    _repCount = 0;
    _currentState = RepState.down;
    _lastAngle = 0;
    _lastExercise = '';

    _previousMetric = 0;
    _previousMetric2 = 0;
    _transitionCandidate = '';
    _transitionFrames = 0;
    _lastTransitionMs = 0;

    _shoulderRollAnalyzer.reset();

    _lastFeedback = const PostureFeedback(
      isGood: false,
      statusText: 'SCANNING POSE',
      guidanceText: 'Align your body in the camera',
      shoulderTilt: 0,
      spineDeviation: 0,
      primaryAngle: 0,
      formScore: 0,
      phaseName: 'READY',
      diagnosticText: 'Scanning for body landmarks...',
      isPoseDetected: false,
      areShouldersDetected: false,
    );
  }

  bool processPose(Pose? pose, String exerciseName) {
    if (pose == null) {
      _lastFeedback = const PostureFeedback(
        isGood: false,
        statusText: 'SCANNING POSE',
        guidanceText: 'Move your full body into the camera',
        shoulderTilt: 0,
        spineDeviation: 0,
        primaryAngle: 0,
        formScore: 0,
        phaseName: 'READY',
        diagnosticText: 'No pose detected',
        isPoseDetected: false,
        areShouldersDetected: false,
      );

      return false;
    }

    final name = exerciseName.toLowerCase().trim();

    // Reset movement state when switching exercises.
    if (_lastExercise != name) {
      _repCount = 0;
      _currentState = RepState.down;
      _previousMetric = 0;
      _previousMetric2 = 0;
      _transitionCandidate = '';
      _transitionFrames = 0;
      _lastTransitionMs = 0;
      _lastExercise = name;
    }

    // ------------------------------------------------------------
    // 1. SHOULDER ROLLS
    // ------------------------------------------------------------
    if (name.contains('shoulder roll')) {
      return _processShoulderRoll(pose);
    }

    // ------------------------------------------------------------
    // COMMON LANDMARKS
    // ------------------------------------------------------------

    final lm = pose.landmarks;

    final ls = lm[PoseLandmarkType.leftShoulder];
    final rs = lm[PoseLandmarkType.rightShoulder];

    final le = lm[PoseLandmarkType.leftElbow];
    final re = lm[PoseLandmarkType.rightElbow];

    final lw = lm[PoseLandmarkType.leftWrist];
    final rw = lm[PoseLandmarkType.rightWrist];

    final lh = lm[PoseLandmarkType.leftHip];
    final rh = lm[PoseLandmarkType.rightHip];

    final lk = lm[PoseLandmarkType.leftKnee];
    final rk = lm[PoseLandmarkType.rightKnee];

    final la = lm[PoseLandmarkType.leftAnkle];
    final ra = lm[PoseLandmarkType.rightAnkle];

    final nose = lm[PoseLandmarkType.nose];

    if (ls == null || rs == null) {
      _setFeedback(
        isGood: false,
        status: 'ADJUST POSITION',
        guidance: 'Show both shoulders in the camera',
        phase: 'READY',
        angle: 0,
        score: 35,
        poseDetected: true,
        shouldersDetected: false,
      );

      return false;
    }

    final shoulderWidth = _distance(
      Offset(ls.x, ls.y),
      Offset(rs.x, rs.y),
    );

    final shoulderTilt =
        (ls.y - rs.y).abs() / math.max(shoulderWidth, 1);

    final midShoulderX = (ls.x + rs.x) / 2;
    final midShoulderY = (ls.y + rs.y) / 2;

    double spineOffset = 0;

    if (nose != null) {
      spineOffset =
          (nose.x - midShoulderX).abs() /
          math.max(shoulderWidth, 1);
    }

    // ------------------------------------------------------------
    // NECK EXERCISES
    // ------------------------------------------------------------

    if (name.contains('neck rotation')) {
      return _neckRotation(
        nose,
        ls,
        rs,
        shoulderWidth,
      );
    }

    if (name.contains('side neck stretch')) {
      return _neckSideMovement(
        nose,
        ls,
        rs,
        shoulderWidth,
        'SIDE NECK STRETCH',
      );
    }

    if (name.contains('neck side bend')) {
      return _neckSideMovement(
        nose,
        ls,
        rs,
        shoulderWidth,
        'NECK SIDE BEND',
      );
    }

    if (name.contains('chin tuck')) {
      return _chinTuck(
        nose,
        ls,
        rs,
        shoulderWidth,
      );
    }

    if (name.contains('neck extension')) {
      return _neckExtension(
        nose,
        ls,
        rs,
        shoulderWidth,
      );
    }

    // ------------------------------------------------------------
    // SHOULDER EXERCISES
    // ------------------------------------------------------------

    if (name.contains('arm circle')) {
      return _armCircles(
        ls,
        rs,
        le,
        re,
        lw,
        rw,
        shoulderWidth,
      );
    }

    if (name.contains('shoulder stretch')) {
      return _shoulderStretch(
        ls,
        rs,
        le,
        re,
        lw,
        rw,
        shoulderWidth,
      );
    }

    if (name.contains('cross-body')) {
      return _crossBodyStretch(
        ls,
        rs,
        lw,
        rw,
        shoulderWidth,
      );
    }

    if (name.contains('wall angel')) {
      return _wallAngels(
        ls,
        rs,
        le,
        re,
        lw,
        rw,
        shoulderWidth,
      );
    }

    // ------------------------------------------------------------
    // KNEE EXERCISES
    // ------------------------------------------------------------

    if (name.contains('knee flexion')) {
      return _kneeFlexion(
        lh,
        rh,
        lk,
        rk,
        la,
        ra,
        shoulderWidth,
      );
    }

    if (name.contains('quadriceps stretch')) {
      return _quadStretch(
        lk,
        rk,
        la,
        ra,
        lh,
        rh,
        shoulderWidth,
      );
    }

    if (name.contains('hamstring stretch')) {
      return _hamstringStretch(
        lh,
        rh,
        lk,
        rk,
        la,
        ra,
        shoulderWidth,
      );
    }

    if (name.contains('calf stretch')) {
      return _calfStretch(
        lk,
        rk,
        la,
        ra,
        shoulderWidth,
      );
    }

    if (name.contains('seated leg raise')) {
      return _seatedLegRaise(
        lh,
        rh,
        lk,
        rk,
        shoulderWidth,
      );
    }

    // ------------------------------------------------------------
    // BACK EXERCISES
    // ------------------------------------------------------------

    if (name.contains('cat-cow')) {
      return _catCow(
        nose,
        ls,
        rs,
        lh,
        rh,
        shoulderWidth,
      );
    }

    if (name.contains("child's pose") ||
        name.contains('child pose')) {
      return _childPose(
        nose,
        ls,
        rs,
        lh,
        rh,
        shoulderWidth,
      );
    }

    if (name.contains('knee to chest')) {
      return _kneeToChest(
        lh,
        rh,
        lk,
        rk,
        shoulderWidth,
      );
    }

    if (name.contains('pelvic tilt')) {
      return _pelvicTilt(
        ls,
        rs,
        lh,
        rh,
        shoulderWidth,
      );
    }

    if (name.contains('seated spinal twist')) {
      return _spinalTwist(
        nose,
        ls,
        rs,
        lh,
        rh,
        shoulderWidth,
      );
    }

    // ------------------------------------------------------------
    // WRIST / HAND EXERCISES
    // ------------------------------------------------------------

    if (name.contains('wrist rotation')) {
      return _wristRotation(
        le,
        re,
        lw,
        rw,
        shoulderWidth,
      );
    }

    if (name.contains('wrist extensor')) {
      return _wristStretch(
        le,
        re,
        lw,
        rw,
        shoulderWidth,
        'WRIST EXTENSOR STRETCH',
      );
    }

    if (name.contains('wrist flexor')) {
      return _wristStretch(
        le,
        re,
        lw,
        rw,
        shoulderWidth,
        'WRIST FLEXOR STRETCH',
      );
    }

    if (name.contains('finger stretching')) {
      return _wristMovement(
        le,
        re,
        lw,
        rw,
        shoulderWidth,
        'FINGER STRETCHING',
      );
    }

    if (name.contains('grip strengthening')) {
      return _wristMovement(
        le,
        re,
        lw,
        rw,
        shoulderWidth,
        'GRIP STRENGTHENING',
      );
    }

    // ------------------------------------------------------------
    // FALLBACK
    // ------------------------------------------------------------

    return _genericUpperBody(
      ls,
      rs,
      le,
      re,
      lw,
      rw,
      shoulderWidth,
      spineOffset,
      shoulderTilt,
    );
  }

  // ============================================================
  // SHOULDER ROLLS
  // ============================================================

  bool _processShoulderRoll(Pose pose) {
    final result = _shoulderRollAnalyzer.processPose(pose);

    _repCount = result.repCount;
    _lastAngle = result.currentElevation;

    _lastFeedback = PostureFeedback(
      isGood: result.isGoodPosture,
      statusText: result.statusText,
      guidanceText: result.guidanceText,
      shoulderTilt: result.symmetryScore / 100,
      spineDeviation: 0,
      primaryAngle: result.currentElevation,
      formScore: result.formScore,
      phaseName: result.phaseName,
      diagnosticText: result.diagnosticText,
      isPoseDetected: result.isPoseDetected,
      areShouldersDetected: result.areShouldersDetected,
      leftShoulderPos: result.leftShoulderPos,
      rightShoulderPos: result.rightShoulderPos,
    );

    return result.repCompleted;
  }

  // ============================================================
  // NECK ROTATION
  // ============================================================

  bool _neckRotation(
    PoseLandmark? nose,
    PoseLandmark? ls,
    PoseLandmark? rs,
    double scale,
  ) {
    if (nose == null || ls == null || rs == null) {
      return false;
    }

    final midX = (ls.x + rs.x) / 2;

    final metric =
        (nose.x - midX) / math.max(scale, 1);

    final previous = _previousMetric;
    _previousMetric = metric;

    bool completed = false;

    if (_currentState == RepState.down &&
        _stableTransition('1:UP', metric.abs() > 0.22)) {
      _currentState = RepState.up;
    } else if (_currentState == RepState.up &&
        _stableTransition('1:DOWN', metric.abs() < 0.08)) {
      _currentState = RepState.down;
      _repCount++;
      completed = true;
    }

    _lastAngle = metric.abs() * 100;

    _setFeedback(
      isGood: metric.abs() < 0.55,
      status: completed ? 'REP COMPLETE' : 'NECK ROTATION',
      guidance: metric.abs() > 0.55
          ? 'Do not rotate too far'
          : 'Rotate your head slowly',
      phase: _currentState == RepState.up
          ? 'ROTATED'
          : 'READY',
      angle: _lastAngle,
      score: _movementScore(metric.abs(), 0.22, 0.55),
      poseDetected: true,
    );

    return completed;
  }

  // ============================================================
  // SIDE NECK MOVEMENT
  // ============================================================

  bool _neckSideMovement(
    PoseLandmark? nose,
    PoseLandmark? ls,
    PoseLandmark? rs,
    double scale,
    String title,
  ) {
    if (nose == null || ls == null || rs == null) {
      return false;
    }

    final midY = (ls.y + rs.y) / 2;

    final metric =
        (nose.y - midY) / math.max(scale, 1);

    _previousMetric2 = _previousMetric;
    _previousMetric = metric;

    bool completed = false;

    if (_currentState == RepState.down &&
        _stableTransition('2:UP', metric.abs() > 0.18)) {
      _currentState = RepState.up;
    } else if (_currentState == RepState.up &&
        _stableTransition('2:DOWN', metric.abs() < 0.08)) {
      _currentState = RepState.down;
      _repCount++;
      completed = true;
    }

    _lastAngle = metric.abs() * 100;

    _setFeedback(
      isGood: metric.abs() < 0.50,
      status: completed ? 'REP COMPLETE' : title,
      guidance: metric.abs() > 0.50
          ? 'Reduce the neck movement'
          : 'Move slowly and return to center',
      phase: _currentState == RepState.up
          ? 'STRETCHING'
          : 'READY',
      angle: _lastAngle,
      score: _movementScore(metric.abs(), 0.18, 0.50),
      poseDetected: true,
    );

    return completed;
  }

  // ============================================================
  // CHIN TUCK
  // ============================================================

  bool _chinTuck(
    PoseLandmark? nose,
    PoseLandmark? ls,
    PoseLandmark? rs,
    double scale,
  ) {
    if (nose == null || ls == null || rs == null) {
      return false;
    }

    final midX = (ls.x + rs.x) / 2;

    final metric =
        (nose.x - midX) / math.max(scale, 1);

    bool completed = false;

    if (_currentState == RepState.down &&
        _stableTransition('3:UP', metric.abs() < 0.10)) {
      _currentState = RepState.up;
    } else if (_currentState == RepState.up &&
        _stableTransition('3:DOWN', metric.abs() > 0.20)) {
      _currentState = RepState.down;
      _repCount++;
      completed = true;
    }

    _lastAngle = metric.abs() * 100;

    _setFeedback(
      isGood: metric.abs() < 0.55,
      status: completed ? 'REP COMPLETE' : 'CHIN TUCK',
      guidance: 'Pull your chin gently backward',
      phase: _currentState == RepState.up
          ? 'TUCKING'
          : 'RETURN',
      angle: _lastAngle,
      score: 85,
      poseDetected: true,
    );

    return completed;
  }

  // ============================================================
  // NECK EXTENSION
  // ============================================================

  bool _neckExtension(
    PoseLandmark? nose,
    PoseLandmark? ls,
    PoseLandmark? rs,
    double scale,
  ) {
    if (nose == null || ls == null || rs == null) {
      return false;
    }

    final midY = (ls.y + rs.y) / 2;

    final metric =
        (midY - nose.y) / math.max(scale, 1);

    bool completed = false;

    if (_currentState == RepState.down &&
        _stableTransition('4:UP', metric > 0.35)) {
      _currentState = RepState.up;
    } else if (_currentState == RepState.up &&
        _stableTransition('4:DOWN', metric < 0.20)) {
      _currentState = RepState.down;
      _repCount++;
      completed = true;
    }

    _lastAngle = metric * 100;

    _setFeedback(
      isGood: metric < 0.65,
      status: completed ? 'REP COMPLETE' : 'NECK EXTENSION',
      guidance: metric > 0.65
          ? 'Avoid excessive extension'
          : 'Tilt head back slowly',
      phase: _currentState == RepState.up
          ? 'EXTENDING'
          : 'READY',
      angle: _lastAngle,
      score: 85,
      poseDetected: true,
    );

    return completed;
  }

  // ============================================================
  // ARM CIRCLES
  // ============================================================

  bool _armCircles(
    PoseLandmark? ls,
    PoseLandmark? rs,
    PoseLandmark? le,
    PoseLandmark? re,
    PoseLandmark? lw,
    PoseLandmark? rw,
    double scale,
  ) {
    if (ls == null || rs == null ||
        le == null || re == null ||
        lw == null || rw == null) {
      return false;
    }

    final leftAngle = _angle(
      Offset(ls.x, ls.y),
      Offset(le.x, le.y),
      Offset(lw.x, lw.y),
    );

    final rightAngle = _angle(
      Offset(rs.x, rs.y),
      Offset(re.x, re.y),
      Offset(rw.x, rw.y),
    );

    final metric =
        (leftAngle + rightAngle) / 2;

    bool completed = false;

    if (_currentState == RepState.down &&
        _stableTransition('5:UP', metric > 100)) {
      _currentState = RepState.up;
    } else if (_currentState == RepState.up &&
        _stableTransition('5:DOWN', metric < 75)) {
      _currentState = RepState.down;
      _repCount++;
      completed = true;
    }

    _lastAngle = metric;

    _setFeedback(
      isGood: true,
      status: completed ? 'REP COMPLETE' : 'ARM CIRCLES',
      guidance: 'Make smooth circular movements',
      phase: _currentState == RepState.up
          ? 'CIRCULATING'
          : 'READY',
      angle: metric,
      score: 90,
      poseDetected: true,
    );

    return completed;
  }

  // ============================================================
  // SHOULDER STRETCH
  // ============================================================

  bool _shoulderStretch(
    PoseLandmark? ls,
    PoseLandmark? rs,
    PoseLandmark? le,
    PoseLandmark? re,
    PoseLandmark? lw,
    PoseLandmark? rw,
    double scale,
  ) {
    if (ls == null || rs == null ||
        lw == null || rw == null) {
      return false;
    }

    final distance =
        _distance(
          Offset(lw.x, lw.y),
          Offset(rs.x, rs.y),
        ) /
        math.max(scale, 1);

    bool completed = false;

    if (_currentState == RepState.down &&
        _stableTransition('6:UP', distance < 0.75)) {
      _currentState = RepState.up;
    } else if (_currentState == RepState.up &&
        _stableTransition('6:DOWN', distance > 1.0)) {
      _currentState = RepState.down;
      _repCount++;
      completed = true;
    }

    _lastAngle = distance * 100;

    _setFeedback(
      isGood: distance < 1.5,
      status: completed
          ? 'REP COMPLETE'
          : 'SHOULDER STRETCH',
      guidance: 'Bring one arm gently across your chest',
      phase: _currentState == RepState.up
          ? 'STRETCHING'
          : 'READY',
      angle: _lastAngle,
      score: 88,
      poseDetected: true,
    );

    return completed;
  }

  // ============================================================
  // CROSS BODY STRETCH
  // ============================================================

  bool _crossBodyStretch(
    PoseLandmark? ls,
    PoseLandmark? rs,
    PoseLandmark? lw,
    PoseLandmark? rw,
    double scale,
  ) {
    if (ls == null || rs == null ||
        lw == null || rw == null) {
      return false;
    }

    final midX = (ls.x + rs.x) / 2;

    final leftCross =
        (lw.x - midX).abs() / math.max(scale, 1);

    final rightCross =
        (rw.x - midX).abs() / math.max(scale, 1);

    final metric = math.max(leftCross, rightCross);

    bool completed = false;

    if (_currentState == RepState.down &&
        _stableTransition('7:UP', metric < 0.30)) {
      _currentState = RepState.up;
    } else if (_currentState == RepState.up &&
        _stableTransition('7:DOWN', metric > 0.45)) {
      _currentState = RepState.down;
      _repCount++;
      completed = true;
    }

    _lastAngle = metric * 100;

    _setFeedback(
      isGood: true,
      status: completed
          ? 'REP COMPLETE'
          : 'CROSS-BODY STRETCH',
      guidance: 'Bring your arm gently across your chest',
      phase: _currentState == RepState.up
          ? 'STRETCHING'
          : 'READY',
      angle: _lastAngle,
      score: 90,
      poseDetected: true,
    );

    return completed;
  }

  // ============================================================
  // WALL ANGELS
  // ============================================================

  bool _wallAngels(
    PoseLandmark? ls,
    PoseLandmark? rs,
    PoseLandmark? le,
    PoseLandmark? re,
    PoseLandmark? lw,
    PoseLandmark? rw,
    double scale,
  ) {
    if (ls == null || rs == null ||
        le == null || re == null) {
      return false;
    }

    final left =
        _angle(
          Offset(ls.x, ls.y),
          Offset(le.x, le.y),
          Offset(lw?.x ?? le.x, lw?.y ?? le.y),
        );

    final right =
        _angle(
          Offset(rs.x, rs.y),
          Offset(re.x, re.y),
          Offset(rw?.x ?? re.x, rw?.y ?? re.y),
        );

    final metric = (left + right) / 2;

    bool completed = false;

    if (_currentState == RepState.down &&
        _stableTransition('8:UP', metric > 110)) {
      _currentState = RepState.up;
    } else if (_currentState == RepState.up &&
        _stableTransition('8:DOWN', metric < 80)) {
      _currentState = RepState.down;
      _repCount++;
      completed = true;
    }

    _lastAngle = metric;

    _setFeedback(
      isGood: true,
      status: completed ? 'REP COMPLETE' : 'WALL ANGELS',
      guidance: 'Keep elbows and shoulders controlled',
      phase: _currentState == RepState.up
          ? 'RAISING'
          : 'LOWERING',
      angle: metric,
      score: 90,
      poseDetected: true,
    );

    return completed;
  }

  // ============================================================
  // KNEE FLEXION
  // ============================================================

  bool _kneeFlexion(
    PoseLandmark? lh,
    PoseLandmark? rh,
    PoseLandmark? lk,
    PoseLandmark? rk,
    PoseLandmark? la,
    PoseLandmark? ra,
    double scale,
  ) {
    if (lh == null || lk == null || la == null) {
      return false;
    }

    final angle = _angle(
      Offset(lh.x, lh.y),
      Offset(lk.x, lk.y),
      Offset(la.x, la.y),
    );

    bool completed = false;

    if (_currentState == RepState.down &&
        _stableTransition('9:UP', angle < 125)) {
      _currentState = RepState.up;
    } else if (_currentState == RepState.up &&
        _stableTransition('9:DOWN', angle > 155)) {
      _currentState = RepState.down;
      _repCount++;
      completed = true;
    }

    _lastAngle = angle;

    _setFeedback(
      isGood: angle > 65,
      status: completed ? 'REP COMPLETE' : 'KNEE FLEXION',
      guidance: angle < 65
          ? 'Do not bend the knee too far'
          : 'Bend and straighten your knee slowly',
      phase: _currentState == RepState.up
          ? 'STRAIGHTENING'
          : 'BENDING',
      angle: angle,
      score: 88,
      poseDetected: true,
    );

    return completed;
  }

  // ============================================================
  // QUADRICEPS STRETCH
  // ============================================================

  bool _quadStretch(
    PoseLandmark? lk,
    PoseLandmark? rk,
    PoseLandmark? la,
    PoseLandmark? ra,
    PoseLandmark? lh,
    PoseLandmark? rh,
    double scale,
  ) {
    if (lk == null || la == null || lh == null) {
      return false;
    }

    final angle = _angle(
      Offset(lh.x, lh.y),
      Offset(lk.x, lk.y),
      Offset(la.x, la.y),
    );

    bool completed = false;

    if (_currentState == RepState.down &&
        _stableTransition('10:UP', angle < 125)) {
      _currentState = RepState.up;
    } else if (_currentState == RepState.up &&
        _stableTransition('10:DOWN', angle > 150)) {
      _currentState = RepState.down;
      _repCount++;
      completed = true;
    }

    _lastAngle = angle;

    _setFeedback(
      isGood: angle > 70,
      status: completed
          ? 'REP COMPLETE'
          : 'QUADRICEPS STRETCH',
      guidance: 'Pull your heel gently toward your body',
      phase: _currentState == RepState.up
          ? 'STRETCHING'
          : 'RETURN',
      angle: angle,
      score: 87,
      poseDetected: true,
    );

    return completed;
  }

  // ============================================================
  // HAMSTRING STRETCH
  // ============================================================

  bool _hamstringStretch(
    PoseLandmark? lh,
    PoseLandmark? rh,
    PoseLandmark? lk,
    PoseLandmark? rk,
    PoseLandmark? la,
    PoseLandmark? ra,
    double scale,
  ) {
    if (lh == null || lk == null || la == null) {
      return false;
    }

    final angle = _angle(
      Offset(lh.x, lh.y),
      Offset(lk.x, lk.y),
      Offset(la.x, la.y),
    );

    bool completed = false;

    if (_currentState == RepState.down &&
        _stableTransition('11:UP', angle > 150)) {
      _currentState = RepState.up;
    } else if (_currentState == RepState.up &&
        _stableTransition('11:DOWN', angle < 125)) {
      _currentState = RepState.down;
      _repCount++;
      completed = true;
    }

    _lastAngle = angle;

    _setFeedback(
      isGood: angle > 80,
      status: completed
          ? 'REP COMPLETE'
          : 'HAMSTRING STRETCH',
      guidance: 'Keep your back straight and reach gently',
      phase: _currentState == RepState.up
          ? 'STRETCHING'
          : 'RETURN',
      angle: angle,
      score: 88,
      poseDetected: true,
    );

    return completed;
  }

  // ============================================================
  // CALF STRETCH
  // ============================================================

  bool _calfStretch(
    PoseLandmark? lk,
    PoseLandmark? rk,
    PoseLandmark? la,
    PoseLandmark? ra,
    double scale,
  ) {
    if (lk == null || la == null) {
      return false;
    }

    final metric =
        (lk.y - la.y).abs() /
        math.max(scale, 1);

    bool completed = false;

    if (_currentState == RepState.down &&
        _stableTransition('12:UP', metric > 0.45)) {
      _currentState = RepState.up;
    } else if (_currentState == RepState.up &&
        _stableTransition('12:DOWN', metric < 0.25)) {
      _currentState = RepState.down;
      _repCount++;
      completed = true;
    }

    _lastAngle = metric * 100;

    _setFeedback(
      isGood: true,
      status: completed
          ? 'REP COMPLETE'
          : 'CALF STRETCH',
      guidance: 'Keep your heel controlled',
      phase: _currentState == RepState.up
          ? 'STRETCHING'
          : 'RETURN',
      angle: _lastAngle,
      score: 88,
      poseDetected: true,
    );

    return completed;
  }

  // ============================================================
  // SEATED LEG RAISE
  // ============================================================

  bool _seatedLegRaise(
    PoseLandmark? lh,
    PoseLandmark? rh,
    PoseLandmark? lk,
    PoseLandmark? rk,
    double scale,
  ) {
    if (lh == null || lk == null) {
      return false;
    }

    final metric =
        (lh.y - lk.y) /
        math.max(scale, 1);

    bool completed = false;

    if (_currentState == RepState.down &&
        _stableTransition('13:UP', metric > 0.15)) {
      _currentState = RepState.up;
    } else if (_currentState == RepState.up &&
        _stableTransition('13:DOWN', metric < -0.05)) {
      _currentState = RepState.down;
      _repCount++;
      completed = true;
    }

    _lastAngle = metric * 100;

    _setFeedback(
      isGood: true,
      status: completed
          ? 'REP COMPLETE'
          : 'SEATED LEG RAISE',
      guidance: 'Raise and lower your leg slowly',
      phase: _currentState == RepState.up
          ? 'RAISING'
          : 'LOWERING',
      angle: _lastAngle,
      score: 90,
      poseDetected: true,
    );

    return completed;
  }

  // ============================================================
  // CAT COW
  // ============================================================

  bool _catCow(
    PoseLandmark? nose,
    PoseLandmark? ls,
    PoseLandmark? rs,
    PoseLandmark? lh,
    PoseLandmark? rh,
    double scale,
  ) {
    if (nose == null || ls == null || rs == null) {
      return false;
    }

    final shoulderY = (ls.y + rs.y) / 2;

    final metric =
        (nose.y - shoulderY) /
        math.max(scale, 1);

    bool completed = false;

    if (_currentState == RepState.down &&
        _stableTransition('14:UP', metric.abs() > 0.25)) {
      _currentState = RepState.up;
    } else if (_currentState == RepState.up &&
        _stableTransition('14:DOWN', metric.abs() < 0.12)) {
      _currentState = RepState.down;
      _repCount++;
      completed = true;
    }

    _lastAngle = metric.abs() * 100;

    _setFeedback(
      isGood: true,
      status: completed ? 'REP COMPLETE' : 'CAT-COW',
      guidance: 'Move your spine slowly between positions',
      phase: _currentState == RepState.up
          ? 'FLEXING'
          : 'READY',
      angle: _lastAngle,
      score: 90,
      poseDetected: true,
    );

    return completed;
  }

  // ============================================================
  // CHILD'S POSE
  // ============================================================

  bool _childPose(
    PoseLandmark? nose,
    PoseLandmark? ls,
    PoseLandmark? rs,
    PoseLandmark? lh,
    PoseLandmark? rh,
    double scale,
  ) {
    if (nose == null || lh == null || rh == null) {
      return false;
    }

    final hipY = (lh.y + rh.y) / 2;

    final metric =
        (hipY - nose.y) /
        math.max(scale, 1);

    bool completed = false;

    if (_currentState == RepState.down &&
        _stableTransition('15:UP', metric > 0.7)) {
      _currentState = RepState.up;
    } else if (_currentState == RepState.up &&
        _stableTransition('15:DOWN', metric < 0.45)) {
      _currentState = RepState.down;
      _repCount++;
      completed = true;
    }

    _lastAngle = metric * 100;

    _setFeedback(
      isGood: true,
      status: completed
          ? 'REP COMPLETE'
          : 'CHILD\'S POSE',
      guidance: 'Lower your torso gently toward the floor',
      phase: _currentState == RepState.up
          ? 'FOLDING'
          : 'RETURN',
      angle: _lastAngle,
      score: 90,
      poseDetected: true,
    );

    return completed;
  }

  // ============================================================
  // KNEE TO CHEST
  // ============================================================

  bool _kneeToChest(
    PoseLandmark? lh,
    PoseLandmark? rh,
    PoseLandmark? lk,
    PoseLandmark? rk,
    double scale,
  ) {
    if (lh == null || lk == null) {
      return false;
    }

    final distance =
        _distance(
          Offset(lh.x, lh.y),
          Offset(lk.x, lk.y),
        ) /
        math.max(scale, 1);

    bool completed = false;

    if (_currentState == RepState.down &&
        _stableTransition('16:UP', distance < 0.65)) {
      _currentState = RepState.up;
    } else if (_currentState == RepState.up &&
        _stableTransition('16:DOWN', distance > 0.90)) {
      _currentState = RepState.down;
      _repCount++;
      completed = true;
    }

    _lastAngle = distance * 100;

    _setFeedback(
      isGood: true,
      status: completed
          ? 'REP COMPLETE'
          : 'KNEE TO CHEST',
      guidance: 'Bring your knee gently toward your chest',
      phase: _currentState == RepState.up
          ? 'PULLING'
          : 'RETURN',
      angle: _lastAngle,
      score: 88,
      poseDetected: true,
    );

    return completed;
  }

  // ============================================================
  // PELVIC TILT
  // ============================================================

  bool _pelvicTilt(
    PoseLandmark? ls,
    PoseLandmark? rs,
    PoseLandmark? lh,
    PoseLandmark? rh,
    double scale,
  ) {
    if (ls == null || rs == null ||
        lh == null || rh == null) {
      return false;
    }

    final shoulderY = (ls.y + rs.y) / 2;
    final hipY = (lh.y + rh.y) / 2;

    final metric =
        (hipY - shoulderY) /
        math.max(scale, 1);

    bool completed = false;

    if (_currentState == RepState.down &&
        _stableTransition('17:UP', metric > 0.7)) {
      _currentState = RepState.up;
    } else if (_currentState == RepState.up &&
        _stableTransition('17:DOWN', metric < 0.55)) {
      _currentState = RepState.down;
      _repCount++;
      completed = true;
    }

    _lastAngle = metric * 100;

    _setFeedback(
      isGood: true,
      status: completed ? 'REP COMPLETE' : 'PELVIC TILT',
      guidance: 'Tighten your core and tilt your pelvis',
      phase: _currentState == RepState.up
          ? 'TILTING'
          : 'RETURN',
      angle: _lastAngle,
      score: 90,
      poseDetected: true,
    );

    return completed;
  }

  // ============================================================
  // SEATED SPINAL TWIST
  // ============================================================

  bool _spinalTwist(
    PoseLandmark? nose,
    PoseLandmark? ls,
    PoseLandmark? rs,
    PoseLandmark? lh,
    PoseLandmark? rh,
    double scale,
  ) {
    if (nose == null || ls == null || rs == null) {
      return false;
    }

    final midX = (ls.x + rs.x) / 2;

    final metric =
        (nose.x - midX).abs() /
        math.max(scale, 1);

    bool completed = false;

    if (_currentState == RepState.down &&
        _stableTransition('18:UP', metric > 0.20)) {
      _currentState = RepState.up;
    } else if (_currentState == RepState.up &&
        _stableTransition('18:DOWN', metric < 0.08)) {
      _currentState = RepState.down;
      _repCount++;
      completed = true;
    }

    _lastAngle = metric * 100;

    _setFeedback(
      isGood: true,
      status: completed
          ? 'REP COMPLETE'
          : 'SPINAL TWIST',
      guidance: 'Rotate your upper body slowly',
      phase: _currentState == RepState.up
          ? 'TWISTING'
          : 'CENTER',
      angle: _lastAngle,
      score: 88,
      poseDetected: true,
    );

    return completed;
  }

  // ============================================================
  // WRIST ROTATION
  // ============================================================

  bool _wristRotation(
    PoseLandmark? le,
    PoseLandmark? re,
    PoseLandmark? lw,
    PoseLandmark? rw,
    double scale,
  ) {
    if (le == null || lw == null) {
      return false;
    }

    final angle = math.atan2(
          lw.y - le.y,
          lw.x - le.x,
        ) *
        180 /
        math.pi;

    final normalized = angle.abs();

    bool completed = false;

    if (_currentState == RepState.down &&
        _stableTransition('19:UP', normalized > 35)) {
      _currentState = RepState.up;
    } else if (_currentState == RepState.up &&
        _stableTransition('19:DOWN', normalized < 15)) {
      _currentState = RepState.down;
      _repCount++;
      completed = true;
    }

    _lastAngle = normalized;

    _setFeedback(
      isGood: true,
      status: completed
          ? 'REP COMPLETE'
          : 'WRIST ROTATION',
      guidance: 'Rotate your wrist slowly',
      phase: _currentState == RepState.up
          ? 'ROTATING'
          : 'READY',
      angle: normalized,
      score: 88,
      poseDetected: true,
    );

    return completed;
  }

  // ============================================================
  // WRIST STRETCH
  // ============================================================

  bool _wristStretch(
    PoseLandmark? le,
    PoseLandmark? re,
    PoseLandmark? lw,
    PoseLandmark? rw,
    double scale,
    String title,
  ) {
    if (le == null || lw == null) {
      return false;
    }

    final angle = _angle(
      Offset(le.x, le.y),
      Offset(lw.x, lw.y),
      Offset(
        lw.x + (lw.x - le.x),
        lw.y + (lw.y - le.y),
      ),
    );

    bool completed = false;

    if (_currentState == RepState.down &&
        _stableTransition('20:UP', angle > 20)) {
      _currentState = RepState.up;
    } else if (_currentState == RepState.up &&
        _stableTransition('20:DOWN', angle < 10)) {
      _currentState = RepState.down;
      _repCount++;
      completed = true;
    }

    _lastAngle = angle;

    _setFeedback(
      isGood: true,
      status: completed ? 'REP COMPLETE' : title,
      guidance: 'Hold the stretch gently',
      phase: _currentState == RepState.up
          ? 'STRETCHING'
          : 'READY',
      angle: angle,
      score: 90,
      poseDetected: true,
    );

    return completed;
  }

  // ============================================================
  // FINGER / GRIP
  // ============================================================

  bool _wristMovement(
    PoseLandmark? le,
    PoseLandmark? re,
    PoseLandmark? lw,
    PoseLandmark? rw,
    double scale,
    String title,
  ) {
    if (le == null || lw == null) {
      return false;
    }

    final distance =
        _distance(
          Offset(le.x, le.y),
          Offset(lw.x, lw.y),
        ) /
        math.max(scale, 1);

    bool completed = false;

    if (_currentState == RepState.down &&
        _stableTransition('21:UP', distance > 0.40)) {
      _currentState = RepState.up;
    } else if (_currentState == RepState.up &&
        _stableTransition('21:DOWN', distance < 0.32)) {
      _currentState = RepState.down;
      _repCount++;
      completed = true;
    }

    _lastAngle = distance * 100;

    _setFeedback(
      isGood: true,
      status: completed ? 'REP COMPLETE' : title,
      guidance: title == 'GRIP STRENGTHENING'
          ? 'Squeeze and release slowly'
          : 'Open and close your fingers slowly',
      phase: _currentState == RepState.up
          ? 'MOVING'
          : 'READY',
      angle: _lastAngle,
      score: 85,
      poseDetected: true,
    );

    return completed;
  }

  // ============================================================
  // GENERIC UPPER BODY
  // ============================================================

  bool _genericUpperBody(
    PoseLandmark? ls,
    PoseLandmark? rs,
    PoseLandmark? le,
    PoseLandmark? re,
    PoseLandmark? lw,
    PoseLandmark? rw,
    double scale,
    double spineOffset,
    double shoulderTilt,
  ) {
    if (ls == null || rs == null) {
      return false;
    }

    double angle = 0;

    if (le != null && lw != null) {
      angle = _angle(
        Offset(ls.x, ls.y),
        Offset(le.x, le.y),
        Offset(lw.x, lw.y),
      );
    }

    _lastAngle = angle;

    _setFeedback(
      isGood: shoulderTilt < 0.25 &&
          spineOffset < 0.35,
      status: 'POSE DETECTED',
      guidance: 'Perform the exercise slowly',
      phase: 'MOVING',
      angle: angle,
      score: 80,
      poseDetected: true,
    );

    return false;
  }

  // ============================================================
  // HELPERS
  // ============================================================

  void _setFeedback({
    required bool isGood,
    required String status,
    required String guidance,
    required String phase,
    required double angle,
    required int score,
    required bool poseDetected,
    bool shouldersDetected = true,
  }) {
    final lmScore = score.clamp(0, 100);

    final ls = _lastLandmark(
      PoseLandmarkType.leftShoulder,
    );

    final rs = _lastLandmark(
      PoseLandmarkType.rightShoulder,
    );

    _lastFeedback = PostureFeedback(
      isGood: isGood,
      statusText: status,
      guidanceText: guidance,
      shoulderTilt: 0,
      spineDeviation: 0,
      primaryAngle: angle,
      formScore: lmScore,
      phaseName: phase,
      diagnosticText:
          'Exercise analysis active • Angle: ${angle.toStringAsFixed(1)}°',
      isPoseDetected: poseDetected,
      areShouldersDetected: shouldersDetected,
      leftShoulderPos:
          ls == null ? null : Offset(ls.x, ls.y),
      rightShoulderPos:
          rs == null ? null : Offset(rs.x, rs.y),
    );
  }

  PoseLandmark? _lastLandmark(
    PoseLandmarkType type,
  ) {
    // Position is supplied through processPose-specific feedback.
    return null;
  }

  /// Requires the same transition condition to remain true for
  /// several consecutive pose frames and enforces a short dead-time
  /// between transitions. This filters landmark jitter and small
  /// camera/phone shakes without changing the existing exercise rules.
  bool _stableTransition(String key, bool condition) {
    final now = DateTime.now().millisecondsSinceEpoch;

    if (!condition) {
      if (_transitionCandidate == key) {
        _transitionCandidate = '';
        _transitionFrames = 0;
      }
      return false;
    }

    if (_transitionCandidate != key) {
      _transitionCandidate = key;
      _transitionFrames = 1;
      return false;
    }

    _transitionFrames++;

    if (_transitionFrames < _requiredStableFrames) {
      return false;
    }

    if (_lastTransitionMs != 0 &&
        now - _lastTransitionMs < _minimumTransitionGapMs) {
      return false;
    }

    _lastTransitionMs = now;
    _transitionCandidate = '';
    _transitionFrames = 0;
    return true;
  }

  int _movementScore(
    double value,
    double good,
    double maximum,
  ) {
    if (value <= good) return 95;

    final penalty =
        ((value - good) /
                math.max(maximum - good, 0.01)) *
            40;

    return (95 - penalty)
        .round()
        .clamp(50, 95);
  }

  double _distance(
    Offset a,
    Offset b,
  ) {
    final dx = a.dx - b.dx;
    final dy = a.dy - b.dy;

    return math.sqrt(
      dx * dx + dy * dy,
    );
  }

  double _angle(
    Offset a,
    Offset b,
    Offset c,
  ) {
    final ab = a - b;
    final cb = c - b;

    final denominator =
        ab.distance * cb.distance;

    if (denominator == 0) {
      return 0;
    }

    final cosValue =
        (ab.dx * cb.dx + ab.dy * cb.dy) /
            denominator;

    return math.acos(
          cosValue.clamp(-1.0, 1.0),
        ) *
        180 /
        math.pi;
  }
}