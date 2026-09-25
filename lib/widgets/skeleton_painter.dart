import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import '../services/rep_counter_service.dart';

class SkeletonPainter extends CustomPainter {
  final Pose? pose;
  final String exerciseName;
  final PostureFeedback? postureFeedback;
  final Size? imageSize;
  final InputImageRotation rotation;
  final bool isFrontCamera;

  SkeletonPainter({
    required this.pose,
    required this.exerciseName,
    this.postureFeedback,
    this.imageSize,
    this.rotation = InputImageRotation.rotation270deg,
    this.isFrontCamera = true,
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

  Offset _mapPoint(PoseLandmark lm, Size canvasSize) {
    double rawW = imageSize?.width ?? 480.0;
    double rawH = imageSize?.height ?? 640.0;

    // ML Kit processes the image after applying sensor rotation.
    // For 90deg / 270deg (typical portrait phone cameras), width and height are swapped in ML Kit's landmark space.
    bool isRotated = rotation == InputImageRotation.rotation90deg ||
        rotation == InputImageRotation.rotation270deg;
    double orientedW = isRotated ? rawH : rawW;
    double orientedH = isRotated ? rawW : rawH;

    // FittedBox(fit: BoxFit.cover) coordinate transform
    final double imgAspect = orientedW / orientedH;
    final double canvasAspect = canvasSize.width / canvasSize.height;

    double scale;
    double offsetX = 0.0;
    double offsetY = 0.0;

    if (canvasAspect > imgAspect) {
      scale = canvasSize.width / orientedW;
      offsetY = (canvasSize.height - (orientedH * scale)) / 2.0;
    } else {
      scale = canvasSize.height / orientedH;
      offsetX = (canvasSize.width - (orientedW * scale)) / 2.0;
    }

    double landmarkX = lm.x;
    if (isFrontCamera) {
      // Mirror horizontally for front-facing selfie camera
      landmarkX = orientedW - landmarkX;
    }

    double finalX = offsetX + (landmarkX * scale);
    double finalY = offsetY + (lm.y * scale);

    return Offset(finalX, finalY);
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (pose == null) {
      _drawGhostGuide(canvas, size);
      return;
    }

    final isGood = postureFeedback?.isGood ?? false;
    final primaryColor = isGood ? const Color(0xFF00E676) : const Color(0xFFFF5252);
    final accentColor = isGood ? const Color(0xFF00E5FF) : const Color(0xFFFF9100);

    // High contrast bone paint
    final bonePaint = Paint()
      ..color = primaryColor.withValues(alpha: 0.9)
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final armBonePaint = Paint()
      ..color = accentColor.withValues(alpha: 0.9)
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final lm = pose!.landmarks;

    // 1. Draw Skeleton Bones
    for (final (typeA, typeB) in _bones) {
      final a = lm[typeA];
      final b = lm[typeB];
      if (a != null && b != null && a.likelihood > 0.15 && b.likelihood > 0.15) {
        final ptA = _mapPoint(a, size);
        final ptB = _mapPoint(b, size);
        final isArm = typeA == PoseLandmarkType.leftShoulder && typeB == PoseLandmarkType.leftElbow ||
            typeA == PoseLandmarkType.leftElbow && typeB == PoseLandmarkType.leftWrist ||
            typeA == PoseLandmarkType.rightShoulder && typeB == PoseLandmarkType.rightElbow ||
            typeA == PoseLandmarkType.rightElbow && typeB == PoseLandmarkType.rightWrist;

        canvas.drawLine(ptA, ptB, isArm ? armBonePaint : bonePaint);
      }
    }

    // 2. Draw Key Joint Circles (Shoulders, Elbows, Wrists, Nose)
    for (final entry in lm.entries) {
      final landmark = entry.value;
      if (landmark.likelihood > 0.15) {
        final pos = _mapPoint(landmark, size);

        // Glow ring
        canvas.drawCircle(pos, 8, Paint()..color = primaryColor.withValues(alpha: 0.35));
        // Outer dot
        canvas.drawCircle(pos, 5, Paint()..color = Colors.white);
        // Joint core
        canvas.drawCircle(pos, 3, Paint()..color = accentColor);
      }
    }

    // 3. Prominently Highlight Tracked Shoulders
    final lShoulder = lm[PoseLandmarkType.leftShoulder];
    final rShoulder = lm[PoseLandmarkType.rightShoulder];
    if (lShoulder != null && rShoulder != null && lShoulder.likelihood > 0.15 && rShoulder.likelihood > 0.15) {
      final pL = _mapPoint(lShoulder, size);
      final pR = _mapPoint(rShoulder, size);

      // Shoulder alignment line
      final linePaint = Paint()
        ..color = isGood ? Colors.tealAccent.withValues(alpha: 0.9) : Colors.redAccent.withValues(alpha: 0.9)
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke;
      canvas.drawLine(pL, pR, linePaint);

      // Large Target Rings on Tracked Shoulders
      final targetRing = Paint()
        ..color = isGood ? const Color(0xFF00E676) : const Color(0xFFFF5252)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5;

      canvas.drawCircle(pL, 14, targetRing);
      canvas.drawCircle(pR, 14, targetRing);
      canvas.drawCircle(pL, 6, Paint()..color = Colors.white);
      canvas.drawCircle(pR, 6, Paint()..color = Colors.white);

      // Spine / Neck reference line
      final nose = lm[PoseLandmarkType.nose];
      if (nose != null && nose.likelihood > 0.15) {
        final pNose = _mapPoint(nose, size);
        final pMid = Offset((pL.dx + pR.dx) / 2, (pL.dy + pR.dy) / 2);
        final spinePaint = Paint()
          ..color = Colors.cyanAccent.withValues(alpha: 0.65)
          ..strokeWidth = 2.0
          ..style = PaintingStyle.stroke;
        canvas.drawLine(pNose, pMid, spinePaint);
      }
    }

    // 4. Live Telemetry Badge over Active Joint
    final activeJoint = lShoulder ?? rShoulder;
    if (activeJoint != null && activeJoint.likelihood > 0.15) {
      final pos = _mapPoint(activeJoint, size) + const Offset(16, -14);
      final phase = postureFeedback?.phaseName ?? 'READY';
      _drawTelemetryBadge(canvas, phase, pos, primaryColor);
    }
  }

  void _drawTelemetryBadge(Canvas canvas, String text, Offset pos, Color color) {
    final textSpan = TextSpan(
      text: text,
      style: TextStyle(
        color: Colors.white,
        fontSize: 11,
        fontWeight: FontWeight.bold,
        shadows: [
          Shadow(color: Colors.black.withValues(alpha: 0.9), blurRadius: 4),
        ],
      ),
    );
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    )..layout();

    final bgRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(pos.dx - 4, pos.dy - 2, textPainter.width + 8, textPainter.height + 4),
      const Radius.circular(6),
    );

    canvas.drawRRect(bgRect, Paint()..color = color.withValues(alpha: 0.85));
    textPainter.paint(canvas, pos);
  }

  /// Subtle guide overlay shown when waiting for camera user alignment
  void _drawGhostGuide(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.18)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final head = Offset(cx, cy - 60);
    final neck = Offset(cx, cy - 35);
    final lshoulder = Offset(cx - 40, cy - 25);
    final rshoulder = Offset(cx + 40, cy - 25);
    final lElbow = Offset(cx - 55, cy + 15);
    final rElbow = Offset(cx + 55, cy + 15);

    canvas
      ..drawCircle(head, 18, paint)
      ..drawLine(neck, Offset(cx, cy + 30), paint)
      ..drawLine(neck, lshoulder, paint)
      ..drawLine(neck, rshoulder, paint)
      ..drawLine(lshoulder, lElbow, paint)
      ..drawLine(rshoulder, rElbow, paint);

    final textSpan = TextSpan(
      text: 'Stand or sit in camera view',
      style: TextStyle(
        color: Colors.white.withValues(alpha: 0.5),
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
    );
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(canvas, Offset(cx - (textPainter.width / 2), cy + 50));
  }

  @override
  bool shouldRepaint(covariant SkeletonPainter oldDelegate) => true;
}
