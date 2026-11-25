import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gymmane/catalog/exercise_catalog.dart';
import 'package:gymmane/widgets/exercise_demos.dart';

void main() {
  test('every shipped demo asset exists and stays under 1 MB', () {
    expect(kExerciseDemos, isNotEmpty);
    for (final demo in kExerciseDemos) {
      expect(demo.assets, isNotEmpty, reason: demo.id);
      for (final asset in demo.assets) {
        final file = File(asset);
        expect(file.existsSync(), isTrue, reason: asset);
        expect(file.lengthSync(), lessThan(1024 * 1024), reason: asset);
      }
      if (demo.kind == ExerciseDemoKind.video) {
        expect(demo.poster, isNotNull, reason: demo.id);
        expect(File(demo.poster!).existsSync(), isTrue, reason: demo.poster);
        expect(demo.assets.single.endsWith('.mp4'), isTrue, reason: demo.id);
      }
    }
  });

  test('each demo maps to at least one catalog exercise, and only by its keys', () {
    for (final demo in kExerciseDemos) {
      final hits = kExercises.where((e) => demoOf(e)?.id == demo.id).toList();
      expect(hits, isNotEmpty, reason: demo.id);
      for (final ex in hits) {
        expect(demo.keys.contains(ex.id) || demo.keys.contains(ex.art), isTrue, reason: '${demo.id} -> ${ex.id}');
      }
    }
  });

  test('HQ slugs attach only to the named move', () {
    expect(hqSlugOf(kExercises.firstWhere((e) => e.id == 'I4hDWkc')), 'push-up');
    expect(hqSlugOf(kExercises.firstWhere((e) => e.id == 'sit-up')), 'sit-up');
    expect(hqSlugOf(kExercises.firstWhere((e) => e.id == '6YUfHPL')), 'squat');
    expect(hqSlugOf(kExercises.firstWhere((e) => e.id == 'plank-hold')), 'plank');
    expect(hqSlugOf(kExercises.firstWhere((e) => e.id == 'pseudo-planche-push-up')), isNull);
    expect(hqSlugOf(kExercises.firstWhere((e) => e.id == 'x6KpKpq')), 'diamond-push-up');
    expect(hqSlugOf(kExercises.firstWhere((e) => e.id == 'VBAWRPG')), isNull);
    expect(hqSlugOf(kExercises.firstWhere((e) => e.id == 'QChZi3x')), isNull);
    expect(hqSlugOf(kExercises.firstWhere((e) => e.id == 'assisted-squat')), isNull);
    expect(demoOf(kExercises.firstWhere((e) => e.id == 'pseudo-planche-push-up')), isNull);
  });

  test('old Mixkit, Wikimedia and mannequin media are no longer shipped', () {
    final root = Directory('assets/demos');
    final leftovers = <File>[];
    for (final entity in root.listSync(recursive: true)) {
      if (entity is! File) continue;
      if (entity.path.endsWith('.webp')) leftovers.add(entity);
    }
    expect(leftovers, isEmpty, reason: leftovers.map((f) => f.path).join(', '));
    expect(Directory('assets/demos/still').existsSync(), isFalse);
    expect(Directory('assets/demos/photo').existsSync(), isFalse);
    expect(Directory('assets/demos/3d').existsSync(), isFalse);
  });
}
