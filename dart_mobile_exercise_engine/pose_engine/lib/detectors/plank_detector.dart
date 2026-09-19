import 'dart:ui';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import '../utils/angle_calculator.dart';
import '../exercise_detector.dart';

/// Plank detector — ported from Python detect_plank()
///
/// SIDE VIEW, face down. This is an ISOMETRIC exercise — no reps.
/// repCount = seconds held. Includes a 20-second rest tolerance window.
class PlankDetector extends ExerciseDetector {
  static const _requiredLandmarks = [
    PoseLandmarkType.leftShoulder,
    PoseLandmarkType.rightShoulder,
    PoseLandmarkType.leftElbow,
    PoseLandmarkType.rightElbow,
    PoseLandmarkType.leftWrist,
    PoseLandmarkType.rightWrist,
    PoseLandmarkType.leftHip,
    PoseLandmarkType.leftAnkle,
  ];

  DateTime? _plankStartTime;
  double _plankDuration = 0;
  bool _plankHoldActive = false;
  DateTime? _pauseTime;

  @override
  void reset() {
    super.reset();
    _plankStartTime = null;
    _plankDuration = 0;
    _plankHoldActive = false;
    _pauseTime = null;
  }

  /// Get the current plank duration in seconds.
  double get plankDuration => _plankDuration;

  @override
  DetectionResult detect(Map<PoseLandmarkType, PoseLandmark> landmarks, Size imageSize) {
    if (!hasAllLandmarks(landmarks, _requiredLandmarks)) {
      return const DetectionResult(repComplete: false, feedback: 'POSITION YOURSELF IN FRAME');
    }

    final leftShoulder = landmarks[PoseLandmarkType.leftShoulder]!;
    final rightShoulder = landmarks[PoseLandmarkType.rightShoulder]!;
    final leftElbow = landmarks[PoseLandmarkType.leftElbow]!;
    final rightElbow = landmarks[PoseLandmarkType.rightElbow]!;
    final leftWrist = landmarks[PoseLandmarkType.leftWrist]!;
    final rightWrist = landmarks[PoseLandmarkType.rightWrist]!;
    final leftHip = landmarks[PoseLandmarkType.leftHip]!;
    final leftAnkle = landmarks[PoseLandmarkType.leftAnkle]!;

    // Body alignment angles
    final bodyAngle = AngleCalculator.angleBetweenLandmarks(leftShoulder, leftHip, leftAnkle);

    // Arm angles for L-shape detection
    final leftArmAngle = AngleCalculator.angleBetweenLandmarks(leftShoulder, leftElbow, leftWrist);
    final rightArmAngle = AngleCalculator.angleBetweenLandmarks(rightShoulder, rightElbow, rightWrist);
    final avgArmAngle = (leftArmAngle + rightArmAngle) / 2;

    // Comprehensive plank position check
    final isBodyStraight = bodyAngle > 160 && bodyAngle < 200;
    final isBodyHorizontal = (leftShoulder.y - leftHip.y).abs() < (imageSize.height * 0.15);
    final isFacingDown = leftShoulder.y < leftAnkle.y;
    final hasProperArms = avgArmAngle > 80 && avgArmAngle < 100;
    final wristsBelowShoulders = leftWrist.y > leftShoulder.y && rightWrist.y > rightShoulder.y;

    final isPlankPosition = isBodyStraight && isBodyHorizontal &&
        isFacingDown && hasProperArms && wristsBelowShoulders;

    final now = DateTime.now();
    String feedback = 'GET IN PLANK POSITION';

    if (isPlankPosition) {
      // USER IS IN PLANK POSITION
      if (!_plankHoldActive) {
        if (_pauseTime != null) {
          final pauseDuration = now.difference(_pauseTime!).inSeconds;
          if (pauseDuration <= 20) {
            _plankStartTime = _plankStartTime!.add(Duration(seconds: pauseDuration));
            feedback = 'WELCOME BACK! PLANK RESUMED 💪';
          } else {
            _plankStartTime = now;
            _plankDuration = 0;
            repCount = 0;
            feedback = 'REST TIME EXCEEDED — PLANK RESET! 🔄';
          }
          _pauseTime = null;
        } else {
          _plankStartTime ??= now;
          feedback = 'PLANK STARTED! HOLD IT! 💪';
        }
        _plankHoldActive = true;
      }

      // Calculate current duration
      _plankDuration = now.difference(_plankStartTime!).inMilliseconds / 1000.0;
      repCount = _plankDuration.toInt();

      if (_plankDuration < 10) {
        feedback = 'PLANK: ${_plankDuration.toInt()}s — KEEP GOING!';
      } else if (_plankDuration < 30) {
        feedback = 'PLANK: ${_plankDuration.toInt()}s — GREAT HOLD!';
      } else if (_plankDuration < 60) {
        feedback = 'PLANK: ${_plankDuration.toInt()}s — AMAZING ENDURANCE! 🔥';
      } else {
        feedback = 'PLANK: ${_plankDuration.toInt()}s — LEGENDARY! ⚡';
      }
    } else {
      // USER IS NOT IN PLANK POSITION
      if (_plankHoldActive) {
        _plankHoldActive = false;
        _pauseTime = now;
        feedback = 'PLANK PAUSED — GET BACK IN 20s! ⏰';
      } else if (_pauseTime != null) {
        final restTime = now.difference(_pauseTime!).inSeconds;
        final timeRemaining = 20 - restTime;

        if (timeRemaining > 0) {
          feedback = 'RETURN TO PLANK IN ${timeRemaining}s! ⏳';
        } else {
          _plankStartTime = null;
          _plankDuration = 0;
          repCount = 0;
          _pauseTime = null;
          feedback = 'REST TIME EXCEEDED — PLANK RESET! 🔄';
        }
      } else {
        if (!isBodyStraight) {
          feedback = "KEEP BODY STRAIGHT — DON'T SAG OR ARCH";
        } else if (!isBodyHorizontal) {
          feedback = 'ALIGN SHOULDERS WITH HIPS';
        } else if (!hasProperArms) {
          feedback = 'FORM 90-DEGREE ANGLES WITH ARMS';
        } else if (!isFacingDown) {
          feedback = 'FACE DOWN — HEAD IN NEUTRAL POSITION';
        } else {
          feedback = 'GET IN PLANK POSITION — ARMS BENT, BODY STRAIGHT';
        }
      }
    }

    return DetectionResult(repComplete: false, feedback: feedback);
  }
}
