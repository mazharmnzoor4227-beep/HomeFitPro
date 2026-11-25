import '../models/exercise.dart';
import 'exercise_catalog.dart';

enum HomeKit { none, support, bar }

enum HomeGoal { fullBody, upper, lower, core, cardio, mobility }

class HomePlan {
  const HomePlan({
    required this.id,
    required this.goal,
    required this.kit,
    required this.nameKey,
    required this.exerciseIds,
    this.sets = 3,
    this.reps = 12,
    this.restSec = 45,
  });

  final String id;
  final HomeGoal goal;
  final HomeKit kit;
  final String nameKey;
  final List<String> exerciseIds;
  final int sets;
  final int reps;
  final int restSec;
}

const _barNeedles = [
  'pull-up',
  'pull up',
  'chin-up',
  'chin up',
  'hanging',
  'dead hang',
  'active hang',
  'arch hang',
  'muscle-up',
  'parallel bar',
  'chest dip',
  'triceps dip',
  'negative dip',
  'scapula dip',
  'scapular pull',
  'l-sit hold',
  'l-sit pull',
];

const _supportNeedles = [
  'incline push',
  'decline push',
  'feet-elevated',
  'chair dip',
  'bench dip',
  'bench pull',
  'bench hip',
  'bench leg',
  'wall sit',
  'wall push',
  'wall handstand',
  'wall walk',
  'wall calf',
  'doorway',
  'bulgarian',
  'box squat',
  'step-down',
  'pike push',
];

const _cardioNeedles = [
  'burpee',
  'high knees',
  'jumping jack',
  'mountain climber',
  'skater',
  'seal jack',
  'quick feet',
  'lateral shuffle',
  'sprawl',
  'squat thrust',
  'outdoor run',
  'walk',
  'hiking',
  'plank jack',
];

const _mobilityNeedles = ['stretch', 'fold', 'pose', 'cat-cow', 'leg swings', 'wrist prep', 'toe touch'];

const _holdNeedles = ['plank', 'hold', 'wall sit', 'hang', 'hollow body'];

HomeKit homeKitOf(Exercise e) {
  final n = '${e.name} ${e.id}'.toLowerCase().replaceAll('\\', '');
  if (_barNeedles.any(n.contains)) return HomeKit.bar;
  if (_supportNeedles.any(n.contains)) return HomeKit.support;
  return HomeKit.none;
}

bool isHomeExercise(Exercise e) => e.equipment == 'Bodyweight';

bool isHomeHold(Exercise e) {
  final n = e.name.toLowerCase();
  return _holdNeedles.any(n.contains) && !n.contains('push');
}

HomeGoal homeGoalOf(Exercise e) {
  final n = '${e.name} ${e.id}'.toLowerCase();
  if (_mobilityNeedles.any(n.contains)) return HomeGoal.mobility;
  if (_cardioNeedles.any(n.contains)) return HomeGoal.cardio;
  switch (muscleFamily(e.primary)) {
    case 'core':
      return HomeGoal.core;
    case 'legs':
      return HomeGoal.lower;
    default:
      return HomeGoal.upper;
  }
}

List<Exercise> homeExercises({HomeKit? kit, HomeGoal? goal, String? muscle}) {
  var list = kExercises.where(isHomeExercise);
  if (kit != null) list = list.where((e) => homeKitOf(e) == kit);
  if (goal != null) {
    list = list.where((e) {
      if (goal == HomeGoal.fullBody) {
        return homeGoalOf(e) != HomeGoal.mobility;
      }
      return homeGoalOf(e) == goal;
    });
  }
  if (muscle != null && muscle.isNotEmpty) {
    list = list.where((e) => e.primary == muscle || e.secondary.contains(muscle));
  }
  return list.toList();
}

