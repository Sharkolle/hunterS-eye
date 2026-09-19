/// pose_engine — Hunter's Eye's open-source pose detection engine.
///
/// Mirrors hunterS-eye's pose_detector.py + system_utils.py +
/// exercise_categories.py "Open Core" on the mobile side.
///
/// Import this single file to get everything: detectors, calibration,
/// the camera/ML Kit orchestration service, and exercise metadata.
library pose_engine;

// Core contracts
export 'exercise_detector.dart';
export 'calibration_detector.dart';
export 'pose_detector_service.dart';

// Metadata (equivalent of exercise_categories.py)
export 'exercise_database.dart';

// Models
export 'models/calibration_baseline.dart';

// Utils
export 'utils/angle_calculator.dart';
export 'utils/landmark_smoother.dart';

// Detectors (equivalent of each detect_*() in pose_detector.py)
export 'detectors/pushup_detector.dart';
export 'detectors/squat_detector.dart';
export 'detectors/jumping_jack_detector.dart';
export 'detectors/situp_detector.dart';
export 'detectors/lunge_detector.dart';
export 'detectors/plank_detector.dart';
export 'detectors/high_knees_detector.dart';
export 'detectors/burpee_detector.dart';
export 'detectors/wall_sit_detector.dart';
export 'detectors/leg_raise_detector.dart';
export 'detectors/tricep_dip_detector.dart';
export 'detectors/arm_circle_detector.dart';
