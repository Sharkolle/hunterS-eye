# pose_engine — Standalone Test

The Flutter equivalent of `hunterS-eye`'s `example_test.py`. Lets you test the
detection engine directly — camera in, rep count + feedback out — with no app
shell, no gamification, no auth.

## One-time setup

This folder ships as source only (no `android/`/`ios/` platform folders,
since those are machine-generated). Before first run:

```bash
cd example
flutter create . --platforms=android,ios   # generates android/ and ios/ without touching lib/
flutter pub get
```

Then add camera permissions:

**`android/app/src/main/AndroidManifest.xml`** — inside `<manifest>`:
```xml
<uses-permission android:name="android.permission.CAMERA" />
```

**`ios/Runner/Info.plist`** — inside `<dict>`:
```xml
<key>NSCameraUsageDescription</key>
<string>Used to detect exercise reps.</string>
```

## Run it

```bash
flutter run
```

Current Exercise: **Push-up** (hardcoded in `lib/main.dart`, same as the
Python script's "Current Exercise: Push-up (Hardcoded for test)"). To test a
different detector, change the `_exerciseType` constant at the top of
`main.dart` to any `ExerciseTypes.*` value — it's already wired through
`pose_detector_service.dart`'s detector factory.

## What you'll see

1. **Calibration phase** — stand in frame until "TARGET LOCKED" fires (this
   is `CalibrationDetector`'s 3-gate check: visibility → frame fill →
   stability). This step doesn't exist in the Python engine; it's mobile-only
   because phone camera distance/angle isn't fixed the way a desktop webcam
   is.
2. **Live rep counting** — once locked, the overlay switches to `Reps: N` and
   `Feedback: ...`, updating every processed frame — the direct equivalent of
   the Python script's `cv2.putText` overlay of `count` and `feedback`.

No data leaves the device and nothing is written to disk — this harness
doesn't touch gamification, storage, or network code at all.
