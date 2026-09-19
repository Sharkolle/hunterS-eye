/// Pose Engine - Exercise Metadata & Database
///
/// This is the mobile equivalent of the desktop project's
/// `exercise_categories.py` — pure workout-library metadata, with zero
/// gamification (XP/levels/badges) mixed in. That logic stays in the
/// private app.
library;

import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────
// EXERCISE INFO MODEL
// ─────────────────────────────────────────────────────────────

class ExerciseInfo {
  final String id;
  final String displayName;
  final int requiredLevel;
  final String description;
  final List<String> muscleGroups;
  final String difficulty;
  final String cameraPosition;
  final List<String> howTo;
  final List<String> tips;
  final String? gifAsset; // null = no GIF available
  final String icon;
  final bool isTimeBased; // true for plank/wall-sit (seconds), false for reps
  final bool isGroundExercise; // true for exercises performed on the floor

  const ExerciseInfo({
    required this.id,
    required this.displayName,
    required this.requiredLevel,
    required this.description,
    required this.muscleGroups,
    required this.difficulty,
    required this.cameraPosition,
    required this.howTo,
    required this.tips,
    this.gifAsset,
    required this.icon,
    this.isTimeBased = false,
    this.isGroundExercise = false,
  });
}

class ExerciseCategory {
  final String name;
  final String emoji;
  final Color color;
  final List<ExerciseInfo> exercises;

  const ExerciseCategory({
    required this.name,
    required this.emoji,
    required this.color,
    required this.exercises,
  });
}

// ─────────────────────────────────────────────────────────────
// EXERCISE TYPES (string IDs — used as keys everywhere)
// ─────────────────────────────────────────────────────────────

class ExerciseTypes {
  static const String pushups = 'pushups';
  static const String squats = 'squats';
  static const String jumpingJacks = 'jumping_jacks';
  static const String situps = 'situps';
  static const String lunges = 'lunges';
  static const String planks = 'planks';

  // Phase 2 exercises (adding later)
  static const String tricepDips = 'tricep_dips';
  static const String legRaises = 'leg_raises';
  static const String wallSit = 'wall_sit';
  static const String highKnees = 'high_knees';
  static const String burpees = 'burpees';
  static const String armCircles = 'arm_circles';

  // Warmup-only
  static const String torsoTwist = 'torso_twist';

  static const List<String> mainExercises = [
    pushups, squats, jumpingJacks, situps, lunges, planks,
    tricepDips, legRaises, wallSit, highKnees, burpees, armCircles,
  ];

  static const List<String> warmupExercises = [
    armCircles, highKnees, torsoTwist,
  ];

  static const List<String> all = mainExercises;

  static String getDisplayName(String type) {
    final info = ExerciseDatabase.getExerciseById(type);
    if (info != null) return info.displayName;
    switch (type) {
      case torsoTwist: return 'Torso Twist';
      default: return type;
    }
  }

  static String getIcon(String type) {
    final info = ExerciseDatabase.getExerciseById(type);
    if (info != null) return info.icon;
    switch (type) {
      case torsoTwist: return '🌀';
      default: return '🏋️';
    }
  }

  static bool isGroundExercise(String type) {
    final info = ExerciseDatabase.getExerciseById(type);
    return info?.isGroundExercise ?? false;
  }
}

// ─────────────────────────────────────────────────────────────
// EXERCISE DATABASE (ported from Python exercise_categories.py)
// ─────────────────────────────────────────────────────────────

