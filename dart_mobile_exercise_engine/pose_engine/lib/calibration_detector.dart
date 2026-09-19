import 'dart:math' as math;
import 'dart:ui';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'models/calibration_baseline.dart';

// ─────────────────────────────────────────────────────────────
// CALIBRATION STATUS
// ─────────────────────────────────────────────────────────────

enum CalibrationStatus {
  /// Still waiting for a full-body pose to be detected.
  scanning,

  /// Body detected but not filling enough of the frame (user too far).
  tooFar,

  /// Body detected but extends beyond frame (user too close).
  tooClose,

  /// Full body visible at correct distance, but user is still moving.
  holdStill,

  /// All conditions met — body visible, correct distance, stable for 2s.
  locked,
}

// ─────────────────────────────────────────────────────────────
// CALIBRATION RESULT (emitted per-frame)
// ─────────────────────────────────────────────────────────────

class CalibrationResult {
  final CalibrationStatus status;

  /// Progress toward lock from 0.0 to 1.0.
  /// Only counts up when [status] is [CalibrationStatus.holdStill].
  final double progress;

  /// Populated only when [status] == [CalibrationStatus.locked].
  final CalibrationBaseline? baseline;

  /// Human-readable instruction string for the UI overlay.
  final String instruction;

  const CalibrationResult({
    required this.status,
    required this.progress,
    required this.instruction,
    this.baseline,
  });
}

// ─────────────────────────────────────────────────────────────
// CALIBRATION DETECTOR
// ─────────────────────────────────────────────────────────────

/// Processes incoming smoothed landmarks and checks three sequential gates
/// before emitting a CalibrationResult with status == locked.
///
/// IMPORTANT — coordinate system note:
/// ML Kit returns landmark coordinates in the PRE-ROTATION input image space.
/// This means the body ALWAYS appears vertically (nose near top, ankles near
/// bottom) regardless of whether the phone is held portrait or landscape.
/// The rotation tag fed to ML Kit corrects the detection internally, but the
/// returned (x, y) coordinates are always in the original sensor frame.
///
/// Therefore the fill check always measures the VERTICAL axis (ankleY − noseY).
/// The [isGroundExercise] flag only adjusts the fill THRESHOLD, not the axis:
///   - Standing exercises: body fills 52–95% of image height.
///   - Ground exercises (phone in landscape): lying body fills a smaller
///     fraction of image height → lower minimum threshold (40%).
///
/// Gate 1  — CORE VISIBILITY: nose, both shoulders, both hips ALL present.
/// Gate 1b — ANKLE VISIBILITY: at least ONE ankle must be visible.
/// Gate 2  — FILL: vertical body span within [minFill, maxFill].
/// Gate 3  — STABILITY: landmark positions stable (< 6px delta) for ~2 seconds.
class CalibrationDetector {
  // ── Standing exercise thresholds ──
  static const double _minBodyFill = 0.52;   // 52% of image height minimum
  static const double _maxBodyFill = 0.95;   // 95% cap (too close)

  // ── Ground exercise thresholds (phone in landscape, body lying horizontal) ──
  // When the phone is rotated to landscape, the image buffer is NOT swapped
  // (rotation0deg = sensor270 + device90 = 360 = 0). The image dimensions
  // stay as the native sensor size (e.g. 480 wide × 640 tall).  A person
  // lying on the floor still spans vertically in this coordinate space, but
  // they appear shorter top-to-bottom than a standing person, so we use a
  // lower minimum fill threshold.
  static const double _minBodyFillGround = 0.40; // 40% of image height minimum
  static const double _maxBodyFillGround = 0.95;

  // Stability threshold in raw pixel space (ML Kit absolute coordinates).
  static const double _stabilityThresholdPx = 6.0;
  static const int _stableFramesRequired = 20; // ~2s at ~10fps effective

  // ── Key landmarks required for calibration ──
  // Core: ALL must be present before calibration can proceed.
  static const _coreLandmarks = [
    PoseLandmarkType.nose,
    PoseLandmarkType.leftShoulder,
    PoseLandmarkType.rightShoulder,
    PoseLandmarkType.leftHip,
    PoseLandmarkType.rightHip,
  ];
  // Ankle: at least ONE must be present.
  // (Poor lighting often drops one ankle below the 0.65 likelihood threshold.)
  static const _ankleLandmarks = [
    PoseLandmarkType.leftAnkle,
    PoseLandmarkType.rightAnkle,
  ];

  // ── State ──
  int _stableFrameCount = 0;
  Map<PoseLandmarkType, PoseLandmark>? _previousLandmarks;

  void reset() {
    _stableFrameCount = 0;
    _previousLandmarks = null;
  }

