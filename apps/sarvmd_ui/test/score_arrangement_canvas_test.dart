// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Licensed under the Business Source License 1.1 (BUSL-1.1).

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sarvmd_core/sarvmd_core.dart' as core;
import 'package:sarvmd_ui/src/l10n/app_localizations.dart';
import 'package:sarvmd_ui/src/logic/document/document_cubit.dart';
import 'package:sarvmd_ui/src/logic/locale/locale_cubit.dart';
import 'package:sarvmd_ui/src/logic/locale/locale_state.dart';
import 'package:sarvmd_ui/src/logic/view/view_cubit.dart';
import 'package:sarvmd_ui/src/logic/view/view_state.dart';
import 'package:sarvmd_ui/src/presentation/screens/pointer_editor_screen.dart';
import 'package:sarvmd_ui/src/presentation/widgets/canvas/canvas_page_navigator.dart';
import 'package:sarvmd_ui/src/presentation/widgets/canvas/canvas_zoom_calculator.dart';
import 'package:sarvmd_ui/src/presentation/widgets/canvas/preview_canvas.dart';
import 'package:sarvmd_ui/src/presentation/widgets/canvas/score_arrangement_canvas.dart';
import 'package:sarvmd_ui/src/presentation/widgets/panels/view_panel.dart';
import 'package:sarvmd_ui/src/presentation/widgets/staff/document_settings_group.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _buildTestApp({
  required Widget child,
  bool unconstrained = false,
  LocaleCubit? localeCubit,
  ViewCubit? viewCubit,
  DocumentCubit? docCubit,
}) {
  Widget content = child;
  if (unconstrained) {
    content = InteractiveViewer(
      constrained: false,
      child: child,
    );
  }

  Widget app = MaterialApp(
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: const [Locale('en')],
    home: Scaffold(
      body: content,
    ),
  );

  final providers = <BlocProvider>[];
  if (localeCubit != null) {
    providers.add(BlocProvider<LocaleCubit>.value(value: localeCubit));
  }
  if (viewCubit != null) {
    providers.add(BlocProvider<ViewCubit>.value(value: viewCubit));
  }
  if (docCubit != null) {
    providers.add(BlocProvider<DocumentCubit>.value(value: docCubit));
  }

  if (providers.isNotEmpty) {
    return MultiBlocProvider(providers: providers, child: app);
  }
  return app;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('ScoreArrangementCanvas Layout & Rendering Tests', () {
    late DocumentCubit docCubit;

    setUp(() {
      docCubit = DocumentCubit();
      docCubit.setPageCount(4); // 4-page score
    });

    tearDown(() {
      docCubit.close();
    });

    testWidgets('single mode renders only the active page with no badges', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          unconstrained: true,
          child: ScoreArrangementCanvas(
            documentCubit: docCubit,
            viewState: const ViewState(
              pageArrangement: PageArrangementMode.single,
              currentPageIndex: 0,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(PreviewCanvas), findsOneWidget);
      // In single mode, floating badges ('p. 1') are not shown
      expect(find.text('p. 1'), findsNothing);
    });

    testWidgets('facingSpread mode on page 1 renders verso placeholder and recto page 1', (tester) async {
      tester.view.physicalSize = const Size(2400, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      int? tappedIndex;

      await tester.pumpWidget(
        _buildTestApp(
          unconstrained: true,
          child: ScoreArrangementCanvas(
            documentCubit: docCubit,
            viewState: const ViewState(
              pageArrangement: PageArrangementMode.facingSpread,
              currentPageIndex: 0,
            ),
            onPageTapped: (idx) => tappedIndex = idx,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Should find the ghost verso placeholder
      expect(find.text('— (Verso) —'), findsOneWidget);

      // Should find 1 active PreviewCanvas (Page 1 on the recto side)
      expect(find.byType(PreviewCanvas), findsOneWidget);
      expect(find.text('p. 1'), findsOneWidget);

      // Tap on Page 1
      await tester.tap(find.text('p. 1'));
      expect(tappedIndex, equals(0));
    });

    testWidgets('facingSpread mode on page 2 renders spread 1: page 2 (verso) and page 3 (recto)', (tester) async {
      tester.view.physicalSize = const Size(2400, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      int? tappedIndex;

      await tester.pumpWidget(
        _buildTestApp(
          unconstrained: true,
          child: ScoreArrangementCanvas(
            documentCubit: docCubit,
            viewState: const ViewState(
              pageArrangement: PageArrangementMode.facingSpread,
              currentPageIndex: 1, // Page 2
            ),
            onPageTapped: (idx) => tappedIndex = idx,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verso placeholder should NOT be present on spread 1
      expect(find.text('— (Verso) —'), findsNothing);

      // Both Page 2 and Page 3 are rendered
      expect(find.byType(PreviewCanvas), findsNWidgets(2));
      expect(find.text('p. 2'), findsOneWidget);
      expect(find.text('p. 3'), findsOneWidget);

      // Tap on Page 3
      await tester.tap(find.text('p. 3'));
      expect(tappedIndex, equals(2));
    });

    testWidgets('continuousVertical mode stacks all pages top-to-bottom', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          unconstrained: true,
          child: ScoreArrangementCanvas(
            documentCubit: docCubit,
            viewState: const ViewState(
              pageArrangement: PageArrangementMode.continuousVertical,
              currentPageIndex: 0,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(PreviewCanvas), findsNWidgets(4));
      expect(find.text('p. 1'), findsOneWidget);
      expect(find.text('p. 2'), findsOneWidget);
      expect(find.text('p. 3'), findsOneWidget);
      expect(find.text('p. 4'), findsOneWidget);
    });

    testWidgets('continuousHorizontal mode places all pages side-by-side', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          unconstrained: true,
          child: ScoreArrangementCanvas(
            documentCubit: docCubit,
            viewState: const ViewState(
              pageArrangement: PageArrangementMode.continuousHorizontal,
              currentPageIndex: 1,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(PreviewCanvas), findsNWidgets(4));
      expect(find.text('p. 1'), findsOneWidget);
      expect(find.text('p. 2'), findsOneWidget);
      expect(find.text('p. 3'), findsOneWidget);
      expect(find.text('p. 4'), findsOneWidget);
    });

    testWidgets('grid mode arranges pages in rows according to gridColumns', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          unconstrained: true,
          child: ScoreArrangementCanvas(
            documentCubit: docCubit,
            viewState: const ViewState(
              pageArrangement: PageArrangementMode.grid,
              gridColumns: 2,
              currentPageIndex: 0,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(PreviewCanvas), findsNWidgets(4));
      expect(find.text('p. 1'), findsOneWidget);
      expect(find.text('p. 2'), findsOneWidget);
      expect(find.text('p. 3'), findsOneWidget);
      expect(find.text('p. 4'), findsOneWidget);
    });
  });

  group('CanvasPageNavigator Arrangement Switcher Tests', () {
    testWidgets('renders arrangement button and triggers onArrangementModeChanged', (tester) async {
      PageArrangementMode? changedMode;

      await tester.pumpWidget(
        _buildTestApp(
          child: CanvasPageNavigator(
            currentPageIndex: 0,
            pageCount: 3,
            arrangementMode: PageArrangementMode.single,
            onArrangementModeChanged: (mode) => changedMode = mode,
            onPageChanged: (_) {},
            onAddPage: () {},
            onRemovePage: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Find the arrangement popup button
      final arrangementButton = find.byTooltip('Page Arrangement');
      expect(arrangementButton, findsOneWidget);

      await tester.tap(arrangementButton);
      await tester.pumpAndSettle();

      // Verify all 5 arrangement items appear in popup
      expect(find.text('Single Page'), findsOneWidget);
      expect(find.text('Facing Pages'), findsOneWidget);
      expect(find.text('Vertical Flow'), findsOneWidget);
      expect(find.text('Horizontal Ribbon'), findsOneWidget);
      expect(find.text('Grid Overview'), findsOneWidget);

      // Select Facing Pages
      await tester.tap(find.text('Facing Pages'));
      await tester.pumpAndSettle();

      expect(changedMode, equals(PageArrangementMode.facingSpread));
    });
  });

  group('ViewCubit Arrangement Logic & Persistence Tests', () {
    test('updates pageArrangement and persists to SharedPreferences', () async {
      final cubit = ViewCubit();
      await Future.delayed(const Duration(milliseconds: 20));

      expect(cubit.state.pageArrangement, equals(PageArrangementMode.single));

      await cubit.setPageArrangement(PageArrangementMode.facingSpread);
      expect(cubit.state.pageArrangement, equals(PageArrangementMode.facingSpread));

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('view_page_arrangement'), equals(PageArrangementMode.facingSpread.index));

      await cubit.close();
    });

    test('updates gridColumns and clamps values', () async {
      final cubit = ViewCubit();
      await Future.delayed(const Duration(milliseconds: 20));

      expect(cubit.state.gridColumns, equals(2));

      await cubit.setGridColumns(4);
      expect(cubit.state.gridColumns, equals(4));

      // Test clamping
      await cubit.setGridColumns(10);
      expect(cubit.state.gridColumns, equals(6));

      await cubit.setGridColumns(0);
      expect(cubit.state.gridColumns, equals(1));

      await cubit.close();
    });
  });

  group('DocumentSettingsGroup Page Arrangement Integration Tests', () {
    testWidgets('renders arrangement group and handles mode & column selection', (tester) async {
      PageArrangementMode? changedMode;
      int? changedCols;

      await tester.pumpWidget(
        _buildTestApp(
          child: DocumentSettingsGroup(
            pageSize: core.PageSize.a4,
            onPageSizeChanged: (_) {},
            orientation: core.PageOrientation.portrait,
            onOrientationChanged: (_) {},
            pageCount: 4,
            arrangementMode: PageArrangementMode.grid,
            onArrangementModeChanged: (m) => changedMode = m,
            gridColumns: 2,
            onGridColumnsChanged: (c) => changedCols = c,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Page Arrangement'), findsOneWidget);
      expect(find.text('Grid Overview'), findsOneWidget);

      // Tap Facing Pages chip
      await tester.tap(find.text('Facing Pages'));
      await tester.pumpAndSettle();
      expect(changedMode, equals(PageArrangementMode.facingSpread));

      // Tap + button on Grid Columns
      final addBtn = find.widgetWithIcon(IconButton, Icons.add_rounded);
      expect(addBtn, findsOneWidget);
      await tester.tap(addBtn);
      expect(changedCols, equals(3));
    });
  });

  group('ViewPanel Page Arrangement Integration Tests', () {
    testWidgets('renders arrangement control in ViewPanel and changes mode', (tester) async {
      final viewCubit = ViewCubit();
      final localeCubit = LocaleCubit(const LocaleState());
      final docCubit = DocumentCubit();
      final tc = TransformationController();

      await tester.pumpWidget(
        _buildTestApp(
          localeCubit: localeCubit,
          viewCubit: viewCubit,
          docCubit: docCubit,
          child: SizedBox(
            width: 320,
            height: 900,
            child: ViewPanel(
              transformationController: tc,
              onZoomPreset: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('PAGE ARRANGEMENT'), findsOneWidget);
      expect(find.text('Single Page'), findsOneWidget);

      // Tap Continuous Vertical icon in segmented control
      final vertIcon = find.byIcon(Icons.view_day_rounded);
      expect(vertIcon, findsOneWidget);
      await tester.tap(vertIcon);
      await tester.pumpAndSettle();

      expect(viewCubit.state.pageArrangement, equals(PageArrangementMode.continuousVertical));
      expect(find.text('Vertical Flow'), findsOneWidget);

      viewCubit.close();
      localeCubit.close();
      docCubit.close();
    });
  });

  group('CanvasZoomCalculator Page Focus & Auto-Focus Geometry Tests', () {
    const pageWidth = 210.0 * (96.0 / 25.4);
    const pageHeight = 297.0 * (96.0 / 25.4);

    test('computePageCenter calculates proper centers across all modes', () {
      // Single mode
      final singleCenter = CanvasZoomCalculator.computePageCenter(
        arrangement: PageArrangementMode.single,
        pageIndex: 0,
        pageWidth: pageWidth,
        pageHeight: pageHeight,
      );
      expect(singleCenter, equals(const Offset(pageWidth / 2.0, pageHeight / 2.0)));

      // Continuous vertical mode
      final vertPage0 = CanvasZoomCalculator.computePageCenter(
        arrangement: PageArrangementMode.continuousVertical,
        pageIndex: 0,
        pageWidth: pageWidth,
        pageHeight: pageHeight,
        spacing: 32.0,
      );
      expect(vertPage0, equals(const Offset(pageWidth / 2.0, pageHeight / 2.0)));

      final vertPage1 = CanvasZoomCalculator.computePageCenter(
        arrangement: PageArrangementMode.continuousVertical,
        pageIndex: 1,
        pageWidth: pageWidth,
        pageHeight: pageHeight,
        spacing: 32.0,
      );
      expect(vertPage1, equals(const Offset(pageWidth / 2.0, pageHeight + 32.0 + pageHeight / 2.0)));

      // Continuous horizontal mode
      final horizPage1 = CanvasZoomCalculator.computePageCenter(
        arrangement: PageArrangementMode.continuousHorizontal,
        pageIndex: 1,
        pageWidth: pageWidth,
        pageHeight: pageHeight,
        spacing: 32.0,
      );
      expect(horizPage1, equals(const Offset(pageWidth + 32.0 + pageWidth / 2.0, pageHeight / 2.0)));

      // Grid mode (2 columns)
      final gridPage2 = CanvasZoomCalculator.computePageCenter(
        arrangement: PageArrangementMode.grid,
        pageIndex: 2, // row 1, col 0
        pageWidth: pageWidth,
        pageHeight: pageHeight,
        gridColumns: 2,
        spacing: 32.0,
      );
      expect(gridPage2, equals(const Offset(pageWidth / 2.0, pageHeight + 32.0 + pageHeight / 2.0)));

      final gridPage3 = CanvasZoomCalculator.computePageCenter(
        arrangement: PageArrangementMode.grid,
        pageIndex: 3, // row 1, col 1
        pageWidth: pageWidth,
        pageHeight: pageHeight,
        gridColumns: 2,
        spacing: 32.0,
      );
      expect(gridPage3, equals(const Offset(pageWidth + 32.0 + pageWidth / 2.0, pageHeight + 32.0 + pageHeight / 2.0)));
    });

    test('computePageFocusMatrix computes centering translation at given scale', () {
      final config = core.PageConfig(
        pageSize: core.PageSize.a4,
        orientation: core.PageOrientation.portrait,
      );
      const constraints = BoxConstraints(maxWidth: 1920, maxHeight: 1080);
      const scale = 1.5;

      final matrix = CanvasZoomCalculator.computePageFocusMatrix(
        arrangement: PageArrangementMode.continuousVertical,
        pageIndex: 1,
        constraints: constraints,
        config: config,
        currentScale: scale,
        rulerSize: 0,
      );

      final translation = matrix.getTranslation();
      final page1Center = CanvasZoomCalculator.computePageCenter(
        arrangement: PageArrangementMode.continuousVertical,
        pageIndex: 1,
        pageWidth: config.effectiveWidth * (96.0 / 25.4),
        pageHeight: config.effectiveHeight * (96.0 / 25.4),
      );

      // (translation.x + page1Center.dx * scale) must match viewport center (1920 / 2 = 960)
      expect(translation.x + page1Center.dx * scale, closeTo(960.0, 0.001));
      // (translation.y + page1Center.dy * scale) must match viewport center (1080 / 2 = 540)
      expect(translation.y + page1Center.dy * scale, closeTo(540.0, 0.001));
    });
  });

  group('ViewCubit Auto-Focus State & Preferences Tests', () {
    test('setAutoFocusOnPageChange updates state and persists', () async {
      final cubit = ViewCubit();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(cubit.state.autoFocusOnPageChange, isTrue);

      await cubit.setAutoFocusOnPageChange(false);
      expect(cubit.state.autoFocusOnPageChange, isFalse);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('view_auto_focus_on_page_change'), isFalse);

      await cubit.setAutoFocusOnPageChange(true);
      expect(cubit.state.autoFocusOnPageChange, isTrue);

      cubit.close();
    });
  });

  group('Auto-Focus Toggle in ViewPanel & DocumentSettingsGroup Tests', () {
    testWidgets('toggling auto-focus switch in ViewPanel calls onAutoFocusChanged', (tester) async {
      final viewCubit = ViewCubit();
      final localeCubit = LocaleCubit(const LocaleState());
      final docCubit = DocumentCubit();
      final tc = TransformationController();

      await tester.pumpWidget(
        _buildTestApp(
          localeCubit: localeCubit,
          viewCubit: viewCubit,
          docCubit: docCubit,
          child: SizedBox(
            width: 320,
            height: 900,
            child: ViewPanel(
              transformationController: tc,
              onZoomPreset: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Auto-Focus Active Page'), findsOneWidget);
      final autoFocusRow = find.ancestor(
        of: find.text('Auto-Focus Active Page'),
        matching: find.byType(Row),
      );
      final switchFinder = find.descendant(
        of: autoFocusRow,
        matching: find.byType(Switch),
      );
      expect(switchFinder, findsOneWidget);

      final switchWidget = tester.widget<Switch>(switchFinder);
      expect(switchWidget.value, isTrue);

      await tester.tap(switchFinder);
      await tester.pumpAndSettle();

      expect(viewCubit.state.autoFocusOnPageChange, isFalse);

      viewCubit.close();
      localeCubit.close();
      docCubit.close();
    });

    testWidgets('toggling auto-focus switch in DocumentSettingsGroup updates state', (tester) async {
      bool autoFocus = true;

      await tester.pumpWidget(
        _buildTestApp(
          child: DocumentSettingsGroup(
            pageSize: core.PageSize.a4,
            onPageSizeChanged: (_) {},
            orientation: core.PageOrientation.portrait,
            onOrientationChanged: (_) {},
            arrangementMode: PageArrangementMode.grid,
            onArrangementModeChanged: (_) {},
            autoFocusOnPageChange: autoFocus,
            onAutoFocusChanged: (val) => autoFocus = val,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Auto-Focus Active Page'), findsOneWidget);
      final switchFinder = find.byType(Switch);
      expect(switchFinder, findsOneWidget);

      await tester.tap(switchFinder);
      expect(autoFocus, isFalse);
    });
  });

  group('PointerEditorScreen Auto-Focus Integration Tests', () {
    testWidgets('advancing page in continuousVertical mode translates camera to center page 2', (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final docCubit = DocumentCubit();
      docCubit.setPageCount(3);
      final viewCubit = ViewCubit();
      final localeCubit = LocaleCubit(const LocaleState());

      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider.value(value: localeCubit),
            BlocProvider.value(value: viewCubit),
            BlocProvider.value(value: docCubit),
          ],
          child: const MaterialApp(
            localizationsDelegates: [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: PointerEditorScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Switch to continuous vertical
      await viewCubit.setPageArrangement(PageArrangementMode.continuousVertical);
      await tester.pumpAndSettle();

      // Find InteractiveViewer and get initial translation
      final ivFinder = find.byType(InteractiveViewer);
      expect(ivFinder, findsOneWidget);
      final ivWidget = tester.widget<InteractiveViewer>(ivFinder);
      final initialTy = ivWidget.transformationController!.value.getTranslation().y;

      // Click next page button on CanvasPageNavigator
      final nextBtn = find.widgetWithIcon(IconButton, Icons.chevron_right_rounded);
      expect(nextBtn, findsOneWidget);
      await tester.tap(nextBtn);

      // Pump through animation
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      expect(viewCubit.state.currentPageIndex, equals(1));
      final newTy = ivWidget.transformationController!.value.getTranslation().y;

      // Because page 1 is below page 0 in vertical flow, the camera must pan down (Ty becomes more negative)
      expect(newTy, lessThan(initialTy));

      viewCubit.close();
      localeCubit.close();
      docCubit.close();
    });
  });
}
