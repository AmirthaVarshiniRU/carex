import 'dart:math' as math;
import 'dart:ui';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

enum ShoulderRollPhase {
  ready,
  rolling,
  peak,
  returning,
  completed,
}

class FrameMeasurement {
  final DateTime timestamp;
  final double normDisplacement; // Shoulder elevation normalized by shoulder width
  final double shoulderTilt;     // |leftY - rightY| / shoulderWidth
  final double spineOffset;      // |noseX - midShoulderX| / shoulderWidth
  final double confidence;       // Average landmark confidence
  final double midY;
  final double midX;

  FrameMeasurement({
    required this.timestamp,
    required this.normDisplacement,
    required this.shoulderTilt,
    required this.spineOffset,
    required this.confidence,
    required this.midY,
    required this.midX,
  });
}

class ShoulderRollResult {
  final bool repCompleted;
  final int repCount;
  final ShoulderRollPhase phase;
  final String phaseName;
  final int formScore;           // 0 to 100
  final bool isGoodPosture;
  final String statusText;       // OPTIMAL ALIGNMENT / ADJUST POSTURE
  final String guidanceText;
  final double currentElevation; // Normalized elevation percentage (-50% to +100%)
  final double symmetryScore;    // 0 to 100%
  final String diagnosticText;   // Diagnostic telemetry for HUD
  final bool isPoseDetected;
  final bool areShouldersDetected;
  final Offset? leftShoulderPos;
  final Offset? rightShoulderPos;

  const ShoulderRollResult({
    required this.repCompleted,
    required this.repCount,
    required this.phase,
    required this.phaseName,
    required this.formScore,
    required this.isGoodPosture,
    required this.statusText,
    required this.guidanceText,
    required this.currentElevation,
    required this.symmetryScore,
    required this.diagnosticText,
    this.isPoseDetected = false,
    this.areShouldersDetected = false,
    this.leftShoulderPos,
    this.rightShoulderPos,
  });
}

class ShoulderRollAnalyzer {
  int _repCount = 0;
  ShoulderRollPhase _phase = ShoulderRollPhase.ready;
  
  // Rolling temporal history of recent frames (up to 30 frames ~ 1 sec)
  final List<FrameMeasurement> _history = [];
  static const int _maxHistoryLength = 30;

  // Running adaptive baseline (rest position of shoulder relative to nose)
  double _baselineDeltaY = 0.0;
  bool _isBaselineInitialized = false;

  // Repetition phase tracking & validation
  DateTime? _repStartTime;
  double _peakDisplacementInRep = 0.0;
  double _maxTiltInRep = 0.0;

  // Smoothed metrics
  double _smoothedScore = 0.0;
  double _smoothedElevation = 0.0;

  // Guidance debouncing (prevents UI flicker)
  String _activeGuidance = 'Roll shoulders up & back';
  DateTime _lastGuidanceChange = DateTime.now();
  static const Duration _guidanceDebounce = Duration(milliseconds: 1400);

  // Thresholds normalized against body scale (shoulder width)
  static const double _minRepElevationThreshold = 0.08;  // Minimum elevation to reach PEAK
  static const double _rollingStartThreshold = 0.035;    // Threshold to enter ROLLING
  static const double _returnThreshold = 0.06;           // Threshold to return to READY
  static const double _maxTiltAllowed = 0.24;            // Symmetry check
  static const double _maxSpineOffsetAllowed = 0.30;     // Spine alignment check

  int get repCount => _repCount;
  ShoulderRollPhase get phase => _phase;

  void reset() {
    _repCount = 0;
    _phase = ShoulderRollPhase.ready;
    _history.clear();
    _isBaselineInitialized = false;
    _baselineDeltaY = 0.0;
    _repStartTime = null;
    _peakDisplacementInRep = 0.0;
    _maxTiltInRep = 0.0;
    _smoothedScore = 0.0;
    _smoothedElevation = 0.0;
    _activeGuidance = 'Roll shoulders up & back';
    _lastGuidanceChange = DateTime.now();
  }

