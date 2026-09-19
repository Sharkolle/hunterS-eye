import 'dart:ui';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import '../utils/angle_calculator.dart';
import '../exercise_detector.dart';

class TricepDipDetector extends ExerciseDetector {
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

    final avgAngle = (leftAngle + rightAngle) / 2;

    bool repComplete = false;
    String feedback = 'START TRICEP DIPS';

    // Arms straight -> up
    // Arms bent -> down

    if (avgAngle > 150) {
      if (stage == 'down') {
        repCount++;
        repComplete = true;
      }
      stage = 'up';
      feedback = 'BEND ELBOWS';
    } else if (avgAngle < 110) {
      stage = 'down';
      feedback = 'PUSH UP';
    } else {
      feedback = stage == 'down' ? 'PUSH UP' : 'BEND ELBOWS';
    }

    return DetectionResult(repComplete: repComplete, feedback: feedback);
  }
}
