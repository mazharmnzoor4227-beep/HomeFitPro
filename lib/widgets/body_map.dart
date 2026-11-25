import 'package:flutter/material.dart';

import '../catalog/body_art.dart';
import '../l10n/l10n.dart';
import '../theme/app_theme.dart';
import '../catalog/body_svg.dart';
import '../state/fit_state.dart';
import '../theme/app_colors.dart';
import 'svg_icon.dart';

const double kBodyAspect = bodyViewH / bodyViewW;

BodyArt get currentBody => bodyArtFor(fit.profile.sex);

String? muscleAt(Offset p) {
  final art = currentBody;
  for (final id in art.fills.keys) {
    final hits = art.hits[id];
    final probes = (hits != null && hits.isNotEmpty) ? hits : art.fills[id]!;
    for (final d in probes) {
      if (svgPath(d).contains(p)) return id;
    }
  }
  return null;
}

void paintBodyBase(Canvas canvas, BodyArt art, Color main, Color lite) {
  final paint = Paint()..isAntiAlias = true;
  final cut = art.head.isNotEmpty;
  if (cut) {
    canvas.save();
    canvas.clipRect(Rect.fromLTRB(-bodyViewW, art.headCut, bodyViewW * 2, bodyViewH * 2));
  }
  for (final d in art.base) {
    canvas.drawPath(svgPath(d), paint..color = main);
  }
  for (final d in art.lite) {
    canvas.drawPath(svgPath(d), paint..color = lite);
  }
  if (cut) {
    canvas.restore();
    for (final d in art.head) {
      canvas.drawPath(svgPath(d), paint..color = lite);
    }
  }
}

final Map<String, Path> _muscleClips = {};

void clipMuscles(Canvas canvas, BodyArt art) {
  if (art.headInner.isEmpty) return;
  canvas.clipPath(
    _muscleClips.putIfAbsent(art.id, () {
      final p = Path()..addRect(Rect.fromLTRB(-bodyViewW, art.headCut, bodyViewW * 2, bodyViewH * 2));
      for (final d in art.headInner) {
        p.addPath(svgPath(d), Offset.zero);
      }
      return p;
    }),
  );
}

Color idleMuscle(GymColors gc) {
  final dark = gc.bg.computeLuminance() < 0.5;
  return Color.lerp(gc.bgRaised, gc.textSecondary, dark ? 0.42 : 0.26)!;
}

const Map<String, List<Color>> kHeatRampsDark = {
  'ember': [Color(0xFF7A3A18), Color(0xFFC85A1C), Color(0xFFEE6A20), Color(0xFFFF7A2F)],
  'green': [Color(0xFF164B32), Color(0xFF1E8A56), Color(0xFF3FBF78), Color(0xFF7BE0A8)],
  'blue': [Color(0xFF1E3A5C), Color(0xFF2C5E96), Color(0xFF3D86C9), Color(0xFF6EB4F0)],
  'mono': [Color(0xFF2A332E), Color(0xFF4E5A54), Color(0xFF8A948C), Color(0xFFD8DDD6)],
};

const Map<String, List<Color>> kHeatRampsLight = {
  'ember': [Color(0xFFFFD0B3), Color(0xFFFFB38A), Color(0xFFFF7A2F), Color(0xFFE85E12)],
  'green': [Color(0xFFC5E6D2), Color(0xFF7FC8A0), Color(0xFF2F9A64), Color(0xFF176B42)],
  'blue': [Color(0xFFC5D8EC), Color(0xFF7EA5D2), Color(0xFF3F74AE), Color(0xFF1F4876)],
  'mono': [Color(0xFFD5DAD4), Color(0xFFA0A79F), Color(0xFF6A726C), Color(0xFF2E342F)],
};

const List<String> kHeatTones = ['ember', 'green', 'blue', 'mono'];

List<Color> heatRamp(GymColors gc, String tone) {
  final table = gc.bg.computeLuminance() < 0.5 ? kHeatRampsDark : kHeatRampsLight;
  return table[tone] ?? table['ember']!;
}

Color heatLevelColor(GymColors gc, int level, {String? tone}) {
  if (level <= 0) return idleMuscle(gc);
  final ramp = heatRamp(gc, tone ?? fit.heatTone);
  return ramp[(level - 1).clamp(0, heatLevels - 1)];
}

