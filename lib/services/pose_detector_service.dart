import 'dart:ui';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

class PoseDetectorService {
  PoseDetector? _poseDetector;
  bool _isBusy = false;
  int _frameCount = 0;
  static const int _frameSkip = 2; // Process every 2nd frame for smooth 15-20 FPS inference

  Size _lastImageSize = Size.zero;
  InputImageRotation _lastRotation = InputImageRotation.rotation0deg;

  Size get lastImageSize => _lastImageSize;
  InputImageRotation get lastRotation => _lastRotation;
  bool get isBusy => _isBusy;

  PoseDetectorService() {
    if (!kIsWeb) {
      _poseDetector = PoseDetector(
        options: PoseDetectorOptions(
          mode: PoseDetectionMode.stream,
        ),
      );
    }
  }

  /// Processes a [CameraImage] and returns a [Pose] if one is detected.
  Future<Pose?> detect({
    required CameraImage cameraImage,
    required CameraDescription camera,
  }) async {
    if (kIsWeb || _poseDetector == null) return null;

    _frameCount++;
    if (_frameCount % _frameSkip != 0) return null;
    if (_isBusy) return null;
    _isBusy = true;

    try {
      debugPrint('CONVERTING INPUT IMAGE: ${cameraImage.width}x${cameraImage.height}, planes=${cameraImage.planes.length}, rawFmt=${cameraImage.format.raw}');
      final inputImage = _toInputImage(cameraImage, camera);
      if (inputImage == null) {
        debugPrint('PoseDetectorService: inputImage conversion failed. rawFmt=${cameraImage.format.raw}, sensorOrientation=${camera.sensorOrientation}');
        return null;
      }
      debugPrint('INPUT IMAGE CREATED: size=${inputImage.metadata?.size}, rot=${inputImage.metadata?.rotation.rawValue}, fmt=${inputImage.metadata?.format.rawValue}, bytesLen=${inputImage.bytes?.length}');

      debugPrint('SENDING TO ML KIT');
      final poses = await _poseDetector!.processImage(inputImage);
      debugPrint('POSE COUNT: ${poses.length}');

      if (poses.isNotEmpty) {
        final pose = poses.first;
        final lm = pose.landmarks;
        final lShoulder = lm[PoseLandmarkType.leftShoulder];
        final rShoulder = lm[PoseLandmarkType.rightShoulder];
        final lElbow = lm[PoseLandmarkType.leftElbow];
        final rElbow = lm[PoseLandmarkType.rightElbow];
        final nose = lm[PoseLandmarkType.nose];

        final shouldersValid = (lShoulder != null && rShoulder != null);
        if (shouldersValid) {
          debugPrint('SHOULDERS: VALID');
        } else {
          debugPrint('SHOULDERS: MISSING');
        }

        debugPrint(
          'LANDMARKS: nose=(${nose?.x.toStringAsFixed(1)}, ${nose?.y.toStringAsFixed(1)}, c=${nose?.likelihood.toStringAsFixed(2)}) '
          'L_sh=(${lShoulder?.x.toStringAsFixed(1)}, ${lShoulder?.y.toStringAsFixed(1)}, c=${lShoulder?.likelihood.toStringAsFixed(2)}) '
          'R_sh=(${rShoulder?.x.toStringAsFixed(1)}, ${rShoulder?.y.toStringAsFixed(1)}, c=${rShoulder?.likelihood.toStringAsFixed(2)}) '
          'L_el=(${lElbow?.x.toStringAsFixed(1)}, ${lElbow?.y.toStringAsFixed(1)}, c=${lElbow?.likelihood.toStringAsFixed(2)}) '
          'R_el=(${rElbow?.x.toStringAsFixed(1)}, ${rElbow?.y.toStringAsFixed(1)}, c=${rElbow?.likelihood.toStringAsFixed(2)})',
        );

        return pose;
      }
      return null;
    } catch (e, stack) {
      debugPrint('PoseDetectorService error during detection: $e\n$stack');
      return null;
    } finally {
      _isBusy = false;
    }
  }

  InputImage? _toInputImage(
  CameraImage image,
  CameraDescription camera,
) {
  if (kIsWeb) return null;

  try {
    final rotation =
        InputImageRotationValue.fromRawValue(camera.sensorOrientation) ??
        _rotationFromSensor(camera.sensorOrientation);

    final format =
        InputImageFormatValue.fromRawValue(image.format.raw);

    if (format == null) {
      debugPrint(
        'UNSUPPORTED IMAGE FORMAT: ${image.format.raw}',
      );
      return null;
    }

    if (image.planes.length != 1) {
      debugPrint(
        'UNEXPECTED PLANE COUNT: ${image.planes.length}',
      );
      return null;
    }

    final plane = image.planes.first;

    _lastImageSize = Size(
      image.width.toDouble(),
      image.height.toDouble(),
    );

    _lastRotation = rotation;

    final metadata = InputImageMetadata(
      size: _lastImageSize,
      rotation: rotation,
      format: format,
      bytesPerRow: plane.bytesPerRow,
    );

    return InputImage.fromBytes(
      bytes: plane.bytes,
      metadata: metadata,
    );
  } catch (e) {
    debugPrint(
      'INPUT IMAGE CONVERSION ERROR: $e',
    );
    return null;
  }
}

  InputImageRotation _rotationFromSensor(int sensorOrientation) {
    switch (sensorOrientation) {
      case 90:
        return InputImageRotation.rotation90deg;
      case 180:
        return InputImageRotation.rotation180deg;
      case 270:
        return InputImageRotation.rotation270deg;
      default:
        return InputImageRotation.rotation0deg;
    }
  }

  Future<void> dispose() async {
    if (!kIsWeb && _poseDetector != null) {
      try {
        await _poseDetector!.close();
      } catch (e) {
        debugPrint('Error closing PoseDetector: $e');
      }
      _poseDetector = null;
    }
  }
}