  ShoulderRollResult processPose(Pose? pose) {
    if (pose == null) {
      return _buildFallbackResult('Position upper body in camera view', isPose: false);
    }

    final now = DateTime.now();
    final lm = pose.landmarks;

    final lShoulder = lm[PoseLandmarkType.leftShoulder];
    final rShoulder = lm[PoseLandmarkType.rightShoulder];
    final nose = lm[PoseLandmarkType.nose];
    final lEar = lm[PoseLandmarkType.leftEar];
    final rEar = lm[PoseLandmarkType.rightEar];

    // Must have shoulders to analyze
    if (lShoulder == null || rShoulder == null) {
      return _buildFallbackResult('Position shoulders inside camera frame', isPose: true);
    }

    final double conf = (lShoulder.likelihood + rShoulder.likelihood) / 2.0;

    // Body Scale Normalization: Shoulder Width
    final double dx = (lShoulder.x - rShoulder.x).abs();
    final double dy = (lShoulder.y - rShoulder.y).abs();
    final double shoulderWidth = math.sqrt(dx * dx + dy * dy);
    if (shoulderWidth < 15.0) {
      return _buildFallbackResult('Step closer to camera', isPose: true);
    }

    // Midpoints
    final double midShoulderX = (lShoulder.x + rShoulder.x) / 2.0;
    final double midShoulderY = (lShoulder.y + rShoulder.y) / 2.0;

    // Head reference point (prefer nose, fallback to ear midpoint)
    double headY = midShoulderY - (shoulderWidth * 0.7);
    double headX = midShoulderX;
    if (nose != null && nose.likelihood > 0.1) {
      headY = nose.y;
      headX = nose.x;
    } else if (lEar != null && rEar != null) {
      headY = (lEar.y + rEar.y) / 2.0;
      headX = (lEar.x + rEar.x) / 2.0;
    }

    // Vertical distance from head down to shoulders (in camera space, Y points downwards)
    final double currentDeltaY = midShoulderY - headY;

    // Adaptive Baseline: initialize or slowly drift when in neutral ready state
    if (!_isBaselineInitialized) {
      _baselineDeltaY = currentDeltaY;
      _isBaselineInitialized = true;
      _smoothedScore = 85.0;
    } else if (_phase == ShoulderRollPhase.ready) {
      // Very slow EMA drift (0.5%) to adapt to minor camera/patient position shifts
      _baselineDeltaY = (_baselineDeltaY * 0.995) + (currentDeltaY * 0.005);
    }

    // Normalized elevation (positive when shoulders shrug up closer to head)
    final double rawElevation = (_baselineDeltaY - currentDeltaY) / shoulderWidth;
    final double shoulderTilt = dy / shoulderWidth;
    final double spineOffset = (headX - midShoulderX).abs() / shoulderWidth;

    // Add to temporal history buffer
    _history.add(FrameMeasurement(
      timestamp: now,
      normDisplacement: rawElevation,
      shoulderTilt: shoulderTilt,
      spineOffset: spineOffset,
      confidence: conf,
      midY: midShoulderY,
      midX: midShoulderX,
    ));
    if (_history.length > _maxHistoryLength) {
      _history.removeAt(0);
    }

    // Calculate temporal smoothed elevation & velocity
    final double smoothedNormElev = _calculateMovingAverageElevation();
    _smoothedElevation = (_smoothedElevation * 0.75) + (smoothedNormElev * 0.25);

    // Posture evaluation
    final bool isLevel = shoulderTilt <= _maxTiltAllowed;
    final bool isSpineAligned = spineOffset <= _maxSpineOffsetAllowed;
    final bool isGoodPosture = isLevel && isSpineAligned;

    // State Machine & Repetition Validation
    bool repCompleted = false;
    String candidateGuidance = _activeGuidance;

    switch (_phase) {
      case ShoulderRollPhase.ready:
        if (_smoothedElevation > _rollingStartThreshold) {
          _phase = ShoulderRollPhase.rolling;
          _repStartTime = now;
          _peakDisplacementInRep = _smoothedElevation;
          _maxTiltInRep = shoulderTilt;
          candidateGuidance = 'Rolling up... reach peak';
        } else {
          candidateGuidance = isGoodPosture
              ? 'Roll shoulders up & back'
              : (isLevel ? 'Align head & spine straight' : 'Level shoulders evenly');
        }
        break;

      case ShoulderRollPhase.rolling:
        if (_smoothedElevation > _peakDisplacementInRep) {
          _peakDisplacementInRep = _smoothedElevation;
        }
        if (shoulderTilt > _maxTiltInRep) {
          _maxTiltInRep = shoulderTilt;
        }

        if (_smoothedElevation >= _minRepElevationThreshold) {
          _phase = ShoulderRollPhase.peak;
          candidateGuidance = 'Hold top of roll, now lower';
        } else if (_smoothedElevation < (_rollingStartThreshold - 0.015)) {
          // Reverted back without reaching peak (Jitter / incomplete motion)
          _phase = ShoulderRollPhase.ready;
          candidateGuidance = 'Move shoulders through a larger range';
        }
        break;

      case ShoulderRollPhase.peak:
        if (_smoothedElevation > _peakDisplacementInRep) {
          _peakDisplacementInRep = _smoothedElevation;
        }
        if (shoulderTilt > _maxTiltInRep) {
          _maxTiltInRep = shoulderTilt;
        }

        // Descending from peak
        if (_smoothedElevation < (_peakDisplacementInRep - 0.025)) {
          _phase = ShoulderRollPhase.returning;
          candidateGuidance = 'Smoothly lower shoulders down';
        }
        break;

      case ShoulderRollPhase.returning:
        if (_smoothedElevation <= _returnThreshold) {
          // Rep completed! Validate full movement quality
          final repDurationMs =
              _repStartTime != null ? now.difference(_repStartTime!).inMilliseconds : 1000;
          final bool validAmplitude = _peakDisplacementInRep >= _minRepElevationThreshold;
          final bool validPacing = repDurationMs >= 350 && repDurationMs <= 6000;
          final bool validSymmetry = _maxTiltInRep <= (_maxTiltAllowed * 1.4);

          if (validAmplitude && validPacing && validSymmetry) {
            _repCount++;
            repCompleted = true;
            _phase = ShoulderRollPhase.completed;
            candidateGuidance = 'Great repetition! +1';
          } else if (!validAmplitude) {
            _phase = ShoulderRollPhase.ready;
            candidateGuidance = 'Move shoulders through a larger range';
          } else if (!validPacing) {
            _phase = ShoulderRollPhase.ready;
            candidateGuidance = 'Control movement pacing';
          } else {
            _phase = ShoulderRollPhase.ready;
            candidateGuidance = 'Keep both shoulders level';
          }
        }
        break;

      case ShoulderRollPhase.completed:
        _phase = ShoulderRollPhase.ready;
        candidateGuidance = 'Roll shoulders up & back';
        break;
    }

    // Debounce guidance updates
    if (candidateGuidance != _activeGuidance &&
        now.difference(_lastGuidanceChange) > _guidanceDebounce) {
      _activeGuidance = candidateGuidance;
      _lastGuidanceChange = now;
    } else if (repCompleted) {
      _activeGuidance = candidateGuidance;
      _lastGuidanceChange = now;
    }

    // Deterministic Real-time Quality Score (0–100)
    final double ampRatio =
        (_smoothedElevation / _minRepElevationThreshold).clamp(0.0, 1.3) / 1.3;
    final double ampScore =
        (_phase == ShoulderRollPhase.ready ? 38.0 : ampRatio * 40.0);
    final double symScore = (1.0 - (shoulderTilt * 3.0).clamp(0.0, 1.0)) * 30.0;
    final double stabScore = (1.0 - (spineOffset * 2.5).clamp(0.0, 1.0)) * 20.0;
    final double confScore = conf.clamp(0.0, 1.0) * 10.0;

    final double instantScore =
        (ampScore + symScore + stabScore + confScore).clamp(30.0, 99.0);
    if (_smoothedScore == 0.0) {
      _smoothedScore = instantScore;
    } else {
      _smoothedScore = (_smoothedScore * 0.82) + (instantScore * 0.18);
    }

    final symmetryPct =
        ((1.0 - (shoulderTilt * 2.5).clamp(0.0, 1.0)) * 100.0).clamp(10.0, 100.0);
    final elevDisplay = (_smoothedElevation * 100).clamp(-20.0, 99.0);

    // Live Diagnostic Telemetry String
    final diag =
        'L: ${lShoulder.x.toInt()},${lShoulder.y.toInt()} | R: ${rShoulder.x.toInt()},${rShoulder.y.toInt()} | DELTA: ${elevDisplay >= 0 ? '+' : ''}${elevDisplay.toStringAsFixed(0)}%';

    return ShoulderRollResult(
      repCompleted: repCompleted,
      repCount: _repCount,
      phase: _phase,
      phaseName: _getPhaseDisplayString(_phase),
      formScore: _smoothedScore.round(),
      isGoodPosture: isGoodPosture,
      statusText: isGoodPosture ? 'OPTIMAL ALIGNMENT' : 'ADJUST POSTURE',
      guidanceText: _activeGuidance,
      currentElevation: elevDisplay,
      symmetryScore: symmetryPct,
      diagnosticText: diag,
      isPoseDetected: true,
      areShouldersDetected: true,
      leftShoulderPos: Offset(lShoulder.x, lShoulder.y),
      rightShoulderPos: Offset(rShoulder.x, rShoulder.y),
    );
  }

