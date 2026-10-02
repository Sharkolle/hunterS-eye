# 🎮 Hunter's Eye (Project: Shadow)

> **"Arise."** Stop working out in the dark. Turn your room into a dungeon and your sweat into XP.

Huntery's Eye is a professional-grade AI fitness coach inspired by the *Solo Leveling* universe. It uses real-time computer vision to monitor your form, count your reps, and rank you from an *[...]*

---

## 🏗️ Architecture: The "Open Core" Model

To balance user trust with our unique gamification, this project is split into two parts:

### 🔓 Open Source (The Engine)
We believe AI transparency is a right. The following modules are open-sourced for community audit and improvement:
* **`pose_detector.py`**: The logic for landmark extraction and rep-counting.
* **`system_utils.py`**: Hardware profiling that scales the AI model to your CPU/GPU.
* **`exercise_categories.py`**: The metadata defining our workout library.

### 🔒 Closed Source (The Game)
The proprietary "secret sauce" that makes the app a unique experience remains private:
* **`gamification.py`**: XP curves, level thresholds, and rank-up logic.
* **`card_generator.py`**: The logic that creates your shareable Hunter Card.
* **`auth_system.py` / `cloud_sync.py`**: Security protocols and leaderboard integration.

---

## ✨ Key Features
* **AI Pose Estimation:** Uses MediaPipe to track 33 body landmarks in real-time.
* **Smart Scaling:** Automatically adjusts model complexity based on your hardware (RTX 4090 vs. Laptop CPU).
* **Privacy-First:** All video data is processed locally. We never store or upload your camera feed.
* **Hunter Progression:** Earn XP, unlock badges, and climb the global leaderboards.

---

## 🚀 For Developers: Testing the Engine
If you want to use our detection engine in your own project:

1. **Install Requirements:**
   ```bash
   pip install opencv-python mediapipe numpy customtkinter

**⚖️ License & Contributions**

​The Open Core of this project is licensed under the MIT License. We welcome contributions to the pose_detector.py logic. See CONTRIBUTING.md for details.
