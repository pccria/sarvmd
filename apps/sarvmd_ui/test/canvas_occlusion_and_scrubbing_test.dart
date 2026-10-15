// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Licensed under the Business Source License 1.1 (BUSL-1.1).

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sarvmd_ui/src/l10n/app_localizations.dart';
import 'package:sarvmd_ui/src/logic/document/document_cubit.dart';
import 'package:sarvmd_ui/src/logic/locale/locale_cubit.dart';
import 'package:sarvmd_ui/src/logic/locale/locale_state.dart';
import 'package:sarvmd_ui/src/logic/view/view_cubit.dart';
import 'package:sarvmd_ui/src/presentation/widgets/touch/settings_panel.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Canvas Occlusion & Scrubbing State Tests', () {
    late LocaleCubit localeCubit;
    late ViewCubit viewCubit;
    late DocumentCubit documentCubit;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      localeCubit = LocaleCubit(const LocaleState());
      viewCubit = ViewCubit();
      documentCubit = DocumentCubit();
    });

    tearDown(() {
      localeCubit.close();
      viewCubit.close();
      documentCubit.close();
    });

    test('ViewCubit scrubbing lifecycle transitions correctly', () {
      expect(viewCubit.state.isScrubbing, isFalse);
      expect(viewCubit.state.activeScrubbingTelemetry, isNull);

      // Start scrubbing
      viewCubit.startScrubbing(
        marginSide: 'left',
        telemetry: 'Left: 15.0 mm',
      );
      expect(viewCubit.state.isScrubbing, isTrue);
      expect(viewCubit.state.activeScrubbingMargin, equals('left'));
      expect(viewCubit.state.activeScrubbingTelemetry, equals('Left: 15.0 mm'));

      // Update telemetry
      viewCubit.updateScrubbingTelemetry('Left: 18.5 mm');
      expect(viewCubit.state.activeScrubbingTelemetry, equals('Left: 18.5 mm'));
      expect(viewCubit.state.isScrubbing, isTrue);

      // End scrubbing
      viewCubit.endScrubbing();
      expect(viewCubit.state.isScrubbing, isFalse);
      expect(viewCubit.state.activeScrubbingMargin, isNull);
      expect(viewCubit.state.activeScrubbingTelemetry, isNull);
    });

    test('ViewCubit panel peeking toggles correctly', () {
      expect(viewCubit.state.isPanelPeeking, isFalse);

      viewCubit.togglePanelPeeking(true);
      expect(viewCubit.state.isPanelPeeking, isTrue);

      viewCubit.togglePanelPeeking(false);
      expect(viewCubit.state.isPanelPeeking, isFalse);

      viewCubit.togglePanelPeeking();
      expect(viewCubit.state.isPanelPeeking, isTrue);
    });

    testWidgets('SettingsPanel renders scrub-ghosting opacity and telemetry pill when scrubbing',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 900));

      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider.value(value: localeCubit),
            BlocProvider.value(value: viewCubit),
            BlocProvider.value(value: documentCubit),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: SettingsPanel(
                transformationController: TransformationController(),
                onZoomPreset: (_) {},
                isPanelDocked: true,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Normal state: find AnimatedOpacity with opacity 1.0
      final opacityFinder = find.byWidgetPredicate(
        (w) => w is AnimatedOpacity && w.opacity == 1.0,
      );
      expect(opacityFinder, findsWidgets);

      // Trigger scrubbing with telemetry
      viewCubit.startScrubbing(telemetry: 'Line Gap: 1.75 mm');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Ghosting state: AnimatedOpacity with opacity 0.18
      final ghostOpacityFinder = find.byWidgetPredicate(
        (w) => w is AnimatedOpacity && w.opacity == 0.18,
      );
      expect(ghostOpacityFinder, findsOneWidget);

      // Telemetry pill is displayed with exact text
      expect(find.text('Line Gap: 1.75 mm'), findsOneWidget);

      // End scrubbing: restores to 1.0
      viewCubit.endScrubbing();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byWidgetPredicate(
        (w) => w is AnimatedOpacity && w.opacity == 1.0,
      ), findsWidgets);
      expect(find.text('Line Gap: 1.75 mm'), findsNothing);
    });

    testWidgets('SettingsPanel stays solid (does NOT transparentize) when paper is in clear aperture',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 900));

      final clearTransform = TransformationController(
        Matrix4.translationValues(400.0, 0.0, 0.0),
      );

      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider.value(value: localeCubit),
            BlocProvider.value(value: viewCubit),
            BlocProvider.value(value: documentCubit),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: SettingsPanel(
                transformationController: clearTransform,
                onZoomPreset: (_) {},
                isPanelDocked: true,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Trigger scrubbing with telemetry
      viewCubit.startScrubbing(telemetry: 'Line Gap: 1.75 mm');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Panel is NOT occluding paper -> stays solid 1.0 opacity, NOT ghosted!
      expect(find.byWidgetPredicate(
        (w) => w is AnimatedOpacity && w.opacity == 0.18,
      ), findsNothing);

      expect(find.byWidgetPredicate(
        (w) => w is AnimatedOpacity && w.opacity == 1.0,
      ), findsWidgets);
    });

    testWidgets('SettingsPanel peek button triggers peeking and restore button restores panel',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 900));

      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider.value(value: localeCubit),
            BlocProvider.value(value: viewCubit),
            BlocProvider.value(value: documentCubit),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: SettingsPanel(
                transformationController: TransformationController(),
                onZoomPreset: (_) {},
                isPanelDocked: true,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Find peek button (visibility icon) in header
      final peekBtnFinder = find.byIcon(Icons.visibility_outlined);
      expect(peekBtnFinder, findsOneWidget);

      // Tap peek button
      await tester.tap(peekBtnFinder);
      await tester.pumpAndSettle();

      expect(viewCubit.state.isPanelPeeking, isTrue);

      // Floating restore action button appears
      final restoreBtnFinder = find.byTooltip('Restore Settings Panel');
      expect(restoreBtnFinder, findsOneWidget);

      // Tap restore button
      await tester.tap(restoreBtnFinder);
      await tester.pumpAndSettle();

      expect(viewCubit.state.isPanelPeeking, isFalse);
      expect(find.byTooltip('Restore Settings Panel'), findsNothing);
    });
  });
}