  double _calculateMovingAverageElevation() {
    if (_history.isEmpty) return 0.0;
    final count = math.min(5, _history.length);
    double sum = 0.0;
    for (int i = _history.length - count; i < _history.length; i++) {
      sum += _history[i].normDisplacement;
    }
    return sum / count;
  }

  String _getPhaseDisplayString(ShoulderRollPhase phase) {
    switch (phase) {
      case ShoulderRollPhase.ready:
        return 'READY';
      case ShoulderRollPhase.rolling:
        return 'ROLLING UP';
      case ShoulderRollPhase.peak:
        return 'PEAK ROLL';
      case ShoulderRollPhase.returning:
        return 'RETURNING';
      case ShoulderRollPhase.completed:
        return 'REP COMPLETE';
    }
  }

  ShoulderRollResult _buildFallbackResult(String guidance, {required bool isPose}) {
    return ShoulderRollResult(
      repCompleted: false,
      repCount: _repCount,
      phase: _phase,
      phaseName: _getPhaseDisplayString(_phase),
      formScore: isPose ? 50 : 0,
      isGoodPosture: false,
      statusText: isPose ? 'ADJUST POSITION' : 'SCANNING POSE',
      guidanceText: guidance,
      currentElevation: 0.0,
      symmetryScore: 0.0,
      diagnosticText: isPose ? 'Pose found • Aligning shoulders...' : 'Scanning for body landmarks...',
      isPoseDetected: isPose,
      areShouldersDetected: false,
    );
  }
}
