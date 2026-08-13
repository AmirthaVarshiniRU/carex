import 'dart:io';
import 'dart:ui';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

class PoseDetectorService {
  PoseDetector? _poseDetector;
  bool _isBusy = false;
  int _frameCount = 0;
  static const int _frameSkip = 3;

  PoseDetectorService() {
    if (!kIsWeb) {
      _poseDetector = PoseDetector(
        options: PoseDetectorOptions(mode: PoseDetectionMode.stream),
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
      final inputImage = _toInputImage(cameraImage, camera);
      if (inputImage == null) {
        _isBusy = false;
        return null;
      }
      final poses = await _poseDetector!.processImage(inputImage);
      _isBusy = false;
      return poses.isNotEmpty ? poses.first : null;
    } catch (e) {
      debugPrint('PoseDetectorService error: $e');
      _isBusy = false;
      return null;
    }
  }

  InputImage? _toInputImage(CameraImage image, CameraDescription camera) {
    if (kIsWeb) return null;
    final rotation = _rotationFromSensor(camera.sensorOrientation);
    final format = _imageFormat();
    if (format == null) return null;

    final bytes = _concatenatePlanes(image.planes);

    final metadata = InputImageMetadata(
      size: Size(image.width.toDouble(), image.height.toDouble()),
      rotation: rotation,
      format: format,
      bytesPerRow: image.planes.first.bytesPerRow,
    );

    return InputImage.fromBytes(bytes: Uint8List.fromList(bytes), metadata: metadata);
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

  InputImageFormat? _imageFormat() {
    if (kIsWeb) return null;
    if (Platform.isAndroid) return InputImageFormat.yuv_420_888;
    if (Platform.isIOS) return InputImageFormat.bgra8888;
    return null;
  }

  List<int> _concatenatePlanes(List<Plane> planes) {
    final allBytes = <int>[];
    for (final plane in planes) {
      allBytes.addAll(plane.bytes);
    }
    return allBytes;
  }

  Future<void> dispose() async {
    if (!kIsWeb && _poseDetector != null) {
      await _poseDetector!.close();
    }
  }
}
