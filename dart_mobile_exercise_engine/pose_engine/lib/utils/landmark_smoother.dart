import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

/// One Euro Filter for smoothing landmark coordinates.
///
/// This filter adapts its cutoff frequency based on the speed of movement:
/// - Slow movements → heavy smoothing (removes jitter)
/// - Fast movements → light smoothing (preserves responsiveness)
///
/// Reference: https://cristal.univ-lille.fr/~casiez/1euro/
class _OneEuroFilter {
  final double _minCutoff;
  final double _beta;
  final double _dCutoff;

  double? _xPrev;
  double? _dxPrev;
  DateTime? _tPrev;

  _OneEuroFilter({
    double minCutoff = 1.0,
    double beta = 0.007,
    double dCutoff = 1.0,
  })  : _minCutoff = minCutoff,
        _beta = beta,
        _dCutoff = dCutoff;

  double _smoothingFactor(double cutoff, double dt) {
    final r = 2 * 3.141592653589793 * cutoff * dt;
    return r / (r + 1);
  }

  double _exponentialSmoothing(double alpha, double x, double xPrev) {
    return alpha * x + (1 - alpha) * xPrev;
  }

  double filter(double x, {DateTime? timestamp}) {
    final now = timestamp ?? DateTime.now();

    if (_tPrev == null || _xPrev == null) {
      _xPrev = x;
      _dxPrev = 0.0;
      _tPrev = now;
      return x;
    }

    final dt = now.difference(_tPrev!).inMicroseconds / 1000000.0;
    if (dt <= 0) return _xPrev!;

    _tPrev = now;

    // Estimate derivative
    final dx = (x - _xPrev!) / dt;
    final edAlpha = _smoothingFactor(_dCutoff, dt);
    final dxSmoothed = _exponentialSmoothing(edAlpha, dx, _dxPrev ?? 0.0);
    _dxPrev = dxSmoothed;

    // Adaptive cutoff based on speed of movement
    final cutoff = _minCutoff + _beta * dxSmoothed.abs();
    final alpha = _smoothingFactor(cutoff, dt);

    final xSmoothed = _exponentialSmoothing(alpha, x, _xPrev!);
    _xPrev = xSmoothed;

    return xSmoothed;
  }

  void reset() {
    _xPrev = null;
    _dxPrev = null;
    _tPrev = null;
  }
}

/// Smooths all 33 ML Kit pose landmarks using paired One Euro Filters (x, y).
///
/// Usage:
///   final smoother = LandmarkSmoother();
///   final smoothed = smoother.smooth(rawLandmarks);
class LandmarkSmoother {
  final Map<PoseLandmarkType, _OneEuroFilter> _xFilters = {};
  final Map<PoseLandmarkType, _OneEuroFilter> _yFilters = {};

  /// Minimum confidence for ML Kit. Landmarks below this are dropped entirely.
  static const double likelihoodThreshold = 0.65;

  /// Tuning parameters — adjust these if needed:
  /// - minCutoff: lower = smoother but more laggy (default 1.7 is good for fitness)
  /// - beta: higher = faster response to quick movements (default 0.01)
  final double _minCutoff;
  final double _beta;

  LandmarkSmoother({double minCutoff = 1.7, double beta = 0.01})
      : _minCutoff = minCutoff,
        _beta = beta;

  /// Takes raw ML Kit landmarks and returns smoothed + filtered landmarks.
  ///
  /// - Landmarks with likelihood < [likelihoodThreshold] are REMOVED.
  /// - Remaining landmarks are passed through a One Euro Filter per axis.
  Map<PoseLandmarkType, PoseLandmark> smooth(
    Map<PoseLandmarkType, PoseLandmark> raw,
  ) {
    final now = DateTime.now();
    final smoothed = <PoseLandmarkType, PoseLandmark>{};

    for (final entry in raw.entries) {
      final type = entry.key;
      final lm = entry.value;

      // ─── Fix #1: Likelihood filtering ───
      if (lm.likelihood < likelihoodThreshold) {
        continue; // Skip uncertain landmarks entirely
      }

      // Lazily create filters for each landmark type
      _xFilters.putIfAbsent(
        type,
        () => _OneEuroFilter(minCutoff: _minCutoff, beta: _beta),
      );
      _yFilters.putIfAbsent(
        type,
        () => _OneEuroFilter(minCutoff: _minCutoff, beta: _beta),
      );

      // ─── Fix #2: Temporal smoothing ───
      final sx = _xFilters[type]!.filter(lm.x, timestamp: now);
      final sy = _yFilters[type]!.filter(lm.y, timestamp: now);

      // Create a new PoseLandmark with smoothed coordinates
      smoothed[type] = PoseLandmark(
        type: type,
        x: sx,
        y: sy,
        z: lm.z,
        likelihood: lm.likelihood,
      );
    }

    return smoothed;
  }

  /// Reset all filter state (call when starting a new workout).
  void reset() {
    _xFilters.values.forEach((f) => f.reset());
    _yFilters.values.forEach((f) => f.reset());
  }
}
