// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Licensed under the Business Source License 1.1 (BUSL-1.1).
// See the LICENSE file in the project root for details.

import 'package:sarvmd_core/sarvmd_core.dart';
import 'package:test/test.dart';

void main() {
  group('Printable Score Typography & Header Block', () {
    test('DocumentMetadataTypography extension identifies printable typography correctly', () {
      const emptyMeta = DocumentMetadata();
      expect(emptyMeta.hasPrintableTypography, isFalse);
      expect(emptyMeta.hasTitleBlock, isFalse);

      const titleOnly = DocumentMetadata(title: 'Symphony No. 5');
      expect(titleOnly.hasPrintableTypography, isTrue);
      expect(titleOnly.hasTitleBlock, isTrue);

      const copyrightOnly = DocumentMetadata(copyright: '© 2026 SarvMD');
      expect(copyrightOnly.hasPrintableTypography, isTrue);
      expect(copyrightOnly.hasTitleBlock, isFalse);

      const composerOnly = DocumentMetadata(composer: 'L. v. Beethoven');
      expect(composerOnly.hasPrintableTypography, isTrue);
      expect(composerOnly.hasTitleBlock, isTrue);
    });

    test('ScoreTypographyMetrics calculates Gouldian vertical headroom and footer clearances', () {
      expect(ScoreTypographyMetrics.computeHeaderHeadroomMm(null), equals(0.0));
      expect(
        ScoreTypographyMetrics.computeHeaderHeadroomMm(const DocumentMetadata()),
        equals(0.0),
      );

      // Title only -> 18mm
      const titleOnly = DocumentMetadata(title: 'Prelude in C Major');
      expect(ScoreTypographyMetrics.computeHeaderHeadroomMm(titleOnly), equals(18.0));

      // Title + Subtitle -> 22mm
      const titleAndSub = DocumentMetadata(
        title: 'Well-Tempered Clavier',
        subtitle: 'Book 1, Prelude 1',
      );
      expect(ScoreTypographyMetrics.computeHeaderHeadroomMm(titleAndSub), equals(22.0));

      // Title + Composer -> 22mm
      const titleAndComp = DocumentMetadata(
        title: 'Well-Tempered Clavier',
        composer: 'J. S. Bach',
      );
      expect(ScoreTypographyMetrics.computeHeaderHeadroomMm(titleAndComp), equals(22.0));

      // Title + Subtitle + Composer -> 28mm
      const fullHeader = DocumentMetadata(
        title: 'Well-Tempered Clavier',
        subtitle: 'Book 1, Prelude 1',
        composer: 'J. S. Bach',
        lyricist: 'Traditional',
      );
      expect(ScoreTypographyMetrics.computeHeaderHeadroomMm(fullHeader), equals(28.0));

      // Copyright clearance
      expect(ScoreTypographyMetrics.computeFooterClearanceMm(null), equals(0.0));
      expect(
        ScoreTypographyMetrics.computeFooterClearanceMm(const DocumentMetadata()),
        equals(0.0),
      );
      expect(
        ScoreTypographyMetrics.computeFooterClearanceMm(
          const DocumentMetadata(copyright: '© 2026 Plain Platform'),
        ),
        equals(6.0),
      );
    });

    test('computeLayout seamlessly incorporates headerHeadroom on Page 1 and restores space on Page 2', () {
      const config = PageConfig();
      final defaultLayout = computeLayout(config);
      expect(defaultLayout.headerHeadroomMm, equals(0.0));
      expect(defaultLayout.footerClearanceMm, equals(0.0));

      const meta = DocumentMetadata(
        title: 'Art of the Fugue',
        subtitle: 'Contrapunctus I',
        composer: 'J. S. Bach',
        copyright: 'Public Domain',
      );

      // Page 1 with metadata
      final page1Layout = computeLayout(config, metadata: meta, pageIndex: 0);
      expect(page1Layout.headerHeadroomMm, equals(28.0));
      expect(page1Layout.footerClearanceMm, equals(6.0));
      expect(
        page1Layout.systems.first.topY,
        greaterThan(defaultLayout.systems.first.topY),
      );
      // Top of first system should equal top margin + headerHeadroom
      expect(
        page1Layout.systems.first.topY,
        closeTo(config.margins.top + 28.0, 0.01),
      );

      // Page 2 (subsequent page) reclaims headroom space for music staves
      final page2Layout = computeLayout(config, metadata: meta, pageIndex: 1);
      expect(page2Layout.headerHeadroomMm, equals(0.0));
      expect(page2Layout.footerClearanceMm, equals(0.0));
      expect(
        page2Layout.systems.first.topY,
        closeTo(config.margins.top, 0.01),
      );
    });

    test('compileToSvg renders SVG score typography layer on page 1 and running header on subsequent pages', () {
      const config = PageConfig();
      const meta = DocumentMetadata(
        title: 'Goldberg Variations',
        subtitle: 'Aria mit 30 Veränderungen',
        composer: 'Johann Sebastian Bach',
        arranger: 'Pooria Askari Moqaddam',
        lyricist: 'Sacred Text',
        copyright: '© 2026 Plain Platform. All rights reserved.',
      );

      final page1Layout = computeLayout(config, metadata: meta, pageIndex: 0);
      final svgPage1 = ScoreCompiler.compileToSvg(config, page1Layout, metadata: meta);

      expect(svgPage1, contains('id="layer-score-typography"'));
      expect(svgPage1, contains('Goldberg Variations'));
      expect(svgPage1, contains('Aria mit 30 Ver'));
      expect(svgPage1, contains('Johann Sebastian Bach'));
      expect(svgPage1, contains('arr. Pooria Askari Moqaddam'));
      expect(svgPage1, contains('Sacred Text'));
      expect(svgPage1, contains('© 2026 Plain Platform'));

      // Subsequent page
      final page2Layout = computeLayout(config, metadata: meta, pageIndex: 1);
      final svgPage2 = ScoreCompiler.compileToSvg(config, page2Layout, metadata: meta);
      expect(svgPage2, contains('id="layer-score-typography"'));
      expect(svgPage2, contains('- 2 -'));
    });

    test('compileToTex emits LaTeX score typography block on page 1 and running page numbers on subsequent pages', () {
      const config = PageConfig();
      const meta = DocumentMetadata(
        title: 'Brandenburg Concerto No. 3',
        subtitle: 'BWV 1048',
        composer: 'J. S. Bach',
        arranger: 'Arranger Name',
        copyright: '© 2026 SarvMD',
      );

      final page1Layout = computeLayout(config, metadata: meta, pageIndex: 0);
      final tex = ScoreCompiler.compileToTex(config, page1Layout, pageCount: 2, metadata: meta);

      expect(tex, contains(r'\textbf{\LARGE Brandenburg Concerto No. 3}'));
      expect(tex, contains(r'\textit{\large BWV 1048}'));
      expect(tex, contains(r'\textbf{\normalsize J. S. Bach}'));
      expect(tex, contains(r'\textit{\small arr. Arranger Name}'));
      expect(tex, contains(r'\footnotesize © 2026 SarvMD'));
      expect(tex, contains(r'\small - 2 -'));
    });

    test('compileToPdf produces valid vector PDF bytes with printable typography', () async {
      const config = PageConfig();
      const meta = DocumentMetadata(
        title: 'Cello Suite No. 1',
        subtitle: 'Prélude',
        composer: 'J. S. Bach',
        copyright: 'Public Domain',
      );

      final layout = computeLayout(config, metadata: meta, pageIndex: 0);
      final pdfBytes = await ScoreCompiler.compileToPdf(
        config,
        layout,
        pageCount: 2,
        metadata: meta,
      );

      expect(pdfBytes, isNotEmpty);
      // PDF magic header
      expect(pdfBytes.sublist(0, 4), equals([0x25, 0x50, 0x44, 0x46])); // %PDF
    });
  });
}
