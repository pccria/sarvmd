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
import 'package:sarvmd_ui/src/presentation/screens/touch_editor_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Touch Mode Back Button & Navigation Ergonomics Tests', () {
    late LocaleCubit localeCubit;
    late ViewCubit viewCubit;
    late DocumentCubit documentCubit;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      localeCubit = LocaleCubit(const LocaleState());
      viewCubit = ViewCubit(const ViewState());
      documentCubit = DocumentCubit();
    });

    tearDown(() {
      localeCubit.close();
      viewCubit.close();
      documentCubit.close();
    });

    Widget buildAppWithEditor({required Widget child}) {
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
          home: child,
        ),
      );
    }

    testWidgets('TouchEditorScreen: back in sub-page unwinds to mainMenu without closing drawer',
        (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        buildAppWithEditor(
          child: const TouchEditorScreen(),
        ),
      );
      await tester.pumpAndSettle();

      final scaffoldState = tester.state<ScaffoldState>(find.byType(Scaffold));
      scaffoldState.openDrawer();
      await tester.pumpAndSettle();
      expect(scaffoldState.isDrawerOpen, isTrue);

      // Navigate to Margins sub-page
      viewCubit.setTouchSection(SettingsSection.margins);
      await tester.pumpAndSettle();
      expect(viewCubit.state.activeTouchSection, SettingsSection.margins);

      // Simulate system Back button press
      final dynamic widgetsAppState = tester.state(find.byType(WidgetsApp));
      await widgetsAppState.didPopRoute();
      await tester.pumpAndSettle();

      // Drawer should still be open, but section unwound to mainMenu
      expect(scaffoldState.isDrawerOpen, isTrue);
      expect(viewCubit.state.activeTouchSection, SettingsSection.mainMenu);

      // Second system Back button press: closes the drawer
      await widgetsAppState.didPopRoute();
      await tester.pumpAndSettle();

      expect(scaffoldState.isDrawerOpen, isFalse);
    });

    testWidgets('TouchEditorScreen: back while peeking restores panel without closing drawer',
        (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        buildAppWithEditor(
          child: const TouchEditorScreen(),
        ),
      );
      await tester.pumpAndSettle();

      final scaffoldState = tester.state<ScaffoldState>(find.byType(Scaffold));
      scaffoldState.openDrawer();
      await tester.pumpAndSettle();
      expect(scaffoldState.isDrawerOpen, isTrue);

      // Trigger panel peek
      viewCubit.togglePanelPeeking(true);
      await tester.pumpAndSettle();
      expect(viewCubit.state.isPanelPeeking, isTrue);

      // System back press while peeking must restore panel and keep drawer open
      final dynamic widgetsAppState = tester.state(find.byType(WidgetsApp));
      await widgetsAppState.didPopRoute();
      await tester.pumpAndSettle();

      expect(viewCubit.state.isPanelPeeking, isFalse);
      expect(scaffoldState.isDrawerOpen, isTrue);

      // Another back press from mainMenu closes drawer
      await widgetsAppState.didPopRoute();
      await tester.pumpAndSettle();
      expect(scaffoldState.isDrawerOpen, isFalse);
    });

    testWidgets('TouchEditorScreen: clean document shows double-back SnackBar on first back',
        (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        buildAppWithEditor(
          child: const TouchEditorScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Ensure document is not dirty
      expect(documentCubit.state.isDirty, isFalse);

      // First back press: should show floating SnackBar
      final dynamic widgetsAppState = tester.state(find.byType(WidgetsApp));
      await widgetsAppState.didPopRoute();
      await tester.pump();

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('Press back again to exit'), findsOneWidget);
    });

    testWidgets('TouchEditorScreen: dirty document prompts UnsavedChangesDialog on back',
        (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        buildAppWithEditor(
          child: const TouchEditorScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Mutate document to make it dirty
      documentCubit.setTitle('Modified Score');
      await tester.pumpAndSettle();
      expect(documentCubit.state.isDirty, isTrue);

      // Press back: should display UnsavedChangesDialog
      final dynamic widgetsAppState = tester.state(find.byType(WidgetsApp));
      await widgetsAppState.didPopRoute();
      await tester.pumpAndSettle();

      expect(find.text('Unsaved Changes'), findsOneWidget);

      // Tapping Cancel dismisses modal and keeps user on editor
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('Unsaved Changes'), findsNothing);
      expect(find.byType(TouchEditorScreen), findsOneWidget);
    });
  });
}
