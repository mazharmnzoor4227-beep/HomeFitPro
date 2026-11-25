import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../l10n/l10n.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'svg_icon.dart';
import 'ui_kit.dart';

class PracticeTracker extends StatefulWidget {
  const PracticeTracker({
    super.key,
    required this.exerciseId,
    this.initialSets = 3,
    this.initialReps = 12,
    this.initialRest = 45,
    this.hold = false,
    this.onStartWorkout,
  });

  final String exerciseId;
  final int initialSets;
  final int initialReps;
  final int initialRest;
  final bool hold;
  final ValueChanged<int>? onStartWorkout;

  @override
  State<PracticeTracker> createState() => _PracticeTrackerState();
}

class _PracticeTrackerState extends State<PracticeTracker> {
  late int _reps;
  late int _rest;
  late List<bool> _done;
  Timer? _timer;
  int _left = 0;

  @override
  void initState() {
    super.initState();
    _reps = widget.initialReps;
    _rest = widget.initialRest;
    _done = List<bool>.filled(widget.initialSets, false);
  }

  @override
  void didUpdateWidget(PracticeTracker old) {
    super.didUpdateWidget(old);
    if (old.exerciseId != widget.exerciseId) {
      _timer?.cancel();
      _left = 0;
      _reps = widget.initialReps;
      _rest = widget.initialRest;
      _done = List<bool>.filled(widget.initialSets, false);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  int get _finished => _done.where((d) => d).length;

  void _setCount(int n) {
    n = n.clamp(1, 8);
    setState(() {
      if (n > _done.length) {
        _done = [..._done, ...List<bool>.filled(n - _done.length, false)];
      } else {
        _done = _done.take(n).toList();
      }
    });
  }

  void _toggle(int i) {
    HapticFeedback.selectionClick();
    setState(() => _done[i] = !_done[i]);
    if (_done[i]) {
      _startRest();
    } else {
      _timer?.cancel();
      setState(() => _left = 0);
    }
  }

  void _startRest() {
    _timer?.cancel();
    if (_rest <= 0 || _finished >= _done.length) {
      setState(() => _left = 0);
      return;
    }
    setState(() => _left = _rest);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      if (_left <= 1) {
        t.cancel();
        HapticFeedback.mediumImpact();
        setState(() => _left = 0);
      } else {
        setState(() => _left -= 1);
      }
    });
  }

  String _clock(int s) {
    final m = (s ~/ 60).toString().padLeft(2, '0');
    final r = (s % 60).toString().padLeft(2, '0');
    return '$m:$r';
  }

  @override
  Widget build(BuildContext context) {
    final gc = context.gc;
    final allDone = _done.isNotEmpty && _done.every((d) => d);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        color: gc.bgRaised,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(children: [
            Text(t.practice.toUpperCase(),
                style: AppTheme.f(10.5, weight: FontWeight.w700, color: gc.textTertiary, letterSpacing: 1.3)),
            const Spacer(),
            _countChip(gc, '−', () => _setCount(_done.length - 1)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(t.setCount(_done.length),
                  style: AppTheme.f(13, weight: FontWeight.w700, color: gc.text)),
            ),
            _countChip(gc, '+', () => _setCount(_done.length + 1)),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            _stat(gc, widget.hold ? t.practiceHold : t.repsTitle, _reps, (v) => setState(() => _reps = v.clamp(1, 99))),
            const SizedBox(width: 10),
            _stat(gc, t.rest, _rest, (v) => setState(() => _rest = v.clamp(0, 300)), step: 15, clock: true),
          ]),
          if (_left > 0) ...[
            const SizedBox(height: 12),
            _restBar(gc),
          ],
          const SizedBox(height: 12),
          for (var i = 0; i < _done.length; i++) ...[
            if (i > 0) const SizedBox(height: 8),
            _setRow(gc, i),
          ],
          if (widget.onStartWorkout != null) ...[
            const SizedBox(height: 14),
            PrimaryButton(
              label: allDone ? t.trainAgain : t.startThis,
              icon: Ic.play,
              height: 48,
              bg: allDone ? gc.bgRaised2 : gc.ember,
              fg: allDone ? gc.text : gc.onEmber,
              onTap: () => widget.onStartWorkout!(_done.length),
            ),
          ],
        ],
      ),
    );
  }

  Widget _restBar(GymColors gc) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: gc.sageSoft,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(children: [
        Icon(PhosphorIconsFill.timer, size: 18, color: gc.sage),
        const SizedBox(width: 10),
        Text(_clock(_left), style: AppTheme.f(22, weight: FontWeight.w800, color: gc.text, height: 1)),
        const Spacer(),
        GestureDetector(
          onTap: () => setState(() => _left = (_left - 15).clamp(0, 999)),
          child: Text('−15', style: AppTheme.f(12, weight: FontWeight.w700, color: gc.textSecondary)),
        ),
        const SizedBox(width: 14),
        GestureDetector(
          onTap: () {
            _timer?.cancel();
            setState(() => _left = 0);
          },
          child: Text(t.skip, style: AppTheme.f(12, weight: FontWeight.w700, color: gc.sage)),
        ),
      ]),
    );
  }

  Widget _setRow(GymColors gc, int i) {
    final done = _done[i];
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _toggle(i),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: done ? gc.sageSoft : gc.bgRaised2,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(children: [
          SizedBox(
            width: 22,
            child: Text('${i + 1}',
                style: AppTheme.f(13, weight: FontWeight.w700, color: done ? gc.sage : gc.textTertiary)),
          ),
          Expanded(
            child: Text(
              widget.hold ? t.voiceSeconds(_reps) : t.practiceReps(_reps),
              style: AppTheme.f(15, weight: FontWeight.w700, color: gc.text),
            ),
          ),
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: done ? gc.sage : Colors.transparent,
              shape: BoxShape.circle,
              border: Border.all(color: done ? gc.sage : gc.border, width: 1.6),
            ),
            child: done ? Icon(PhosphorIconsBold.check, size: 14, color: gc.onEmber) : null,
          ),
        ]),
      ),
    );
  }

  Widget _stat(GymColors gc, String label, int value, ValueChanged<int> onChanged,
      {int step = 1, bool clock = false}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        decoration: BoxDecoration(color: gc.bgRaised2, borderRadius: BorderRadius.circular(16)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label.toUpperCase(),
              style: AppTheme.f(9.5, weight: FontWeight.w700, color: gc.textTertiary, letterSpacing: 1.1)),
          const SizedBox(height: 6),
          Row(children: [
            _countChip(gc, '−', () => onChanged(value - step)),
            Expanded(
              child: Text(clock ? _clock(value) : '$value',
                  textAlign: TextAlign.center,
                  style: AppTheme.f(18, weight: FontWeight.w800, color: gc.text)),
            ),
            _countChip(gc, '+', () => onChanged(value + step)),
          ]),
        ]),
      ),
    );
  }

  Widget _countChip(GymColors gc, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: gc.mutedFill, borderRadius: BorderRadius.circular(9)),
        child: Text(label, style: AppTheme.f(15, weight: FontWeight.w700, color: gc.text)),
      ),
    );
  }
}
