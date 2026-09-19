# Contributing to pose_engine

Thanks for wanting to improve Hunter's Eye's detection engine.

## Scope

This package is the detection engine only: camera → ML Kit → rep counting →
calibration. It intentionally contains **no** gamification, auth, or
networking code, and PRs adding any of that will be redirected back to the
private app repo instead.

## Good first contributions

- Improving an existing detector's angle thresholds or feedback strings
- Adding a new exercise detector (see `detectors/pushup_detector.dart` as a
  template — extend `ExerciseDetector`, implement `detect()`)
- Improving `CalibrationDetector`'s gates for edge cases (poor lighting,
  partial occlusion, non-standard camera placement)
- Tuning `LandmarkSmoother`'s One Euro Filter parameters

## Guidelines

1. Every detector must remain a pure function of `(landmarks, imageSize)` →
   `DetectionResult` plus its own `stage`/`repCount` state — no I/O, no
   platform channels, no external service calls.
2. Keep exercise metadata changes in `exercise_database.dart` separate from
   detection-logic changes in `detectors/`.
3. Add or update tests alongside any threshold changes so regressions in rep
   accuracy are caught automatically.
4. Open an issue describing the exercise/form problem before submitting a
   large detector rewrite, so we can agree on the approach first.

## License

By contributing, you agree your contributions are licensed under this
package's MIT License.
