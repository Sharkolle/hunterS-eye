import 'dart:ui';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import '../utils/angle_calculator.dart';
import '../exercise_detector.dart';

class LegRaiseDetector extends ExerciseDetector {
  static const _requiredLandmarks = [
    PoseLandmarkType.leftShoulder,
    PoseLandmarkType.rightShoulder,
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
    final rightShoulder = landmarks[PoseLandmarkType.rightShoulder]!;
    final leftHip = landmarks[PoseLandmarkType.leftHip]!;
    final rightHip = landmarks[PoseLandmarkType.rightHip]!;
    final leftKnee = landmarks[PoseLandmarkType.leftKnee]!;
    final rightKnee = landmarks[PoseLandmarkType.rightKnee]!;

    final leftAngle = AngleCalculator.angleBetweenLandmarks(leftShoulder, leftHip, leftKnee);
    final rightAngle = AngleCalculator.angleBetweenLandmarks(rightShoulder, rightHip, rightKnee);

    final avgAngle = (leftAngle + rightAngle) / 2;

    bool repComplete = false;
    String feedback = 'START LEG RAISES';

    // Laying flat: body is straight, angle ~180
    // Legs raised: angle ~90

    if (avgAngle < 110) {
      if (stage == 'down') {
        stage = 'up';
      }
      feedback = 'CONTROL THE DESCENT';
    } else if (avgAngle > 150) {
      if (stage == 'up') {
        repCount++;
        repComplete = true;
      }
      stage = 'down';
      feedback = 'LEGS UP';
    } else {
      feedback = stage == 'up' ? 'CONTROL THE DESCENT' : 'LEGS UP';
    }

    return DetectionResult(repComplete: repComplete, feedback: feedback);
  }
}
