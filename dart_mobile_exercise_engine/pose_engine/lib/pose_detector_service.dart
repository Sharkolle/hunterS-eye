import 'dart:async';
import 'dart:ui';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'exercise_database.dart';
import 'models/calibration_baseline.dart';
import 'utils/landmark_smoother.dart';
import 'calibration_detector.dart';
import 'exercise_detector.dart';
import 'detectors/pushup_detector.dart';
import 'detectors/squat_detector.dart';
import 'detectors/jumping_jack_detector.dart';
import 'detectors/situp_detector.dart';
import 'detectors/lunge_detector.dart';
import 'detectors/plank_detector.dart';
import 'detectors/high_knees_detector.dart';
import 'detectors/burpee_detector.dart';
import 'detectors/wall_sit_detector.dart';
import 'detectors/leg_raise_detector.dart';
import 'detectors/tricep_dip_detector.dart';
import 'detectors/arm_circle_detector.dart';

/// Service that manages the camera and ML Kit pose detection pipeline.
/// Converts live camera frames into exercise detection results.
///
/// Optimizations applied:
///  1. Likelihood filtering (via LandmarkSmoother — drops landmarks < 0.65)
///  2. One Euro Filter temporal smoothing (sticky skeleton)
///  3. try-finally pipeline safety (no stream lock-ups)
///  4. Low resolution camera + minimized allocations
class PoseDetectorService {
  CameraController? _cameraController;
  PoseDetector? _poseDetector;
  ExerciseDetector? _exerciseDetector;
  bool _isProcessing = false;
  bool _isInitialized = false;

  // ─── Calibration state ───
  final CalibrationDetector _calibrationDetector = CalibrationDetector();
  bool _isCalibrating = true; // Starts in calibration mode

  // ─── Optimization #2: Temporal smoother ───
  final LandmarkSmoother _smoother = LandmarkSmoother();

  // ─── Streams ───
  final _poseStreamController = StreamController<PoseDetectionFrame>.broadcast();
  // These streams are currently unused by the reference UI (the example app
  // uses poseStream). Kept for potential future use (e.g. external plugins,
  // analytics) by consumers of this package.
  final _feedbackStreamController = StreamController<String>.broadcast();
  final _repCountStreamController = StreamController<int>.broadcast();
  final _calibrationStreamController = StreamController<CalibrationResult>.broadcast();

  /// Stream of live pose frames (landmarks + rep feedback) — active after calibration.
  Stream<PoseDetectionFrame> get poseStream => _poseStreamController.stream;
  Stream<String> get feedbackStream => _feedbackStreamController.stream;
  Stream<int> get repCountStream => _repCountStreamController.stream;

  /// Stream of calibration frames — active until [lockCalibration] is called.
  Stream<CalibrationResult> get calibrationStream => _calibrationStreamController.stream;

  bool get isInitialized => _isInitialized;
  bool get isCalibrating => _isCalibrating;
  CameraController? get cameraController => _cameraController;
  ExerciseDetector? get exerciseDetector => _exerciseDetector;

  int _frameCount = 0;
  static const int _processEveryNFrames = 3;

  // ─── Optimization #4: Dynamic rotation tracking ───
  int _sensorOrientation = 0;
  bool _isLandscapeMode = false; // Set during initialize(), used for calibration axis

