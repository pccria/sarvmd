// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Licensed under the Business Source License 1.1 (BUSL-1.1).

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sarvmd_core/sarvmd_core.dart' as core;
import 'package:sarvmd_ui/src/l10n/app_localizations.dart';
import 'package:sarvmd_ui/src/logic/document/document_cubit.dart';
import 'package:sarvmd_ui/src/logic/view/view_cubit.dart';
import 'package:sarvmd_ui/src/logic/view/view_state.dart';
import 'package:sarvmd_ui/src/presentation/widgets/canvas/canvas_page_navigator.dart';
import 'package:sarvmd_ui/src/presentation/widgets/canvas/preview_canvas.dart';
import 'package:sarvmd_ui/src/presentation/widgets/common/shortcut_gateway.dart';
import 'package:sarvmd_ui/src/presentation/widgets/staff/document_settings_group.dart';

Widget _buildTestApp({required Widget child}) {
  return MaterialApp(
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: const [Locale('en')],
    home: Scaffold(
      body: child,
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CanvasPageNavigator Widget Tests', () {
    testWidgets('renders single page state correctly (Page 1 of 1, disabled navigation, no remove button)', (tester) async {
      int? changedIndex;
      bool addedPage = false;
      bool removedPage = false;

      await tester.pumpWidget(
        _buildTestApp(
          child: CanvasPageNavigator(
            currentPageIndex: 0,
            pageCount: 1,
            onPageChanged: (idx) => changedIndex = idx,
            onAddPage: () => addedPage = true,
            onRemovePage: () => removedPage = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Page 1 of 1'), findsOneWidget);

      // Previous button should be disabled
      final prevBtn = tester.widget<IconButton>(find.widgetWithIcon(IconButton, Icons.chevron_left_rounded));
      expect(prevBtn.onPressed, isNull);

      // Next button should be disabled
      final nextBtn = tester.widget<IconButton>(find.widgetWithIcon(IconButton, Icons.chevron_right_rounded));
      expect(nextBtn.onPressed, isNull);

      // Remove button (-) should not be present when pageCount == 1
      expect(find.byIcon(Icons.remove_rounded), findsNothing);

      // Add button (+) should be enabled
      final addBtn = tester.widget<IconButton>(find.widgetWithIcon(IconButton, Icons.add_rounded));
      expect(addBtn.onPressed, isNotNull);

      await tester.tap(find.widgetWithIcon(IconButton, Icons.add_rounded));
      await tester.pump();
      expect(addedPage, isTrue);
      expect(changedIndex, isNull);
      expect(removedPage, isFalse);
    });

    testWidgets('navigates forward and backward when multiple pages exist', (tester) async {
      int? targetIndex;
      bool removedPage = false;

      await tester.pumpWidget(
        _buildTestApp(
          child: CanvasPageNavigator(
            currentPageIndex: 1,
            pageCount: 3,
            onPageChanged: (idx) => targetIndex = idx,
            onAddPage: () {},
            onRemovePage: () => removedPage = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Page 2 of 3'), findsOneWidget);

      // Previous button should be active and navigate to page 0
      await tester.tap(find.widgetWithIcon(IconButton, Icons.chevron_left_rounded));
      await tester.pump();
      expect(targetIndex, equals(0));

      // Next button should be active and navigate to page 2
      await tester.tap(find.widgetWithIcon(IconButton, Icons.chevron_right_rounded));
      await tester.pump();
      expect(targetIndex, equals(2));

      // Remove button should be present and call onRemovePage
      expect(find.byIcon(Icons.remove_rounded), findsOneWidget);
      await tester.tap(find.widgetWithIcon(IconButton, Icons.remove_rounded));
      await tester.pump();
      expect(removedPage, isTrue);
    });
  });

  group('PreviewCanvas Multi-Page Layout Tests', () {
    testWidgets('renders Page 1 title block and Page 2 running page header', (tester) async {
      const config = core.PageConfig(
        pageSize: core.PageSize.a4,
        orientation: core.PageOrientation.portrait,
      );

      final p1Layout = core.computeLayout(
        config,
        metadata: const core.DocumentMetadata(
          title: 'Symphony No. 5',
          composer: 'L. v. Beethoven',
        ),
        pageIndex: 0,
      );

      final p2Layout = core.computeLayout(
        config,
        metadata: const core.DocumentMetadata(
          title: 'Symphony No. 5',
          composer: 'L. v. Beethoven',
        ),
        pageIndex: 1,
      );

      expect(p1Layout.pageIndex, equals(0));
      expect(p1Layout.headerHeadroomMm, greaterThan(0.0));
      expect(p1Layout.hasTitleBlock, isTrue);

      expect(p2Layout.pageIndex, equals(1));
      expect(p2Layout.headerHeadroomMm, equals(0.0));
      expect(p2Layout.hasTitleBlock, isFalse);

      // Render Page 1
      await tester.pumpWidget(
        _buildTestApp(
          child: PreviewCanvas(
            layout: p1Layout,
            viewState: const ViewState(),
            metadata: const core.DocumentMetadata(
              title: 'Symphony No. 5',
              composer: 'L. v. Beethoven',
            ),
            pageIndex: 0,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(PreviewCanvas), findsOneWidget);

      // Render Page 2
      await tester.pumpWidget(
        _buildTestApp(
          child: PreviewCanvas(
            layout: p2Layout,
            viewState: const ViewState(),
            metadata: const core.DocumentMetadata(
              title: 'Symphony No. 5',
              composer: 'L. v. Beethoven',
            ),
            pageIndex: 1,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(PreviewCanvas), findsOneWidget);
    });
  });

  group('DocumentSettingsGroup Page Setup Stepper & Chips Tests', () {
    testWidgets('renders page count stepper and quick preset chips', (tester) async {
      int? updatedPages;

      await tester.pumpWidget(
        _buildTestApp(
          child: SingleChildScrollView(
            child: DocumentSettingsGroup(
              pageSize: core.PageSize.a4,
              orientation: core.PageOrientation.portrait,
              onPageSizeChanged: (_) {},
              onOrientationChanged: (_) {},
              pageCount: 2,
              onPageCountChanged: (count) => updatedPages = count,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Document Pages'), findsOneWidget);
      expect(find.text('Total pages in score manuscript'), findsOneWidget);

      // Quick preset chips 1, 2, 4, 8 (and stepper '2')
      expect(find.text('1'), findsOneWidget);
      expect(find.text('2'), findsNWidgets(2));
      expect(find.text('4'), findsOneWidget);
      expect(find.text('8'), findsOneWidget);

      // Tap preset '4'
      await tester.tap(find.text('4'));
      await tester.pump();
      expect(updatedPages, equals(4));

      // Tap '+' stepper button
      await tester.tap(find.byIcon(Icons.add_rounded));
      await tester.pump();
      expect(updatedPages, equals(3));

      // Tap '-' stepper button
      await tester.tap(find.byIcon(Icons.remove_rounded));
      await tester.pump();
      expect(updatedPages, equals(1));
    });
  });

  group('ShortcutGateway Multi-Page Navigation Tests', () {
    testWidgets('PageDown and PageUp keys dispatch NextPage and PreviousPage actions', (tester) async {
      final docCubit = DocumentCubit();
      final viewCubit = ViewCubit();

      // Set document to 3 pages
      docCubit.setPageCount(3);
      expect(docCubit.state.pageCount, equals(3));
      expect(viewCubit.state.currentPageIndex, equals(0));

      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider<DocumentCubit>.value(value: docCubit),
            BlocProvider<ViewCubit>.value(value: viewCubit),
          ],
          child: _buildTestApp(
            child: const SarvShortcutGateway(
              child: Focus(
                autofocus: true,
                child: SizedBox(width: 100, height: 100),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Press PageDown -> next page
      await tester.sendKeyEvent(LogicalKeyboardKey.pageDown);
      await tester.pumpAndSettle();
      expect(viewCubit.state.currentPageIndex, equals(1));

      // Press PageDown again -> next page
      await tester.sendKeyEvent(LogicalKeyboardKey.pageDown);
      await tester.pumpAndSettle();
      expect(viewCubit.state.currentPageIndex, equals(2));

      // Press PageDown at end of document -> stays on page 2
      await tester.sendKeyEvent(LogicalKeyboardKey.pageDown);
      await tester.pumpAndSettle();
      expect(viewCubit.state.currentPageIndex, equals(2));

      // Press PageUp -> previous page
      await tester.sendKeyEvent(LogicalKeyboardKey.pageUp);
      await tester.pumpAndSettle();
      expect(viewCubit.state.currentPageIndex, equals(1));

      // Press PageUp -> previous page
      await tester.sendKeyEvent(LogicalKeyboardKey.pageUp);
      await tester.pumpAndSettle();
      expect(viewCubit.state.currentPageIndex, equals(0));

      // Press PageUp at start of document -> stays on page 0
      await tester.sendKeyEvent(LogicalKeyboardKey.pageUp);
      await tester.pumpAndSettle();
      expect(viewCubit.state.currentPageIndex, equals(0));
    });
  });
}