class ExerciseDatabase {
  static final List<ExerciseCategory> categories = [
    // ───── UPPER BODY ─────
    ExerciseCategory(
      name: 'UPPER BODY',
      emoji: '💪',
      color: const Color(0xFFFF6B6B),
      exercises: [
        const ExerciseInfo(
          id: ExerciseTypes.pushups,
          displayName: 'Push-ups',
          requiredLevel: 1,
          description: 'Classic upper body strength',
          muscleGroups: ['Chest', 'Triceps', 'Shoulders'],
          difficulty: 'Medium',
          cameraPosition: 'SIDE VIEW',
          icon: '💪',
          gifAsset: 'assets/gifs/push-up.gif',
          isGroundExercise: true,
          howTo: [
            'Start in a high plank — hands shoulder-width apart, body in a straight line from head to heels.',
            'Lower your chest toward the floor by bending both elbows evenly.',
            'Stop when your chest is about 2-3 cm from the floor (or as low as you can).',
            'Push through your palms to straighten your arms back to the start.',
            'Keep your core tight and hips level throughout — no sagging or piking.',
          ],
          tips: [
            'Squeeze your glutes to keep your hips from dropping.',
            'Elbows should flare about 45° from your body — not straight out.',
            'Look slightly forward, not straight down, to keep your neck neutral.',
            'If full push-ups are too hard, drop to your knees to build strength first.',
          ],
        ),
        const ExerciseInfo(
          id: ExerciseTypes.tricepDips,
          displayName: 'Tricep Dips',
          requiredLevel: 2,
          description: 'Isolate and strengthen triceps',
          muscleGroups: ['Triceps', 'Shoulders'],
          difficulty: 'Medium',
          cameraPosition: 'SIDE VIEW',
          icon: '🦾',
          gifAsset: 'assets/gifs/push-up.gif', // Placeholder
          isGroundExercise: true,
          howTo: [
            'Sit on the floor with knees bent and feet flat.',
            'Place hands behind you with fingers pointing toward your feet.',
            'Lift your hips off the floor.',
            'Bend your elbows to lower your body, then push back up.',
          ],
          tips: ['Keep your chest up and shoulders pulled back.'],
        ),
        const ExerciseInfo(
          id: ExerciseTypes.armCircles,
          displayName: 'Arm Circles',
          requiredLevel: 1,
          description: 'Shoulder mobility and warmup',
          muscleGroups: ['Shoulders', 'Upper Back'],
          difficulty: 'Easy',
          cameraPosition: 'FRONT VIEW',
          icon: '🔄',
          gifAsset: 'assets/gifs/push-up.gif', // Placeholder
          isGroundExercise: false,
          howTo: [
            'Stand with arms extended straight out to your sides.',
            'Make small circular motions with your hands.',
            'Gradually increase the size of the circles.',
          ],
          tips: ['Keep your core tight and maintain a straight posture.'],
        ),
      ],
    ),

    // ───── CORE / ABS ─────
    ExerciseCategory(
      name: 'CORE / ABS',
      emoji: '🔥',
      color: const Color(0xFFFFD700),
      exercises: [
        const ExerciseInfo(
          id: ExerciseTypes.situps,
          displayName: 'Sit-ups',
          requiredLevel: 1,
          description: 'Core strength fundamental',
          muscleGroups: ['Abs', 'Hip Flexors'],
          difficulty: 'Medium',
          cameraPosition: 'SIDE VIEW',
          icon: '🔥',
          gifAsset: 'assets/gifs/sit-up.gif',
          isGroundExercise: true,
          howTo: [
            'Lie on your back with knees bent at roughly 90° and feet flat on the floor.',
            'Cross your arms over your chest or place your hands lightly behind your head.',
            'Engage your core and curl your torso up toward your knees.',
            'Rise until your elbows (or chest) touch or pass your knees.',
            'Slowly lower back down until your shoulder blades touch the floor.',
          ],
          tips: [
            "Don't pull on your neck — let your abs do the work.",
            'Exhale as you rise, inhale as you lower.',
            'Keep your feet planted; anchor them under a sofa if needed.',
            'Full range of motion = full shoulder blade contact on the way down.',
          ],
        ),
        const ExerciseInfo(
          id: ExerciseTypes.planks,
          displayName: 'Plank',
          requiredLevel: 1,
          description: 'Total core stability',
          muscleGroups: ['Core', 'Shoulders', 'Glutes'],
          difficulty: 'Hard',
          cameraPosition: 'SIDE VIEW',
          icon: '⏱️',
          isTimeBased: true,
          isGroundExercise: true,
          gifAsset: 'assets/gifs/plank.png',
          howTo: [
            'Place your forearms on the floor, elbows directly below your shoulders.',
            'Extend your legs behind you, balancing on your toes.',
            'Create a straight line from your head through your heels — no sagging or piking.',
            'Brace your core as if you\'re about to take a punch to the stomach.',
            'Hold the position and breathe steadily. The AI tracks your hold time.',
          ],
          tips: [
            'Squeeze your glutes hard — it locks your hips in place.',
            'Push your forearms into the floor to engage your lats and keep shoulders stable.',
            'Look at a spot on the floor slightly in front of your hands to keep your neck neutral.',
            'If your hips drop, reset — a 20-second perfect plank beats a 60-second sloppy one.',
          ],
        ),
        const ExerciseInfo(
          id: ExerciseTypes.legRaises,
          displayName: 'Leg Raises',
          requiredLevel: 2,
          description: 'Lower abs targeting',
          muscleGroups: ['Abs', 'Hip Flexors'],
          difficulty: 'Medium',
          cameraPosition: 'SIDE VIEW',
          icon: '📐',
          gifAsset: 'assets/gifs/sit-up.gif', // Placeholder
          isGroundExercise: true,
          howTo: [
            'Lie flat on your back, legs straight and together.',
            'Keep your legs straight and lift them all the way up to the ceiling until your butt comes off the floor.',
            'Slowly lower your legs back down till they\'re just above the floor. Hold for a moment.',
            'Raise your legs back up. Repeat.',
          ],
          tips: ['Press your lower back into the floor.'],
        ),
      ],
    ),

    // ───── LOWER BODY ─────
    ExerciseCategory(
      name: 'LOWER BODY',
      emoji: '🦵',
      color: const Color(0xFF4ECDC4),
      exercises: [
        const ExerciseInfo(
          id: ExerciseTypes.squats,
          displayName: 'Squats',
          requiredLevel: 1,
          description: 'Leg strength powerhouse',
          muscleGroups: ['Quads', 'Glutes', 'Hamstrings'],
          difficulty: 'Medium',
          cameraPosition: 'FRONT or SIDE VIEW',
          icon: '🦵',
          gifAsset: 'assets/gifs/squat.gif',
          howTo: [
            'Stand with feet shoulder-width apart, toes pointing slightly outward.',
            'Keep your chest tall and core braced.',
            'Bend your knees and push your hips back as if sitting into a chair.',
            'Lower until your thighs are at least parallel to the floor (or as low as comfortable).',
            'Drive through your heels to stand back up to the starting position.',
          ],
          tips: [
            "Keep your knees tracking over your toes — don't let them cave inward.",
            'Your weight should be in your heels, not your toes.',
            "Keep your chest upright — don't let your torso collapse forward.",
            'Full depth builds more muscle — aim to break parallel with your thighs.',
          ],
        ),
        const ExerciseInfo(
          id: ExerciseTypes.lunges,
          displayName: 'Lunges',
          requiredLevel: 1,
          description: 'Unilateral leg developer',
          muscleGroups: ['Quads', 'Glutes', 'Balance'],
          difficulty: 'Medium',
          cameraPosition: 'FRONT VIEW',
          icon: '🏃',
          gifAsset: 'assets/gifs/lunge.gif',
          howTo: [
            'Stand tall with feet together, hands on hips or by your sides.',
            'Step one foot forward about 60–90 cm, landing heel first.',
            'Lower your back knee toward the floor until both knees are at roughly 90°.',
            'Your front knee should stay directly above your front ankle — not past your toes.',
            'Push off your front heel to step back to the start, then alternate legs.',
          ],
          tips: [
            "Keep your torso upright — don't lean forward over your front leg.",
            'The longer your step, the more glute activation. Shorter = more quad.',
            "Control the drop — don't let your back knee crash into the floor.",
            'Focus on a point in front of you to help with balance.',
          ],
        ),
        const ExerciseInfo(
          id: ExerciseTypes.wallSit,
          displayName: 'Wall Sit',
          requiredLevel: 2,
          description: 'Quad endurance builder',
          muscleGroups: ['Quads', 'Glutes'],
          difficulty: 'Medium',
          cameraPosition: 'SIDE VIEW',
          icon: '🪑',
          isTimeBased: true,
          gifAsset: 'assets/gifs/squat.gif', // Placeholder
          howTo: [
            'Start with your back against a wall with your feet shoulder width and about 2 feet from the wall.',
            'Engage your abdominal muscles and slowly slide your back down the wall until your thighs are parallel to the ground.',
            'Adjust your feet so your knees are directly above your ankles (rather than over your toes).',
            'Keep your back flat against the wall.',
            'Hold the position and breathe steadily.',
          ],
          tips: ['Keep your weight in your heels.'],
        ),
      ],
    ),

    // ───── CARDIO / FULL BODY ─────
    ExerciseCategory(
      name: 'CARDIO / FULL BODY',
      emoji: '⚡',
      color: const Color(0xFF45B7D1),
      exercises: [
        const ExerciseInfo(
          id: ExerciseTypes.jumpingJacks,
          displayName: 'Jumping Jacks',
          requiredLevel: 1,
          description: 'Full body warmup & cardio',
          muscleGroups: ['Full Body', 'Cardiovascular'],
          difficulty: 'Easy',
          cameraPosition: 'FRONT VIEW',
          icon: '⭐',
          gifAsset: 'assets/gifs/jumping-jack.gif',
          howTo: [
            'Stand tall with feet together and arms by your sides.',
            'Jump and simultaneously spread your feet wider than shoulder-width.',
            'As your feet spread, raise both arms overhead until your hands nearly meet.',
            'Jump again to bring your feet back together and lower your arms to your sides.',
            "That's one rep. Keep a steady rhythm and maintain a soft bend in the knees.",
          ],
          tips: [
            'Land softly on the balls of your feet to protect your knees.',
            "Keep your core engaged so your back doesn't arch as arms go up.",
            'Use a consistent pace — quality rhythm beats sloppy speed.',
            'Great as a warm-up: 2–3 minutes gets your heart rate up fast.',
          ],
        ),
        const ExerciseInfo(
          id: ExerciseTypes.highKnees,
          displayName: 'High Knees',
          requiredLevel: 2,
          description: 'Explosive cardio burst',
          muscleGroups: ['Cardio', 'Legs', 'Core'],
          difficulty: 'Medium',
          cameraPosition: 'SIDE or FRONT VIEW',
          icon: '🏃',
          gifAsset: 'assets/gifs/jumping-jack.gif', // Placeholder
          howTo: [
            'Stand with feet hip-width apart. Look straight ahead and keep your chest up.',
            'Jump from one foot to the other at the same time lifting your knees as high as possible, hip height is advisable.',
            'Your arms should follow the motion.',
            'Touch the ground with the balls of your feet.',
          ],
          tips: ['Keep your core tight and your back straight.'],
        ),
        const ExerciseInfo(
          id: ExerciseTypes.burpees,
          displayName: 'Burpees',
          requiredLevel: 3,
          description: 'Ultimate full-body challenge',
          muscleGroups: ['Full Body', 'Cardio'],
          difficulty: 'Hard',
          cameraPosition: 'SIDE VIEW',
          icon: '🔥',
          gifAsset: 'assets/gifs/jumping-jack.gif', // Placeholder
          howTo: [
            'Stand with your feet shoulder-width apart, weight in your heels, and your arms at your sides.',
            'Push your hips back, bend your knees, and lower your body into a squat.',
            'Place your hands on the floor directly in front of, and just inside, your feet.',
            'Shift your weight onto your hands.',
            'Jump your feet back to softly land on the balls of your feet in a plank position.',
            'Jump your feet back so that they land just outside of your hands.',
            'Reach your arms over head and explosively jump up into the air.',
            'Land and immediately lower back into a squat for your next rep.',
          ],
          tips: ['Don\'t let your back sag during the plank phase.'],
        ),
      ],
    ),
  ];

  /// Get ExerciseInfo by ID
  static ExerciseInfo? getExerciseById(String id) {
    for (final category in categories) {
      for (final exercise in category.exercises) {
        if (exercise.id == id) return exercise;
      }
    }
    return null;
  }

  /// Get all unlocked exercises at a given level
  static List<ExerciseInfo> getAvailableExercises(int userLevel) {
    final List<ExerciseInfo> available = [];
    for (final category in categories) {
      for (final exercise in category.exercises) {
        if (userLevel >= exercise.requiredLevel) {
          available.add(exercise);
        }
      }
    }
    return available;
  }

  /// Get the category that contains a given exercise ID
  static ExerciseCategory? getCategoryForExercise(String id) {
    for (final category in categories) {
      for (final exercise in category.exercises) {
        if (exercise.id == id) return category;
      }
    }
    return null;
  }
}
