import 'dart:ui';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import '../utils/angle_calculator.dart';
import '../exercise_detector.dart';

/// Squat detector — ported from Python detect_squat()
///
/// FRONT or SIDE VIEW. Uses average knee angle of both legs.
/// Rep: avg angle > 160° (up/standing) → < 100° (down/squatting) → > 160° = 1 rep.
class SquatDetector extends ExerciseDetector {
  static const _requiredLandmarks = [
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

    final leftHip = landmarks[PoseLandmarkType.leftHip]!;
    final rightHip = landmarks[PoseLandmarkType.rightHip]!;
    final leftKnee = landmarks[PoseLandmarkType.leftKnee]!;
    final rightKnee = landmarks[PoseLandmarkType.rightKnee]!;
    final leftAnkle = landmarks[PoseLandmarkType.leftAnkle]!;
    final rightAnkle = landmarks[PoseLandmarkType.rightAnkle]!;

    // Calculate knee angles for BOTH legs
    final leftAngle = AngleCalculator.angleBetweenLandmarks(leftHip, leftKnee, leftAnkle);
    final rightAngle = AngleCalculator.angleBetweenLandmarks(rightHip, rightKnee, rightAnkle);

    final avgAngle = (leftAngle + rightAngle) / 2;
    final legSymmetry = (leftAngle - rightAngle).abs();

    // Check symmetry
    if (legSymmetry > 30) {
      return const DetectionResult(
        repComplete: false,
        feedback: 'KEEP LEGS EVEN — BOTH KNEES SHOULD BEND TOGETHER',
      );
    }

    bool repComplete = false;
    String feedback = 'GOOD FORM';

    if (avgAngle > 160) {
      if (stage == 'down') {
        repCount++;
        repComplete = true;
      }
      stage = 'up';
      feedback = 'YOU ARE STANDING, SQUAT DOWN ⬇️';
    } else if (avgAngle < 100) {
      stage = 'down';
      if (avgAngle < 80) {
        feedback = 'PERFECT DEPTH 🔥! NOW GET BACK UP';
      } else {
        feedback = 'GOOD SQUAT';
      }
    }

    return DetectionResult(repComplete: repComplete, feedback: feedback);
  }
}
