// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Licensed under the Business Source License 1.1 (BUSL-1.1).

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sarvmd_core/sarvmd_core.dart' as core;
import 'package:sarvmd_ui/src/l10n/app_localizations.dart';
import 'package:sarvmd_ui/src/presentation/widgets/staff/score_typography_settings_group.dart';

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
      body: SingleChildScrollView(child: child),
    ),
  );
}

void main() {
  group('ScoreTypographySettingsGroup Widget Tests', () {
    testWidgets('renders all fields with metadata initial values and master switches', (tester) async {
      const meta = core.DocumentMetadata(
        title: 'Air on the G String',
        subtitle: 'Orchestral Suite No. 3',
        composer: 'J. S. Bach',
        arranger: 'A. Wilhelmj',
        lyricist: 'Instrumental',
        copyright: '© 2026 SarvMD',
      );

      core.DocumentMetadata? updated;

      await tester.pumpWidget(
        _buildTestApp(
          child: ScoreTypographySettingsGroup(
            metadata: meta,
            onMetadataChanged: (m) => updated = m,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Master switch labels
      expect(find.text('Show Header Block'), findsOneWidget);
      expect(find.text('Show Page Numbers'), findsOneWidget);

      // Text fields
      expect(find.text('Air on the G String'), findsOneWidget);
      expect(find.text('Orchestral Suite No. 3'), findsOneWidget);
      expect(find.text('J. S. Bach'), findsOneWidget);
      expect(find.text('A. Wilhelmj'), findsOneWidget);
      expect(find.text('Instrumental'), findsOneWidget);
      expect(find.text('© 2026 SarvMD'), findsOneWidget);

      // Advanced properties button
      expect(find.text('Advanced Properties…'), findsOneWidget);
      expect(updated, isNull);
    });

    testWidgets('toggling master header block switch updates showTitleBlock in metadata', (tester) async {
      core.DocumentMetadata currentMeta = const core.DocumentMetadata(
        title: 'Test Score',
        showTitleBlock: true,
      );

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return _buildTestApp(
              child: ScoreTypographySettingsGroup(
                metadata: currentMeta,
                onMetadataChanged: (newMeta) {
                  setState(() => currentMeta = newMeta);
                },
              ),
            );
          },
        ),
      );
      await tester.pumpAndSettle();

      // Switch for header block is currently on
      final switches = find.byType(Switch);
      expect(switches, findsNWidgets(2)); // Header block switch + Page numbers switch

      // Tap first switch (Header block)
      await tester.tap(switches.first);
      await tester.pumpAndSettle();

      expect(currentMeta.showTitleBlock, isFalse);
    });

    testWidgets('toggling individual eye toggle updates element visibility flag without deleting content', (tester) async {
      core.DocumentMetadata currentMeta = const core.DocumentMetadata(
        title: 'Symphony No. 5',
        composer: 'Beethoven',
        showTitle: true,
        showComposer: true,
      );

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return _buildTestApp(
              child: ScoreTypographySettingsGroup(
                metadata: currentMeta,
                onMetadataChanged: (newMeta) {
                  setState(() => currentMeta = newMeta);
                },
              ),
            );
          },
        ),
      );
      await tester.pumpAndSettle();

      // Find visibility icon for Title
      final hideOnScoreButtons = find.byIcon(Icons.visibility_outlined);
      expect(hideOnScoreButtons, findsWidgets);

      // Tap first eye toggle (Title)
      await tester.tap(hideOnScoreButtons.first);
      await tester.pumpAndSettle();

      expect(currentMeta.showTitle, isFalse);
      expect(currentMeta.title, equals('Symphony No. 5')); // Text is preserved!
    });

    testWidgets('editing text in field fires onMetadataChanged with updated string', (tester) async {
      core.DocumentMetadata currentMeta = const core.DocumentMetadata(
        title: 'Initial',
      );

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return _buildTestApp(
              child: ScoreTypographySettingsGroup(
                metadata: currentMeta,
                onMetadataChanged: (newMeta) {
                  setState(() => currentMeta = newMeta);
                },
              ),
            );
          },
        ),
      );
      await tester.pumpAndSettle();

      final titleField = find.widgetWithText(TextField, 'Initial');
      await tester.enterText(titleField, 'New Masterpiece');
      await tester.pumpAndSettle();

      expect(currentMeta.title, equals('New Masterpiece'));
    });

    testWidgets('secondary credits are collapsed by default when empty, and expand on tap', (tester) async {
      core.DocumentMetadata currentMeta = const core.DocumentMetadata(
        title: 'Solo Violin Piece',
        composer: 'Paganini',
      );

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return _buildTestApp(
              child: ScoreTypographySettingsGroup(
                metadata: currentMeta,
                onMetadataChanged: (newMeta) {
                  setState(() => currentMeta = newMeta);
                },
              ),
            );
          },
        ),
      );
      await tester.pumpAndSettle();

      // Primary fields are present
      expect(find.text('Solo Violin Piece'), findsOneWidget);
      expect(find.text('Paganini'), findsOneWidget);

      // Secondary fields are collapsed initially
      expect(find.text('Subtitle'), findsNothing);
      expect(find.text('Arranger'), findsNothing);
      expect(find.text('Lyricist'), findsNothing);

      // Expansion button is visible
      final expandBtn = find.text('Additional Credits (Subtitle, Arranger, Lyricist)');
      expect(expandBtn, findsOneWidget);

      // Tap to expand
      await tester.tap(expandBtn);
      await tester.pumpAndSettle();

      // Secondary fields are now visible
      expect(find.text('Subtitle'), findsOneWidget);
      expect(find.text('Arranger'), findsOneWidget);
      expect(find.text('Lyricist'), findsOneWidget);
      expect(find.text('Hide Additional Credits'), findsOneWidget);

      // Tap again to collapse
      await tester.tap(find.text('Hide Additional Credits'));
      await tester.pumpAndSettle();

      expect(find.text('Subtitle'), findsNothing);
      expect(find.text('Additional Credits (Subtitle, Arranger, Lyricist)'), findsOneWidget);
    });

    testWidgets('live headroom badge displays dynamic Gouldian clearance on page 1', (tester) async {
      // 1. Title only -> 18.0 mm
      core.DocumentMetadata currentMeta = const core.DocumentMetadata(
        title: 'Title Only',
      );

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return _buildTestApp(
              child: ScoreTypographySettingsGroup(
                metadata: currentMeta,
                onMetadataChanged: (newMeta) {
                  setState(() => currentMeta = newMeta);
                },
              ),
            );
          },
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Header Headroom: 18.0 mm (Page 1)'), findsOneWidget);

      // 2. Title + Composer -> 22.0 mm
      currentMeta = const core.DocumentMetadata(
        title: 'Title',
        composer: 'Composer',
      );
      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return _buildTestApp(
              child: ScoreTypographySettingsGroup(
                metadata: currentMeta,
                onMetadataChanged: (newMeta) {
                  setState(() => currentMeta = newMeta);
                },
              ),
            );
          },
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Header Headroom: 22.0 mm (Page 1)'), findsOneWidget);

      // 3. Title + Subtitle + Composer -> 28.0 mm
      currentMeta = const core.DocumentMetadata(
        title: 'Title',
        subtitle: 'Subtitle',
        composer: 'Composer',
      );
      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return _buildTestApp(
              child: ScoreTypographySettingsGroup(
                metadata: currentMeta,
                onMetadataChanged: (newMeta) {
                  setState(() => currentMeta = newMeta);
                },
              ),
            );
          },
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Header Headroom: 28.0 mm (Page 1)'), findsOneWidget);
    });

    testWidgets('when header block is disabled, collapses fields and displays notice', (tester) async {
      const currentMeta = core.DocumentMetadata(
        title: 'Hidden Header Piece',
        showTitleBlock: false,
      );

      await tester.pumpWidget(
        _buildTestApp(
          child: ScoreTypographySettingsGroup(
            metadata: currentMeta,
            onMetadataChanged: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Inputs are collapsed
      expect(find.text('Hidden Header Piece'), findsNothing);
      expect(find.text('Header block is hidden. Staves occupy full first page.'), findsOneWidget);
    });
  });
}
