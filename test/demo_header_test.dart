import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymmane/app/gymmane_app.dart';
import 'package:gymmane/state/fit_state.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

Future<void> _phoneInset(WidgetTester tester) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  const pad = FakeViewPadding(top: 47, bottom: 34);
  tester.view.padding = pad;
  tester.view.viewPadding = pad;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPadding);
  addTearDown(tester.view.resetViewPadding);
}

Future<void> _shot(WidgetTester tester, String path) async {
  await tester.pump();
  final ro = tester.renderObject(find.byKey(const Key('hq-shot')));
  expect(ro, isA<RenderRepaintBoundary>());
  final image = await (ro as RenderRepaintBoundary).toImage(pixelRatio: 1);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  final file = File(path);
  file.parent.createSync(recursive: true);
  file.writeAsBytesSync(bytes!.buffer.asUint8List());
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    fit.onboarded = true;
    fit.session = null;
  });

  testWidgets('exercise detail header sits below a 47px status inset', (tester) async {
    await _phoneInset(tester);
    fit.activeExerciseId = 'I4hDWkc';
    fit.route = 'exercise-detail';
    await tester.pumpWidget(const RepaintBoundary(key: Key('hq-shot'), child: GymManeApp()));
    await tester.pump(const Duration(milliseconds: 500));
    expect(tester.takeException(), isNull);

    final back = find.byIcon(PhosphorIconsRegular.caretLeft);
    expect(back, findsWidgets);
    final top = tester.getRect(back.first).top;
    expect(top, greaterThanOrEqualTo(47 + 10), reason: 'back button top was $top');

    await _shot(tester, '/workspace/HomeFit Pro-shots/detail-header-390.png');
  });

  testWidgets('session timer bar sits below a 47px status inset', (tester) async {
    await _phoneInset(tester);
    fit.startWorkout();
    fit.toggleMuscle('chest');
    fit.trainContinue();
    if (!fit.sessionPicks.contains('I4hDWkc')) {
      fit.togglePick('I4hDWkc');
    }
    fit.startSession();
    expect(fit.session, isNotNull);
    fit.route = 'session';
    await tester.pumpWidget(const RepaintBoundary(key: Key('hq-shot'), child: GymManeApp()));
    await tester.pump(const Duration(milliseconds: 500));
    expect(tester.takeException(), isNull);

    // The live bar is at the top of the SafeArea + 12 padding.
    final elapsed = find.textContaining(':');
    expect(elapsed, findsWidgets);
    final top = tester.getRect(elapsed.first).top;
    expect(top, greaterThanOrEqualTo(47 + 10), reason: 'timer top was $top');

    await _shot(tester, '/workspace/HomeFit Pro-shots/session-header-390.png');
  });
}
