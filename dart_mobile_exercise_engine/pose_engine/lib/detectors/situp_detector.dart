import 'dart:ui';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import '../utils/angle_calculator.dart';
import '../exercise_detector.dart';

/// Sit-up detector — ported from Python detect_situp()
///
/// SIDE VIEW. Requires knees bent at < 95° (pyramid position).
/// Rep: torso angle (shoulder→hip→knee) < 60° (up) → > 100° (down) → < 60° = 1 rep.
class SitupDetector extends ExerciseDetector {
  static const _requiredLandmarks = [
    PoseLandmarkType.leftShoulder,
    PoseLandmarkType.leftHip,
    PoseLandmarkType.rightHip,
    PoseLandmarkType.leftKnee,
    PoseLandmarkType.rightKnee,
    PoseLandmarkType.leftAnkle,
    PoseLandmarkType.rightAnkle,
  ];

  @override
  DetectionResult detect(Map<PoseLandmarkType, PoseLandmark> landmarks, Size imageSize) {
    if (!hasAllLandmarks(landmarks, _requiredLandmarks)) {
      return const DetectionResult(repComplete: false, feedback: 'POSITION YOURSELF IN FRAME');
    }

    final leftShoulder = landmarks[PoseLandmarkType.leftShoulder]!;
    final leftHip = landmarks[PoseLandmarkType.leftHip]!;
    final rightHip = landmarks[PoseLandmarkType.rightHip]!;
    final leftKnee = landmarks[PoseLandmarkType.leftKnee]!;
    final rightKnee = landmarks[PoseLandmarkType.rightKnee]!;
    final leftAnkle = landmarks[PoseLandmarkType.leftAnkle]!;
    final rightAnkle = landmarks[PoseLandmarkType.rightAnkle]!;

    // Calculate leg angles to ensure proper sit-up position
    final leftLegAngle = AngleCalculator.angleBetweenLandmarks(leftHip, leftKnee, leftAnkle);
    final rightLegAngle = AngleCalculator.angleBetweenLandmarks(rightHip, rightKnee, rightAnkle);
    final avgLegAngle = (leftLegAngle + rightLegAngle) / 2;

    // Calculate torso angle
    final torsoAngle = AngleCalculator.angleBetweenLandmarks(leftShoulder, leftHip, leftKnee);

    // Check pyramid position (knees bent at < 95°)
    final legsBent = avgLegAngle < 95;

    if (!legsBent) {
      return const DetectionResult(
        repComplete: false,
        feedback: 'Bend knees to pyramid position 🔺 (knees at <95°)',
      );
    }

    bool repComplete = false;
    String feedback = 'GET IN SIT-UP POSITION';

    // State machine — only works with proper leg position
    if (torsoAngle < 60) {
      if (stage == 'down') {
        repCount++;
        repComplete = true;
      }
      stage = 'up';
      feedback = 'SIT UP COMPLETE! 💪';
    } else if (torsoAngle > 100) {
      stage = 'down';
      if (torsoAngle > 140) {
        feedback = 'FULL RANGE — EXCELLENT! 🔥';
      } else {
        feedback = 'GOOD RANGE OF MOTION';
      }
    }

    return DetectionResult(repComplete: repComplete, feedback: feedback);
  }
}
