import 'dart:math';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

/// Utility class for calculating angles between body landmarks.
/// Ported from Python's PoseDetector.calculate_angle()
class AngleCalculator {
  /// Calculate the angle (in degrees) at point [b] formed by points [a]-[b]-[c].
  ///
  /// Uses atan2 to compute the angle, returns a value between 0° and 180°.
  /// This is the exact same math as the Python desktop version.
  static double calculateAngle(Point a, Point b, Point c) {
    final radians = atan2(c.y - b.y, c.x - b.x) - atan2(a.y - b.y, a.x - b.x);
    double angle = (radians * 180.0 / pi).abs();

    if (angle > 180.0) {
      angle = 360.0 - angle;
    }

    return angle;
  }

  /// Convert a PoseLandmark to a simple Point (x, y) for angle calculations.
  static Point landmarkToPoint(PoseLandmark landmark) {
    return Point(landmark.x, landmark.y);
  }

  /// Calculate angle between three PoseLandmarks directly.
  static double angleBetweenLandmarks(
    PoseLandmark a,
    PoseLandmark b,
    PoseLandmark c,
  ) {
    return calculateAngle(
      landmarkToPoint(a),
      landmarkToPoint(b),
      landmarkToPoint(c),
    );
  }
}

/// Simple 2D point for angle calculations.
class Point {
  final double x;
  final double y;

  const Point(this.x, this.y);
}
