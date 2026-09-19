// pose_engine — Standalone Detection Engine Test
//
// This is the Flutter equivalent of hunterS-eye's `example_test.py`: it lets
// a developer test the open-source detection engine directly, with no app,
// no gamification, no auth — just camera in, rep count + feedback out.
//
// Flutter has no headless "just open a webcam window" option the way
// `cv2.VideoCapture(0)` does, so this takes the form of a minimal one-screen
// app instead of a bare script — same spirit, same "hardcoded exercise for
// testing" idea as the Python version.
//
// Run with: flutter run (inside this example/ folder)

import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:pose_engine/pose_engine.dart';

void main() {
  runApp(const PoseEngineTestApp());
}

class PoseEngineTestApp extends StatelessWidget {
  const PoseEngineTestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'pose_engine — Standalone Test',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        colorSchemeSeed: const Color(0xFF00D4FF),
      ),
      home: const EngineTestScreen(),
    );
  }
}

/// --- Pose Engine Test Started ---
/// Current Exercise: Push-up (Hardcoded for test)
///
/// Change [_exerciseType] below to test a different detector — every value
/// in ExerciseTypes is wired up in pose_detector_service.dart's
/// _createDetector() switch.
const String _exerciseType = ExerciseTypes.pushups;

class EngineTestScreen extends StatefulWidget {
  const EngineTestScreen({super.key});

  @override
  State<EngineTestScreen> createState() => _EngineTestScreenState();
}

class _EngineTestScreenState extends State<EngineTestScreen> {
  final PoseDetectorService _service = PoseDetectorService();

  bool _ready = false;
  String? _error;

  // Calibration state (the engine requires this before it starts counting reps)
  CalibrationStatus _calStatus = CalibrationStatus.scanning;
  String _calInstruction = 'POSITION YOURSELF IN FRAME';
  bool _calibrated = false;

  // Live exercise state — this is the direct equivalent of the Python
  // script's (rep_complete, feedback, count) tuple from process_frame().
  int _reps = 0;
  String _feedback = '';

  final bool _isGroundExercise = false; // push-ups are ground exercises on
  // mobile (landscape) but we keep this false here for the simplest possible
  // standing-camera test setup. Flip to ExerciseTypes.isGroundExercise(_exerciseType)
  // to test ground exercises with the phone propped in landscape.

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      await _service.initialize(_exerciseType, isLandscape: _isGroundExercise);

      // Calibration frames + landmarks both arrive on these streams.
      _service.calibrationStream.listen((result) {
        if (!mounted) return;
        setState(() {
          _calStatus = result.status;
          _calInstruction = result.instruction;
        });

        if (result.status == CalibrationStatus.locked && result.baseline != null) {
          _service.lockCalibration(result.baseline!);
          setState(() => _calibrated = true);
        }
      });

      _service.poseStream.listen((frame) {
        if (!mounted || !_calibrated) return;
        setState(() {
          _feedback = frame.feedback;
          _reps = frame.repCount;
        });
      });

      _service.startDetection();

      setState(() => _ready = true);
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: _error != null
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Camera error: $_error',
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            : !_ready
                ? const Center(child: CircularProgressIndicator())
                : Stack(
                    fit: StackFit.expand,
                    children: [
                      CameraPreview(_service.cameraController!),
                      _buildOverlay(),
                    ],
                  ),
      ),
    );
  }

  Widget _buildOverlay() {
    return Positioned(
      top: 16,
      left: 16,
      right: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _pill('EXERCISE: $_exerciseType'),
          const SizedBox(height: 8),
          if (!_calibrated) ...[
            _pill('CALIBRATION: ${_calStatus.name}'),
            const SizedBox(height: 4),
            _pill(_calInstruction),
          ] else ...[
            _pill('Reps: $_reps'),
            const SizedBox(height: 4),
            _pill('Feedback: $_feedback'),
          ],
        ],
      ),
    );
  }

  Widget _pill(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(160),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Color(0xFF00D4FF), fontSize: 14, fontWeight: FontWeight.bold),
      ),
    );
  }
}
