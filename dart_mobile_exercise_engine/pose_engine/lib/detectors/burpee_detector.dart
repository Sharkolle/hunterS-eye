import 'dart:ui';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import '../exercise_detector.dart';

class BurpeeDetector extends ExerciseDetector {
  static const _requiredLandmarks = [
    PoseLandmarkType.leftShoulder,
    PoseLandmarkType.rightShoulder,
    PoseLandmarkType.leftKnee,
    PoseLandmarkType.rightKnee,
  ];

  @override
  DetectionResult detect(Map<PoseLandmarkType, PoseLandmark> landmarks, Size imageSize) {
    if (!hasAllLandmarks(landmarks, _requiredLandmarks)) {
      return const DetectionResult(repComplete: false, feedback: 'POSITION YOURSELF IN FRAME');
    }

    final leftShoulder = landmarks[PoseLandmarkType.leftShoulder]!;
    final rightShoulder = landmarks[PoseLandmarkType.rightShoulder]!;
    final leftKnee = landmarks[PoseLandmarkType.leftKnee]!;
    final rightKnee = landmarks[PoseLandmarkType.rightKnee]!;

    final avgShoulderY = (leftShoulder.y + rightShoulder.y) / 2;
    final avgKneeY = (leftKnee.y + rightKnee.y) / 2;

    bool repComplete = false;
    String feedback = 'START BURPEES';

    // In portrait, Y=0 is top.
    // Standing: shoulder is way above knee. (avgKneeY - avgShoulderY is large positive)
    // Down in pushup: shoulder is roughly same Y as knee, or slightly higher/lower.

    final verticalDistance = avgKneeY - avgShoulderY;

    if (verticalDistance > imageSize.height * 0.35) {
      // Standing up
      if (stage == 'down') {
        repCount++;
        repComplete = true;
      }
      stage = 'up';
      feedback = 'DROP DOWN';
    } else if (verticalDistance < imageSize.height * 0.15) {
      // Down on the ground
      stage = 'down';
      feedback = 'JUMP UP';
    } else {
      feedback = stage == 'down' ? 'JUMP UP' : 'DROP DOWN';
    }

    return DetectionResult(repComplete: repComplete, feedback: feedback);
  }
}
