// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Licensed under the Business Source License 1.1 (BUSL-1.1).

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sarvmd_ui/src/l10n/app_localizations.dart';
import 'package:sarvmd_ui/src/logic/document/document_cubit.dart';
import 'package:sarvmd_ui/src/logic/locale/locale_cubit.dart';
import 'package:sarvmd_ui/src/logic/locale/locale_state.dart';
import 'package:sarvmd_ui/src/logic/view/view_cubit.dart';
import 'package:sarvmd_ui/src/logic/view/view_state.dart';
import 'package:sarvmd_ui/src/presentation/widgets/touch/settings_panel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Touch Section Spine Navigation Tests', () {
    late LocaleCubit localeCubit;
    late ViewCubit viewCubit;
    late DocumentCubit documentCubit;
    late TransformationController transformationController;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      localeCubit = LocaleCubit(const LocaleState());
      viewCubit = ViewCubit(const ViewState());
      documentCubit = DocumentCubit();
      transformationController = TransformationController();
    });

    tearDown(() {
      localeCubit.close();
      viewCubit.close();
      documentCubit.close();
      transformationController.dispose();
    });

    Widget createTestWidget({required Widget child}) {
      return MultiBlocProvider(
        providers: [
          BlocProvider.value(value: localeCubit),
          BlocProvider.value(value: viewCubit),
          BlocProvider.value(value: documentCubit),
        ],
        child: MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: PageStorage(
            bucket: PageStorageBucket(),
            child: child,
          ),
        ),
      );
    }

    testWidgets('renders all 7 spine beads with correct keys and icons', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          child: Scaffold(
            body: SettingsPanel(
              transformationController: transformationController,
              onZoomPreset: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify all 7 section spine bead keys are present
      expect(find.byKey(const ValueKey('touch_spine_mainMenu')), findsOneWidget);
      expect(find.byKey(const ValueKey('touch_spine_profiles')), findsOneWidget);
      expect(find.byKey(const ValueKey('touch_spine_pageSetup')), findsOneWidget);
      expect(find.byKey(const ValueKey('touch_spine_margins')), findsOneWidget);
      expect(find.byKey(const ValueKey('touch_spine_staffSpacing')), findsOneWidget);
      expect(find.byKey(const ValueKey('touch_spine_systemHierarchy')), findsOneWidget);
      expect(find.byKey(const ValueKey('touch_spine_export')), findsOneWidget);
    });

    testWidgets('1-tap direct jump between sections via spine without using back button', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          child: Scaffold(
            body: SettingsPanel(
              transformationController: transformationController,
              onZoomPreset: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Starts in mainMenu
      expect(viewCubit.state.activeTouchSection, SettingsSection.mainMenu);

      // Jump directly to Margins via spine bead
      await tester.tap(find.byKey(const ValueKey('touch_spine_margins')));
      await tester.pumpAndSettle();

      expect(viewCubit.state.activeTouchSection, SettingsSection.margins);

      // Jump directly to Staff Spacing from Margins without pressing Back!
      await tester.tap(find.byKey(const ValueKey('touch_spine_staffSpacing')));
      await tester.pumpAndSettle();

      expect(viewCubit.state.activeTouchSection, SettingsSection.staffSpacing);

      // Jump directly to Profiles from Staff Spacing
      await tester.tap(find.byKey(const ValueKey('touch_spine_profiles')));
      await tester.pumpAndSettle();

      expect(viewCubit.state.activeTouchSection, SettingsSection.profiles);

      // Jump back to Main Menu via spine
      await tester.tap(find.byKey(const ValueKey('touch_spine_mainMenu')));
      await tester.pumpAndSettle();

      expect(viewCubit.state.activeTouchSection, SettingsSection.mainMenu);
    });

    testWidgets('Landscape docked side sheet fits within short screen without overflowing', (tester) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(720, 340); // Ultra-compact landscape phone
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        createTestWidget(
          child: Scaffold(
            body: SizedBox(
              width: 320,
              child: SettingsPanel(
                transformationController: transformationController,
                onZoomPreset: (_) {},
                isPanelDocked: true,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify no overflow occurred
      expect(tester.takeException(), isNull);

      // Tap each bead and verify zero exceptions
      await tester.tap(find.byKey(const ValueKey('touch_spine_margins')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(viewCubit.state.activeTouchSection, SettingsSection.margins);

      await tester.tap(find.byKey(const ValueKey('touch_spine_staffSpacing')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(viewCubit.state.activeTouchSection, SettingsSection.staffSpacing);
    });
  });
}
