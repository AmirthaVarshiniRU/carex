import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Angle helper
// ─────────────────────────────────────────────────────────────────────────────

/// Returns the angle (0–180°) at joint [b], formed by rays a→b and c→b.
double _angleBetween(Offset a, Offset b, Offset c) {
  final ab = a - b;
  final cb = c - b;
  final dot = ab.dx * cb.dx + ab.dy * cb.dy;
  final mag = ab.distance * cb.distance;
  if (mag == 0) return 0;
  return math.acos((dot / mag).clamp(-1.0, 1.0)) * 180 / math.pi;
}

/// Maps a normalised ML Kit landmark to canvas pixel coordinates.
Offset _toOffset(PoseLandmark lm, Size size) =>
    Offset(lm.x * size.width, lm.y * size.height);

// ─────────────────────────────────────────────────────────────────────────────
// PostureResult
// ─────────────────────────────────────────────────────────────────────────────

class PostureResult {
  final bool isGood;
  final double spineAngle;
  final double shoulderDiff;
  final String feedback;

  const PostureResult({
    required this.isGood,
    required this.spineAngle,
    required this.shoulderDiff,
    required this.feedback,
  });
}

PostureResult evaluatePosture(Pose pose, Size size, String exerciseName) {
  final lm = pose.landmarks;

  final leftShoulder = lm[PoseLandmarkType.leftShoulder];
  final rightShoulder = lm[PoseLandmarkType.rightShoulder];
  final leftHip = lm[PoseLandmarkType.leftHip];
  final leftKnee = lm[PoseLandmarkType.leftKnee];

  double spineAngle = 180.0;
  double shoulderDiff = 0.0;

  if (leftShoulder != null && leftHip != null && leftKnee != null) {
    spineAngle = _angleBetween(
      _toOffset(leftShoulder, size),
      _toOffset(leftHip, size),
      _toOffset(leftKnee, size),
    );
  }

  if (leftShoulder != null && rightShoulder != null) {
    shoulderDiff =
        (leftShoulder.y * size.height - rightShoulder.y * size.height).abs();
  }

  final name = exerciseName.toLowerCase();
  double minSpine = 155.0;
  if (name.contains('knee') || name.contains('leg')) minSpine = 140.0;
  if (name.contains('spinal') || name.contains('twist')) minSpine = 120.0;

  final spineOk = spineAngle >= minSpine;
  final shoulderOk = shoulderDiff < 30.0;
  final isGood = spineOk && shoulderOk;

  final feedback = !spineOk
      ? 'Straighten your back!'
      : !shoulderOk
          ? 'Level your shoulders!'
          : 'Great posture!';

  return PostureResult(
    isGood: isGood,
    spineAngle: spineAngle,
    shoulderDiff: shoulderDiff,
    feedback: feedback,
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// SkeletonPainter
// ─────────────────────────────────────────────────────────────────────────────

class SkeletonPainter extends CustomPainter {
  final Pose? pose;
  final String exerciseName;
  final PostureResult? postureResult;

  SkeletonPainter({
    required this.pose,
    required this.exerciseName,
    this.postureResult,
  });

  static const List<(PoseLandmarkType, PoseLandmarkType)> _bones = [
    (PoseLandmarkType.nose, PoseLandmarkType.leftEye),
    (PoseLandmarkType.nose, PoseLandmarkType.rightEye),
    (PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder),
    (PoseLandmarkType.leftShoulder, PoseLandmarkType.leftHip),
    (PoseLandmarkType.rightShoulder, PoseLandmarkType.rightHip),
    (PoseLandmarkType.leftHip, PoseLandmarkType.rightHip),
    (PoseLandmarkType.leftShoulder, PoseLandmarkType.leftElbow),
    (PoseLandmarkType.leftElbow, PoseLandmarkType.leftWrist),
    (PoseLandmarkType.rightShoulder, PoseLandmarkType.rightElbow),
    (PoseLandmarkType.rightElbow, PoseLandmarkType.rightWrist),
    (PoseLandmarkType.leftHip, PoseLandmarkType.leftKnee),
    (PoseLandmarkType.leftKnee, PoseLandmarkType.leftAnkle),
    (PoseLandmarkType.rightHip, PoseLandmarkType.rightKnee),
    (PoseLandmarkType.rightKnee, PoseLandmarkType.rightAnkle),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    if (pose == null) {
      _drawGhostSkeleton(canvas, size);
      return;
    }

    final isGood = postureResult?.isGood ?? true;
    final boneColor = isGood ? Colors.greenAccent : Colors.redAccent;
    final jointColor = isGood ? Colors.green : Colors.red;

    final bonePaint = Paint()
      ..color = boneColor.withOpacity(0.85)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final jointPaint = Paint()
      ..color = jointColor
      ..style = PaintingStyle.fill;

    final lm = pose!.landmarks;

    // Bones
    for (final (typeA, typeB) in _bones) {
      final a = lm[typeA];
      final b = lm[typeB];
      if (a != null && b != null && a.likelihood > 0.5 && b.likelihood > 0.5) {
        canvas.drawLine(_toOffset(a, size), _toOffset(b, size), bonePaint);
      }
    }

    // Joints
    for (final landmark in lm.values) {
      if (landmark.likelihood > 0.5) {
        final pos = _toOffset(landmark, size);
        canvas.drawCircle(pos, 6, jointPaint);
        canvas.drawCircle(pos, 3, Paint()..color = Colors.white);
      }
    }

    // Warning glow on bad-posture joints
    if (!isGood) {
      final warnPaint = Paint()
        ..color = Colors.redAccent.withOpacity(0.25)
        ..style = PaintingStyle.fill;
      final lhip = lm[PoseLandmarkType.leftHip];
      final lshoulder = lm[PoseLandmarkType.leftShoulder];
      if (lhip != null) canvas.drawCircle(_toOffset(lhip, size), 22, warnPaint);
      if (lshoulder != null) {
        canvas.drawCircle(_toOffset(lshoulder, size), 22, warnPaint);
      }
    }

    // Spine angle label
    if (postureResult != null) {
      final lhip = lm[PoseLandmarkType.leftHip];
      if (lhip != null) {
        _drawLabel(
          canvas,
          '${postureResult!.spineAngle.toStringAsFixed(0)}°',
          _toOffset(lhip, size) + const Offset(10, -10),
          isGood ? Colors.greenAccent : Colors.redAccent,
        );
      }
    }
  }

  void _drawLabel(Canvas canvas, String text, Offset pos, Color color) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: 14,
          fontWeight: FontWeight.bold,
          shadows: const [Shadow(blurRadius: 4, color: Colors.black)],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, pos);
  }

  /// Ghost skeleton shown when no person is detected.
  void _drawGhostSkeleton(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    final paint = Paint()
      ..color = Colors.white.withOpacity(0.15)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final head = Offset(cx, cy - 90);
    final neck = Offset(cx, cy - 60);
    final lshoulder = Offset(cx - 45, cy - 45);
    final rshoulder = Offset(cx + 45, cy - 45);
    final lhip = Offset(cx - 25, cy + 20);
    final rhip = Offset(cx + 25, cy + 20);
    final lknee = Offset(cx - 25, cy + 70);
    final rknee = Offset(cx + 25, cy + 70);
    final lankle = Offset(cx - 25, cy + 110);
    final rankle = Offset(cx + 25, cy + 110);

    canvas
      ..drawCircle(head, 18, paint)
      ..drawLine(neck, Offset(cx, cy + 20), paint)
      ..drawLine(lshoulder, rshoulder, paint)
      ..drawLine(lshoulder, Offset(cx - 65, cy), paint)
      ..drawLine(rshoulder, Offset(cx + 65, cy), paint)
      ..drawLine(lhip, rhip, paint)
      ..drawLine(lhip, lknee, paint)
      ..drawLine(lknee, lankle, paint)
      ..drawLine(rhip, rknee, paint)
      ..drawLine(rknee, rankle, paint);

    _drawLabel(canvas, 'Stand in frame', Offset(cx - 55, cy - 130), Colors.white54);
  }

  @override
  bool shouldRepaint(covariant SkeletonPainter old) =>
      old.pose != pose || old.postureResult != postureResult;
}

