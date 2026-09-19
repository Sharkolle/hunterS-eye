import 'dart:ui';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import '../utils/angle_calculator.dart';
import '../exercise_detector.dart';

class HighKneesDetector extends ExerciseDetector {
  static const _requiredLandmarks = [
    PoseLandmarkType.leftHip,
    PoseLandmarkType.rightHip,
    PoseLandmarkType.leftKnee,
    PoseLandmarkType.rightKnee,
    PoseLandmarkType.leftShoulder,
    PoseLandmarkType.rightShoulder,
  ];

  String _lastLeg = '';

  @override
  void reset() {
    super.reset();
    _lastLeg = '';
  }

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

    bool repComplete = false;
    String feedback = 'START HIGH KNEES';

    // A knee is "high" when the angle is less than 110 degrees (thigh is roughly horizontal)
    bool leftHigh = leftAngle < 110;
    bool rightHigh = rightAngle < 110;

    if (leftHigh && rightHigh) {
      feedback = 'ONE LEG AT A TIME';
    } else if (leftHigh) {
      if (_lastLeg != 'left') {
        stage = 'up';
        _lastLeg = 'left';
        repCount++;
        repComplete = true; // Every alternating lift counts as 1
        feedback = 'GOOD HEIGHT';
      }
    } else if (rightHigh) {
      if (_lastLeg != 'right') {
        stage = 'up';
        _lastLeg = 'right';
        repCount++;
        repComplete = true; // Every alternating lift counts as 1
        feedback = 'GOOD HEIGHT';
      }
    } else {
      if (leftAngle > 150 && rightAngle > 150) {
        stage = 'down';
      }
      feedback = 'LIFT KNEES HIGHER';
    }

    return DetectionResult(repComplete: repComplete, feedback: feedback);
  }
}
