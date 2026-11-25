import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:video_player/video_player.dart';

import '../models/exercise.dart';
import '../services/media_store.dart';
import '../state/fit_state.dart';
import '../theme/app_colors.dart';
import 'exercise_diagram.dart';
import 'exercise_demos.dart';
import 'file_thumb.dart';
import 'shimmer.dart';
import 'local_image.dart';

const _shortDemo = Duration(seconds: 10);

class ExerciseMedia extends StatelessWidget {
  const ExerciseMedia({
    super.key,
    required this.ex,
    this.height = 210,
    this.radius = 20,
    this.live = false,
    this.bordered = true,
    this.loops,
  });

  final Exercise ex;
  final double height;
  final double radius;
  final bool live;
  final bool bordered;
  final int? loops;

  @override
  Widget build(BuildContext context) {
    final media = fit.mediaFor(ex.id);
    final path = media.isEmpty ? null : MediaStore.pathFor(media);
    if (path == null) {
      // User media still wins. HQ clips play only in the live (top) demo area.
      final slug = hqSlugOf(ex);
      if (slug != null && live && !_inWidgetTest) {
        return _HqLoopVideo(slug: slug, ex: ex, height: height, radius: radius, bordered: bordered);
      }
      return ExerciseDiagram(ex: ex, height: height, radius: radius, live: false, bordered: bordered);
    }
    final isVideo = MediaStore.isVideo(media);
    if (isVideo && live) {
      return _VideoTile(
        key: ValueKey(path),
        path: path,
        height: height,
        radius: radius,
        short: loops != null,
      );
    }
    if (isVideo) {
      return Stack(
        children: [
          _VideoTile(
            key: ValueKey('still-$path'),
            path: path,
            height: height,
            radius: radius,
            bordered: bordered,
            still: true,
          ),
          Positioned(right: 6, bottom: 6, child: _PlayBadge(height: height)),
        ],
      );
    }
    return _MediaFrame(
      height: height,
      radius: radius,
      bordered: bordered,
      child: Center(
        child: FileThumb(
          path,
          key: ValueKey(media),
          fit: BoxFit.contain,
          errorBuilder: (_, _, _) => _fallbackIcon(context, height),
        ),
      ),
    );
  }
}

Widget _fallbackIcon(BuildContext context, double height) => Center(
  child: Icon(PhosphorIconsRegular.barbell, size: height * 0.32, color: context.gc.textTertiary),
);

class _MediaFrame extends StatelessWidget {
  const _MediaFrame({required this.child, required this.height, required this.radius, this.bordered = true});
  final Widget child;
  final double height;
  final double radius;
  final bool bordered;

  @override
  Widget build(BuildContext context) {
    final gc = context.gc;
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: gc.bgRaised2,
        borderRadius: BorderRadius.circular(radius),
        border: bordered ? Border.all(color: gc.border) : null,
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}

class _PlayBadge extends StatelessWidget {
  const _PlayBadge({required this.height});
  final double height;

  @override
  Widget build(BuildContext context) {
    final gc = context.gc;
    final size = (height * 0.2).clamp(16.0, 30.0);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: gc.bg.withValues(alpha: 0.72), shape: BoxShape.circle),
      child: Icon(PhosphorIconsFill.play, size: size * 0.5, color: gc.text),
    );
  }
}

class _VideoTile extends StatefulWidget {
  const _VideoTile({
    super.key,
    required this.path,
    required this.height,
    required this.radius,
    this.short = false,
    this.still = false,
    this.bordered = true,
  });
  final String path;
  final double height;
  final double radius;
  final bool short;
  final bool still;
  final bool bordered;

  @override
  State<_VideoTile> createState() => _VideoTileState();
}