Color heatColor(GymColors gc, double v) => heatLevelColor(gc, heatLevel(v));

String heatToken(Map<String, double> intensity) {
  final keys = intensity.keys.toList()..sort();
  return keys.map((k) => '$k${(intensity[k]! * 100).round()}').join(',');
}

class BodyMap extends StatelessWidget {
  const BodyMap({super.key, required this.selected, required this.onToggle});

  final Set<String> selected;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    final gc = context.gc;
    final muscle = idleMuscle(gc);
    final labels = {for (final id in selected) id: t.muscle(id)};
    return _BodyCanvas(
      onTap: onToggle,
      painter: BodyPainter(
        gc: gc,
        token: 'sel${(selected.toList()..sort()).join(',')}',
        color: (id) => selected.contains(id) ? gc.ember : muscle,
        highlighted: selected,
        labels: labels,
        showFacings: true,
      ),
    );
  }
}

class BodyHeatMap extends StatelessWidget {
  const BodyHeatMap({super.key, required this.intensity, this.focus, this.onTap});

  final Map<String, double> intensity;
  final String? focus;
  final ValueChanged<String>? onTap;

  String get _token => heatToken(intensity);

  @override
  Widget build(BuildContext context) {
    final gc = context.gc;
    return _BodyCanvas(
      onTap: onTap,
      painter: BodyPainter(
        gc: gc,
        token: _token,
        color: (id) => heatColor(gc, intensity[id] ?? 0),
        outline: focus,
      ),
    );
  }
}

Color recoveryColor(GymColors gc, double recovered) {
  final v = recovered.clamp(0.0, 1.0);
  final fresh = Color.lerp(idleMuscle(gc), gc.sage, 0.62)!;
  if (v < 0.5) return Color.lerp(gc.danger, gc.warn, v / 0.5)!;
  return Color.lerp(gc.warn, fresh, (v - 0.5) / 0.5)!;
}

class BodyRecoveryMap extends StatelessWidget {
  const BodyRecoveryMap({super.key, required this.recovery, this.focus, this.onTap});

  final Map<String, double> recovery;
  final String? focus;
  final ValueChanged<String>? onTap;

  @override
  Widget build(BuildContext context) {
    final gc = context.gc;
    return _BodyCanvas(
      onTap: onTap,
      painter: BodyPainter(
        gc: gc,
        token: 'r${heatToken(recovery)}',
        color: (id) => recoveryColor(gc, recovery[id] ?? 1),
        outline: focus,
      ),
    );
  }
}

class BodyHeatArt extends StatelessWidget {
  const BodyHeatArt({super.key, required this.gc, required this.intensity, required this.width});

  final GymColors gc;
  final Map<String, double> intensity;
  final double width;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(width, width * kBodyAspect),
      painter: BodyPainter(
        gc: gc,
        token: heatToken(intensity),
        color: (id) => heatColor(gc, intensity[id] ?? 0),
      ),
    );
  }
}

class _BodyCanvas extends StatelessWidget {
  const _BodyCanvas({required this.painter, this.onTap});

  final BodyPainter painter;
  final ValueChanged<String>? onTap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        final scale = w / bodyViewW;
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapUp: onTap == null
              ? null
              : (d) {
                  final p = Offset(d.localPosition.dx / scale, d.localPosition.dy / scale);
                  final id = muscleAt(p);
                  if (id != null) onTap!(id);
                },
          child: CustomPaint(size: Size(w, w * kBodyAspect), painter: painter),
        );
      },
    );
  }
}

class BodyPainter extends CustomPainter {
  BodyPainter({
    required this.gc,
    required this.color,
    required this.token,
    this.outline,
    this.crop,
    this.quiet = false,
    this.showFacings = false,
    this.highlighted = const {},
    this.labels = const {},
    BodyArt? art,
  }) : art = art ?? currentBody;

  final BodyArt art;
  final bool quiet;
  final GymColors gc;
  final Color Function(String id) color;
  final String token;
  final String? outline;
  final Rect? crop;
  final bool showFacings;
  final Set<String> highlighted;
  final Map<String, String> labels;

