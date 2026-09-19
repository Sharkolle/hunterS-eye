import 'dart:ui';

/// Immutable snapshot of the user's body metrics captured at calibration time.
/// Once "TARGET LOCKED" fires, this object is passed to the exercise detector
/// so all thresholds are normalized to the actual user's body proportions
/// regardless of height or camera distance.
class CalibrationBaseline {
  /// Pixel distance from nose to ankle in the camera frame.
  /// This is the normalizing unit for all vertical thresholds.
  final double bodyHeightPx;

  /// Pixel distance between the two shoulder landmarks.
  /// Used to normalize lateral/width-based thresholds.
  final double shoulderWidthPx;

  /// Normalized Y-position of the hip midpoint (0.0 top → 1.0 bottom).
  /// Used as the anchor for squat and lunge depth measurements.
  final double hipCenterY;

  /// Normalized Y-position of the shoulder midpoint.
  /// Used for push-up and upper-body exercise anchoring.
  final double shoulderCenterY;

  /// The camera frame size at the moment of calibration.
  /// Detectors use this to convert normalized values back to pixel space.
  final Size imageSize;

  const CalibrationBaseline({
    required this.bodyHeightPx,
    required this.shoulderWidthPx,
    required this.hipCenterY,
    required this.shoulderCenterY,
    required this.imageSize,
  });

  /// Convenience: body height as a fraction of the image height.
  double get bodyFillRatio => bodyHeightPx / imageSize.height;

  /// Converts a normalized Y fraction to an absolute pixel Y in the frame.
  double normalizedToPixelY(double normalizedY) => normalizedY * imageSize.height;

  /// Converts a normalized X fraction to an absolute pixel X in the frame.
  double normalizedToPixelX(double normalizedX) => normalizedX * imageSize.width;

  @override
  String toString() =>
      'CalibrationBaseline(bodyH=${bodyHeightPx.toStringAsFixed(1)}px, '
      'fill=${(bodyFillRatio * 100).toStringAsFixed(1)}%, '
      'shoulderW=${shoulderWidthPx.toStringAsFixed(1)}px)';
}
