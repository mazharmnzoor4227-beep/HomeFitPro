import '../models/exercise.dart';

/// Catalog of shipped demonstration media.
///
/// HQ diagram videos in [kHqDemoKeys] take precedence in the top demo
/// area when `assets/demos/video/<slug>.mp4` is present. User-supplied
/// media still wins in [ExerciseMedia].
enum ExerciseDemoKind { video, photos, diagram }

class ExerciseDemo {
  const ExerciseDemo({
    required this.id,
    required this.keys,
    required this.kind,
    required this.assets,
    this.poster,
    required this.author,
    required this.license,
    required this.sourceUrl,
  });

  /// Stable media id (matches the on-disk folder / file stem).
  final String id;

  /// Exercise ids and unique art slugs this media may attach to.
  /// Shared art slugs (e.g. `push-up`, used by several variations) are
  /// intentionally omitted so a clip never appears on the wrong move.
  final Set<String> keys;

  final ExerciseDemoKind kind;

  /// One `.mp4` for [ExerciseDemoKind.video], or one or two stills for photos.
  /// Two stills are shown as a looping start/end crossfade.
  final List<String> assets;

  /// Lightweight still used in lists so the video player is not created.
  final String? poster;

  final String author;
  final String license;
  final String sourceUrl;
}

const kExerciseDemos = <ExerciseDemo>[
  ExerciseDemo(
    id: 'bulgarian-split-squat',
    keys: {'bulgarian-split-squat'},
    kind: ExerciseDemoKind.video,
    assets: ['assets/demos/video/bulgarian-split-squat.mp4'],
    poster: 'assets/demos/diagram/bulgarian-split-squat.jpg',
    author: 'HomeFit Pro',
    license: 'Original work',
    sourceUrl: '',
  ),
  ExerciseDemo(
    id: 'burpee',
    keys: {'burpee'},
    kind: ExerciseDemoKind.video,
    assets: ['assets/demos/video/burpee.mp4'],
    poster: 'assets/demos/diagram/burpee.jpg',
    author: 'HomeFit Pro',
    license: 'Original work',
    sourceUrl: '',
  ),
  ExerciseDemo(
    id: 'calf-raise',
    keys: {'bJYHBIN'},
    kind: ExerciseDemoKind.video,
    assets: ['assets/demos/video/calf-raise.mp4'],
    poster: 'assets/demos/diagram/calf-raise.jpg',
    author: 'HomeFit Pro',
    license: 'Original work',
    sourceUrl: '',
  ),
  ExerciseDemo(
    id: 'forward-lunge',
    keys: {'ecl28tP'},
    kind: ExerciseDemoKind.video,
    assets: ['assets/demos/video/forward-lunge.mp4'],
    poster: 'assets/demos/diagram/forward-lunge.jpg',
    author: 'HomeFit Pro',
    license: 'Original work',
    sourceUrl: '',
  ),
  ExerciseDemo(
    id: 'glute-bridge',
    keys: {'glute-bridge'},
    kind: ExerciseDemoKind.video,
    assets: ['assets/demos/video/glute-bridge.mp4'],
    poster: 'assets/demos/diagram/glute-bridge.jpg',
    author: 'HomeFit Pro',
    license: 'Original work',
    sourceUrl: '',
  ),
  ExerciseDemo(
    id: 'high-knees',
    keys: {'high-knees'},
    kind: ExerciseDemoKind.video,
    assets: ['assets/demos/video/high-knees.mp4'],
    poster: 'assets/demos/diagram/high-knees.jpg',
    author: 'HomeFit Pro',
    license: 'Original work',
    sourceUrl: '',
  ),
  ExerciseDemo(
    id: 'jump-squat',
    keys: {'wfotm7S'},
    kind: ExerciseDemoKind.video,
    assets: ['assets/demos/video/jump-squat.mp4'],
    poster: 'assets/demos/diagram/jump-squat.jpg',
    author: 'HomeFit Pro',
    license: 'Original work',
    sourceUrl: '',
  ),
  ExerciseDemo(
    id: 'jumping-jack',
    keys: {'jumping-jack'},
    kind: ExerciseDemoKind.video,
    assets: ['assets/demos/video/jumping-jack.mp4'],
    poster: 'assets/demos/diagram/jumping-jack.jpg',
    author: 'HomeFit Pro',
    license: 'Original work',
    sourceUrl: '',
  ),
  ExerciseDemo(
    id: 'mountain-climber',
    keys: {'mountain-climber'},
    kind: ExerciseDemoKind.video,
    assets: ['assets/demos/video/mountain-climber.mp4'],
    poster: 'assets/demos/diagram/mountain-climber.jpg',
    author: 'HomeFit Pro',
    license: 'Original work',
    sourceUrl: '',
  ),
  ExerciseDemo(
    id: 'push-up',
    keys: {'I4hDWkc'},
    kind: ExerciseDemoKind.video,
    assets: ['assets/demos/video/push-up.mp4'],
    poster: 'assets/demos/diagram/push-up.jpg',
    author: 'HomeFit Pro',
    license: 'Original work',
    sourceUrl: '',
  ),
  ExerciseDemo(
    id: 'reverse-lunge',
    keys: {'reverse-lunge'},
    kind: ExerciseDemoKind.video,
    assets: ['assets/demos/video/reverse-lunge.mp4'],
    poster: 'assets/demos/diagram/reverse-lunge.jpg',
    author: 'HomeFit Pro',
    license: 'Original work',
    sourceUrl: '',
  ),
  ExerciseDemo(
    id: 'sit-up',
    keys: {'sit-up'},
    kind: ExerciseDemoKind.video,
    assets: ['assets/demos/video/sit-up.mp4'],
    poster: 'assets/demos/diagram/sit-up.jpg',
    author: 'HomeFit Pro',
    license: 'Original work',
    sourceUrl: '',
  ),
  ExerciseDemo(
    id: 'superman',
    keys: {'superman'},
    kind: ExerciseDemoKind.video,
    assets: ['assets/demos/video/superman.mp4'],
    poster: 'assets/demos/diagram/superman.jpg',
    author: 'HomeFit Pro',
    license: 'Original work',
    sourceUrl: '',
  ),
  ExerciseDemo(
    id: 'wall-sit',
    keys: {'wall-sit'},
    kind: ExerciseDemoKind.video,
    assets: ['assets/demos/video/wall-sit.mp4'],
    poster: 'assets/demos/diagram/wall-sit.jpg',
    author: 'HomeFit Pro',
    license: 'Original work',
    sourceUrl: '',
  ),
];

