import 'package:flutter/widgets.dart';

import '../models/exercise.dart';
import '../theme/app_colors.dart';
import 'body_map.dart';
import 'exercise_demos.dart';

/// Cool-grey demo canvas, sampled from the approved HQ push-up video edges
/// (top / bottom). Used as a vertical gradient so the video has no seam.
const kDemoCanvasTop = Color(0xFFF0F3F7);
const kDemoCanvasBottom = Color(0xFFDCE2EA);
const kDemoCanvasGradient = LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [kDemoCanvasTop, kDemoCanvasBottom],
);
const kDiagramBg = kDemoCanvasTop;
const kMuscleSecondary = Color(0xFFFFB38A);

/// Fallback still used when an HQ start frame is not shipped yet.
const kPushupDiagramAsset = 'assets/demos/diagram/push-up.jpg';

/// Flat anatomical figure used for every built-in exercise image.
///
/// HQ start-frame posters are used when present. Every other move reuses
/// the in-app muscle-map SVG with primary (orange) and secondary (soft
/// apricot) muscles highlighted. Motion lives in the HQ video on the
/// top demo only; thumbnails, cards, and panel icons stay static.
class ExerciseDiagram extends StatelessWidget {
  const ExerciseDiagram({
    super.key,
    required this.ex,
    this.height = 210,
    this.radius = 20,
    this.live = false,
    this.bordered = true,
  });

  final Exercise ex;
  final double height;
  final double radius;
  final bool live;
  final bool bordered;

  @override
  Widget build(BuildContext context) {
    final gc = context.gc;
    final poster = hqPosterOf(ex);
    final figure = poster != null
        ? Image.asset(
            poster,
            fit: BoxFit.contain,
            gaplessPlayback: true,
            filterQuality: FilterQuality.medium,
            alignment: Alignment.center,
            errorBuilder: (_, _, _) => _MuscleMapFigure(ex: ex, height: height, gc: gc),
          )
        : ex.id == 'I4hDWkc'
        ? Image.asset(
            kPushupDiagramAsset,
            fit: BoxFit.contain,
            gaplessPlayback: true,
            filterQuality: FilterQuality.medium,
            alignment: Alignment.center,
          )
        : _MuscleMapFigure(ex: ex, height: height, gc: gc);

    // Motion lives in the HQ video, not in a bob/tilt on a still.
    return Container(
      height: height,
      decoration: BoxDecoration(
        gradient: kDemoCanvasGradient,
        borderRadius: BorderRadius.circular(radius),
        border: bordered ? Border.all(color: gc.border) : null,
      ),
      clipBehavior: Clip.antiAlias,
      child: figure,
    );
  }
}

class _MuscleMapFigure extends StatelessWidget {
  const _MuscleMapFigure({required this.ex, required this.height, required this.gc});

  final Exercise ex;
  final double height;
  final GymColors gc;

  @override
  Widget build(BuildContext context) {
    final muscles = [ex.primary, ...ex.secondary];
    final view = bodyViewFor(muscles);
    return Center(
      child: CustomPaint(
        size: Size(height * view.width / view.height, height),
        painter: BodyPainter(
          gc: gc,
          token: 'exd${muscles.join(',')}',
          crop: view,
          highlighted: muscles.toSet(),
          color: (id) {
            if (id == ex.primary) return gc.ember;
            if (muscles.contains(id)) return kMuscleSecondary;
            return idleMuscle(gc);
          },
          quiet: true,
        ),
      ),
    );
  }
}