class _VideoTileState extends State<_VideoTile> {
  VideoPlayerController? _c;
  Timer? _stop;
  bool _ok = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final c = localVideo(widget.path, options: VideoPlayerOptions(mixWithOthers: true));
      await c.initialize();
      await c.setVolume(0);
      if (widget.still) {
        final ms = c.value.duration.inMilliseconds;
        await c.seekTo(Duration(milliseconds: math.min(500, ms ~/ 3)));
      } else {
        await c.setLooping(true);
        await c.play();
      }
      if (!mounted) {
        c.dispose();
        return;
      }
      setState(() {
        _c = c;
        _ok = true;
      });
      if (widget.short) _stop = Timer(_shortDemo, () => c.setLooping(false));
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  void dispose() {
    _stop?.cancel();
    _c?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget child;
    if (_ok && _c != null) {
      child = FittedBox(
        fit: BoxFit.contain,
        clipBehavior: Clip.hardEdge,
        child: SizedBox(width: _c!.value.size.width, height: _c!.value.size.height, child: VideoPlayer(_c!)),
      );
    } else if (_failed) {
      child = _fallbackIcon(context, widget.height);
    } else {
      child = Stack(
        children: [
          Positioned.fill(child: Shimmer(radius: widget.radius)),
          const Center(child: CupertinoActivityIndicator()),
        ],
      );
    }
    return _MediaFrame(height: widget.height, radius: widget.radius, bordered: widget.bordered, child: child);
  }
}

bool get _inWidgetTest => WidgetsBinding.instance.runtimeType.toString().contains('TestWidgets');

class _HqLoopVideo extends StatefulWidget {
  const _HqLoopVideo({
    required this.slug,
    required this.ex,
    required this.height,
    required this.radius,
    required this.bordered,
  });

  final String slug;
  final Exercise ex;
  final double height;
  final double radius;
  final bool bordered;

  @override
  State<_HqLoopVideo> createState() => _HqLoopVideoState();
}

class _HqLoopVideoState extends State<_HqLoopVideo> with WidgetsBindingObserver {
  VideoPlayerController? _c;
  bool _ok = false;

  String get _asset => hqVideoAsset(widget.slug);
  String get _poster => hqPosterAsset(widget.slug);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  Future<void> _load() async {
    try {
      final c = VideoPlayerController.asset(
        _asset,
        videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
      );
      await c.initialize();
      await c.setVolume(0);
      await c.setLooping(true);
      await c.play();
      if (!mounted) {
        c.dispose();
        return;
      }
      c.addListener(_onTick);
      setState(() {
        _c = c;
        _ok = true;
      });
    } catch (_) {
      if (mounted) setState(() => _ok = false);
    }
  }

  void _onTick() {
    final c = _c;
    if (c == null || !c.value.isInitialized) return;
    if (!c.value.isPlaying && !c.value.hasError) {
      c.setLooping(true);
      c.play();
    }
  }

  void _ensurePlaying() {
    final c = _c;
    if (c == null || !c.value.isInitialized) return;
    c.setVolume(0);
    c.setLooping(true);
    if (!c.value.isPlaying) c.play();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _ensurePlaying();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route == null || route.isCurrent) _ensurePlaying();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _c?.removeListener(_onTick);
    _c?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gc = context.gc;
    final poster = Image.asset(
      _poster,
      fit: BoxFit.contain,
      gaplessPlayback: true,
      filterQuality: FilterQuality.medium,
      alignment: Alignment.center,
      errorBuilder: (_, _, _) =>
          ExerciseDiagram(ex: widget.ex, height: widget.height, radius: 0, bordered: false),
    );
    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        gradient: kDemoCanvasGradient,
        borderRadius: BorderRadius.circular(widget.radius),
        border: widget.bordered ? Border.all(color: gc.border) : null,
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          poster,
          if (_ok && _c != null)
            FittedBox(
              fit: BoxFit.contain,
              clipBehavior: Clip.hardEdge,
              child: SizedBox(
                width: _c!.value.size.width,
                height: _c!.value.size.height,
                child: VideoPlayer(_c!),
              ),
            ),
        ],
      ),
    );
  }
}
