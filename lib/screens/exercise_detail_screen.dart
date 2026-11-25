import 'dart:math' as math;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../app/desktop.dart';
import '../l10n/l10n.dart';
import '../catalog/home_workout.dart';
import '../models/exercise.dart';
import '../models/workout.dart';
import '../services/exercise_match.dart';
import '../state/fit_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/body_map.dart';
import '../widgets/charts.dart';
import '../widgets/dialogs.dart';
import '../widgets/entrance.dart';
import '../widgets/exercise_history_sheet.dart';
import '../widgets/exercise_media.dart';
import '../widgets/exercise_diagram.dart';
import '../widgets/exercise_preview.dart';
import '../widgets/ruler_picker.dart';
import '../widgets/glass.dart';
import '../widgets/liquid_notch.dart';
import '../widgets/practice_tracker.dart';
import '../widgets/progression_sheet.dart';
import '../widgets/stopwatch_card.dart';
import '../widgets/svg_icon.dart';
import '../widgets/timer_panel.dart';
import '../widgets/ui_kit.dart';
import '../widgets/weight_stack_sheet.dart';
import 'exercises_screen.dart' show showCreateExerciseSheet;

class ExerciseDetailScreen extends StatefulWidget {
  const ExerciseDetailScreen({super.key});

  @override
  State<ExerciseDetailScreen> createState() => _ExerciseDetailScreenState();
}

class _ExerciseDetailScreenState extends State<ExerciseDetailScreen> {
  String get _exId => fit.activeExercise.id;
  String? _foldFor;
  bool _howOpen = true;
  bool _similarOpen = false;
  int _detailTab = 0; // 0 target, 1 instructions, 2 equipment (mobile sheet)

  String _fmtDate(DateTime d) => t.shortDate(d);

