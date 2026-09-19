import 'dart:ui';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import '../utils/angle_calculator.dart';
import '../exercise_detector.dart';

/// Push-up detector — ported from Python detect_pushup()
///
/// Requires SIDE VIEW. Player must be in plank position (face down).
/// Checks: body horizontal, shoulders/hips aligned, wrists below shoulders.
/// Rep: arm angle > 160° (up) → < 90° (down) → > 160° (up) = 1 rep.
class PushupDetector extends ExerciseDetector {
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

  @override
  DetectionResult detect(Map<PoseLandmarkType, PoseLandmark> landmarks, Size imageSize) {
    // Likelihood check — all required landmarks must be present & confident
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

    // Calculate arm angles
    final leftArmAngle = AngleCalculator.angleBetweenLandmarks(leftShoulder, leftElbow, leftWrist);
    final rightArmAngle = AngleCalculator.angleBetweenLandmarks(rightShoulder, rightElbow, rightWrist);
    final avgArmAngle = (leftArmAngle + rightArmAngle) / 2;

    // Body horizontal alignment (shoulder-hip-ankle)
    final bodyAngle = AngleCalculator.angleBetweenLandmarks(leftShoulder, leftHip, leftAnkle);

    // Check plank position
    final isHorizontal = bodyAngle > 160 && bodyAngle < 200;
    final shouldersHipsAligned = (leftShoulder.y - leftHip.y).abs() < (imageSize.height * 0.15);
    final wristsBelowShoulders = leftWrist.y > leftShoulder.y && rightWrist.y > rightShoulder.y;

    final isPlankPosition = isHorizontal && shouldersHipsAligned && wristsBelowShoulders;

    if (!isPlankPosition) {
      return const DetectionResult(
        repComplete: false,
        feedback: 'GET IN PLANK POSITION — body straight, hands below shoulders',
      );
    }

    bool repComplete = false;
    String feedback = 'START PUSH UP';

    if (avgArmAngle > 160) {
      if (stage == 'down') {
        repCount++;
        repComplete = true;
      }
      stage = 'up';
      feedback = 'START PUSH UP';
    } else if (avgArmAngle < 90) {
      stage = 'down';
      if (avgArmAngle < 70) {
        feedback = 'GO LOWER — CHEST TO GROUND';
      } else {
        feedback = 'GOOD DEPTH';
      }
    }

    // Check arm symmetry
    final armSymmetry = (leftArmAngle - rightArmAngle).abs();
    if (armSymmetry > 20) {
      feedback = 'KEEP ARMS EVEN';
    }

    return DetectionResult(repComplete: repComplete, feedback: feedback);
  }
}
