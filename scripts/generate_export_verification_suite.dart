// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Licensed under the Business Source License 1.1 (BUSL-1.1).

import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:sarvmd_core/sarvmd_core.dart';

void main() async {
  final outDir = Directory(p.join(Directory.current.path, 'exports_visual_verification'));
  if (outDir.existsSync()) {
    outDir.deleteSync(recursive: true);
  }
  outDir.createSync(recursive: true);

  print('================================================================');
  print(' SarvMD Visual Verification Suite Generator');
  print(' Output Directory: ${outDir.path}');
  print('================================================================\n');

  // ── Scenario 1: Single-Page Piano Grand Staff with Full Title Block ─────
  print('Generating Scenario 1: Single-Page Piano Grand Staff...');
  {
    final config = StaffProfiles.piano.applyTo(const PageConfig(
      pageSize: PageSize.a4,
      orientation: PageOrientation.portrait,
    ));
    final meta = const DocumentMetadata(
      title: 'Piano Sonata No. 14 in C-sharp minor',
      subtitle: 'Quasi una fantasia (Moonlight Sonata), Op. 27 No. 2',
      composer: 'Ludwig van Beethoven',
      arranger: 'Franz Liszt',
      copyright: '© 2026 SarvMD Engraving Engine. Public Domain Edition.',
      showTitleBlock: true,
      showPageNumbers: true,
    );
    final layout = computeLayout(config, pageIndex: 0, metadata: meta);

    // 1. PDF
    final pdfBytes = await ScoreCompiler.compileToPdf(config, layout, pageCount: 1, metadata: meta);
    File(p.join(outDir.path, '01_piano_sonata_single_page.pdf')).writeAsBytesSync(pdfBytes);

    // 2. SVG
    final svgString = ScoreCompiler.compileToSvg(config, layout, metadata: meta);
    File(p.join(outDir.path, '01_piano_sonata_single_page.svg')).writeAsStringSync(svgString);

    // 3. TeX
    final texString = ScoreCompiler.compileToTex(config, layout, pageCount: 1, metadata: meta);
    File(p.join(outDir.path, '01_piano_sonata_single_page.tex')).writeAsStringSync(texString);
  }

  // ── Scenario 2: Multi-Page String Quartet (3 Pages) ───────────────────
  print('Generating Scenario 2: Multi-Page String Quartet (3 Pages)...');
  {
    final config = StaffProfiles.stringQuartet.applyTo(const PageConfig(
      pageSize: PageSize.a4,
      orientation: PageOrientation.portrait,
    ));
    final meta = const DocumentMetadata(
      title: 'String Quartet in F major',
      subtitle: 'Op. 18 No. 1 — I. Allegro con brio',
      composer: 'Ludwig van Beethoven',
      copyright: '© 2026 SarvMD Engraving Engine. Urtext Master Edition.',
      showTitleBlock: true,
      showPageNumbers: true,
    );
    final layout = computeLayout(config, pageIndex: 0, metadata: meta);

    // 1. Multi-page PDF (3 pages)
    final pdfBytes = await ScoreCompiler.compileToPdf(config, layout, pageCount: 3, metadata: meta);
    File(p.join(outDir.path, '02_string_quartet_3pages.pdf')).writeAsBytesSync(pdfBytes);

    // 2. Multi-page SVGs (Pages 1, 2, 3 as individual files)
    final svgs = ScoreCompiler.compileAllPagesToSvg(config, pageCount: 3, initialLayout: layout, metadata: meta);
    for (var i = 0; i < svgs.length; i++) {
      File(p.join(outDir.path, '02_string_quartet_page_${i + 1}.svg')).writeAsStringSync(svgs[i]);
    }

    // 3. Multi-page TeX (3 pages with \newpage and per-page layout)
    final texString = ScoreCompiler.compileToTex(config, layout, pageCount: 3, metadata: meta);
    File(p.join(outDir.path, '02_string_quartet_3pages.tex')).writeAsStringSync(texString);
  }

  // ── Scenario 3: Empty Manuscript Notebook (Zero Metadata, 3 Pages) ─────
  print('Generating Scenario 3: Empty Manuscript Notebook (Zero Headroom)...');
  {
    final config = StaffProfiles.treble.applyTo(const PageConfig(
      pageSize: PageSize.a4,
      orientation: PageOrientation.portrait,
    ));
    const meta = DocumentMetadata(
      title: '',
      subtitle: '',
      composer: '',
      showTitleBlock: false,
      showPageNumbers: true,
    );
    final layout = computeLayout(config, pageIndex: 0, metadata: meta);

    // 1. PDF
    final pdfBytes = await ScoreCompiler.compileToPdf(config, layout, pageCount: 3, metadata: meta);
    File(p.join(outDir.path, '03_empty_notebook_a4_portrait_3pages.pdf')).writeAsBytesSync(pdfBytes);

    // 2. SVG (Page 1 and Page 2)
    final svgs = ScoreCompiler.compileAllPagesToSvg(config, pageCount: 2, initialLayout: layout, metadata: meta);
    File(p.join(outDir.path, '03_empty_notebook_page_1.svg')).writeAsStringSync(svgs[0]);
    File(p.join(outDir.path, '03_empty_notebook_page_2.svg')).writeAsStringSync(svgs[1]);
  }

  // ── Scenario 4: Complex Multi-Tier Nested Brackets (Woodwinds & Strings)
  print('Generating Scenario 4: Complex Nested Brackets & Multi-Tier Indents...');
  {
    final f1 = StaffDefinition(uid: 'f1', instrumentName: '1', instrumentAbbreviation: '1');
    final f2 = StaffDefinition(uid: 'f2', instrumentName: '2', instrumentAbbreviation: '2');
    final flutes = StaffNodeGroup(
      connector: SystemConnector.bracket,
      label: 'Flauti',
      abbreviation: 'Fl.',
      children: [f1, f2],
    );

    final ob1 = StaffDefinition(uid: 'ob1', instrumentName: '1', instrumentAbbreviation: '1');
    final ob2 = StaffDefinition(uid: 'ob2', instrumentName: '2', instrumentAbbreviation: '2');
    final oboes = StaffNodeGroup(
      connector: SystemConnector.bracket,
      label: 'Oboi',
      abbreviation: 'Ob.',
      children: [ob1, ob2],
    );

    final woodwinds = StaffNodeGroup(
      connector: SystemConnector.bracket,
      label: 'Woodwinds',
      abbreviation: 'Ww.',
      children: [flutes, oboes],
    );

    final config = PageConfig(
      pageSize: PageSize.a4,
      orientation: PageOrientation.landscape,
      systemLayout: SystemLayout(rootGroup: woodwinds),
    );
    final meta = const DocumentMetadata(
      title: 'Symphonie Fantastique',
      subtitle: 'Hierarchical Section Demonstration',
      composer: 'Hector Berlioz',
      showTitleBlock: true,
      showPageNumbers: true,
    );
    final layout = computeLayout(config, pageIndex: 0, metadata: meta);

    final pdfBytes = await ScoreCompiler.compileToPdf(config, layout, pageCount: 2, metadata: meta);
    File(p.join(outDir.path, '04_hierarchical_woodwinds_a4_landscape_2pages.pdf')).writeAsBytesSync(pdfBytes);

    final svgs = ScoreCompiler.compileAllPagesToSvg(config, pageCount: 2, initialLayout: layout, metadata: meta);
    File(p.join(outDir.path, '04_hierarchical_woodwinds_page_1.svg')).writeAsStringSync(svgs[0]);
    File(p.join(outDir.path, '04_hierarchical_woodwinds_page_2.svg')).writeAsStringSync(svgs[1]);
  }

  // ── Scenario 5: Large Orchestral Study Score (A3 Landscape) ───────────
  print('Generating Scenario 5: Large Orchestral Study Score (A3 Landscape)...');
  {
    final config = StaffProfiles.chamberOrchestra.applyTo(const PageConfig(
      pageSize: PageSize.a3,
      orientation: PageOrientation.landscape,
    ));
    final meta = const DocumentMetadata(
      title: 'Symphony No. 9 in D minor',
      subtitle: 'Op. 125 — IV. Finale (Ode to Joy)',
      composer: 'Ludwig van Beethoven',
      showTitleBlock: true,
      showPageNumbers: true,
    );
    final layout = computeLayout(config, pageIndex: 0, metadata: meta);

    final pdfBytes = await ScoreCompiler.compileToPdf(config, layout, pageCount: 2, metadata: meta);
    File(p.join(outDir.path, '05_orchestral_symphony9_a3_landscape_2pages.pdf')).writeAsBytesSync(pdfBytes);
  }

  // ── Scenario 6: TAB & Contemporary Percussion Score ───────────────────
  print('Generating Scenario 6: TAB & Neutral Percussion Clefs...');
  {
    final tabStaff = StaffDefinition(uid: 'tab1', lines: 6, clef: Clef.tab, instrumentName: 'Guitar (Drop D)');
    final percStaff = StaffDefinition(uid: 'perc1', lines: 1, clef: Clef.percussion, instrumentName: 'Kick/Snare');
    final band = StaffNodeGroup(
      connector: SystemConnector.bracket,
      label: 'Rhythm Section',
      children: [tabStaff, percStaff],
    );
    final config = PageConfig(
      pageSize: PageSize.letter,
      orientation: PageOrientation.portrait,
      systemLayout: SystemLayout(rootGroup: band),
    );
    final meta = const DocumentMetadata(
      title: 'Rock Groove Study',
      composer: 'Contemporary Guitar & Percussion',
      showTitleBlock: true,
    );
    final layout = computeLayout(config, pageIndex: 0, metadata: meta);

    final pdfBytes = await ScoreCompiler.compileToPdf(config, layout, pageCount: 1, metadata: meta);
    File(p.join(outDir.path, '06_tab_and_percussion_letter_portrait.pdf')).writeAsBytesSync(pdfBytes);

    final svg = ScoreCompiler.compileToSvg(config, layout, metadata: meta);
    File(p.join(outDir.path, '06_tab_and_percussion_letter_portrait.svg')).writeAsStringSync(svg);
  }

  // ── Scenario 7: Saddle-Stitch Booklet Imposition ──────────────────────
  print('Generating Scenario 7: Saddle-Stitch Imposed Booklets...');
  {
    // 7A: String Quartet (4 pages imposed on 1 sheet A3 Landscape, 1:1 scale)
    final configA4 = StaffProfiles.stringQuartet.applyTo(const PageConfig(
      pageSize: PageSize.a4,
      orientation: PageOrientation.portrait,
    ));
    final meta = const DocumentMetadata(
      title: 'String Quartet in F Major',
      subtitle: 'Op. 18 No. 1 — Booklet Edition',
      composer: 'Ludwig van Beethoven',
      showTitleBlock: true,
      showPageNumbers: true,
    );
    final layoutA4 = computeLayout(configA4, pageIndex: 0, metadata: meta);

    final bookletDoubleBytes = await ScoreCompiler.compileToBookletPdf(
      configA4,
      layoutA4,
      pageCount: 4,
      metadata: meta,
      bookletConfig: const BookletConfig(
        sheetMode: BookletSheetMode.doubleSize,
        drawSpineTicks: true,
      ),
    );
    File(p.join(outDir.path, '07_booklet_string_quartet_4pages_a3_double.pdf'))
        .writeAsBytesSync(bookletDoubleBytes);

    // 7B: String Quartet (3 pages with blank back cover, scaled 2-up onto A4 Landscape)
    final bookletScaledBytes = await ScoreCompiler.compileToBookletPdf(
      configA4,
      layoutA4,
      pageCount: 3,
      metadata: meta,
      bookletConfig: const BookletConfig(
        sheetMode: BookletSheetMode.sameSizeScaled,
        drawSpineTicks: true,
      ),
    );
    File(p.join(outDir.path, '07_booklet_string_quartet_3pages_a4_scaled.pdf'))
        .writeAsBytesSync(bookletScaledBytes);
  }

  print('\n✓ All visual verification scenarios successfully generated in ${outDir.path}!');
}
