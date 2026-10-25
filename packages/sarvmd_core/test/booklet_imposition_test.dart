// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Use of this source code is governed by a Business Source License 1.1
// license that can be found in the LICENSE file in the root of this project.

import 'package:sarvmd_core/sarvmd_core.dart';
import 'package:test/test.dart';

void main() {
  group('BookletImpositionCalculator Signature & Spreads Tests', () {
    test('calculateTotalBookletPages rounds up to multiples of 4 (min 4)', () {
      expect(BookletImpositionCalculator.calculateTotalBookletPages(0), 4);
      expect(BookletImpositionCalculator.calculateTotalBookletPages(1), 4);
      expect(BookletImpositionCalculator.calculateTotalBookletPages(2), 4);
      expect(BookletImpositionCalculator.calculateTotalBookletPages(3), 4);
      expect(BookletImpositionCalculator.calculateTotalBookletPages(4), 4);
      expect(BookletImpositionCalculator.calculateTotalBookletPages(5), 8);
      expect(BookletImpositionCalculator.calculateTotalBookletPages(8), 8);
      expect(BookletImpositionCalculator.calculateTotalBookletPages(9), 12);
      expect(BookletImpositionCalculator.calculateTotalBookletPages(16), 16);
    });

    test('calculateSheetCount returns totalBookletPages / 4', () {
      expect(BookletImpositionCalculator.calculateSheetCount(1), 1);
      expect(BookletImpositionCalculator.calculateSheetCount(4), 1);
      expect(BookletImpositionCalculator.calculateSheetCount(5), 2);
      expect(BookletImpositionCalculator.calculateSheetCount(8), 2);
      expect(BookletImpositionCalculator.calculateSheetCount(12), 3);
    });

    test('computeSpreads for 4 pages produces 1 sheet with 2 sides', () {
      final spreads = BookletImpositionCalculator.computeSpreads(4);
      expect(spreads.length, 2);

      // Sheet 1 Front: [Page 4 | Page 1] -> 0-indexed [3 | 0]
      final front = spreads[0];
      expect(front.sheetIndex, 0);
      expect(front.sheetNumber, 1);
      expect(front.isFrontSide, isTrue);
      expect(front.leftPageIndex, 3);
      expect(front.rightPageIndex, 0);
      expect(front.leftLabel, '4');
      expect(front.rightLabel, '1');

      // Sheet 1 Back: [Page 2 | Page 3] -> 0-indexed [1 | 2]
      final back = spreads[1];
      expect(back.sheetIndex, 0);
      expect(back.sheetNumber, 1);
      expect(back.isFrontSide, isFalse);
      expect(back.leftPageIndex, 1);
      expect(back.rightPageIndex, 2);
      expect(back.leftLabel, '2');
      expect(back.rightLabel, '3');
    });

    test('computeSpreads for 8 pages produces 2 sheets with 4 sides', () {
      final spreads = BookletImpositionCalculator.computeSpreads(8);
      expect(spreads.length, 4);

      // Sheet 1 Front: [8 | 1] -> 0-indexed [7 | 0]
      expect(spreads[0].leftPageIndex, 7);
      expect(spreads[0].rightPageIndex, 0);
      expect(spreads[0].leftLabel, '8');
      expect(spreads[0].rightLabel, '1');

      // Sheet 1 Back: [2 | 7] -> 0-indexed [1 | 6]
      expect(spreads[1].leftPageIndex, 1);
      expect(spreads[1].rightPageIndex, 6);
      expect(spreads[1].leftLabel, '2');
      expect(spreads[1].rightLabel, '7');

      // Sheet 2 Front: [6 | 3] -> 0-indexed [5 | 2]
      expect(spreads[2].leftPageIndex, 5);
      expect(spreads[2].rightPageIndex, 2);
      expect(spreads[2].leftLabel, '6');
      expect(spreads[2].rightLabel, '3');

      // Sheet 2 Back: [4 | 5] -> 0-indexed [3 | 4]
      expect(spreads[3].leftPageIndex, 3);
      expect(spreads[3].rightPageIndex, 4);
      expect(spreads[3].leftLabel, '4');
      expect(spreads[3].rightLabel, '5');
    });

    test('computeSpreads for 3 pages (odd count) leaves page 4 as blank padding', () {
      final spreads = BookletImpositionCalculator.computeSpreads(3);
      expect(spreads.length, 2);

      // Sheet 1 Front: [Blank | Page 1]
      expect(spreads[0].leftPageIndex, isNull);
      expect(spreads[0].leftLabel, 'Blank');
      expect(spreads[0].rightPageIndex, 0);
      expect(spreads[0].rightLabel, '1');

      // Sheet 1 Back: [Page 2 | Page 3]
      expect(spreads[1].leftPageIndex, 1);
      expect(spreads[1].leftLabel, '2');
      expect(spreads[1].rightPageIndex, 2);
      expect(spreads[1].rightLabel, '3');
    });

    test('computeSpreads satisfies signature invariant: Left + Right = Total + 1', () {
      for (final count in [1, 2, 3, 4, 5, 8, 12, 16]) {
        final spreads = BookletImpositionCalculator.computeSpreads(count);
        final total = BookletImpositionCalculator.calculateTotalBookletPages(count);

        for (final spread in spreads) {
          final leftNum = (spread.leftPageIndex ?? (total - 1)) + 1;
          final rightNum = (spread.rightPageIndex ?? 0) + 1;
          // In standard signature imposition, the sum of page positions equals total + 1
          if (spread.leftPageIndex != null && spread.rightPageIndex != null) {
            expect(leftNum + rightNum, total + 1);
          }
        }
      }
    });
  });

  group('Booklet PDF Compilation Tests', () {
    test('compileToBookletPdf generates double-size A3 sheet from A4 score', () async {
      final config = StaffProfiles.piano.applyTo(const PageConfig(
        pageSize: PageSize.a4,
        orientation: PageOrientation.portrait,
      ));
      final meta = const DocumentMetadata(
        title: 'Booklet Sonata',
        composer: 'Test Composer',
        showTitleBlock: true,
      );
      final layout = computeLayout(config, pageIndex: 0, metadata: meta);

      final pdfBytes = await ScoreCompiler.compileToBookletPdf(
        config,
        layout,
        pageCount: 4,
        metadata: meta,
        bookletConfig: const BookletConfig(sheetMode: BookletSheetMode.doubleSize),
      );

      expect(pdfBytes.length, greaterThan(1000));
      // PDF header verification
      expect(String.fromCharCodes(pdfBytes.sublist(0, 5)), '%PDF-');
    });

    test('compileToBookletPdf generates scaled same-size landscape sheet from A4 score', () async {
      final config = StaffProfiles.stringQuartet.applyTo(const PageConfig(
        pageSize: PageSize.a4,
        orientation: PageOrientation.portrait,
      ));
      final meta = const DocumentMetadata(
        title: 'String Quartet Booklet',
        subtitle: 'Op. 18',
        composer: 'L. v. Beethoven',
      );
      final layout = computeLayout(config, pageIndex: 0, metadata: meta);

      final pdfBytes = await ScoreCompiler.compileToBookletPdf(
        config,
        layout,
        pageCount: 3,
        metadata: meta,
        bookletConfig: const BookletConfig(
          sheetMode: BookletSheetMode.sameSizeScaled,
          drawSpineTicks: true,
        ),
      );

      expect(pdfBytes.length, greaterThan(1000));
      expect(String.fromCharCodes(pdfBytes.sublist(0, 5)), '%PDF-');
    });
  });
}