final Map<String, ExerciseDemo> kExerciseDemoIndex = {
  for (final demo in kExerciseDemos)
    for (final key in demo.keys) key: demo,
};

ExerciseDemo? demoOf(Exercise ex) => kExerciseDemoIndex[ex.id] ?? kExerciseDemoIndex[ex.art];

/// Kept as a thin alias so older call sites compile during the swap.
String? demoSlugOf(Exercise ex) => demoOf(ex)?.id;

/// HQ demo slug → catalog exercise ids. Ids only, never a shared art slug,
/// so a clip cannot land on a variation. Copy `hq/<slug>.mp4` and
/// `hq/<slug>-start.jpg` into `assets/demos/video/` and
/// `assets/demos/diagram/` (see `scripts/sync_hq_demos.sh`); the next
/// rebuild picks the file up with no Dart change.
const kHqDemoKeys = <String, Set<String>>{
  'push-up': {'I4hDWkc'},
  'sit-up': {'sit-up'},
  'squat': {'6YUfHPL'},
  'plank': {'plank-hold'},
  'wide-push-up': {'wide-push-up'},
  'diamond-push-up': {'x6KpKpq'},
  'pike-push-up': {'pike-push-up'},
  'chair-dip': {'chair-dip'},
  'crunch': {'TFqbd8t'},
  'bicycle-crunch': {'bicycle-crunch'},
  'leg-raise': {'lying-leg-raise'},
  'russian-twist': {'XVDdcoj'},
  'side-plank': {'side-plank-hold'},
  'jump-squat': {'wfotm7S'},
  'forward-lunge': {'ecl28tP'},
  'reverse-lunge': {'reverse-lunge'},
  'bulgarian-split-squat': {'bulgarian-split-squat'},
  'glute-bridge': {'glute-bridge'},
  'wall-sit': {'wall-sit'},
  'calf-raise': {'bJYHBIN'},
  'mountain-climber': {'mountain-climber'},
  'burpee': {'burpee'},
  'jumping-jack': {'jumping-jack'},
  'high-knees': {'high-knees'},
  'superman': {'superman'},
};

String hqVideoAsset(String slug) => 'assets/demos/video/$slug.mp4';

String hqPosterAsset(String slug) => 'assets/demos/diagram/$slug.jpg';

String? hqSlugOf(Exercise ex) {
  for (final entry in kHqDemoKeys.entries) {
    if (entry.value.contains(ex.id)) return entry.key;
  }
  return null;
}

String? hqPosterOf(Exercise ex) {
  final slug = hqSlugOf(ex);
  return slug == null ? null : hqPosterAsset(slug);
}
