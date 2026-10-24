# Changelog - SarvMD Core (`sarvmd_core`)

All notable changes to the `sarvmd_core` layout engine and engraving pipeline will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [Unreleased]

### Added
- **Printable Score Typography & Gouldian Header Engraving**:
  - Added `DocumentMetadataTypography` extension (`hasPrintableTypography`, `hasTitleBlock`) for smart layout detection.
  - Added `ScoreTypographyMetrics` with Elaine Gould standard proportions (Title 20pt bold, Subtitle 12pt italic, Composer/Lyricist 10.5pt, Copyright 8.5pt, running header 9pt).
  - Updated `computeLayout` to compute vertical headroom dynamically on Page 1 while reclaiming stave drawing space on subsequent pages, remaining 100% backward-compatible when metadata is empty.
  - Implemented authentic typography engraving in `pdf_emitter.dart`, `svg_emitter.dart` (`<g id="layer-score-typography">`), and `emitter.dart` (LaTeX picture environment).
  - Extended `ScoreCompiler` methods (`compileToTex`, `compileToPdf`, `compileToSvg`) with optional `DocumentMetadata? metadata`.
- **Developer Documentation & Recipes (`packages/sarvmd_core/README.md`)**:
  - Published comprehensive API Reference covering domain models (`PageConfig`, `StaffConfig`, `SystemLayout`, `StaffNodeGroup`, `Clef`, `ScoreCompiler`, `SarvDocument`).
  - Added copy-paste code recipes for constructing layouts, programmatic `.sarv` mutation, vector PDF/SVG emission, and layout calculation queries.

## [0.12.4] - 2026-10-22

### Added
- **Zero-Dependency Direct Vector PDF & SVG Emitters (`ScoreCompiler`)**:
  - Implemented `ScoreCompiler.compileToPdf` emitting high-resolution, vector-accurate PDF documents natively in pure Dart using `package:pdf`, eliminating external `pdflatex` binary requirements.
  - Implemented `ScoreCompiler.compileToSvg` emitting layered, scalable vector graphics markup with configurable grouping (`SvgLayeringMode.byStaff` and `.unified`).
- **Gouldian Engraving Standards & Dynamic Layout Indentation**:
  - Two-tier hierarchical labeling: space-aware dynamic horizontal indentation for group labels vs. inner staff descriptors with character-weighted typographic advance estimation (`estimateLabelWidthMm`).
  - Implemented Gould's rule on initial barlines (*Behind Bars*, p. 230): solo classical staves remain open on the left edge, while ensembles, grand staves, and TAB layouts enforce a closed system start line.
  - Bracket clearance buffer: added cumulative 2.0mm clearance ticks to prevent connectors colliding with long instrument names.
- **SMuFL Bravura Music Typography (`domain/clef.dart`, `domain/smufl.dart`)**:
  - Embedded vector paths for standard SMuFL Bravura music glyphs (Treble, Bass, Alto, Tenor, Percussion, and 4/6-string TAB clefs).
  - Standardized TAB clefs dynamically scaled to 90% staff height with vertical midline alignment across PDF, SVG, and LaTeX emitters.
- **Transactional Mutation Pipeline (`command/`)**:
  - Command pattern infrastructure (`DocumentCommand`, `CommandHistory`, `ScoreCommand`, `ConfigCommand`) supporting value-equality `canUndo`/`canRedo` tracking.
- **Cross-Platform File Naming Engine (`compiler/file_naming.dart`)**:
  - Zero-dependency file naming and collision disambiguation utility ensuring number suffixes are positioned strictly before extensions (`name (1).pdf`, `name (1).sarv`).
- **Standard Ensemble Profiles (`StaffProfiles`)**:
  - Added 15 historical and standard profiles including `chamberOrchestra` (nested brackets and sub-brackets), `stringQuartet`, `choirSatb`, `piano`, and `guitarTab`.
