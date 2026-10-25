# SarvMD Core (`sarvmd_core`)

A zero-dependency, pure Dart music score layout and engraving engine.

`sarvmd_core` is the foundational computation engine powering the [SarvMD workspace](file:///home/ono/Projects/sarvmd/README.md). It models hierarchical music staves, calculates physical page geometry based on Gouldian engraving principles, serializes `.sarv` project files, and emits print-ready vector PDF, SVG, and LaTeX documents with zero runtime Flutter or external CLI dependencies.

---

## Table of Contents
- [Features](#features)
- [Architecture & Core Concepts](#architecture--core-concepts)
  - [1. Page Geometry & Rastral Sizing (`PageConfig`)](#1-page-geometry--rastral-sizing-pageconfig)
  - [2. Hierarchical Ensemble Layout (`SystemLayout`)](#2-hierarchical-ensemble-layout-systemlayout)
  - [3. Clefs & Musical Glyphs (`Clef`, SMuFL)](#3-clefs--musical-glyphs-clef-smufl)
  - [4. Native Document Schema (`SarvDocument`)](#4-native-document-schema-sarvdocument)
  - [5. Vector Compilation & Emitters (`ScoreCompiler`)](#5-vector-compilation--emitters-scorecompiler)
  - [6. Standard Profiles & Presets (`StaffProfiles`)](#6-standard-profiles--presets-staffprofiles)
- [Installation](#installation)
- [Developer How-To Recipes](#developer-how-to-recipes)
  - [Recipe 1: Generate a Blank Manuscript PDF from Scratch](#recipe-1-generate-a-blank-manuscript-pdf-from-scratch)
  - [Recipe 2: Build a Nested Ensemble Layout (String Quartet)](#recipe-2-build-a-nested-ensemble-layout-string-quartet)
  - [Recipe 3: Load, Modify, and Save a `.sarv` Project File](#recipe-3-load-modify-and-save-a-sarv-project-file)
  - [Recipe 4: Emit Vector SVG XML Strings for Web or Canvas](#recipe-4-emit-vector-svg-xml-strings-for-web-or-canvas)
  - [Recipe 5: Perform Layout Calculations & Page Geometry Queries](#recipe-5-perform-layout-calculations--page-geometry-queries)
- [Engraving Standards & Rules](#engraving-standards--rules)
- [Testing & Quality Assurance](#testing--quality-assurance)
- [License](#license)

---

## Features

* **Zero-Dependency Pure Dart**: Runs on any Dart runtime (CLI, Server, Flutter, Web/WASM). Does not require `flutter/widgets.dart` or native C/C++ toolchains.
* **Direct Vector PDF & SVG Emitters**: Generates crisp, resolution-independent vector PDF and SVG graphics natively in memory without requiring external utilities like `pdflatex` or `inkscape`.
* **Hierarchical Ensemble Trees**: Flexible multi-tier grouping tree ([`StaffNodeGroup`](file:///home/ono/Projects/sarvmd/packages/sarvmd_core/lib/src/layout.dart)) supporting brackets, sub-brackets, grand staff braces, and custom barlines.
* **MOLA & Gouldian Engraving Standards**: Automates dynamic first-system indentations, cumulative bracket tick clearances, and two-tier instrument labeling (Models A, B, and C).
* **Authentic SMuFL Typography**: Embeds vector paths matching standard SMuFL Bravura music glyphs (Treble, Bass, Alto, Tenor, Percussion, and 4/6-string TAB clefs).
* **Transactional Undo/Redo Engine**: Includes a command-pattern infrastructure ([`DocumentCommand`](file:///home/ono/Projects/sarvmd/packages/sarvmd_core/lib/src/command/document_command.dart), [`CommandHistory`](file:///home/ono/Projects/sarvmd/packages/sarvmd_core/lib/src/command/command_history.dart)) for mutation tracking and historical playback.

---

## Architecture & Core Concepts

### 1. Page Geometry & Rastral Sizing (`PageConfig`)

[`PageConfig`](file:///home/ono/Projects/sarvmd/packages/sarvmd_core/lib/src/config.dart) defines the physical canvas dimensions, print margins, and Rastral staff spacing metrics:

* **`size`**: Standard paper formats ([`PageSize.a3`](file:///home/ono/Projects/sarvmd/packages/sarvmd_core/lib/src/config.dart), `a4`, `a5`, `b4`, `b5`, `letter`).
* **`orientation`**: `portrait` or `landscape`.
* **`margins`**: Physical page borders in millimeters (`topMm`, `bottomMm`, `leftMm`, `rightMm`).
* **`staffConfig`**: Rastral spacing parameters:
  * `lineGapMm`: Distance between adjacent staff lines (e.g. `1.8` mm for Rastral size 3).
  * `interStaffGapMm`: Vertical distance between adjacent staves within a system.
  * `systemGapMm`: Vertical clearance between successive systems on a page.

### 2. Hierarchical Ensemble Layout (`SystemLayout`)

A manuscript page is composed of musical systems modeled as a composite tree of [`StaffNode`](file:///home/ono/Projects/sarvmd/packages/sarvmd_core/lib/src/layout.dart) objects:

```text
StaffNodeGroup (Root System) [connector: bracket, barline: single]
 ├── StaffNodeGroup (Violins) [connector: subBracket, barline: single]
 │    ├── StaffNodeLeaf ("Violin I", Clef: Treble, Lines: 5)
 │    └── StaffNodeLeaf ("Violin II", Clef: Treble, Lines: 5)
 ├── StaffNodeLeaf ("Viola", Clef: Alto, Lines: 5)
 └── StaffNodeLeaf ("Violoncello", Clef: Bass, Lines: 5)
```

* **Connectors ([`SystemConnector`](file:///home/ono/Projects/sarvmd/packages/sarvmd_core/lib/src/layout.dart))**: `none`, `bracket` (thick orchestral bracket with serifs), `subBracket` (thin straight secondary bracket), `brace` (curly keyboard brace).
* **Barlines ([`BarlineStyle`](file:///home/ono/Projects/sarvmd/packages/sarvmd_core/lib/src/layout.dart))**: `single`, `double`, `dashed`, `dotted`, `none`.
* **System Start Line**: Configurable initial barline closing the left edge for TAB or ensemble staves while keeping solo classical staves open per Gould p. 230.

### 3. Clefs & Musical Glyphs (`Clef`, SMuFL)

Staves are configured with a [`Clef`](file:///home/ono/Projects/sarvmd/packages/sarvmd_core/lib/src/domain/clef.dart) definition:

* **Types ([`ClefType`](file:///home/ono/Projects/sarvmd/packages/sarvmd_core/lib/src/domain/clef.dart))**: `treble`, `bass`, `alto`, `tenor`, `percussion`, `tab`, `none`.
* **Anchor Line**: Integer staff line (1-indexed from bottom) where the clef focal point aligns (e.g., Line 2 for Treble G-clef, Line 4 for Bass F-clef, Line 3 for Alto C-clef).
* **Glyph Engine**: Built-in SVG and PDF vector curves scaled precisely to staff line height.

### 4. Native Document Schema (`SarvDocument`)

[`SarvDocument`](file:///home/ono/Projects/sarvmd/packages/sarvmd_core/lib/src/domain/document.dart) represents a complete manuscript project:

* **`score`**: Document title and score identifiers.
* **`metadata`**: Extended composer, arranger, subtitle, lyricist, and copyright strings.
* **`config`**: The active [`PageConfig`](file:///home/ono/Projects/sarvmd/packages/sarvmd_core/lib/src/config.dart) and nested [`SystemLayout`](file:///home/ono/Projects/sarvmd/packages/sarvmd_core/lib/src/layout.dart).
* **`pageCount`**: Total pages in the score document.
* **JSON Serialization**: Full round-trip fidelity via `toSarvJson()` and `SarvDocument.fromSarvJson()`.

### 5. Vector Compilation & Emitters (`ScoreCompiler`)

[`ScoreCompiler`](file:///home/ono/Projects/sarvmd/packages/sarvmd_core/lib/src/compiler/score_compiler.dart) coordinates page layout calculation and binary vector generation:

* `ScoreCompiler.compileToPdf(doc, ...)`: Emits a binary vector PDF (`List<int>` or written to disk).
* `ScoreCompiler.compileToSvg(doc, ...)`: Emits an SVG XML document string or file with configurable layering.
* `ScoreCompiler.compileToTex(doc, ...)`: Emits standalone LaTeX source with `\pdfliteral` and `picture` environments.

### 6. Standard Profiles & Presets (`StaffProfiles`)

[`StaffProfiles.all`](file:///home/ono/Projects/sarvmd/packages/sarvmd_core/lib/src/profiles.dart) provides 15 pre-configured historical and standard scoring templates:
* Solo: `treble`, `bass`, `alto`, `tenor`, `percussionStandard`, `guitarTab`.
* Keyboard: `piano`, `organ`.
* Chamber & Ensemble: `stringQuartet`, `brassQuintet`, `windQuintet`, `choirSatb`, `chamberOrchestra`.

---

## Installation

Add `sarvmd_core` to your `pubspec.yaml`:

```yaml
dependencies:
  sarvmd_core:
    path: ../../packages/sarvmd_core # In monorepo
```

Import the central library:

```dart
import 'package:sarvmd_core/sarvmd_core.dart';
```

---

## Developer How-To Recipes

### Recipe 1: Generate a Blank Manuscript PDF from Scratch

Construct a default single-staff manuscript and compile directly to a PDF file:

```dart
import 'dart:io';
import 'package:sarvmd_core/sarvmd_core.dart';

void main() async {
  // 1. Create a page configuration (A4 portrait, 15mm margins)
  final config = PageConfig(
    size: PageSize.a4,
    orientation: PageOrientation.portrait,
    margins: const PageMargins.all(15.0),
    staffConfig: const StaffConfig(
      lineGapMm: 1.8,
      interStaffGapMm: 8.0,
      systemGapMm: 14.0,
    ),
  );

  // 2. Wrap into a SarvDocument
  final doc = SarvDocument(
    score: const Score(title: 'Concert Étude'),
    metadata: const DocumentMetadata(
      title: 'Concert Étude',
      composer: 'F. Chopin',
    ),
    config: config,
    pageCount: 2,
  );

  // 3. Compile directly to vector PDF bytes
  final pdfBytes = ScoreCompiler.compileToPdf(doc);

  // 4. Save to disk
  await File('etude.pdf').writeAsBytes(pdfBytes);
  print('Generated etude.pdf (${pdfBytes.length} bytes)');
}
```

---

### Recipe 2: Build a Nested Ensemble Layout (String Quartet)

Construct a multi-tiered ensemble layout using [`StaffProfiles.stringQuartet`](file:///home/ono/Projects/sarvmd/packages/sarvmd_core/lib/src/profiles.dart) or build manually:

```dart
import 'package:sarvmd_core/sarvmd_core.dart';

void main() {
  // Apply the built-in string quartet preset to an A4 page
  final quartetConfig = StaffProfiles.stringQuartet.applyTo(
    const PageConfig(
      size: PageSize.a4,
      orientation: PageOrientation.portrait,
    ),
  );

  // Inspect the layout structure
  final rootGroup = quartetConfig.systemLayout.rootGroup;
  print('Total staves per system: ${rootGroup.allStaves.length}');
  print('Root connector: ${rootGroup.connector}'); // SystemConnector.bracket

  for (final staff in rootGroup.allStaves) {
    print('Staff: "${staff.label}" | Clef: ${staff.clef.type.name}');
  }
}
```

---

### Recipe 3: Load, Modify, and Save a `.sarv` Project File

Manipulate native project files programmatically:

```dart
import 'dart:io';
import 'package:sarvmd_core/sarvmd_core.dart';

void main() {
  final file = File('project.sarv');
  final jsonString = file.readAsStringSync();

  // 1. Deserialize from JSON
  final doc = SarvDocument.fromSarvJson(jsonString);
  print('Loaded score: "${doc.score.title}" by ${doc.metadata.composer}');

  // 2. Modify metadata or page setup
  final updatedDoc = doc.copyWith(
    metadata: doc.metadata.copyWith(
      composer: 'J. S. Bach',
      subtitle: 'Arranged for String Trio',
    ),
    pageCount: 4,
  );

  // 3. Serialize back to JSON with clean formatting
  file.writeAsStringSync(updatedDoc.toSarvJson());
  print('Updated project.sarv successfully.');
}
```

---

### Recipe 4: Emit Vector SVG XML Strings for Web or Canvas

Generate SVG vector markup for browser embedding or custom UI rendering:

```dart
import 'package:sarvmd_core/sarvmd_core.dart';

void main() {
  final doc = SarvDocument(
    score: const Score(title: 'Chamber Score'),
    config: StaffProfiles.chamberOrchestra.applyTo(const PageConfig()),
    pageCount: 1,
  );

  // Emit clean SVG XML string with guides and staves
  final svgString = ScoreCompiler.compileToSvg(
    doc,
    layeringMode: SvgLayeringMode.unified,
  );

  print('SVG XML Length: ${svgString.length} characters');
  assert(svgString.startsWith('<svg') && svgString.endsWith('</svg>\n'));
}
```

---

### Recipe 5: Perform Layout Calculations & Page Geometry Queries

Inspect exact physical millimeter coordinates calculated by the engraving engine:

```dart
import 'package:sarvmd_core/sarvmd_core.dart';

void main() {
  const config = PageConfig();
  final calculator = SystemLayoutCalculator(config);

  // 1. Compute systems per page that fit cleanly within vertical margins
  final systemsPerPage = calculator.calculateSystemsPerPage();
  print('Calculated systems per page: $systemsPerPage');

  // 2. Query physical staff height
  final staffHeightMm = calculator.staffHeightMm;
  print('Staff height: ${staffHeightMm.toStringAsFixed(2)} mm');

  // 3. Query total system height (including inter-staff gaps)
  final systemHeightMm = calculator.systemHeightMm;
  print('System height: ${systemHeightMm.toStringAsFixed(2)} mm');

  // 4. Query printable page boundaries
  print('Printable width: ${calculator.printableWidthMm} mm');
  print('Printable height: ${calculator.printableHeightMm} mm');
}
```

---

## Engraving Standards & Rules

`sarvmd_core` adheres to classical and professional music engraving literature:

1. **Gould's Rule on System Start Lines** (*Behind Bars*, p. 230):
   - Standalone solo staves leave the left edge open without an initial barline.
   - Ensembles, keyboard grand staves, and TAB layouts enforce a closed initial vertical barline connecting the system.
2. **Two-Tier Dynamic System Indentation**:
   - Scores with outer group labels (e.g., "WOODWINDS") and inner staff descriptors (e.g., "Flute 1") automatically reserve proportional horizontal indentation (`estimateLabelWidthMm`).
   - Group brackets automatically clear instrument labels with a 2.0 mm margin buffer.
3. **Universal Brace Placement**:
   - Keyboard braces (`SystemConnector.brace`) always position descriptors outside the curl to prevent typographic collision.

---

## Testing & Quality Assurance

`sarvmd_core` is rigorously validated by unit test suites under [`test/`](file:///home/ono/Projects/sarvmd/packages/sarvmd_core/test):

```bash
# Run core test suite
flutter test packages/sarvmd_core
# Or with dart test
cd packages/sarvmd_core && dart test
```

Test suites cover:
* **`hierarchical_labeling_test.dart`**: Multi-tier nesting, bracket positioning, and label clearance calculations.
* **`score_compiler_test.dart`**: PDF, SVG, and LaTeX emission validity and file sanitization.
* **`document_serialization_test.dart`**: Round-trip `.sarv` JSON serialization without data loss.

---

## License

Licensed under the **Business Source License 1.1 (BUSL-1.1)**. See the root [LICENSE](file:///home/ono/Projects/sarvmd/LICENSE) file for complete details.
