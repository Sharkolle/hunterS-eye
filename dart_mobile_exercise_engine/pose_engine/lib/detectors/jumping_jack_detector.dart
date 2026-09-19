import 'dart:ui';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import '../exercise_detector.dart';

/// Jumping Jack detector — ported from Python detect_jumping_jack()
///
/// FRONT VIEW. Uses a 3-state machine: init → together → apart → together = 1 rep.
/// Checks: arms raised + spread AND legs wider than 1.5× shoulder width.
class JumpingJackDetector extends ExerciseDetector {
  static const _requiredLandmarks = [
    PoseLandmarkType.leftShoulder,
    PoseLandmarkType.rightShoulder,
    PoseLandmarkType.leftWrist,
    PoseLandmarkType.rightWrist,
    PoseLandmarkType.leftAnkle,
    PoseLandmarkType.rightAnkle,
  ];

  @override
  void reset() {
    super.reset();
    stage = 'init';
  }

  @override
  DetectionResult detect(Map<PoseLandmarkType, PoseLandmark> landmarks, Size imageSize) {
    if (!hasAllLandmarks(landmarks, _requiredLandmarks)) {
      return const DetectionResult(repComplete: false, feedback: 'POSITION YOURSELF IN FRAME');
    }

    final leftShoulder = landmarks[PoseLandmarkType.leftShoulder]!;
    final rightShoulder = landmarks[PoseLandmarkType.rightShoulder]!;
    final leftWrist = landmarks[PoseLandmarkType.leftWrist]!;
    final rightWrist = landmarks[PoseLandmarkType.rightWrist]!;
    final leftAnkle = landmarks[PoseLandmarkType.leftAnkle]!;
    final rightAnkle = landmarks[PoseLandmarkType.rightAnkle]!;

    // Calculate position indicators
    final leftArmRaised = leftWrist.y < leftShoulder.y;
    final rightArmRaised = rightWrist.y < rightShoulder.y;
    final armsRaised = leftArmRaised && rightArmRaised;

    final shoulderWidth = (leftShoulder.x - rightShoulder.x).abs();
    final legSpread = (leftAnkle.x - rightAnkle.x).abs();
    final legsSpread = legSpread > shoulderWidth * 1.5;

    final armSpread = (leftWrist.x - rightWrist.x).abs();
    final armsSpread = armSpread > shoulderWidth * 1.8;

    // Check neutral position
    final isNeutral = !armsRaised && !legsSpread;

    bool repComplete = false;
    String feedback = 'START IN NEUTRAL POSITION';

    // Initialize state machine
    if (stage == null) {
      stage = 'init';
      return const DetectionResult(repComplete: false, feedback: 'Get ready — arms down, legs together');
    }

    // State machine logic (exact port from Python)
    if (stage == 'init') {
      if (isNeutral) {
        stage = 'together';
        feedback = 'READY — JUMP AND SPREAD!';
      } else {
        feedback = 'START WITH ARMS DOWN & LEGS TOGETHER';
      }
    } else if (stage == 'together') {
      if (armsRaised && armsSpread && legsSpread) {
        stage = 'apart';
        feedback = 'GOOD SPREAD! NOW RETURN ✨';
      } else if (isNeutral) {
        feedback = 'JUMP! SPREAD ARMS & LEGS WIDER';
      } else {
        feedback = 'SPREAD ARMS & LEGS WIDER';
      }
    } else if (stage == 'apart') {
      if (isNeutral) {
        repCount++;
        repComplete = true;
        stage = 'together';
        feedback = 'REP COMPLETE! 🔥';
      } else if (!armsRaised) {
        feedback = 'BRING LEGS TOGETHER';
      } else if (!legsSpread) {
        feedback = 'BRING ARMS DOWN';
      } else {
        feedback = 'RETURN TO START POSITION';
      }
    }

    return DetectionResult(repComplete: repComplete, feedback: feedback);
  }
}
