import 'dart:ui';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'models/calibration_baseline.dart';

/// Result from processing a single frame through an exercise detector.
class DetectionResult {
  final bool repComplete;
  final String feedback;

  const DetectionResult({
    required this.repComplete,
    required this.feedback,
  });
}

/// Abstract base class for all exercise detectors.
/// Each detector maintains its own state machine and counts reps.
abstract class ExerciseDetector {
  int repCount = 0;
  String? stage;

  /// Optional calibration baseline. When set, detectors use body-proportional
  /// thresholds instead of hardcoded pixel/angle values.
  CalibrationBaseline? baseline;

  /// Process a set of pose landmarks and return detection result.
  /// [landmarks] have already been smoothed and likelihood-filtered by the service.
  DetectionResult detect(Map<PoseLandmarkType, PoseLandmark> landmarks, Size imageSize);

  /// Reset the detector state for a new workout session.
  void reset() {
    repCount = 0;
    stage = null;
  }

  /// Helper: Check if ALL required landmark types are present and confident.
  /// Returns true if all landmarks exist in the map (already filtered by smoother).
  bool hasAllLandmarks(
    Map<PoseLandmarkType, PoseLandmark> landmarks,
    List<PoseLandmarkType> required,
  ) {
    for (final type in required) {
      if (!landmarks.containsKey(type)) return false;
    }
    return true;
  }
}