  /// Process a smoothed landmark map and return the current calibration state.
  ///
  /// [isGroundExercise] — true for push-ups, sit-ups, planks (phone in landscape).
  /// Adjusts fill thresholds only; the fill axis is always vertical.
  CalibrationResult process(
    Map<PoseLandmarkType, PoseLandmark> landmarks,
    Size imageSize, {
    bool isGroundExercise = false,
  }) {
    // ── Gate 1: Core landmarks must ALL be present ──
    for (final type in _coreLandmarks) {
      if (!landmarks.containsKey(type)) {
        _stableFrameCount = 0;
        return const CalibrationResult(
          status: CalibrationStatus.scanning,
          progress: 0.0,
          instruction: 'POSITION YOURSELF IN FRAME',
        );
      }
    }

    // ── Gate 1b: At least one ankle must be visible ──
    final hasAnkle = _ankleLandmarks.any((t) => landmarks.containsKey(t));
    if (!hasAnkle) {
      _stableFrameCount = 0;
      return const CalibrationResult(
        status: CalibrationStatus.scanning,
        progress: 0.0,
        instruction: 'SHOW YOUR FULL BODY',
      );
    }

    // Safe references — core landmarks guaranteed non-null after Gate 1.
    final nose = landmarks[PoseLandmarkType.nose]!;
    final leftShoulder = landmarks[PoseLandmarkType.leftShoulder]!;
    final rightShoulder = landmarks[PoseLandmarkType.rightShoulder]!;
    final leftHip = landmarks[PoseLandmarkType.leftHip]!;
    final rightHip = landmarks[PoseLandmarkType.rightHip]!;

    // Use whichever ankle(s) are visible.
    final leftAnkle = landmarks[PoseLandmarkType.leftAnkle];
    final rightAnkle = landmarks[PoseLandmarkType.rightAnkle];
    final bestAnkle = leftAnkle ?? rightAnkle!; // Gate 1b guarantees at least one

    final ankleY = leftAnkle != null && rightAnkle != null
        ? (leftAnkle.y + rightAnkle.y) / 2
        : bestAnkle.y;
    final ankleX = leftAnkle != null && rightAnkle != null
        ? (leftAnkle.x + rightAnkle.x) / 2
        : bestAnkle.x;

    // ── Gate 2: Frame fill check ──
    // Fill is ALWAYS measured vertically (ankleY − noseY / imageHeight).
    // ML Kit coordinates are always in pre-rotation image space; the body
    // always spans vertically regardless of device orientation.
    final bodySpanPx = (ankleY - nose.y).abs();
    final fillRatio = bodySpanPx / imageSize.height;

    final double minFill = isGroundExercise ? _minBodyFillGround : _minBodyFill;
    final double maxFill = isGroundExercise ? _maxBodyFillGround : _maxBodyFill;

    if (fillRatio > maxFill) {
      _stableFrameCount = 0;
      _previousLandmarks = null;
      return const CalibrationResult(
        status: CalibrationStatus.tooClose,
        progress: 0.0,
        instruction: 'STEP BACK',
      );
    }

    if (fillRatio < minFill) {
      _stableFrameCount = 0;
      _previousLandmarks = null;
      return const CalibrationResult(
        status: CalibrationStatus.tooFar,
        progress: 0.0,
        instruction: 'MOVE CLOSER',
      );
    }

    // ── Gate 3: Stability check ──
    // Measure delta across all core landmarks + whichever ankles are present.
    final allVisibleTypes = [
      ..._coreLandmarks,
      if (leftAnkle != null) PoseLandmarkType.leftAnkle,
      if (rightAnkle != null) PoseLandmarkType.rightAnkle,
    ];

    if (_previousLandmarks != null) {
      double maxDelta = 0.0;
      for (final type in allVisibleTypes) {
        final curr = landmarks[type];
        final prev = _previousLandmarks![type];
        if (curr != null && prev != null) {
          final dx = curr.x - prev.x;
          final dy = curr.y - prev.y;
          final delta = dx * dx + dy * dy; // squared distance (faster than sqrt)
          if (delta > maxDelta) maxDelta = delta;
        }
      }

      // Compare as squared distance (threshold² = 36)
      if (maxDelta > _stabilityThresholdPx * _stabilityThresholdPx) {
        _stableFrameCount = 0;
        _previousLandmarks = landmarks;
        return const CalibrationResult(
          status: CalibrationStatus.holdStill,
          progress: 0.0,
          instruction: 'HOLD STILL...',
        );
      }
    }

    _previousLandmarks = landmarks;
    _stableFrameCount++;
    final progress = (_stableFrameCount / _stableFramesRequired).clamp(0.0, 1.0);

    // ── All gates passed: emit locked ──
    if (_stableFrameCount >= _stableFramesRequired) {
      // True pixel length of the body regardless of rotation
      final dx = ankleX - nose.x;
      final dy = ankleY - nose.y;
      final bodyHeightPx = math.sqrt(dx * dx + dy * dy);

      final shoulderWidthPx = (rightShoulder.x - leftShoulder.x).abs();
      final hipCenterY = ((leftHip.y + rightHip.y) / 2) / imageSize.height;
      final shoulderCenterY =
          ((leftShoulder.y + rightShoulder.y) / 2) / imageSize.height;

      final baseline = CalibrationBaseline(
        bodyHeightPx: bodyHeightPx,
        shoulderWidthPx: shoulderWidthPx,
        hipCenterY: hipCenterY,
        shoulderCenterY: shoulderCenterY,
        imageSize: imageSize,
      );

      return CalibrationResult(
        status: CalibrationStatus.locked,
        progress: 1.0,
        instruction: 'TARGET LOCKED',
        baseline: baseline,
      );
    }

    // Still accumulating stable frames
    return CalibrationResult(
      status: CalibrationStatus.holdStill,
      progress: progress,
      instruction: 'HOLD STILL...',
    );
  }
}
