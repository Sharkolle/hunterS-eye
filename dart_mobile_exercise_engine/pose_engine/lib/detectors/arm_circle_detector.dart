import 'dart:ui';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import '../utils/angle_calculator.dart';
import '../exercise_detector.dart';

class ArmCircleDetector extends ExerciseDetector {
  static const _requiredLandmarks = [
    PoseLandmarkType.leftShoulder,
    PoseLandmarkType.rightShoulder,
    PoseLandmarkType.leftElbow,
    PoseLandmarkType.rightElbow,
    PoseLandmarkType.leftWrist,
    PoseLandmarkType.rightWrist,
  ];

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

    final leftAngle = AngleCalculator.angleBetweenLandmarks(leftShoulder, leftElbow, leftWrist);
    final rightAngle = AngleCalculator.angleBetweenLandmarks(rightShoulder, rightElbow, rightWrist);

    // Check if arms are straight
    if (leftAngle < 140 || rightAngle < 140) {
      return const DetectionResult(repComplete: false, feedback: 'KEEP ARMS STRAIGHT');
    }

    final avgShoulderY = (leftShoulder.y + rightShoulder.y) / 2;
    final avgWristY = (leftWrist.y + rightWrist.y) / 2;

    bool repComplete = false;
    String feedback = 'BIGGER CIRCLES';

    // Simple vertical oscillation tracker for arm circles
    if (avgWristY < avgShoulderY - (imageSize.height * 0.1)) {
      if (stage == 'down') {
        repCount++;
        repComplete = true;
      }
      stage = 'up';
      feedback = 'KEEP GOING';
    } else if (avgWristY > avgShoulderY + (imageSize.height * 0.1)) {
      stage = 'down';
      feedback = 'KEEP GOING';
    }

    return DetectionResult(repComplete: repComplete, feedback: feedback);
  }
}