  @override
  void paint(Canvas canvas, Size size) {
    final view = crop ?? const Rect.fromLTWH(0, 0, bodyViewW, bodyViewH);
    canvas.clipRect(Offset.zero & size);
    canvas.scale(size.width / view.width);
    canvas.translate(-view.left, -view.top);

    final dark = gc.bg.computeLuminance() < 0.5;
    final bodyMain = quiet
        ? Color.lerp(gc.bgRaised2, gc.textTertiary, 0.1)!
        : Color.lerp(gc.bgRaised, gc.textTertiary, dark ? 0.16 : 0.10)!;
    final bodyLite = Color.lerp(bodyMain, gc.text, dark ? 0.10 : 0.06)!;

    // Soft ground shadow under both figures
    if (!quiet) {
      final shadow = Paint()
        ..color = Colors.black.withValues(alpha: dark ? 0.28 : 0.10)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10)
        ..isAntiAlias = true;
      for (final d in art.base) {
        canvas.drawPath(svgPath(d).shift(const Offset(0, 7)), shadow);
      }
    }

    paintBodyBase(canvas, art, bodyMain, bodyLite);
    canvas.save();
    clipMuscles(canvas, art);

    Path musclePath(String id) {
      final p = Path();
      for (final d in art.fills[id] ?? const <String>[]) {
        p.addPath(svgPath(d), Offset.zero);
      }
      return p;
    }

    // Idle muscles first, with a fine anatomical seam
    for (final entry in art.fills.entries) {
      if (highlighted.contains(entry.key) || entry.key == outline) continue;
      final c = color(entry.key);
      final path = musclePath(entry.key);
      canvas.drawPath(
        path,
        Paint()
          ..color = c
          ..isAntiAlias = true,
      );
      canvas.drawPath(
        path,
        Paint()
          ..color = gc.bg.withValues(alpha: dark ? 0.28 : 0.40)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.7
          ..isAntiAlias = true,
      );
    }