  Future<void> _pickMedia() async {
    try {
      final res = await FilePicker.platform.pickFiles(type: FileType.media);
      final path = res?.files.single.path;
      if (path != null) await fit.attachExerciseMedia(_exId, path);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final gc = context.gc;
    final ex = fit.activeExercise;
    final fav = fit.favorites[ex.id] ?? false;
    final steps = fit.activeExerciseSteps(ex);
    final pr = fit.exerciseRecord(ex.id);
    final oneRm = fit.oneRmSeries(ex.id);
    final bestReps = fit.bestRepsSeries(ex.id);
    final history = fit.exerciseHistory(ex.id);
    final hasMedia = fit.hasCustomMedia(ex.id);
    final mode = fit.modeOf(ex.id);
    final custom = fit.isCustom(ex.id);
    final archived = fit.isArchived(ex.id);
    final desktop = DesktopScope.of(context);
    if (_foldFor != ex.id) {
      _foldFor = ex.id;
      _howOpen = false;
      _similarOpen = false;
      _detailTab = 0;
    }
    final bar = Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          RoundBtn(icon: Ic.chevronLeft, onTap: fit.closeExerciseDetail),
          Row(
            children: [
              if (custom) ...[
                RoundAction(
                  label: t.delete,
                  onTap: () => _confirmDelete(context, ex),
                  child: Icon(PhosphorIconsRegular.trash, size: 16, color: gc.textSecondary),
                ),
                const SizedBox(width: 10),
                Semantics(
                  button: true,
                  label: t.editExercise,
                  child: RoundAction(
                    onTap: () => showCreateExerciseSheet(context, editing: ex),
                    child: Icon(PhosphorIconsRegular.pencilSimple, size: 16, color: gc.textSecondary),
                  ),
                ),
                const SizedBox(width: 10),
                if (history.isNotEmpty) ...[
                  RoundAction(
                    label: t.mergeExercise,
                    onTap: () => _merge(context, ex),
                    child: Icon(PhosphorIconsRegular.gitMerge, size: 16, color: gc.textSecondary),
                  ),
                  const SizedBox(width: 10),
                ],
              ],
              RoundAction(
                label: t.duplicateExercise,
                onTap: () => showCreateExerciseSheet(context, copyOf: ex),
                child: Icon(PhosphorIconsRegular.copy, size: 16, color: gc.textSecondary),
              ),
              const SizedBox(width: 10),
              RoundAction(
                label: archived ? t.restoreExercise : t.archiveExercise,
                onTap: () => _toggleArchived(context, ex),
                child: Icon(
                  archived ? PhosphorIconsFill.archive : PhosphorIconsRegular.archive,
                  size: 16,
                  color: archived ? gc.accent : gc.textSecondary,
                ),
              ),
              const SizedBox(width: 10),
              RoundAction(onTap: () => fit.toggleFavorite(ex.id), child: _star(gc, fav)),
            ],
          ),
        ],
      ),
    );
    final media = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Stack(
        children: [
          GestureDetector(
            onTap: () => showExercisePreview(context, ex),
            child: SizedBox(
              width: double.infinity,
              child: ExerciseMedia(ex: ex, height: 300, radius: 28, live: true, bordered: false),
            ),
          ),
          Positioned(
            bottom: 10,
            right: 10,
            child: Row(
              children: [
                if (hasMedia) ...[
                  _mediaBtn(
                    gc,
                    PhosphorIconsRegular.arrowCounterClockwise,
                    t.useDefaultArt,
                    () => fit.clearExerciseMedia(ex.id),
                  ),
                  const SizedBox(width: 8),
                ],
                _mediaBtn(
                  gc,
                  hasMedia ? PhosphorIconsRegular.pencilSimple : PhosphorIconsRegular.uploadSimple,
                  hasMedia ? t.changeMedia : t.addMedia,
                  _pickMedia,
                ),
              ],
            ),
          ),
        ],
      ),
    );
    final partA = <Widget>[
      AnimatedSize(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
        alignment: Alignment.topCenter,
        child: archived
            ? Padding(padding: const EdgeInsets.only(bottom: 16), child: _archivedBanner(gc, ex))
            : const SizedBox(width: double.infinity),
      ),
      Text(
        exerciseName(ex),
        style: AppTheme.f(26, weight: FontWeight.w800, color: gc.text, height: 1.1),
      ),
      if (ex.aliases.isNotEmpty) ...[
        const SizedBox(height: 6),
        Text(
          t.alsoCalled(ex.aliases.join(', ')),
          style: AppTheme.f(13, weight: FontWeight.w500, color: gc.textSecondary, height: 1.35),
        ),
      ],
      const SizedBox(height: 14),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _tag(gc, muscleLabel(ex.primary), accent: true, onTap: () => _editSecondary(context, ex.id)),
          for (final m in ex.secondary) _tag(gc, muscleLabel(m), onTap: () => _editSecondary(context, ex.id)),
          _tag(gc, t.equipment(ex.equipment)),
        ],
      ),
      if (exerciseCues(ex).isNotEmpty) ...[
        const SizedBox(height: 20),
        Text(
          t.cuesTitle.toUpperCase(),
          style: AppTheme.f(10.5, weight: FontWeight.w700, color: gc.textTertiary, letterSpacing: 1.3),
        ),
        const SizedBox(height: 10),
        for (final (i, cue) in exerciseCues(ex).indexed) ...[
          if (i > 0) const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 20,
                height: 20,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: gc.bgRaised2, shape: BoxShape.circle),
                child: Text(
                  '${i + 1}',
                  style: AppTheme.f(10.5, weight: FontWeight.w800, color: gc.textSecondary),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  cue,
                  style: AppTheme.f(13.5, weight: FontWeight.w500, color: gc.text, height: 1.35),
                ),
              ),
            ],
          ),
        ],
      ],
      const SizedBox(height: 18),
      PracticeTracker(
        key: ValueKey('practice-${ex.id}'),
        exerciseId: ex.id,
        initialSets: 3,
        initialReps: (isHomeHold(ex) || fit.modeOf(ex.id) == 'time') ? 30 : 12,
        initialRest: () {
          final r = fit.restFor(ex.id);
          return r <= 0 ? 45 : r;
        }(),
        hold: isHomeHold(ex) || fit.modeOf(ex.id) == 'time',
        onStartWorkout: (n) => fit.startHomeSession([ex.id], sets: {ex.id: n}),
      ),
      const SizedBox(height: 18),
      _addToRoutineRow(context, gc, ex),
      if (!desktop) ...[const SizedBox(height: 10), _settingsRow(context, gc, ex)],
      const SizedBox(height: 20),
      if (pr != null) ...[
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(color: gc.bgRaised, borderRadius: BorderRadius.circular(20)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _cardLabel(gc, t.personalRecord),
                        const SizedBox(height: 8),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: AlignmentDirectional.centerStart,
                          child: Text(
                            fit.recordLabel(pr),
                            maxLines: 1,
                            style: AppTheme.f(30, weight: FontWeight.w800, color: gc.text, height: 1),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: AlignmentDirectional.centerEnd,
                      child: Text(
                        fit.recordDetail(pr),
                        maxLines: 1,
                        style: AppTheme.f(12, weight: FontWeight.w500, color: gc.textSecondary),
                      ),
                    ),
                  ),
                ],
              ),
              if (fit.strengthToWeight(ex.id, pr) case final ratio?) ...[
                const SizedBox(height: 10),
                Text(
                  t.bodyweightRatio(fmt(ratio)),
                  style: AppTheme.f(12.5, weight: FontWeight.w600, color: gc.textSecondary),
                ),
              ],
              if (history.length > 1) _bests(gc, ex.id, pr.kind),
              if (pr.kind == PrKind.weight && oneRm.length > 2) ...[
                const SizedBox(height: 16),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => showExerciseHistorySheet(context, ex.id),
                  child: TrendChart(
                    values: [for (final v in oneRm) fit.toDisplayWeight(v)],
                    height: 84,
                    scale: fmt,
                  ),
                ),
              ],
              if (pr.kind == PrKind.reps && bestReps.length > 2) ...[
                const SizedBox(height: 16),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => showExerciseHistorySheet(context, ex.id),
                  child: TrendChart(values: bestReps, height: 84, scale: (v) => '${v.round()}'),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),
      ],
      if (fit.goalFits(ex.id)) ...[_goalCard(context, gc, ex.id), const SizedBox(height: 20)],
      if (fit.nextTargetLabel(ex.id) != null) ...[_nextCard(gc, ex.id), const SizedBox(height: 20)],
    ];
    final historyPart = <Widget>[
      _heading(
        gc,
        t.history,
        onMore: history.isEmpty ? null : () => showExerciseHistorySheet(context, ex.id),
      ),
      const SizedBox(height: 4),
      if (history.isEmpty)
        Text(
          t.noHistory,
          style: AppTheme.f(13, weight: FontWeight.w500, color: gc.textSecondary),
        )
      else
        for (int i = 0; i < history.length && i < 5; i++)
          _historyRow(gc, history[i], i < history.length - 1 && i < 4, mode),
      const SizedBox(height: 24),
      _notesRow(gc, ex.id),
      const SizedBox(height: 24),
    ];
    final howTo = <Widget>[
      if (steps.isNotEmpty || custom) ...[
        _fold(
          gc,
          t.howTo,
          _howOpen,
          () => setState(() => _howOpen = !_howOpen),
          trailing: custom && steps.isNotEmpty && _howOpen
              ? Semantics(
                  button: true,
                  label: t.editExercise,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => showCreateExerciseSheet(context, editing: ex),
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: Icon(PhosphorIconsRegular.pencilSimple, size: 17, color: gc.textTertiary),
                    ),
                  ),
                )
              : null,
          [
            if (steps.isEmpty) ...[
              Text(
                t.noStepsYet,
                style: AppTheme.f(13, weight: FontWeight.w500, color: gc.textSecondary, height: 1.45),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: Pill(
                  label: t.addSteps,
                  bg: gc.bgRaised2,
                  fg: gc.accent,
                  onTap: () => showCreateExerciseSheet(context, editing: ex),
                ),
              ),
            ],
            for (int i = 0; i < steps.length; i++) ...[
              _step(gc, i + 1, steps[i]),
              if (i < steps.length - 1) const SizedBox(height: 14),
            ],
          ],
        ),
        const SizedBox(height: 24),
      ],
    ];
    final similar = fit.similarExercises(ex, 4);
    final tail = <Widget>[
      if (desktop) ...[
        _section(gc, t.exerciseSettings),
        const SizedBox(height: 12),
        _group(gc, _settingsRows(context, gc, ex)),
        const SizedBox(height: 24),
      ],
      if (fit.runsClock(ex.id)) ...[
        _section(gc, t.stopwatch),
        const SizedBox(height: 10),
        const StopwatchCard(),
        const SizedBox(height: 24),
      ],
      if (fit.alternativesHere(ex, 3).isNotEmpty) ...[_notHere(gc, ex), const SizedBox(height: 24)],
      if (similar.isNotEmpty)
        _fold(gc, t.similar, _similarOpen, () => setState(() => _similarOpen = !_similarOpen), [
          for (final s in similar) _similarRow(gc, s),
        ]),
    ];
    if (desktop) {
      return RiseScope(
        key: ValueKey(ex.id),
        id: 'exercise',
        once: false,
        child: SingleChildScrollView(
          clipBehavior: Clip.none,
          padding: EdgeInsets.fromLTRB(12, MediaQuery.paddingOf(context).top + 12, 12, 48),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Rise(index: 0, child: bar),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Rise(index: 1, child: media),
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Rise(
                            index: 2,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [...partA, ...historyPart],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 460,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(8, 0, 20, 20),
                      child: Rise(
                        index: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [...howTo, ...tail],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    return _mobileStudio(
      context: context,
      gc: gc,
      ex: ex,
      fav: fav,
      steps: steps,
      custom: custom,
      archived: archived,
      hasMedia: hasMedia,
      history: history,
      howTo: howTo,
      historyPart: historyPart,
      tail: tail,
    );
  }

  bool get _inWidgetTest => WidgetsBinding.instance.runtimeType.toString().contains('TestWidgets');

  static const _sheet = Color(0xFF1C1C1E);
  static const _sheetRaised = Color(0xFF2C2C2E);
  static const _canvas = kDemoCanvasTop;
  static const _handle = Color(0xFF636366);
  static const _label = Color(0xFF8E8E93);
  static const _onSheet = Color(0xFFFFFFFF);
  static const _muted = Color(0xFFC7C7CC);
  static const _badgeBg = Color(0xFF3A3A3C);
  static const _badgeFg = Color(0xFFD1D1D6);
  static const _tabOff = Color(0xFF3A3A3C);
  static const _iconTile = Color(0xFF2C2C2E);
  static const _chrome = Color(0xFF1C1C1E);

  Widget _mobileStudio({
    required BuildContext context,
    required GymColors gc,
    required Exercise ex,
    required bool fav,
    required List<String> steps,
    required bool custom,
    required bool archived,
    required bool hasMedia,
    required List history,
    required List<Widget> howTo,
    required List<Widget> historyPart,
    required List<Widget> tail,
  }) {
    final pad = MediaQuery.paddingOf(context);
    final size = MediaQuery.sizeOf(context);
    final canvasH = size.height * 0.46;
    return ColoredBox(
      color: _canvas,
      child: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: canvasH,
            child: GestureDetector(
              onTap: () => showExercisePreview(context, ex),
              child: DecoratedBox(
                decoration: const BoxDecoration(gradient: kDemoCanvasGradient),
                child: ExerciseMedia(
                  ex: ex,
                  height: canvasH,
                  radius: 0,
                  // Widget tests cannot host a video player; they get the poster via live:false.
                  live: !_inWidgetTest,
                  bordered: false,
                ),
              ),
            ),
          ),
          Positioned(
            top: pad.top + 12,
            left: 16,
            right: 16,
            child: Row(
              children: [
                _chromeBtn(
                  icon: PhosphorIconsRegular.caretLeft,
                  label: t.back,
                  onTap: fit.closeExerciseDetail,
                ),
                const Spacer(),
                _mobileOverflow(
                  context,
                  gc,
                  ex,
                  custom: custom,
                  archived: archived,
                  hasMedia: hasMedia,
                  history: history,
                ),
                const SizedBox(width: 8),
                _chromeBtn(
                  icon: fav ? PhosphorIconsFill.star : PhosphorIconsRegular.star,
                  label: t.favouritesOnly,
                  onTap: () => fit.toggleFavorite(ex.id),
                  iconColor: fav ? const Color(0xFFF2F2F7) : _onSheet,
                ),
              ],
            ),
          ),
          DraggableScrollableSheet(
            initialChildSize: 0.58,
            minChildSize: 0.50,
            maxChildSize: 0.94,
            builder: (ctx, scroll) {
              return Container(
                decoration: const BoxDecoration(
                  color: _sheet,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: ListView(
                  controller: scroll,
                  padding: EdgeInsets.fromLTRB(20, 8, 20, 28 + pad.bottom),
                  children: [
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        margin: const EdgeInsets.only(top: 4, bottom: 16),
                        decoration: BoxDecoration(color: _handle, borderRadius: BorderRadius.circular(99)),
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          muscleLabel(ex.primary).toUpperCase(),
                          style: AppTheme.f(11, weight: FontWeight.w600, color: _label, letterSpacing: 1.2),
                        ),
                        if (isHomeExercise(ex)) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: _badgeBg,
                              borderRadius: BorderRadius.circular(99),
                            ),
                            child: Text(
                              'POPULAR',
                              style: AppTheme.f(
                                9.5,
                                weight: FontWeight.w700,
                                color: _badgeFg,
                                letterSpacing: 0.6,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      exerciseName(ex),
                      style: AppTheme.f(28, weight: FontWeight.w800, color: _onSheet, height: 1.1),
                    ),
                    const SizedBox(height: 18),
                    _sheetTabs(),
                    const SizedBox(height: 20),
                    if (_detailTab == 0) _targetTab(ex),
                    if (_detailTab == 1) _instructionsTab(context, gc, ex, steps, howTo, historyPart, tail),
                    if (_detailTab == 2) _equipmentTab(ex),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _chromeBtn({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: _chrome,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: SizedBox(width: 40, height: 40, child: Icon(icon, size: 20, color: iconColor ?? _onSheet)),
        ),
      ),
    );
  }

  Widget _mobileOverflow(
    BuildContext context,
    GymColors gc,
    Exercise ex, {
    required bool custom,
    required bool archived,
    required bool hasMedia,
    required List history,
  }) {
    return PopupMenuButton<String>(
      tooltip: t.moreOptions,
      color: _sheetRaised,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      onSelected: (value) {
        switch (value) {
          case 'media':
            _pickMedia();
          case 'clear-media':
            fit.clearExerciseMedia(ex.id);
          case 'duplicate':
            showCreateExerciseSheet(context, copyOf: ex);
          case 'edit':
            showCreateExerciseSheet(context, editing: ex);
          case 'delete':
            _confirmDelete(context, ex);
          case 'archive':
            _toggleArchived(context, ex);
          case 'merge':
            _merge(context, ex);
          case 'history':
            showExerciseHistorySheet(context, ex.id);
          case 'settings':
            _openSettingsSheet(context, gc, ex);
        }
      },
      itemBuilder: (ctx) => [
        PopupMenuItem(
          value: 'media',
          child: _menuItem(hasMedia ? t.changeMedia : t.addMedia, PhosphorIconsRegular.uploadSimple),
        ),
        if (hasMedia)
          PopupMenuItem(
            value: 'clear-media',
            child: _menuItem(t.useDefaultArt, PhosphorIconsRegular.arrowCounterClockwise),
          ),
        PopupMenuItem(value: 'duplicate', child: _menuItem(t.duplicateExercise, PhosphorIconsRegular.copy)),
        if (custom)
          PopupMenuItem(value: 'edit', child: _menuItem(t.editExercise, PhosphorIconsRegular.pencilSimple)),
        if (custom && history.isNotEmpty)
          PopupMenuItem(value: 'merge', child: _menuItem(t.mergeExercise, PhosphorIconsRegular.gitMerge)),
        PopupMenuItem(
          value: 'archive',
          child: _menuItem(archived ? t.restoreExercise : t.archiveExercise, PhosphorIconsRegular.archive),
        ),
        if (custom) PopupMenuItem(value: 'delete', child: _menuItem(t.delete, PhosphorIconsRegular.trash)),
        PopupMenuItem(
          value: 'history',
          child: _menuItem(t.history, PhosphorIconsRegular.clockCounterClockwise),
        ),
        PopupMenuItem(
          value: 'settings',
          child: _menuItem(t.exerciseSettings, PhosphorIconsRegular.slidersHorizontal),
        ),
      ],
      child: const Material(
        color: _chrome,
        shape: CircleBorder(),
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(PhosphorIconsRegular.dotsThree, size: 20, color: _onSheet),
        ),
      ),
    );
  }

  Widget _menuItem(String label, IconData icon) => Row(
    children: [
      Icon(icon, size: 18, color: _muted),
      const SizedBox(width: 10),
      Expanded(
        child: Text(
          label,
          style: AppTheme.f(14, weight: FontWeight.w600, color: _onSheet),
        ),
      ),
    ],
  );

  void _openSettingsSheet(BuildContext context, GymColors gc, Exercise ex) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: _sheet,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(16, 12, 16, 24 + MediaQuery.paddingOf(ctx).bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(color: _handle, borderRadius: BorderRadius.circular(99)),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              t.exerciseSettings,
              style: AppTheme.f(18, weight: FontWeight.w800, color: _onSheet),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF4F4F5),
                borderRadius: BorderRadius.circular(20),
              ),
              clipBehavior: Clip.antiAlias,
              child: _group(gc, _settingsRows(context, gc, ex)),
            ),
            const SizedBox(height: 16),
            _addToRoutineRow(context, gc, ex),
          ],
        ),
      ),
    );
  }

  Widget _sheetTabs() {
    const labels = ['TARGET', 'INSTRUCTIONS', 'EQUIPMENT'];
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(color: _tabOff, borderRadius: BorderRadius.circular(99)),
      child: Row(
        children: [
          for (int i = 0; i < labels.length; i++)
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _detailTab = i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: _detailTab == i ? _onSheet : Colors.transparent,
                    borderRadius: BorderRadius.circular(99),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    labels[i],
                    style: AppTheme.f(
                      10.5,
                      weight: FontWeight.w700,
                      color: _detailTab == i ? const Color(0xFF111111) : _muted,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _targetTab(Exercise ex) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _muscleRow('PRIMARY', ex.primary),
        const SizedBox(height: 14),
        Text(
          'SECONDARY',
          style: AppTheme.f(11, weight: FontWeight.w600, color: _label, letterSpacing: 1.1),
        ),
        const SizedBox(height: 10),
        for (final m in ex.secondary) ...[_muscleRow(null, m), const SizedBox(height: 10)],
        if (ex.secondary.isEmpty)
          Text(
            '—',
            style: AppTheme.f(14, weight: FontWeight.w500, color: _muted),
          ),
      ],
    );
  }

  Widget _muscleRow(String? heading, String id) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (heading != null) ...[
          Text(
            heading,
            style: AppTheme.f(11, weight: FontWeight.w600, color: _label, letterSpacing: 1.1),
          ),
          const SizedBox(height: 10),
        ],
        Row(
          children: [
            Container(
              width: 88,
              height: 108,
              decoration: BoxDecoration(
                color: const Color(0xFFF7F9EE),
                borderRadius: BorderRadius.circular(16),
              ),
              clipBehavior: Clip.antiAlias,
              alignment: Alignment.center,
              child: BodyZoneArt(muscles: [id], height: 100, color: context.gc.ember),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                muscleLabel(id),
                style: AppTheme.f(16, weight: FontWeight.w700, color: _onSheet),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _instructionsTab(
    BuildContext context,
    GymColors gc,
    Exercise ex,
    List<String> steps,
    List<Widget> howTo,
    List<Widget> historyPart,
    List<Widget> tail,
  ) {
    final cues = exerciseCues(ex);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (cues.isNotEmpty) ...[
          Text(
            'CUES',
            style: AppTheme.f(11, weight: FontWeight.w600, color: _label, letterSpacing: 1.1),
          ),
          const SizedBox(height: 10),
          for (final (i, cue) in cues.indexed) ...[
            if (i > 0) const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${i + 1}.',
                  style: AppTheme.f(13, weight: FontWeight.w700, color: _muted),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    cue,
                    style: AppTheme.f(14, weight: FontWeight.w500, color: _onSheet, height: 1.4),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 20),
        ],
        if (steps.isNotEmpty) ...[
          Text(
            'HOW TO',
            style: AppTheme.f(11, weight: FontWeight.w600, color: _label, letterSpacing: 1.1),
          ),
          const SizedBox(height: 10),
          for (int i = 0; i < steps.length; i++) ...[
            if (i > 0) const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${i + 1}.',
                  style: AppTheme.f(13, weight: FontWeight.w700, color: _muted),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    steps[i],
                    style: AppTheme.f(14, weight: FontWeight.w500, color: _onSheet, height: 1.4),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 20),
        ],
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: const Color(0xFFF4F4F5), borderRadius: BorderRadius.circular(20)),
          child: PracticeTracker(
            key: ValueKey('practice-${ex.id}'),
            exerciseId: ex.id,
            initialSets: 3,
            initialReps: (isHomeHold(ex) || fit.modeOf(ex.id) == 'time') ? 30 : 12,
            initialRest: () {
              final r = fit.restFor(ex.id);
              return r <= 0 ? 45 : r;
            }(),
            hold: isHomeHold(ex) || fit.modeOf(ex.id) == 'time',
            onStartWorkout: (n) => fit.startHomeSession([ex.id], sets: {ex.id: n}),
          ),
        ),
        const SizedBox(height: 14),
        Container(
          decoration: BoxDecoration(color: const Color(0xFFF4F4F5), borderRadius: BorderRadius.circular(20)),
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _addToRoutineRow(context, gc, ex),
              const SizedBox(height: 8),
              _settingsRow(context, gc, ex),
              ...historyPart,
              ...tail.where((w) => true),
            ],
          ),
        ),
      ],
    );
  }

  Widget _equipmentTab(Exercise ex) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(color: _iconTile, borderRadius: BorderRadius.circular(14)),
              alignment: Alignment.center,
              child: const Icon(PhosphorIconsRegular.barbell, size: 22, color: _muted),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                t.equipment(ex.equipment),
                style: AppTheme.f(16, weight: FontWeight.w700, color: _onSheet),
              ),
            ),
          ],
        ),
        if (ex.equipment == 'Bodyweight') ...[
          const SizedBox(height: 14),
          Text(
            'No equipment needed.',
            style: AppTheme.f(14, weight: FontWeight.w500, color: _muted, height: 1.4),
          ),
        ],
      ],
    );
  }

  List<Widget> _settingsRows(BuildContext context, GymColors gc, Exercise ex) {
    final mode = fit.modeOf(ex.id);
    final repsOnly = fit.isRepsOnly(ex.id);
    return [
      _modeRow(context, gc, ex.id, mode),
      if (mode != 'cardio') _repsOnlyRow(gc, ex.id, repsOnly),
      if (mode == 'time') ...[
        _switchRow(
          gc,
          PhosphorIconsRegular.arrowsLeftRight,
          t.eachSide,
          t.eachSideHint,
          fit.isEachSide(ex.id),
          () => fit.toggleEachSide(ex.id),
        ),
        if (!fit.isEachSide(ex.id)) _keepCountingRow(gc, ex.id),
        _holdProgressRow(gc, ex.id),
      ] else if (mode.isEmpty)
        _switchRow(
          gc,
          PhosphorIconsRegular.arrowsLeftRight,
          t.eachSide,
          t.eachSideRepsHint,
          fit.isSidedReps(ex.id),
          () => fit.toggleSidedReps(ex.id),
        ),
      if (mode == 'cardio') _keepCountingRow(gc, ex.id),
      _restRow(gc, ex.id),
      if (ex.equipment == 'Barbell' || ex.equipment == 'Machine') _barRow(gc, ex),
      if ((ex.equipment == 'Machine' || ex.equipment == 'Cable') && mode.isEmpty && !repsOnly)
        _stackRow(context, gc, ex.id),
      _switchRow(
        gc,
        PhosphorIconsRegular.sparkle,
        t.suggestInWorkouts,
        t.suggestInWorkoutsHint,
        fit.suggests(ex.id),
        () => fit.toggleSuggest(ex.id),
      ),
      if (fit.canCarryBody(ex.id))
        _switchRow(
          gc,
          PhosphorIconsRegular.personSimple,
          t.bodyLoadSetting,
          t.bodyLoadSettingHint,
          fit.carriesBody(ex.id),
          () => fit.toggleCarriesBody(ex.id),
        ),
      if (fit.canCarryBody(ex.id) && fit.carriesBody(ex.id)) _bodyShareRow(gc, ex.id),
      if (!repsOnly && mode.isEmpty) ...[
        _switchRow(
          gc,
          PhosphorIconsRegular.arrowFatLinesDown,
          t.assistedSetting,
          t.assistedSettingHint,
          fit.isAssisted(ex.id),
          () => fit.toggleAssisted(ex.id),
        ),
        if (fit.canPair(ex.id))
          _switchRow(
            gc,
            PhosphorIconsRegular.barbell,
            t.pairSetting,
            t.pairSettingHint,
            fit.isPaired(ex.id),
            () => fit.togglePaired(ex.id),
          ),
        _progressRow(context, gc, ex.id),
        _switchRow(
          gc,
          PhosphorIconsRegular.fire,
          t.autoWarmup,
          t.autoWarmupHint,
          fit.warmsUp(ex.id),
          () => fit.toggleAutoWarmup(ex.id),
        ),
      ],
    ];
  }

  Widget _settingsRow(BuildContext context, GymColors gc, Exercise ex) {
    final mode = fit.modeOf(ex.id);
    final values = [
      (t.restTimer, fit.restFor(ex.id) == 0 ? t.restOff : clockLabel(fit.restFor(ex.id))),
      if (mode.isEmpty)
        (t.progression, progressKindName(fit.progressRule(ex.id).kind))
      else
        (t.exerciseTypeLabel, _modeName(mode)),
    ];
    return Semantics(
      button: true,
      label: t.exerciseSettings,
      child: Pressable(
        onTap: () => _openSettings(context, ex.id),
        scale: 0.98,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
          decoration: BoxDecoration(color: gc.bgRaised, borderRadius: BorderRadius.circular(20)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  _rowIcon(gc, PhosphorIconsRegular.slidersHorizontal, true),
                  Expanded(
                    child: Text(
                      t.exerciseSettings,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.f(14.5, weight: FontWeight.w600, color: gc.text),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Icon(PhosphorIconsRegular.caretRight, size: 15, color: gc.textTertiary),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var i = 0; i < values.length; i++) ...[
                    if (i > 0) const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
                        decoration: BoxDecoration(
                          color: gc.bgRaised2,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _cardLabel(gc, values[i].$1),
                            const SizedBox(height: 4),
                            Text(
                              values[i].$2,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTheme.f(13.5, weight: FontWeight.w700, color: gc.text),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openSettings(BuildContext context, String id) {
    showAppSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheet) => AnimatedBuilder(
        animation: fit,
        builder: (sheet, _) {
          final gc = sheet.gc;
          final ex = fit.exerciseById(id);
          if (ex == null) return const SizedBox.shrink();
          return Container(
            padding: sheetPad(sheet),
            constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(sheet).height * 0.86),
            decoration: sheetDecoration(gc),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SheetHandle(),
                const SizedBox(height: 16),
                SheetTitle(t.exerciseSettings, subtitle: exerciseName(ex)),
                const SizedBox(height: 14),
                Flexible(child: SingleChildScrollView(child: _group(gc, _settingsRows(sheet, gc, ex)))),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _fold(
    GymColors gc,
    String label,
    bool open,
    VoidCallback onToggle,
    List<Widget> children, {
    Widget? trailing,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          button: true,
          expanded: open,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              HapticFeedback.selectionClick();
              onToggle();
            },
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 44),
              child: Row(
                children: [
                  Expanded(child: _section(gc, label)),
                  ?trailing,
                  const SizedBox(width: 6),
                  AnimatedRotation(
                    turns: open ? 0.5 : 0,
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    child: Icon(PhosphorIconsBold.caretDown, size: 14, color: gc.textTertiary),
                  ),
                ],
              ),
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: open
              ? Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
                )
              : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }

  Widget _heading(GymColors gc, String title, {VoidCallback? onMore}) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 44),
      child: Row(
        children: [
          Expanded(child: _section(gc, title)),
          if (onMore != null)
            Semantics(
              button: true,
              child: Pressable(
                onTap: onMore,
                child: Container(
                  height: 30,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: gc.bgRaised, borderRadius: BorderRadius.circular(15)),
                  child: Text(
                    t.healthSeeAll,
                    style: AppTheme.f(12, weight: FontWeight.w700, color: gc.text),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _notHere(GymColors gc, Exercise ex) {
    final place = fit.activePlace!;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: gc.bgRaised,
        border: Border.all(color: gc.warn.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(PhosphorIconsRegular.mapPin, size: 16, color: gc.warn),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  t.notHere(t.equipment(ex.equipment).toLowerCase(), place.name),
                  style: AppTheme.f(14, weight: FontWeight.w600, color: gc.text),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsetsDirectional.only(start: 26),
            child: Text(
              t.notHereWhy,
              style: AppTheme.f(12.5, weight: FontWeight.w500, color: gc.textSecondary, height: 1.4),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            t.altHere,
            style: AppTheme.f(10.5, weight: FontWeight.w700, color: gc.textTertiary, letterSpacing: 1.5),
          ),
          const SizedBox(height: 6),
          for (final alt in fit.alternativesHere(ex, 3)) _similarRow(gc, alt),
        ],
      ),
    );
  }

  String _setsLine(LoggedExercise e) {
    final rpe = e.sets.map((s) => s.rpe).whereType<double>().toList();
    final sets = t.setCount(e.sets.length);
    if (rpe.isEmpty) return sets;
    return '$sets · ${fit.effortLabel(rpe.reduce((a, b) => a > b ? a : b))}';
  }

  String _bestOf(LoggedExercise e, String mode) {
    final working = e.workingSets;
    if (working.isEmpty) return '';
    if (mode == 'cardio') {
      final km = working.fold<double>(0, (s, x) => s + (x.km ?? 0));
      return km > 0
          ? fit.distanceLabelFor(e.id, km)
          : durationLabel(working.fold<int>(0, (s, x) => s + (x.sec ?? 0)));
    }
    return durationLabel(working.fold<int>(0, (s, x) => (x.sec ?? 0) > s ? x.sec! : s));
  }

  Widget _historyRow(GymColors gc, ({DateTime date, LoggedExercise ex}) h, bool border, String mode) {
    final e = h.ex;
    if (mode.isNotEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          border: border ? Border(bottom: BorderSide(color: gc.border.withValues(alpha: 0.55))) : null,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _fmtDate(h.date),
                    style: AppTheme.f(14.5, weight: FontWeight.w600, color: gc.text),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    fit.setsSummary(e.sets),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.f(12, weight: FontWeight.w500, color: gc.textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              _bestOf(e, mode),
              style: AppTheme.f(17, weight: FontWeight.w700, color: gc.text),
            ),
          ],
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 13),
      decoration: BoxDecoration(
        border: border ? Border(bottom: BorderSide(color: gc.border.withValues(alpha: 0.55))) : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _fmtDate(h.date),
                style: AppTheme.f(14.5, weight: FontWeight.w600, color: gc.text),
              ),
              const SizedBox(height: 3),
              Text(
                _setsLine(e),
                style: AppTheme.f(12, weight: FontWeight.w500, color: gc.textSecondary),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                fit.weightLabel(fit.headlineWeight(e)),
                style: AppTheme.f(17, weight: FontWeight.w700, color: gc.text),
              ),
              const SizedBox(height: 3),
              Text(
                t.volumeSuffix(fit.volumeLabel(e.volume)),
                style: AppTheme.f(11.5, weight: FontWeight.w500, color: gc.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _notesRow(GymColors gc, String exId) {
    final n = fit.notesFor(exId).length;
    return Semantics(
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => fit.goNotes(exerciseId: exId, all: true),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          decoration: BoxDecoration(color: gc.bgRaised, borderRadius: BorderRadius.circular(20)),
          child: Row(
            children: [
              _rowIcon(gc, PhosphorIconsRegular.notebook, n > 0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titleCase(t.notes),
                      style: AppTheme.f(14.5, weight: FontWeight.w500, color: gc.text),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      n == 0 ? t.noteNoneForExercise : t.noteCount(n),
                      style: AppTheme.f(11.5, weight: FontWeight.w500, color: gc.textSecondary),
                    ),
                  ],
                ),
              ),
              Icon(PhosphorIconsRegular.caretRight, size: 15, color: gc.textTertiary),
            ],
          ),
        ),
      ),
    );
  }

  Widget _addToRoutineRow(BuildContext context, GymColors gc, Exercise ex) {
    final n = fit.routinesWith(ex.id);
    return Semantics(
      button: true,
      child: Pressable(
        onTap: () => _pickRoutine(context, ex),
        scale: 0.98,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          decoration: BoxDecoration(color: gc.bgRaised, borderRadius: BorderRadius.circular(20)),
          child: Row(
            children: [
              _rowIcon(gc, PhosphorIconsRegular.listPlus, n > 0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.addToRoutine,
                      style: AppTheme.f(14.5, weight: FontWeight.w600, color: gc.text),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      t.inRoutines(n),
                      style: AppTheme.f(11.5, weight: FontWeight.w500, color: gc.textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(color: gc.text, shape: BoxShape.circle),
                child: Icon(PhosphorIconsBold.plus, size: 14, color: gc.bg),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _pickRoutine(BuildContext context, Exercise ex) {
    final gc = context.gc;
    final routines = [
      for (final group in fit.routineGroups) ...fit.routinesInGroup(group),
      ...fit.routinesInGroup(''),
    ];
    void pick(BuildContext sheet, String? id) {
      Navigator.pop(sheet);
      fit.addToRoutineAndEdit(id, ex.id);
    }

    showAppSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheet) => Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(sheet).height * 0.72),
        padding: sheetPad(sheet),
        decoration: sheetDecoration(gc),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SheetHandle(),
            const SizedBox(height: 16),
            SheetTitle(titleCase(t.addToRoutine)),
            const SizedBox(height: 4),
            Text(
              exerciseName(ex),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: AppTheme.f(12.5, weight: FontWeight.w500, color: gc.textSecondary),
            ),
            const SizedBox(height: 14),
            Flexible(
              child: OptionGroup(scroll: true, [
                OptionItem(t.newRoutineName, icon: PhosphorIconsRegular.plus, onTap: () => pick(sheet, null)),
                for (final r in routines)
                  OptionItem(
                    fit.routineTitle(r),
                    detail: fit.routineHas(r.id, ex.id)
                        ? t.alreadyInRoutine
                        : (r.group.isEmpty ? null : r.group),
                    selected: fit.routineHas(r.id, ex.id),
                    onTap: () => pick(sheet, r.id),
                  ),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _similarRow(GymColors gc, Exercise s) {
    return GestureDetector(
      onTap: () => fit.openExercise(s.id),
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.fromLTRB(12, 9, 14, 9),
        decoration: BoxDecoration(color: gc.bgRaised, borderRadius: BorderRadius.circular(18)),
        child: Row(
          children: [
            SizedBox(width: 48, child: ExerciseMedia(ex: s, height: 48, radius: 14, bordered: false)),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    exerciseName(s),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.f(14.5, weight: FontWeight.w600, color: gc.text),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    t.equipment(s.equipment),
                    style: AppTheme.f(12, weight: FontWeight.w500, color: gc.textSecondary),
                  ),
                ],
              ),
            ),
            SvgPathIcon(Ic.chevronRight, size: 15, color: gc.textTertiary),
          ],
        ),
      ),
    );
  }

  Widget _tag(GymColors gc, String label, {bool accent = false, VoidCallback? onTap}) {
    final child = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: accent ? gc.accentSoft : gc.bgRaised2,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        label,
        style: AppTheme.f(12, weight: FontWeight.w700, color: accent ? gc.accent : gc.textSecondary),
      ),
    );
    if (onTap == null) return child;
    return GestureDetector(onTap: onTap, child: child);
  }

  void _editSecondary(BuildContext context, String id) {
    showAppSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheet) => AnimatedBuilder(
        animation: fit,
        builder: (sheet, _) {
          final gc = sheet.gc;
          final ex = fit.exerciseById(id);
          if (ex == null) return const SizedBox.shrink();
          return Container(
            padding: sheetPad(sheet),
            decoration: sheetDecoration(gc),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SheetHandle(),
                const SizedBox(height: 16),
                SheetTitle(exerciseName(ex), subtitle: t.secondaryPickHint),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final m in kMuscles)
                      if (m.id != ex.primary)
                        Pill(
                          label: t.muscle(m.id),
                          bg: ex.secondary.contains(m.id) ? gc.ember : gc.bgRaised2,
                          fg: ex.secondary.contains(m.id) ? gc.onEmber : gc.textSecondary,
                          vPad: 7,
                          onTap: () => fit.setSecondary(
                            id,
                            ex.secondary.contains(m.id)
                                ? [...ex.secondary.where((s) => s != m.id)]
                                : [...ex.secondary, m.id],
                          ),
                        ),
                  ],
                ),
                if (fit.hasSecondaryOverride(id))
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => fit.resetSecondary(id),
                    child: Container(
                      height: 44,
                      margin: const EdgeInsets.only(top: 8),
                      alignment: Alignment.center,
                      child: Text(
                        t.alarmReset,
                        style: AppTheme.f(13, weight: FontWeight.w600, color: gc.accent),
                      ),
                    ),
                  )
                else
                  const SizedBox(height: 18),
                PrimaryButton(label: t.done, onTap: () => Navigator.of(sheet).pop()),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, Exercise ex) async {
    final ok = await askConfirm(
      context,
      title: t.deleteExerciseTitle,
      body: t.deleteExerciseBody(exerciseName(ex)),
      confirmLabel: t.delete,
      danger: true,
    );
    if (!ok) return;
    fit.closeExerciseDetail();
    fit.deleteCustomExercise(ex.id);
  }

  Future<void> _merge(BuildContext context, Exercise ex) async {
    final toId = await showAppSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _MergeTargetSheet(from: ex),
    );
    if (toId == null || !context.mounted) return;
    final to = fit.exerciseById(toId);
    if (to == null) return;
    final ok = await askConfirm(
      context,
      title: t.mergeExerciseTitle,
      body: t.mergeExerciseBody(exerciseName(ex), exerciseName(to)),
      confirmLabel: t.mergeExercise,
    );
    if (!ok || !context.mounted) return;
    fit.mergeExerciseInto(ex.id, to.id);
    showNotchToast(
      context,
      t.mergedToast,
      subtitle: exerciseName(to),
      icon: PhosphorIconsRegular.gitMerge,
      accent: context.gc.accent,
    );
  }

  void _toggleArchived(BuildContext context, Exercise ex) {
    fit.toggleArchived(ex.id);
    if (!fit.isArchived(ex.id)) return;
    showNotchToast(
      context,
      t.archivedToast,
      subtitle: t.archivedToastHint,
      icon: PhosphorIconsFill.archive,
      accent: context.gc.accent,
      action: t.undo,
      onTap: () => fit.toggleArchived(ex.id),
      duration: const Duration(milliseconds: 3600),
    );
  }

  Widget _archivedBanner(GymColors gc, Exercise ex) => Container(
    padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
    decoration: BoxDecoration(color: gc.accentSoft, borderRadius: BorderRadius.circular(16)),
    child: Row(
      children: [
        Icon(PhosphorIconsFill.archive, size: 17, color: gc.accent),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            t.archivedBanner,
            style: AppTheme.f(12.5, weight: FontWeight.w600, color: gc.text, height: 1.35),
          ),
        ),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => fit.toggleArchived(ex.id),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Text(
              t.restoreExercise,
              style: AppTheme.f(13, weight: FontWeight.w700, color: gc.accent),
            ),
          ),
        ),
      ],
    ),
  );

  Widget _bests(GymColors gc, String id, PrKind record) {
    final set = record == PrKind.weight ? fit.bestSet(id) : null;
    final kind = record == PrKind.weight && fit.isAssisted(id) ? PrKind.reps : record;
    final work = fit.bestWorkout(id, kind);
    if (work == null) return const SizedBox.shrink();
    Widget cell(String label, String value, DateTime date) => Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardLabel(gc, label),
          const SizedBox(height: 6),
          FitText(
            value,
            style: AppTheme.f(17, weight: FontWeight.w700, color: gc.text, height: 1),
          ),
          const SizedBox(height: 4),
          Text(
            _fmtDate(date),
            style: AppTheme.f(11.5, weight: FontWeight.w500, color: gc.textTertiary),
          ),
        ],
      ),
    );
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Row(
        children: [
          if (set != null)
            cell(t.prBestSet, ltr('${fit.weightLabel(set.set.weight)} × ${set.set.reps}'), set.date),
          if (set != null) const SizedBox(width: 12),
          cell(t.prBestWorkout, fit.bestWorkoutLabel(work.score, kind), work.date),
        ],
      ),
    );
  }

  Widget _cardLabel(GymColors gc, String label) => FitText(
    label.toUpperCase(),
    style: AppTheme.f(10.5, weight: FontWeight.w700, color: gc.textTertiary, letterSpacing: 1.4),
  );

  Widget _section(GymColors gc, String label) => Text(
    titleCase(label),
    style: AppTheme.f(18, weight: FontWeight.w700, color: gc.text),
  );

  Widget _group(GymColors gc, List<Widget> rows) {
    return Container(
      decoration: BoxDecoration(color: gc.bgRaised, borderRadius: BorderRadius.circular(20)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (int i = 0; i < rows.length; i++) ...[
            rows[i],
            if (i < rows.length - 1)
              Container(
                height: 1,
                margin: const EdgeInsetsDirectional.only(start: 16),
                color: gc.border.withValues(alpha: 0.55),
              ),
          ],
        ],
      ),
    );
  }

  Widget _step(GymColors gc, int n, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(color: gc.emberSoft, shape: BoxShape.circle),
          alignment: Alignment.center,
          child: Text(
            '$n',
            style: AppTheme.f(12, weight: FontWeight.w700, color: gc.ember),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: AppTheme.f(14, weight: FontWeight.w500, color: gc.textSecondary, height: 1.5),
          ),
        ),
      ],
    );
  }

  Widget _star(GymColors gc, bool fav) => FavoriteStar(on: fav);

  Widget _stackRow(BuildContext context, GymColors gc, String id) {
    final stack = fit.ownStackFor(id);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => showWeightStackSheet(context, id),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            _rowIcon(gc, PhosphorIconsRegular.stack, stack != null),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.weightStack,
                    style: AppTheme.f(14.5, weight: FontWeight.w500, color: gc.text),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    stack == null
                        ? t.weightStackOff
                        : '${fit.weightValueFor(id, stack.first)}–${fit.weightValueFor(id, stack.last)} ${fit.unitsFor(id)} · ${t.stackCount(stack.length)}',
                    style: AppTheme.f(
                      11.5,
                      weight: FontWeight.w500,
                      color: stack != null ? gc.accent : gc.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(PhosphorIconsRegular.caretRight, size: 15, color: gc.textTertiary),
          ],
        ),
      ),
    );
  }

  Widget _holdProgressRow(GymColors gc, String id) {
    final step = fit.holdStepFor(id);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          _rowIcon(gc, PhosphorIconsRegular.trendUp, step > 0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.holdProgress,
                  style: AppTheme.f(14.5, weight: FontWeight.w500, color: gc.text),
                ),
                const SizedBox(height: 3),
                Text(
                  step > 0 ? t.holdProgressOn(step) : t.holdProgressHint,
                  style: AppTheme.f(
                    11.5,
                    weight: FontWeight.w500,
                    color: step > 0 ? gc.accent : gc.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          StepperControl(
            value: step == 0 ? t.restOff : '+$step s',
            minWidth: 44,
            btnSize: 30,
            onDec: () => fit.cycleHoldStep(id, -1),
            onInc: () => fit.cycleHoldStep(id, 1),
          ),
        ],
      ),
    );
  }

  Widget _restRow(GymColors gc, String id) {
    final custom = fit.hasCustomRest(id);
    final seconds = fit.restFor(id);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          _rowIcon(gc, PhosphorIconsRegular.timer, custom),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titleCase(t.restForExercise),
                  style: AppTheme.f(14.5, weight: FontWeight.w500, color: gc.text),
                ),
                const SizedBox(height: 3),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: custom ? () => fit.setExerciseRest(id, null) : null,
                  child: Text(
                    custom ? t.restCustom : t.restUsingDefault,
                    style: AppTheme.f(
                      11.5,
                      weight: FontWeight.w500,
                      color: custom ? gc.accent : gc.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          StepperControl(
            value: seconds == 0 ? t.restOff : clockLabel(seconds),
            minWidth: 44,
            btnSize: 30,
            gap: 3,
            fontSize: 14,
            btnRadius: 10,
            onDec: () => fit.setExerciseRest(id, seconds - 15),
            onInc: () => fit.setExerciseRest(id, seconds + 15),
            onEdit: () async {
              final v = await askRuler(
                context,
                title: t.restForExercise,
                value: seconds.toDouble(),
                min: 0,
                max: 600,
                step: 5,
                majorEvery: 6,
                format: (v) => clockLabel(v.round()),
                tickLabel: (v) => clockLabel(v.round()),
              );
              if (v != null) fit.setExerciseRest(id, v.round());
            },
          ),
        ],
      ),
    );
  }

  Widget _bodyShareRow(GymColors gc, String id) {
    final own = fit.hasOwnBodyShare(id);
    final pct = fit.bodyShareOf(id);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          _rowIcon(gc, PhosphorIconsRegular.percent, own),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titleCase(t.bodyShareSetting),
                  style: AppTheme.f(14.5, weight: FontWeight.w500, color: gc.text),
                ),
                const SizedBox(height: 3),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: own ? () => fit.setBodyShare(id, null) : null,
                  child: Text(
                    own ? t.bodyShareCustom(fit.bodyShareDefault(id)) : t.bodyShareHint,
                    style: AppTheme.f(
                      11.5,
                      weight: FontWeight.w500,
                      color: own ? gc.accent : gc.textSecondary,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          StepperControl(
            value: ltr('$pct %'),
            minWidth: 52,
            btnSize: 30,
            gap: 3,
            fontSize: 14,
            btnRadius: 10,
            onDec: () => fit.setBodyShare(id, pct - 5),
            onInc: () => fit.setBodyShare(id, pct + 5),
            onEdit: () async {
              final v = await askNumber(context, title: t.bodyShareSetting, initial: '$pct', decimal: false);
              if (v != null) fit.setBodyShare(id, v.round());
            },
          ),
        ],
      ),
    );
  }

  Widget _barRow(GymColors gc, Exercise ex) {
    final own = fit.hasOwnBar(ex.id);
    final bar = fit.barFor(ex.id, equipment: ex.equipment);
    final step = fit.weightStep;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          _rowIcon(gc, PhosphorIconsRegular.barbell, own),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titleCase(t.barWeightExercise),
                  style: AppTheme.f(14.5, weight: FontWeight.w500, color: gc.text),
                ),
                const SizedBox(height: 3),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: own ? () => fit.setExerciseBar(ex.id, null) : null,
                  child: Text(
                    own ? t.barWeightCustom : t.barWeightHint,
                    style: AppTheme.f(
                      11.5,
                      weight: FontWeight.w500,
                      color: own ? gc.accent : gc.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          StepperControl(
            value: ltr('${fmt(bar)} ${fit.units}'),
            minWidth: 56,
            btnSize: 30,
            gap: 3,
            fontSize: 14,
            btnRadius: 10,
            onDec: () => fit.setExerciseBar(ex.id, bar - step),
            onInc: () => fit.setExerciseBar(ex.id, bar + step),
            onEdit: () async {
              final v = await askNumber(
                context,
                title: t.barWeightExercise,
                initial: fmt(bar),
                decimal: true,
              );
              if (v != null) fit.setExerciseBar(ex.id, v);
            },
          ),
        ],
      ),
    );
  }

  Widget _rowIcon(GymColors gc, IconData icon, bool on) => Padding(
    padding: const EdgeInsetsDirectional.only(end: 14),
    child: SizedBox(width: 22, child: Icon(icon, size: 19, color: on ? gc.text : gc.textSecondary)),
  );

  Widget _goalCard(BuildContext context, GymColors gc, String id) {
    final goal = fit.exerciseGoals[id];
    if (goal == null) {
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _editGoal(context, id),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            border: Border.all(color: gc.border),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Icon(PhosphorIconsRegular.target, size: 18, color: gc.textSecondary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  t.goalSet,
                  style: AppTheme.f(13.5, weight: FontWeight.w600, color: gc.text),
                ),
              ),
              Icon(PhosphorIconsRegular.plus, size: 15, color: gc.textTertiary),
            ],
          ),
        ),
      );
    }
    final best = fit.goalBest(id);
    final done = best >= goal.target;
    final share = goal.target <= 0 ? 1.0 : (best / goal.target).clamp(0.0, 1.0);
    final due = goal.due;
    final today = DateTime.now();
    final days = due == null
        ? null
        : DateTime(
            due.year,
            due.month,
            due.day,
          ).difference(DateTime(today.year, today.month, today.day)).inDays;
    final when = done || due == null
        ? null
        : days! < 0
        ? t.goalOverdue
        : '${t.goalDaysLeft(days)} · ${t.shortDate(due)}';
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _editGoal(context, id),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: gc.bgRaised,
          border: Border.all(color: done ? gc.ember : Colors.transparent),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _cardLabel(gc, t.goal),
                      const SizedBox(height: 8),
                      Text(
                        fit.goalLabel(id, goal.target),
                        style: AppTheme.f(26, weight: FontWeight.w800, color: gc.text, height: 1),
                      ),
                    ],
                  ),
                ),
                Text(
                  done ? t.goalReached : t.goalToGo(fit.goalLabel(id, goal.target - best)),
                  style: AppTheme.f(12.5, weight: FontWeight.w600, color: done ? gc.ember : gc.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: share,
                minHeight: 6,
                backgroundColor: gc.bgRaised2,
                valueColor: AlwaysStoppedAnimation(done ? gc.ember : gc.accent),
              ),
            ),
            if (when != null) ...[
              const SizedBox(height: 10),
              Text(
                when,
                style: AppTheme.f(
                  11.5,
                  weight: FontWeight.w500,
                  color: days! < 0 ? gc.ember : gc.textTertiary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _editGoal(BuildContext context, String id) async {
    final reps = fit.goalKind(id) == PrKind.reps;
    final current = fit.exerciseGoals[id];
    final best = fit.goalBest(id);
    var target =
        current?.target ??
        (reps
            ? math.max(best + 5, 10.0)
            : fit.fromDisplayWeight(fit.toDisplayWeight(best) + fit.weightStep * 4));
    DateTime? due = current?.due;
    String shown() => reps ? '${target.round()}' : ltr('${fit.weightValue(target)} ${fit.units}');
    await showAppSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheet) => StatefulBuilder(
        builder: (sheet, setSheet) {
          final gc = sheet.gc;
          void bump(int dir) => setSheet(() {
            target = reps
                ? math.max(1, target + dir).toDouble()
                : math.max(0, target + dir * fit.fromDisplayWeight(fit.weightStep)).toDouble();
          });
          return Container(
            padding: sheetPad(sheet),
            decoration: sheetDecoration(gc),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SheetHandle(),
                const SizedBox(height: 16),
                SheetTitle(titleCase(t.goal)),
                const SizedBox(height: 18),
                ToolGroup([
                  ToolRow(
                    label: reps ? t.goalTargetReps : t.targetWeight,
                    control: StepperControl(
                      value: shown(),
                      onDec: () => bump(-1),
                      onInc: () => bump(1),
                      onEdit: () async {
                        final v = await askNumber(
                          sheet,
                          title: reps ? t.goalTargetReps : t.targetWeight,
                          initial: reps ? '${target.round()}' : fit.weightValue(target),
                          decimal: !reps,
                        );
                        if (v != null && v > 0)
                          setSheet(() => target = reps ? v.roundToDouble() : fit.fromDisplayWeight(v));
                      },
                    ),
                  ),
                  ToolRow(
                    label: t.goalDeadline,
                    control: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () async {
                        final now = DateTime.now();
                        final picked = await showDatePicker(
                          context: sheet,
                          initialDate: due ?? now.add(const Duration(days: 90)),
                          firstDate: now,
                          lastDate: now.add(const Duration(days: 365 * 3)),
                        );
                        if (picked != null) setSheet(() => due = picked);
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            due == null ? t.goalNoDeadline : t.shortDateYear(due!),
                            style: AppTheme.f(
                              14,
                              weight: FontWeight.w700,
                              color: due == null ? gc.textTertiary : gc.text,
                            ),
                          ),
                          if (due != null) ...[
                            const SizedBox(width: 8),
                            GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () => setSheet(() => due = null),
                              child: Icon(PhosphorIconsRegular.x, size: 14, color: gc.textTertiary),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ]),
                const SizedBox(height: 18),
                PrimaryButton(
                  label: t.save,
                  onTap: () {
                    fit.setExerciseGoal(id, target, due);
                    Navigator.pop(sheet);
                  },
                ),
                if (current != null) ...[
                  const SizedBox(height: 6),
                  Center(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        fit.clearExerciseGoal(id);
                        Navigator.pop(sheet);
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Text(
                          t.goalRemove,
                          style: AppTheme.f(13, weight: FontWeight.w600, color: gc.textSecondary),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _nextCard(GymColors gc, String id) {
    final up = fit.nextTarget(id)?.up ?? fit.holdGoesUp(id);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: gc.bgRaised,
        border: Border.all(color: up ? gc.ember : gc.border),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          SvgPathIcon(Ic.trendUp, size: 18, color: up ? gc.ember : gc.textSecondary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.nextTime,
                  style: AppTheme.f(
                    10.5,
                    weight: FontWeight.w700,
                    color: gc.textTertiary,
                    letterSpacing: 1.4,
                  ),
                ),
                if (fit.nextWhy(id) case final why?) ...[
                  const SizedBox(height: 2),
                  Text(
                    why,
                    style: AppTheme.f(11.5, weight: FontWeight.w500, color: gc.textTertiary),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            fit.nextTargetLabel(id)!,
            style: AppTheme.f(20, weight: FontWeight.w800, color: up ? gc.ember : gc.text),
          ),
        ],
      ),
    );
  }

  Widget _keepCountingRow(GymColors gc, String id) => _switchRow(
    gc,
    PhosphorIconsRegular.timer,
    t.keepCounting,
    t.keepCountingHint,
    fit.keepsCounting(id),
    () => fit.toggleKeepCounting(id),
  );

  Widget _switchRow(GymColors gc, IconData icon, String title, String hint, bool on, VoidCallback onTap) {
    return Semantics(
      button: true,
      toggled: on,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              _rowIcon(gc, icon, on),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTheme.f(14.5, weight: FontWeight.w500, color: gc.text),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      hint,
                      style: AppTheme.f(11.5, weight: FontWeight.w500, color: gc.textSecondary, height: 1.3),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              TinySwitch(on: on),
            ],
          ),
        ),
      ),
    );
  }

  Widget _progressRow(BuildContext context, GymColors gc, String id) {
    final kind = fit.progressRule(id).kind;
    final on = fit.hasProgress(id);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => showProgressionSheet(context, id),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 14),
              child: SizedBox(
                width: 22,
                child: SvgPathIcon(Ic.trendUp, size: 19, color: on ? gc.text : gc.textSecondary),
              ),
            ),
            Expanded(
              child: Text(
                t.progression,
                style: AppTheme.f(14.5, weight: FontWeight.w500, color: gc.text),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              progressKindName(kind),
              style: AppTheme.f(13, weight: FontWeight.w600, color: on ? gc.accent : gc.textSecondary),
            ),
            const SizedBox(width: 6),
            Icon(PhosphorIconsRegular.caretRight, size: 15, color: gc.textTertiary),
          ],
        ),
      ),
    );
  }

  Widget _repsOnlyRow(GymColors gc, String id, bool on) {
    return Semantics(
      button: true,
      toggled: on,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => fit.toggleRepsOnly(id),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              _rowIcon(gc, PhosphorIconsRegular.scales, on),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fit.isTimed(id) ? t.timeOnly : t.repsOnly,
                      style: AppTheme.f(14.5, weight: FontWeight.w500, color: gc.text),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      t.repsOnlyHint,
                      style: AppTheme.f(11.5, weight: FontWeight.w500, color: gc.textSecondary, height: 1.3),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              TinySwitch(on: on),
            ],
          ),
        ),
      ),
    );
  }

  String _modeName(String mode) => switch (mode) {
    'cardio' => t.typeCardio,
    'time' => t.typeTime,
    _ => t.typeReps,
  };

  Widget _modeRow(BuildContext context, GymColors gc, String id, String mode) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _pickMode(context, id),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            _rowIcon(
              gc,
              mode == 'cardio' ? PhosphorIconsRegular.personSimpleRun : PhosphorIconsRegular.listNumbers,
              mode.isNotEmpty,
            ),
            Expanded(
              child: Text(
                t.exerciseTypeLabel,
                style: AppTheme.f(14.5, weight: FontWeight.w500, color: gc.text),
              ),
            ),
            Text(
              _modeName(mode),
              style: AppTheme.f(13, weight: FontWeight.w600, color: gc.textSecondary),
            ),
            const SizedBox(width: 6),
            Icon(PhosphorIconsRegular.caretRight, size: 15, color: gc.textTertiary),
          ],
        ),
      ),
    );
  }

  void _pickMode(BuildContext context, String id) {
    showAppSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheet) => AnimatedBuilder(
        animation: fit,
        builder: (sheet, _) {
          final gc = sheet.gc;
          final now = fit.modeOf(id);
          return Container(
            padding: sheetPad(sheet),
            decoration: sheetDecoration(gc),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SheetHandle(),
                const SizedBox(height: 16),
                SheetTitle(t.exerciseTypeLabel),
                const SizedBox(height: 14),
                OptionGroup([
                  for (final (value, icon) in [
                    ('', PhosphorIconsRegular.barbell),
                    ('time', PhosphorIconsRegular.timer),
                    ('cardio', PhosphorIconsRegular.personSimpleRun),
                  ])
                    OptionItem(
                      _modeName(value),
                      icon: icon,
                      selected: now == value,
                      onTap: () {
                        fit.setExerciseMode(id, value);
                        Navigator.of(sheet).pop();
                      },
                    ),
                ]),
                const SizedBox(height: 12),
                Text(
                  t.exerciseTypeHint,
                  textAlign: TextAlign.center,
                  style: AppTheme.f(11.5, weight: FontWeight.w500, color: gc.textTertiary, height: 1.4),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _mediaBtn(GymColors gc, IconData icon, String semantic, VoidCallback onTap) {
    return Semantics(
      button: true,
      label: semantic,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: gc.bg.withValues(alpha: 0.82),
            shape: BoxShape.circle,
            border: Border.all(color: gc.border),
          ),
          child: Icon(icon, size: 16, color: gc.text),
        ),
      ),
    );
  }
}

class _MergeTargetSheet extends StatefulWidget {
  const _MergeTargetSheet({required this.from});

  final Exercise from;

  @override
  State<_MergeTargetSheet> createState() => _MergeTargetSheetState();
}

class _MergeTargetSheetState extends State<_MergeTargetSheet> {
  final TextEditingController _q = TextEditingController();

  @override
  void dispose() {
    _q.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gc = context.gc;
    final all = fit.mergeTargets(widget.from.id);
    final results = _q.text.trim().isEmpty
        ? all.take(40).toList()
        : all.where(exerciseSearch(_q.text)).take(60).toList();

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.72,
        padding: sheetPad(context, bottom: 16),
        decoration: sheetDecoration(gc),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SheetHandle(),
            const SizedBox(height: 16),
            SheetTitle(t.mergeExerciseInto(exerciseName(widget.from))),
            const SizedBox(height: 14),
            SearchField(
              controller: _q,
              hint: t.searchAllExercises,
              color: gc.bgRaised2,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            Flexible(
              child: OptionGroup(scroll: true, [
                for (final ex in results)
                  OptionItem(
                    exerciseName(ex),
                    detail: muscleLabel(ex.primary),
                    onTap: () => Navigator.of(context).pop(ex.id),
                  ),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}
