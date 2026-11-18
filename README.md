# 🎮 Hunter's Eye (Project: Shadow)

> **"Arise."** Stop working out in the dark. Turn your room into a dungeon and your sweat into XP.

Hunter's Eye is an AI fitness coach inspired by the *Solo Leveling* universe. It uses real-time computer vision to watch your form, count your reps, and rank you from **E** to **S** as you level up in real life.

It exists in two versions that share the same ideas:

| Version | Stack | Pose engine | Status |
|---|---|---|---|
| **Desktop** | Python, MediaPipe, OpenCV | [`pose_detector.py`](pose_detector.py) | Released, see [Releases](https://github.com/Sharkolle/hunterS-eye/releases) |
| **Mobile** (Android / iOS) | Flutter, Google ML Kit | [`dart_mobile_exercise_engine/pose_engine`](dart_mobile_exercise_engine/pose_engine) | In active development |

---

## 🏗️ Architecture: The "Open Core" Model

To balance user trust with the game experience, the project is split into two parts.

### 🔓 Open source (the engine)

Everything that looks at your camera and decides what your body is doing is open for audit and improvement:

**Desktop (Python)**
- **`pose_detector.py`**: landmark extraction and rep counting.
- **`system_utils.py`**: hardware profiling that scales the model to your CPU/GPU.
- **`exercise_categories.py`**: metadata for the workout library.

**Mobile (Dart / Flutter)**
- **`dart_mobile_exercise_engine/pose_engine`**: the mobile detectors. See [Mobile pose engine](#-mobile-pose-engine) below.

### 🔒 Closed source (the game)

The gamification layer is kept private: XP curves and rank-up logic, the shareable Hunter Card, and the account and leaderboard code.

---

## ✨ Key Features

- **Real-time pose estimation:** 33 body landmarks tracked from a normal camera. No wearables, no manual counting.
- **12 exercises** on mobile, in four categories: upper body, core, lower body and cardio.
- **Calibration before every exercise:** the app checks that you are fully in frame, at a usable distance and standing still before counting starts.
- **Form checks:** position gates stop push-ups and tricep dips from counting when you aren't actually in position.
- **Hunter progression:** earn XP, climb ranks E → D → C → B → A → S, complete daily quests and unlock badges.
- **Privacy-first:** video is processed on your device. Camera frames are never stored or uploaded.

---

## 📱 Mobile pose engine

The mobile app runs on Flutter and uses Google ML Kit's on-device pose detection (33 landmarks). The detection code in [`dart_mobile_exercise_engine/pose_engine`](dart_mobile_exercise_engine/pose_engine) turns raw landmarks into reps and form feedback.

### Pipeline

```
Camera frame
  → ML Kit pose detection        (33 landmarks, every 2nd frame)
  → Landmark smoothing           (drop low-confidence points, One Euro Filter)
  → Calibration detector         (until the user is in position)
  → Exercise detector            (state machine per exercise)
  → Rep count + form feedback
```

- **Smoothing:** landmarks with likelihood below 0.65 are dropped, then each axis of each landmark goes through a One Euro Filter to reduce jitter without adding obvious lag.
- **Calibration:** three gates must pass for about 20 consecutive frames: the key landmarks are visible, the body fills a sensible share of the frame, and the user is holding still.
- **Dominant-side tracking:** in side views the far-side limbs are hidden, so most detectors track only the side facing the camera.
- **Joint angles:** computed with `atan2`, ported from the Python desktop version.

### Detectors

Each exercise has its own detector built on a shared abstract base. A detector takes the current landmarks and image size and returns whether a rep was completed, plus any form feedback.

| Exercise | Camera view | How a rep is detected |
|---|---|---|
| Push-ups | Side | Elbow angle goes up → down → up. Counts only when the body is roughly horizontal. |
| Squats | Front or side | Average knee angle goes up → down → up. |
| Jumping jacks | Front | Together → apart → together, using wrist and ankle spread. |
| Sit-ups | Side | Torso angle (shoulder-hip-knee) goes up → down → up. |
| Lunges | Front (side fallback) | Knees bend, then straighten. |
| Plank | Side | Time-based. Counts seconds held in a straight, level position. |
| Tricep dips | Side | Elbow angle up → down → up, with a hands-behind-hips position gate. |
| Leg raises | Side | Hip angle goes from legs up to legs down. |
| Wall sit | Side | Time-based. Counts seconds with the knees bent in the sitting range. |
| High knees | Front or side | Alternating hip-angle lifts. |
| Burpees | Side or front | Standing → ground → standing, using frame-relative body position. |
| Arm circles | Front | Straight arms, wrists passing above then below shoulder height. |

> **Work in progress:** Burpees, high knees, leg raises, arm circles and wall sit use simple heuristics and are still being tuned. Thresholds are mostly fixed angles and frame fractions today, and calibration data is not yet used to scale them to body size.

### Adding or improving a detector

Good first contributions:

- Tune the thresholds of one of the heuristic detectors listed above.
- Add recorded landmark sequences and tests that check rep counts.
- Add a new exercise by implementing a new detector on the shared base.

See [CONTRIBUTION.md](CONTRIBUTION.md) for how to get started.

---

## 🚀 For developers: testing the desktop engine

If you want to use the Python detection engine in your own project:

1. **Install requirements:**

   ```bash
   pip install opencv-python mediapipe numpy customtkinter
   ```

2. Look at [`example_test.py`](example_test.py) for a minimal usage example, and [`pose_detector.md`](pose_detector.md) for how the detector works.

---

## ⚖️ License & contributions

The open core of this project is licensed under the MIT License. Contributions to the pose detection logic, on desktop or mobile, are welcome. See [CONTRIBUTION.md](CONTRIBUTION.md) for details.

*Hunter's Eye is a fan-inspired project and is not affiliated with or endorsed by the creators of Solo Leveling.*
