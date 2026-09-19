import 'dart:ui';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import '../utils/angle_calculator.dart';
import '../exercise_detector.dart';

class WallSitDetector extends ExerciseDetector {
  static const _requiredLandmarks = [
    PoseLandmarkType.leftHip,
    PoseLandmarkType.rightHip,
    PoseLandmarkType.leftKnee,
    PoseLandmarkType.rightKnee,
    PoseLandmarkType.leftAnkle,
    PoseLandmarkType.rightAnkle,
  ];

  DateTime? _wallSitStartTime;
  DateTime? _lastValidTime;
  int _accumulatedSeconds = 0;

  @override
  void reset() {
    super.reset();
    _wallSitStartTime = null;
    _lastValidTime = null;
    _accumulatedSeconds = 0;
  }

  @override
  DetectionResult detect(Map<PoseLandmarkType, PoseLandmark> landmarks, Size imageSize) {
    if (!hasAllLandmarks(landmarks, _requiredLandmarks)) {
      return const DetectionResult(repComplete: false, feedback: 'POSITION YOURSELF IN FRAME');
    }

    final leftHip = landmarks[PoseLandmarkType.leftHip]!;
    final rightHip = landmarks[PoseLandmarkType.rightHip]!;
    final leftKnee = landmarks[PoseLandmarkType.leftKnee]!;
    final rightKnee = landmarks[PoseLandmarkType.rightKnee]!;
    final leftAnkle = landmarks[PoseLandmarkType.leftAnkle]!;
    final rightAnkle = landmarks[PoseLandmarkType.rightAnkle]!;

    final leftAngle = AngleCalculator.angleBetweenLandmarks(leftHip, leftKnee, leftAnkle);
    final rightAngle = AngleCalculator.angleBetweenLandmarks(rightHip, rightKnee, rightAnkle);

    final avgAngle = (leftAngle + rightAngle) / 2;
    String feedback = 'LOWER YOUR HIPS';

    // Wall sit is around 90 degrees
    bool isWallSitting = avgAngle > 70 && avgAngle < 110;

    final now = DateTime.now();

    if (isWallSitting) {
      if (_wallSitStartTime == null) {
        _wallSitStartTime = now;
        _lastValidTime = now;
      } else {
        final sessionDuration = now.difference(_lastValidTime!).inSeconds;
        if (sessionDuration > 0) {
          _accumulatedSeconds += sessionDuration;
          _lastValidTime = now;
        }
      }
      repCount = _accumulatedSeconds;
      feedback = 'HOLD IT';
    } else {
      // Pause tolerance: if they break form, we pause the timer.
      // If they are broken for more than 5 seconds, reset current session.
      if (_lastValidTime != null && now.difference(_lastValidTime!).inSeconds > 5) {
        _wallSitStartTime = null; // Forces them to re-establish
      }

      if (avgAngle > 110) {
        feedback = 'LOWER YOUR HIPS';
      } else {
        feedback = 'RAISE YOUR HIPS SLIGHTLY';
      }
    }

    // repCount acts as seconds for time-based exercises
    return DetectionResult(repComplete: false, feedback: feedback);
  }
}
