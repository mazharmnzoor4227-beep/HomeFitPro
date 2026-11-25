import 'package:flutter_test/flutter_test.dart';
import 'package:gymmane/catalog/exercise_catalog.dart';
import 'package:gymmane/catalog/home_workout.dart';
import 'package:gymmane/models/exercise.dart';

void main() {
  test('bodyweight work splits into floor, support and bar kits', () {
    final all = kExercises.where(isHomeExercise).toList();
    expect(all, isNotEmpty);
    expect(all.length, greaterThan(80));

    final floor = homeExercises(kit: HomeKit.none);
    final support = homeExercises(kit: HomeKit.support);
    final bar = homeExercises(kit: HomeKit.bar);
    expect(floor.length + support.length + bar.length, all.length);
    expect(floor, isNotEmpty);
    expect(bar, isNotEmpty);

    final push = all.firstWhere((e) => e.id == 'I4hDWkc');
    expect(homeKitOf(push), HomeKit.none);
    expect(homeGoalOf(push), HomeGoal.upper);

    final pull = all.firstWhere((e) => e.id == 'lBDjFxJ');
    expect(homeKitOf(pull), HomeKit.bar);

    final wall = all.firstWhere((e) => e.id == 'wall-sit');
    expect(homeKitOf(wall), HomeKit.support);
    expect(homeGoalOf(wall), HomeGoal.lower);

    final crunch = all.firstWhere((e) => e.id == 'TFqbd8t');
    expect(homeGoalOf(crunch), HomeGoal.core);
  });

  test('curated plans only use real catalogue ids', () {
    final ids = {for (final e in kExercises) e.id};
    for (final plan in kHomePlans) {
      expect(plan.exerciseIds, isNotEmpty, reason: plan.id);
      for (final id in plan.exerciseIds) {
        expect(ids, contains(id), reason: '${plan.id} -> $id');
      }
    }
    expect(homePlansFor(kit: HomeKit.none, goal: HomeGoal.fullBody).map((p) => p.id), contains('full-none'));
  });

  test('cues drop the long repeat line and stay short', () {
    final ex = Exercise(
      id: 'x',
      name: 'Demo',
      primary: 'chest',
      secondary: const [],
      equipment: 'Bodyweight',
      difficulty: 'Beginner',
      art: '',
      steps: const [
        'Start in a high plank position with your hands slightly wider than shoulder-width apart and your feet together.',
        'Repeat for the desired number of repetitions.',
      ],
    );
    final cues = exerciseCues(ex);
    expect(cues, hasLength(1));
    expect(cues.first.toLowerCase(), isNot(contains('desired number')));
    expect(cues.first.length, lessThanOrEqualTo(90));
  });
}