  /// Initialize camera and ML Kit pose detector.
  Future<void> initialize(String exerciseType, {bool isLandscape = false}) async {
    try {
      // 1. Get available cameras
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        throw Exception('No cameras available');
      }

      // Find front camera
      CameraDescription? frontCamera;
      for (final camera in cameras) {
        if (camera.lensDirection == CameraLensDirection.front) {
          frontCamera = camera;
          break;
        }
      }
      frontCamera ??= cameras.first;

      // ─── Optimization #4: Resolution & Model Tuning ───
      // Ground exercises (landscape) need higher resolution and accuracy to resolve horizontal bodies against the floor.
      _cameraController = CameraController(
        frontCamera,
        isLandscape ? ResolutionPreset.medium : ResolutionPreset.low,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.nv21,
      );

      await _cameraController!.initialize();

      // Lock camera orientation to match the UI so flat devices don't randomly flip the feed
      if (isLandscape) {
        await _cameraController!.lockCaptureOrientation(DeviceOrientation.landscapeLeft);
      } else {
        await _cameraController!.lockCaptureOrientation(DeviceOrientation.portraitUp);
      }

      // Cache sensor orientation
      _sensorOrientation = frontCamera.sensorOrientation;
      _isLandscapeMode = isLandscape;

      // 3. Initialize ML Kit Pose Detector
      _poseDetector = PoseDetector(
        options: PoseDetectorOptions(
          mode: PoseDetectionMode.stream,
          model: isLandscape ? PoseDetectionModel.accurate : PoseDetectionModel.base,
        ),
      );

      // 4. Create the exercise-specific detector
      _exerciseDetector = _createDetector(exerciseType);
      _exerciseDetector!.reset();

      _isInitialized = true;
    } catch (e) {
      debugPrint('❌ PoseDetectorService init error: $e');
      rethrow;
    }
  }

  InputImageRotation? _getRotation(CameraController? controller) {
    if (controller == null) return null;

    // device orientation degrees
    int deviceAngle = 0;
    switch (controller.value.deviceOrientation) {
      case DeviceOrientation.portraitUp:
        deviceAngle = 0;
        break;
      case DeviceOrientation.landscapeLeft:
        deviceAngle = 90;
        break;
      case DeviceOrientation.portraitDown:
        deviceAngle = 180;
        break;
      case DeviceOrientation.landscapeRight:
        deviceAngle = 270;
        break;
    }

    // Front camera logic (image is mirrored, so angle adds to sensor orientation)
    int rotationCompensation = (_sensorOrientation + deviceAngle) % 360;

    switch (rotationCompensation) {
      case 0: return InputImageRotation.rotation0deg;
      case 90: return InputImageRotation.rotation90deg;
      case 180: return InputImageRotation.rotation180deg;
      case 270: return InputImageRotation.rotation270deg;
      default: return InputImageRotation.rotation0deg;
    }
  }

  ExerciseDetector _createDetector(String exerciseType) {
    switch (exerciseType) {
      case ExerciseTypes.pushups:
        return PushupDetector();
      case ExerciseTypes.squats:
        return SquatDetector();
      case ExerciseTypes.jumpingJacks:
        return JumpingJackDetector();
      case ExerciseTypes.situps:
        return SitupDetector();
      case ExerciseTypes.lunges:
        return LungeDetector();
      case ExerciseTypes.planks:
        return PlankDetector();
      case ExerciseTypes.highKnees:
        return HighKneesDetector();
      case ExerciseTypes.burpees:
        return BurpeeDetector();
      case ExerciseTypes.wallSit:
        return WallSitDetector();
      case ExerciseTypes.legRaises:
        return LegRaiseDetector();
      case ExerciseTypes.tricepDips:
        return TricepDipDetector();
      case ExerciseTypes.armCircles:
        return ArmCircleDetector();
      default:
        return PushupDetector(); // Fallback
    }
  }

  /// Start the camera image stream, beginning in calibration mode.
  void startDetection() {
    if (_cameraController != null && !_cameraController!.value.isStreamingImages) {
      _isCalibrating = true;
      _calibrationDetector.reset();
      _smoother.reset();
      _startImageStream();
    }
  }

  /// Called by the UI once the CalibrationDetector emits [CalibrationStatus.locked].
  /// Arms the exercise detector with the baseline and exits calibration mode.
  void lockCalibration(CalibrationBaseline baseline) {
    _exerciseDetector?.baseline = baseline;
    _exerciseDetector?.reset();
    _isCalibrating = false;
    debugPrint('✅ Calibration locked: $baseline');
  }

  Future<void> stopDetection() async {
    if (_cameraController != null && _cameraController!.value.isStreamingImages) {
      await _cameraController!.stopImageStream();
    }
    _isProcessing = false;
  }

  // ─── Optimization #3: try-finally pipeline safety ───
  void _startImageStream() {
    _cameraController?.startImageStream((CameraImage image) {
      _frameCount++;
      // Skip frames for performance
      if (_frameCount % _processEveryNFrames != 0) return;
      if (_isProcessing) return;

      _isProcessing = true;
      _processImage(image).whenComplete(() {
        _isProcessing = false; // ALWAYS resets, even on errors
      });
    });
  }

  Future<void> _processImage(CameraImage image) async {
    if (_poseDetector == null || _exerciseDetector == null) return;

    try {
      // ─── Optimization #4: Minimal allocation image conversion ───
      final inputImage = _convertCameraImage(image);
      if (inputImage == null) return;

      // Run ML Kit pose detection
      final poses = await _poseDetector!.processImage(inputImage);

      if (poses.isNotEmpty) {
        final pose = poses.first;
        final rawLandmarks = <PoseLandmarkType, PoseLandmark>{};
        for (final entry in pose.landmarks.entries) {
          rawLandmarks[entry.key] = entry.value;
        }

        // ─── Likelihood filter + One Euro smoothing ───
        final smoothedLandmarks = _smoother.smooth(rawLandmarks);

        // Calculate image size (accounting for dynamic rotation)
        Size imageSize = Size(image.width.toDouble(), image.height.toDouble());
        final currentRotation = _getRotation(_cameraController);
        if (currentRotation == InputImageRotation.rotation90deg ||
            currentRotation == InputImageRotation.rotation270deg) {
          imageSize = Size(image.height.toDouble(), image.width.toDouble());
        }

        // The calibration fill axis is ALWAYS vertical (noseY → ankleY) because
        // ML Kit returns landmark coordinates in the pre-rotation input image space.
        // When the phone is physically in landscape, the rotation tag is 0° (sensor
        // 270° + device 90° = 360° = 0°), so the image dimensions are NOT swapped
        // and the body still appears vertically in ML Kit's coordinate space.
        // _isLandscapeMode controls fill THRESHOLDS only (ground vs standing),
        // not the measurement axis.
        if (_isCalibrating) {
          // ─── CALIBRATION MODE: route to CalibrationDetector ───
          final calResult = _calibrationDetector.process(
            smoothedLandmarks,
            imageSize,
            isGroundExercise: _isLandscapeMode,
          );

          if (!_calibrationStreamController.isClosed) {
            _calibrationStreamController.add(calResult);
          }

          // Also emit landmarks so a UI-side painter can draw the skeleton
          if (!_poseStreamController.isClosed) {
            _poseStreamController.add(PoseDetectionFrame(
              landmarks: smoothedLandmarks,
              feedback: calResult.instruction,
              repComplete: false,
              repCount: 0,
            ));
          }
        } else {
          // ─── EXERCISE MODE: route to ExerciseDetector ───
          if (_exerciseDetector == null) return;
          final result = _exerciseDetector!.detect(smoothedLandmarks, imageSize);

          if (!_poseStreamController.isClosed) {
            _poseStreamController.add(PoseDetectionFrame(
              landmarks: smoothedLandmarks,
              feedback: result.feedback,
              repComplete: result.repComplete,
              repCount: _exerciseDetector!.repCount,
            ));
          }
          if (!_feedbackStreamController.isClosed) {
            _feedbackStreamController.add(result.feedback);
          }
          if (!_repCountStreamController.isClosed) {
            _repCountStreamController.add(_exerciseDetector!.repCount);
          }
        }
      }
    } catch (e) {
      debugPrint('⚠️ Frame processing error: $e');
      // _isProcessing is reset by .whenComplete() — stream never locks up
    }
  }

  // ─── Optimization #4: Minimal allocation, dynamic rotation ───
  InputImage? _convertCameraImage(CameraImage image) {
    final rotation = _getRotation(_cameraController);
    if (rotation == null) return null;

    try {
      final bytes = image.planes.first.bytes;
      final bytesPerRow = image.planes.first.bytesPerRow;
      final size = Size(image.width.toDouble(), image.height.toDouble());

      // Android NV21
      if (image.format.group == ImageFormatGroup.nv21) {
        return InputImage.fromBytes(
          bytes: bytes,
          metadata: InputImageMetadata(
            size: size,
            rotation: rotation,
            format: InputImageFormat.nv21,
            bytesPerRow: bytesPerRow,
          ),
        );
      }

      // iOS BGRA8888
      if (image.format.group == ImageFormatGroup.bgra8888) {
        return InputImage.fromBytes(
          bytes: bytes,
          metadata: InputImageMetadata(
            size: size,
            rotation: rotation,
            format: InputImageFormat.bgra8888,
            bytesPerRow: bytesPerRow,
          ),
        );
      }

      return null;
    } catch (e) {
      debugPrint('⚠️ Image conversion error: $e');
      return null;
    }
  }

  /// Dispose all resources.
  Future<void> dispose() async {
    _isInitialized = false;

    try {
      if (_cameraController?.value.isStreamingImages ?? false) {
        await _cameraController?.stopImageStream();
      }
      await _cameraController?.dispose();
    } catch (_) {}

    _poseDetector?.close();
    _poseStreamController.close();
    _feedbackStreamController.close();
    _repCountStreamController.close();
    _calibrationStreamController.close();
  }
}

/// Holds the result of processing a single camera frame.
class PoseDetectionFrame {
  final Map<PoseLandmarkType, PoseLandmark> landmarks;
  final String feedback;
  final bool repComplete;
  final int repCount;

  const PoseDetectionFrame({
    required this.landmarks,
    required this.feedback,
    required this.repComplete,
    required this.repCount,
  });
}
