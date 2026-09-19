# 🎮 pose_engine — Hunter's Eye Mobile Detection Engine

> The mobile counterpart of [`hunterS-eye`](https://github.com/Sharkolle/hunterS-eye)'s `pose_detector.py`.

This package is the "Open Core" of the Hunter's Eye Flutter app: the camera →
ML Kit → rep-counting pipeline, extracted into its own package so it can be
audited, reused, and improved independently of the app's gamification layer.

---

## 🏗️ Architecture: The "Open Core" Model

Just like the desktop project, Hunter's Eye Mobile is split into two parts:

### 🔓 Open Source (this package)

- **`exercise_detector.dart`** — abstract base class + `DetectionResult`, the
  equivalent of `pose_detector.py`'s per-frame `detect_*()` contract.
- **`detectors/*.dart`** — one file per exercise, each a direct port of the
  matching `detect_*()` method:

  | Python | Dart |
  |---|---|
  | `detect_pushup` | `pushup_detector.dart` |
  | `detect_squat` | `squat_detector.dart` |
  | `detect_jumping_jack` | `jumping_jack_detector.dart` |
  | `detect_situp` | `situp_detector.dart` |
  | `detect_lunge` | `lunge_detector.dart` |
  | `detect_plank` | `plank_detector.dart` |
  | `detect_high_knees` | `high_knees_detector.dart` |
  | `detect_tricep_dip` | `tricep_dip_detector.dart` |
  | `detect_burpee` | `burpee_detector.dart` |
  | `detect_leg_raise` | `leg_raise_detector.dart` |
  | `detect_wall_sit` | `wall_sit_detector.dart` |
  | `detect_arm_circles` | `arm_circle_detector.dart` |

- **`utils/angle_calculator.dart`** — identical math to `calculate_angle()`.
- **`utils/landmark_smoother.dart`** — One Euro Filter temporal smoothing +
  likelihood filtering. Mobile-only; compensates for the noisier phone-camera
  signal that a fixed desktop webcam doesn't need.
- **`calibration_detector.dart`** / **`models/calibration_baseline.dart`** —
  body-proportional calibration (3-gate: visibility → frame fill → stability).
  Mobile-only, in the same spirit as `system_utils.py`'s hardware scaling:
  it makes thresholds work regardless of device/user body size.
- **`pose_detector_service.dart`** — camera + ML Kit orchestration, the
  equivalent role to the `PoseDetector` class and its `process_frame()` loop.
- **`exercise_database.dart`** — exercise metadata (names, how-to steps, tips,
  camera position, unlock level). Equivalent of `exercise_categories.py`.

### 🔒 Closed Source (stays in the main app)

XP curves, level thresholds, rank-up logic, quests, badges, auth, and cloud
sync are **not** in this package — same boundary as `gamification.py`,
`card_generator.py`, and `auth_system.py`/`cloud_sync.py` on desktop.

---

## 🚀 Using this package

```yaml
dependencies:
  pose_engine:
    path: packages/pose_engine   # or a git/pub.dev reference once published
```

```dart
import 'package:pose_engine/pose_engine.dart';

final service = PoseDetectorService();
await service.initialize(ExerciseTypes.pushups);
service.startDetection();

service.poseStream.listen((frame) {
  // frame.landmarks, frame.feedback, frame.repComplete, frame.repCount
});
```

---

## ⚖️ License & Contributions

Licensed under the MIT License. Contributions to detector accuracy, new
exercises, or calibration robustness are welcome — see `CONTRIBUTING.md`.