    // Highlighted / focused muscles with glow, fill, and rim
    final focusIds = {...highlighted, if (outline != null) outline!};
    for (final id in focusIds) {
      final path = musclePath(id);
      if (path.getBounds().isEmpty) continue;
      final fillColor = highlighted.contains(id) ? gc.ember : color(id);
      canvas.drawPath(
        path,
        Paint()
          ..color = fillColor.withValues(alpha: 0.32)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8)
          ..isAntiAlias = true,
      );
      canvas.drawPath(
        path,
        Paint()
          ..color = fillColor
          ..isAntiAlias = true,
      );
      canvas.drawPath(
        path,
        Paint()
          ..color = Color.lerp(fillColor, gc.text, 0.18)!
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6
          ..isAntiAlias = true,
      );
    }
    canvas.restore();

    if (showFacings && crop == null) {
      void facing(String label, double cx) {
        final tp = TextPainter(
          text: TextSpan(
            text: label,
            style: AppTheme.s(9, weight: FontWeight.w800, color: gc.textTertiary, letterSpacing: 1.6),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset(cx - tp.width / 2, 6));
      }

      facing('FRONT', bodyViewW * 0.25);
      facing('BACK', bodyViewW * 0.75);
    }

    if (labels.isNotEmpty) {
      for (final id in labels.keys) {
        final path = Path();
        for (final d in art.fills[id] ?? const <String>[]) {
          path.addPath(svgPath(d), Offset.zero);
        }
        final bounds = path.getBounds();
        if (bounds.isEmpty) continue;
        final label = labels[id]!;
        final tp = TextPainter(
          text: TextSpan(
            text: label.toUpperCase(),
            style: AppTheme.s(8.5, weight: FontWeight.w800, color: gc.onEmber, letterSpacing: 0.4),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        final pad = const Offset(7, 3.5);
        final w = tp.width + pad.dx * 2;
        final h = tp.height + pad.dy * 2;
        var x = bounds.center.dx - w / 2;
        var y = bounds.top - h - 6;
        if (y < 4) y = bounds.center.dy - h / 2;
        x = x.clamp(4.0, bodyViewW - w - 4);
        final rect = RRect.fromRectAndRadius(Rect.fromLTWH(x, y, w, h), const Radius.circular(8));
        canvas.drawRRect(
          rect.shift(const Offset(0, 1)),
          Paint()
            ..color = Colors.black.withValues(alpha: dark ? 0.35 : 0.12)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
        );
        canvas.drawRRect(rect, Paint()..color = gc.ember);
        tp.paint(canvas, Offset(x + pad.dx, y + pad.dy));
      }
    }
  }

  @override
  bool shouldRepaint(BodyPainter old) =>
      old.gc != gc ||
      old.token != token ||
      old.outline != outline ||
      old.crop != crop ||
      old.quiet != quiet ||
      old.showFacings != showFacings ||
      old.highlighted != highlighted ||
      old.labels != labels ||
      old.art != art;
}

Color untrainedColor(GymColors gc, int? days) {
  final idle = idleMuscle(gc);
  if (days == null || days >= 14) return gc.danger;
  if (days >= 7) return Color.lerp(gc.warn, gc.danger, (days - 7) / 7)!;
  if (days >= 4) return Color.lerp(idle, gc.warn, 0.35 + (days - 4) * 0.2)!;
  return Color.lerp(idle, gc.sage, 0.35)!;
}

class BodyUntrainedMap extends StatelessWidget {
  const BodyUntrainedMap({super.key, required this.days, this.focus, this.onTap});

  final Map<String, int?> days;
  final String? focus;
  final ValueChanged<String>? onTap;

  @override
  Widget build(BuildContext context) {
    final gc = context.gc;
    final keys = days.keys.toList()..sort();
    return _BodyCanvas(
      onTap: onTap,
      painter: BodyPainter(
        gc: gc,
        token: 'u${keys.map((k) => '$k${days[k] ?? 'n'}').join(',')}',
        color: (id) => untrainedColor(gc, days[id]),
        outline: focus,
      ),
    );
  }
}

final Map<String, Rect> _zoneViews = {};

Rect bodyViewFor(List<String> muscles) => _zoneViews.putIfAbsent('${currentBody.id}${muscles.join(',')}', () {
  const half = bodyViewW / 2;
  var front = false, back = false;
  for (final id in muscles) {
    for (final d in currentBody.fills[id] ?? const <String>[]) {
      if (svgPath(d).getBounds().center.dx < half) {
        front = true;
      } else {
        back = true;
      }
    }
  }
  if (front == back) return const Rect.fromLTWH(0, 0, bodyViewW, bodyViewH);
  return Rect.fromLTWH(front ? 0 : half, 0, half, bodyViewH);
});

class BodyZoneArt extends StatelessWidget {
  const BodyZoneArt({super.key, required this.muscles, required this.height, this.color});

  final List<String> muscles;
  final double height;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final gc = context.gc;
    final view = bodyViewFor(muscles);
    final idle = idleMuscle(gc);
    final on = color ?? heatRamp(gc, fit.heatTone)[2];
    return CustomPaint(
      size: Size(height * view.width / view.height, height),
      painter: BodyPainter(
        gc: gc,
        token: 'z${muscles.join(',')}$on',
        crop: view,
        color: (id) => muscles.contains(id) ? on : idle,
      ),
    );
  }
}

class MiniBody extends StatelessWidget {
  const MiniBody({super.key, required this.sets, this.done, required this.height});

  final Map<String, double> sets;
  final Map<String, double>? done;
  final double height;

  @override
  Widget build(BuildContext context) {
    final gc = context.gc;
    final top = sets.values.fold(0.0, (a, b) => b > a ? b : a);
    final idle = idleMuscle(gc);
    final ramp = heatRamp(gc, fit.heatTone);
    final faint = Color.lerp(idle, ramp[1], 0.55)!;
    final ticked = done;
    Color colorOf(String id) {
      final n = sets[id] ?? 0;
      if (n <= 0 || top <= 0) return idle;
      if (ticked == null) return ramp[((n / top) * (heatLevels - 1)).round().clamp(0, heatLevels - 1)];
      final d = ticked[id] ?? 0;
      if (d <= 0) return faint;
      return Color.lerp(faint, ramp[heatLevels - 1], (d / n).clamp(0.0, 1.0))!;
    }

    final keys = sets.keys.toList()..sort();
    final token =
        'm${keys.map((k) => '$k${sets[k]!.toStringAsFixed(1)}/${ticked?[k]?.toStringAsFixed(1) ?? '-'}').join(',')}';
    return RepaintBoundary(
      child: CustomPaint(
        size: Size(height / kBodyAspect, height),
        painter: BodyPainter(gc: gc, token: '$token${fit.heatTone}', color: colorOf, quiet: true),
      ),
    );
  }
}