const List<HomePlan> kHomePlans = [
  HomePlan(
    id: 'full-none',
    goal: HomeGoal.fullBody,
    kit: HomeKit.none,
    nameKey: 'homePlanFullBody',
    exerciseIds: [
      'I4hDWkc', // Push-up
      '6YUfHPL', // Bodyweight Squat
      'glute-bridge',
      'plank-hold',
      'superman',
      'mountain-climber',
    ],
  ),
  HomePlan(
    id: 'upper-none',
    goal: HomeGoal.upper,
    kit: HomeKit.none,
    nameKey: 'homePlanUpper',
    exerciseIds: [
      'I4hDWkc',
      'wide-push-up',
      'x6KpKpq', // Close-grip Push-up
      'pike-push-up',
      'prone-t-raise',
      'superman',
    ],
    reps: 10,
  ),
  HomePlan(
    id: 'lower-none',
    goal: HomeGoal.lower,
    kit: HomeKit.none,
    nameKey: 'homePlanLower',
    exerciseIds: [
      '6YUfHPL',
      '9E25EOx', // Split Squats
      'W31mMjd', // Lateral Lunge
      'glute-bridge',
      'donkey-kick',
      'bJYHBIN', // Standing Calf Raise
    ],
  ),
  HomePlan(
    id: 'core-none',
    goal: HomeGoal.core,
    kit: HomeKit.none,
    nameKey: 'homePlanCore',
    exerciseIds: [
      'sit-up',
      'TFqbd8t', // Crunch Floor
      'bicycle-crunch',
      'dead-bug',
      'lying-leg-raise',
      'plank-hold',
      'side-plank-hold',
    ],
    restSec: 30,
  ),
  HomePlan(
    id: 'cardio-none',
    goal: HomeGoal.cardio,
    kit: HomeKit.none,
    nameKey: 'homePlanCardio',
    exerciseIds: ['jumping-jack', 'high-knees', 'mountain-climber', 'skater-hop', 'squat-thrust', 'burpee'],
    sets: 3,
    reps: 20,
    restSec: 30,
  ),
  HomePlan(
    id: 'mobility-none',
    goal: HomeGoal.mobility,
    kit: HomeKit.none,
    nameKey: 'homePlanMobility',
    exerciseIds: [
      'cat-cow-stretch',
      'childs-pose',
      'hamstring-stretch',
      'kneeling-hip-flexor-stretch',
      'butterfly-stretch',
      'worlds-greatest-stretch',
    ],
    sets: 2,
    reps: 8,
    restSec: 20,
  ),
  HomePlan(
    id: 'upper-support',
    goal: HomeGoal.upper,
    kit: HomeKit.support,
    nameKey: 'homePlanUpper',
    exerciseIds: [
      'incline-push-up',
      'decline-push-up',
      'pike-push-up',
      'wall-push-up',
      'chair-dip',
      'I4hDWkc',
    ],
    reps: 10,
  ),
  HomePlan(
    id: 'lower-support',
    goal: HomeGoal.lower,
    kit: HomeKit.support,
    nameKey: 'homePlanLower',
    exerciseIds: [
      'wall-sit',
      'bulgarian-split-squat',
      '6YUfHPL',
      'glute-bridge',
      'iPm26QU', // Step-down
      'bJYHBIN',
    ],
  ),
  HomePlan(
    id: 'upper-bar',
    goal: HomeGoal.upper,
    kit: HomeKit.bar,
    nameKey: 'homePlanUpper',
    exerciseIds: [
      'lBDjFxJ', // Pull-up
      'T2mxWqc', // Chin-up
      '9WTm7dq', // Chest Dip
      'X6C6i5Y', // Triceps Dip
      'I4hDWkc',
      'active-hang',
    ],
    reps: 8,
    restSec: 75,
  ),
  HomePlan(
    id: 'core-bar',
    goal: HomeGoal.core,
    kit: HomeKit.bar,
    nameKey: 'homePlanCore',
    exerciseIds: [
      'QOA0FD0', // Hanging Leg Raise
      'uWpxD4v', // Hanging Knee Raise
      'plank-hold',
      'XVDdcoj', // Russian Twist
      'dead-hang-hold',
      'bicycle-crunch',
    ],
    restSec: 45,
  ),
];

List<HomePlan> homePlansFor({HomeKit? kit, HomeGoal? goal}) {
  return [
    for (final p in kHomePlans)
      if ((kit == null || p.kit == kit) && (goal == null || p.goal == goal)) p,
  ];
}

List<String> homeMusclesOf(List<Exercise> exs) {
  final seen = <String>{};
  final out = <String>[];
  for (final e in exs) {
    if (seen.add(e.primary)) out.add(e.primary);
  }
  return out;
}

List<String> exerciseCues(Exercise e) {
  return [
    for (final s in exerciseSteps(e))
      if (_cueOf(s) case final cue when cue.isNotEmpty) cue,
  ];
}

String _cueOf(String step) {
  var s = step.trim();
  s = s.replaceAll(RegExp(r'\s*Repeat for the desired[^.]*\.?', caseSensitive: false), '').trim();
  if (s.length <= 86) return s;
  final cut = s.indexOf(RegExp(r'[.;]'));
  if (cut >= 28 && cut <= 86) return s.substring(0, cut).trim();
  return '${s.substring(0, 84).trim()}…';
}
