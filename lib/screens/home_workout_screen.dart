import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../catalog/home_workout.dart';
import '../l10n/l10n.dart';
import '../models/exercise.dart';
import '../state/fit_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/entrance.dart';
import '../widgets/exercise_media.dart';
import '../widgets/svg_icon.dart';
import '../widgets/ui_kit.dart';

class HomeWorkoutScreen extends StatefulWidget {
  const HomeWorkoutScreen({super.key});

  @override
  State<HomeWorkoutScreen> createState() => _HomeWorkoutScreenState();
}

class _HomeWorkoutScreenState extends State<HomeWorkoutScreen> {
  HomeKit _kit = HomeKit.none;
  HomeGoal? _goal;
  String? _muscle;

  List<Exercise> get _exercises {
    final all = fit.allExercises.where((e) => isHomeExercise(e) && !fit.isArchived(e.id));
    return [
      for (final e in all)
        if (homeKitOf(e) == _kit &&
            (_goal == null || _goal == HomeGoal.fullBody || homeGoalOf(e) == _goal) &&
            (_muscle == null || e.primary == _muscle || e.secondary.contains(_muscle)))
          e,
    ];
  }

  List<HomePlan> get _plans => homePlansFor(kit: _kit, goal: _goal);

  @override
  Widget build(BuildContext context) {
    final gc = context.gc;
    final exs = _exercises;
    final muscles = homeMusclesOf(exs);
    final muscle = muscles.contains(_muscle) ? _muscle : null;
    return RiseScope(
      id: 'home-workout',
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Row(
                children: [
                  RoundBtn(icon: Ic.chevronLeft, onTap: fit.closeHomeWorkout),
                  const Spacer(),
                  const SizedBox(width: 36),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
                children: riseAll([
                  Text(
                    t.homeWorkout,
                    style: AppTheme.f(28, weight: FontWeight.w800, color: gc.text, height: 1.05),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    t.homeWorkoutKicker,
                    style: AppTheme.f(14, weight: FontWeight.w500, color: gc.textSecondary),
                  ),
                  const SizedBox(height: 18),
                  _chips(
                    gc,
                    [
                      (t.kitNone, HomeKit.none, PhosphorIconsRegular.personSimpleWalk),
                      (t.kitSupport, HomeKit.support, PhosphorIconsRegular.chair),
                      (t.kitBar, HomeKit.bar, PhosphorIconsRegular.barbell),
                    ],
                    (v) => setState(() {
                      _kit = v;
                      _muscle = null;
                    }),
                    _kit,
                  ),
                  const SizedBox(height: 10),
                  _goalRow(gc),
                  if (_plans.isNotEmpty) ...[const SizedBox(height: 22), _planRow(gc, _plans)],
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      Text(
                        t.exercises,
                        style: AppTheme.f(13, weight: FontWeight.w700, color: gc.textTertiary),
                      ),
                      const Spacer(),
                      Text(
                        '${exs.length}',
                        style: AppTheme.f(13, weight: FontWeight.w700, color: gc.textTertiary),
                      ),
                    ],
                  ),
                  if (muscles.length > 1) ...[const SizedBox(height: 12), _muscleRow(gc, muscles, muscle)],
                  const SizedBox(height: 14),
                  if (exs.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 24),
                      child: Text(
                        t.noExercisesFound,
                        textAlign: TextAlign.center,
                        style: AppTheme.f(14, weight: FontWeight.w500, color: gc.textSecondary),
                      ),
                    )
                  else
                    _grid(gc, exs),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chips<T>(GymColors gc, List<(String, T, IconData)> items, ValueChanged<T> onPick, T current) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            _pill(gc, items[i].$1, items[i].$2 == current, () => onPick(items[i].$2), icon: items[i].$3),
          ],
        ],
      ),
    );
  }

  Widget _goalRow(GymColors gc) {
    const goals = HomeGoal.values;
    String label(HomeGoal g) => switch (g) {
      HomeGoal.fullBody => t.goalFullBody,
      HomeGoal.upper => t.goalUpper,
      HomeGoal.lower => t.goalLower,
      HomeGoal.core => t.goalCore,
      HomeGoal.cardio => t.goalCardio,
      HomeGoal.mobility => t.goalMobility,
    };
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var i = 0; i < goals.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            _pill(gc, label(goals[i]), _goal == goals[i], () {
              setState(() {
                _goal = _goal == goals[i] ? null : goals[i];
                _muscle = null;
              });
            }),
          ],
        ],
      ),
    );
  }

  Widget _muscleRow(GymColors gc, List<String> muscles, String? selected) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var i = 0; i < muscles.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            _pill(gc, muscleLabel(muscles[i]), selected == muscles[i], () {
              setState(() => _muscle = selected == muscles[i] ? null : muscles[i]);
            }),
          ],
        ],
      ),
    );
  }

  Widget _pill(GymColors gc, String label, bool on, VoidCallback onTap, {IconData? icon}) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: on ? gc.ember : gc.bgRaised,
          borderRadius: BorderRadius.circular(100),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: on ? gc.onEmber : gc.textSecondary),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: AppTheme.f(13, weight: FontWeight.w700, color: on ? gc.onEmber : gc.text),
            ),
          ],
        ),
      ),
    );
  }

  Widget _planRow(GymColors gc, List<HomePlan> plans) {
    return SizedBox(
      height: 168,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: plans.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (_, i) => _planCard(gc, plans[i]),
      ),
    );
  }

  String _planName(HomePlan p) => switch (p.nameKey) {
    'homePlanFullBody' => t.homePlanFullBody,
    'homePlanUpper' => t.homePlanUpper,
    'homePlanLower' => t.homePlanLower,
    'homePlanCore' => t.homePlanCore,
    'homePlanCardio' => t.homePlanCardio,
    'homePlanMobility' => t.homePlanMobility,
    _ => p.nameKey,
  };

  Widget _planCard(GymColors gc, HomePlan plan) {
    final lead = fit.exerciseById(plan.exerciseIds.first);
    return Pressable(
      onTap: () =>
          fit.startHomeSession(plan.exerciseIds, sets: {for (final id in plan.exerciseIds) id: plan.sets}),
      child: Container(
        width: 210,
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
        decoration: BoxDecoration(color: gc.bgRaised, borderRadius: BorderRadius.circular(22)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (lead != null)
                  SizedBox(
                    width: 56,
                    child: ExerciseMedia(ex: lead, height: 56, radius: 14, live: true, bordered: false),
                  ),
                const Spacer(),
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(color: gc.ember, shape: BoxShape.circle),
                  child: Icon(PhosphorIconsFill.play, size: 13, color: gc.onEmber),
                ),
              ],
            ),
            const Spacer(),
            Text(
              _planName(plan),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTheme.f(16, weight: FontWeight.w800, color: gc.text),
            ),
            const SizedBox(height: 3),
            Text(
              '${plan.exerciseIds.length} · ${t.setCount(plan.sets)}',
              style: AppTheme.f(12, weight: FontWeight.w500, color: gc.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _grid(GymColors gc, List<Exercise> exs) {
    return LayoutBuilder(
      builder: (context, box) {
        const gap = 12.0;
        final w = (box.maxWidth - gap) / 2;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [for (final e in exs) SizedBox(width: w, child: _exCard(gc, e))],
        );
      },
    );
  }

  Widget _exCard(GymColors gc, Exercise e) {
    return Pressable(
      onTap: () => fit.openExercise(e.id),
      child: Container(
        decoration: BoxDecoration(color: gc.bgRaised, borderRadius: BorderRadius.circular(20)),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ExerciseMedia(ex: e, height: 132, radius: 0, live: true, bordered: false),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    exerciseName(e),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.f(14, weight: FontWeight.w700, color: gc.text, height: 1.15),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    muscleLabel(e.primary),
                    maxLines: 1,
                    style: AppTheme.f(11.5, weight: FontWeight.w500, color: gc.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
