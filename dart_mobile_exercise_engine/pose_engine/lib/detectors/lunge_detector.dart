import 'dart:ui';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import '../utils/angle_calculator.dart';
import '../exercise_detector.dart';

/// Lunge detector — ported from Python detect_lunge()
///
/// FRONT VIEW. Requires split stance (ankle distance > 1.5× shoulder width).
/// Rep: standing (both knees > 160°) → lunge (both knees < 120°) → standing = 1 rep.
class LungeDetector extends ExerciseDetector {
  static const _requiredLandmarks = [
    PoseLandmarkType.leftHip,
    PoseLandmarkType.rightHip,
    PoseLandmarkType.leftKnee,
    PoseLandmarkType.rightKnee,
    PoseLandmarkType.leftAnkle,
    PoseLandmarkType.rightAnkle,
    PoseLandmarkType.leftShoulder,
    PoseLandmarkType.rightShoulder,
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
    final leftShoulder = landmarks[PoseLandmarkType.leftShoulder]!;
    final rightShoulder = landmarks[PoseLandmarkType.rightShoulder]!;

    // Calculate knee angles for both legs
    final leftKneeAngle = AngleCalculator.angleBetweenLandmarks(leftHip, leftKnee, leftAnkle);
    final rightKneeAngle = AngleCalculator.angleBetweenLandmarks(rightHip, rightKnee, rightAnkle);

    // Check for proper lunge stance
    final ankleDistance = (leftAnkle.x - rightAnkle.x).abs();
    final shoulderWidth = (leftShoulder.x - rightShoulder.x).abs();

    // Legs must be split apart (front/back stance)
    final isSplitStance = ankleDistance > shoulderWidth * 1.5;
    final frontLegForward = (leftAnkle.x - rightAnkle.x).abs() > shoulderWidth * 1.2;

    if (!isSplitStance || !frontLegForward) {
      return const DetectionResult(
        repComplete: false,
        feedback: 'Get into lunge position — step one leg forward 🦿',
      );
    }

    final bothKneesBent = leftKneeAngle < 120 && rightKneeAngle < 120;
    final bothKneesStraight = leftKneeAngle > 160 && rightKneeAngle > 160;

    bool repComplete = false;
    String feedback = 'Step into a lunge — one leg forward, one back';

    // State machine (only works with proper stance)
    if (stage == null) {
      stage = 'standing';
      feedback = 'Good stance! Now lower into lunge';
    }

    if (stage == 'standing' && bothKneesBent) {
      stage = 'lunge';
      feedback = 'Good lunge! Hold it for a moment';
    } else if (stage == 'lunge' && bothKneesStraight) {
      repCount++;
      repComplete = true;
      stage = 'standing';
      feedback = 'REP COMPLETE! 💪 Great work!';
    } else if (stage == 'lunge' && !bothKneesBent) {
      feedback = 'Hold the lunge position';
    } else if (stage == 'standing' && !bothKneesStraight) {
      feedback = 'Stand up fully between reps';
    }

    // Additional form guidance
    if (bothKneesBent && isSplitStance) {
      if (leftKneeAngle < 90 || rightKneeAngle < 90) {
        feedback = 'Perfect depth! 🔥';
      } else {
        feedback = 'Good! Lower a bit more for full depth';
      }
    }

    return DetectionResult(repComplete: repComplete, feedback: feedback);
  }
}
