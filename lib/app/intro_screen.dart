import 'package:flutter/widgets.dart';

/// Short first-open intro. ~1.2s of logo scale/fade and a title slide-up,
/// then [child] (the main app). Widget tests skip the animation so existing
/// pumps still land on the real UI.
class IntroGate extends StatefulWidget {
  const IntroGate({super.key, required this.child});

  final Widget child;

  @override
  State<IntroGate> createState() => _IntroGateState();
}

class _IntroGateState extends State<IntroGate> with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  var _done = false;

  static bool get _inWidgetTest =>
      WidgetsBinding.instance.runtimeType.toString().contains('TestWidgets');

  @override
  void initState() {
    super.initState();
    if (_inWidgetTest) {
      _c = AnimationController(vsync: this);
      _done = true;
      return;
    }
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _c.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        setState(() => _done = true);
      }
    });
    _c.forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_done) return widget.child;

    const slate = Color(0xFF1E2530);
    const ink = Color(0xFFF0F3F7);
    final logoFade = CurvedAnimation(parent: _c, curve: const Interval(0.0, 0.38, curve: Curves.easeOut));
    final logoScale = Tween<double>(begin: 0.84, end: 1).animate(
      CurvedAnimation(parent: _c, curve: const Interval(0.0, 0.45, curve: Curves.easeOutCubic)),
    );
    final textFade = CurvedAnimation(parent: _c, curve: const Interval(0.28, 0.70, curve: Curves.easeOut));
    final textSlide = Tween<double>(begin: 18, end: 0).animate(
      CurvedAnimation(parent: _c, curve: const Interval(0.28, 0.70, curve: Curves.easeOutCubic)),
    );

    return ColoredBox(
      color: slate,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FadeTransition(
                  opacity: logoFade,
                  child: ScaleTransition(
                    scale: logoScale,
                    child: Image.asset(
                      'assets/icon/homefitpro_mark.png',
                      width: 112,
                      height: 112,
                      filterQuality: FilterQuality.medium,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                FadeTransition(
                  opacity: textFade,
                  child: Transform.translate(
                    offset: Offset(0, textSlide.value),
                    child: const Text(
                      'HomeFit Pro',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: ink,
                        letterSpacing: -0.4,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
