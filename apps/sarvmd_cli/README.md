# SarvMD CLI (`sarvmd_cli`)

A headless, zero-dependency command-line music manuscript generator and compiler for composers, publishers, music educators, and automated CI/CD pipelines.

Designed and created by **Pooria Askari Moqaddam** as part of the [SarvMD workspace](file:///home/ono/Projects/sarvmd/README.md).

---

## Table of Contents
- [Overview](#overview)
- [Installation & Quickstart](#installation--quickstart)
  - [Running with the Dart SDK](#running-with-the-dart-sdk)
  - [Compiling a Standalone Native Binary](#compiling-a-standalone-native-binary)
- [Command Reference Matrix](#command-reference-matrix)
- [Global Options](#global-options)
- [Commands & Usage Manual](#commands--usage-manual)
  - [1. `generate` (short: `g`)](#1-generate-short-g)
  - [2. `compile` (short: `c`)](#2-compile-short-c)
  - [3. `inspect` (short: `i`)](#3-inspect-short-i)
  - [4. `profiles` (short: `p`)](#4-profiles-short-p)
- [Practical How-To Recipes](#practical-how-to-recipes)
  - [Recipe 1: Generate Standard Blank Piano Manuscript](#recipe-1-generate-standard-blank-piano-manuscript)
  - [Recipe 2: Generate Vector SVG for Graphic Design or Printing](#recipe-2-generate-vector-svg-for-graphic-design-or-printing)
  - [Recipe 3: Compile `.sarv` Project Files Headlessly in CI/CD](#recipe-3-compile-sarv-project-files-headlessly-in-cicd)
  - [Recipe 4: Automated JSON Inspection with `jq`](#recipe-4-automated-json-inspection-with-jq)
  - [Recipe 5: LaTeX Source Generation and `pdflatex` Fallback](#recipe-5-latex-source-generation-and-pdflatex-fallback)
- [Architecture & Design Principles](#architecture--design-principles)
- [Testing & Quality Assurance](#testing--quality-assurance)
- [License](#license)

---

## Overview

`sarvmd_cli` provides a scriptable interface to the [`sarvmd_core`](file:///home/ono/Projects/sarvmd/packages/sarvmd_core) engraving engine. Unlike traditional music typesetting command-line utilities that require bulky external TeX distributions, `sarvmd_cli` features:

* **Zero External Dependencies**: Generates print-ready vector PDF and SVG documents natively in pure Dart using [`ScoreCompiler`](file:///home/ono/Projects/sarvmd/packages/sarvmd_core/lib/src/compiler/score_compiler.dart).
* **Native `.sarv` Compilation**: Directly compiles project files created in the SarvMD UI editor into final publication formats.
* **Streamlined Single-Character Commands**: Strict 1:1 pairing between long-form commands and single-character shortcuts (`g`, `c`, `i`, `p`) with zero confusing synonym aliases.
* **Automated CI/CD Ready**: Standardized exit codes (`0` for success, `1` for execution failure, `64` for invalid usage) and JSON output flags (`--json`) for pipeline integration.

---

## Installation & Quickstart

### Running with the Dart SDK

You can run `sarvmd_cli` directly from source using the Dart SDK:

```bash
# Navigate to the CLI package
cd apps/sarvmd_cli

# Print version and help
dart run bin/sarvmd.dart --help

# Generate a blank treble manuscript PDF
dart run bin/sarvmd.dart g -p treble -o output/treble.pdf
```

### Compiling a Standalone Native Binary

For maximum execution speed and standalone deployment (no Dart SDK needed on the host system), compile to a native Linux, macOS, or Windows binary:

```bash
# Compile to self-contained native executable
dart compile exe bin/sarvmd.dart -o sarvmd

# Move into your system PATH (e.g., ~/.local/bin or /usr/local/bin)
mv sarvmd ~/.local/bin/

# Execute globally
sarvmd --version
```

---

## Command Reference Matrix

The CLI strictly enforces a **1:1 canonical long-form and single-character shortcut pairing**:

| Command | Shortcut | Description | Primary Inputs | Default Output |
| :--- | :---: | :--- | :--- | :--- |
| [`generate`](#1-generate-short-g) | **`g`** | Generate blank manuscript directly from profiles or parameters | Profile ID, Paper Size, Orientation | `output/<profile>.pdf` |
| [`compile`](#2-compile-short-c) | **`c`** | Compile an existing `.sarv` project file into publication formats | Input `.sarv` file path | `<input_stem>.<format>` |
| [`inspect`](#3-inspect-short-i) | **`i`** | Inspect score metadata, geometry, and staff hierarchy | Input `.sarv` file path | Terminal stdout or JSON |
| [`profiles`](#4-profiles-short-p) | **`p`** | List and filter all available built-in staff profiles and presets | Category filter (optional) | Formatted table or JSON |

> [!NOTE]
> Arbitrary synonym aliases (`new`, `create`, `build`, `info`, `presets`, `list-profiles`) and multi-character abbreviations (`gen`, `cmp`, `ins`, `prof`) are deliberately disallowed to prevent command redundancy and maintain strict predictability.

---

## Global Options

The following flags can be passed to the root `sarvmd` executable:

| Flag | Abbreviation | Description |
| :--- | :---: | :--- |
| `--help` | `-h` | Display help and usage information for root or any subcommand. |
| `--version` | | Print the current SarvMD CLI version. |
| `--verbose` | `-v` | Enable detailed debug logging output (powered by `package:logd`). |
| `--lang` | | Set interface language: `en` (English, default) or `fa` (Persian). |

---

## Commands & Usage Manual

### 1. `generate` (short: `g`)

Generate blank manuscript sheet music directly as vector PDF, SVG, or LaTeX source.

```bash
sarvmd generate [options]
# or using the shortcut:
sarvmd g [options]
```

#### Options:
* `-p, --profile <id>`: Built-in staff profile or ensemble preset ID. Defaults to `treble`. Run `sarvmd p` to see all available IDs.
* `-s, --size <paper>`: Paper size. Allowed values: `a3`, `a4`, `a5`, `b4`, `b5`, `letter`. Defaults to `a4`.
* `--orientation <mode>`: Page orientation. Allowed values: `portrait`, `landscape`. Defaults to `portrait`.
* `-f, --format <ext>`: Output format. Allowed values: `pdf` (default), `svg`, `tex`.
* `-o, --output <path>`: Destination file or folder path. Defaults to `output`.
* `--page-count <int>`: Total number of manuscript pages to generate. Defaults to `1`.
* `--title <text>`: Optional score title to engrave in the score header.
* `--composer <text>`: Optional composer or author name.
* `--use-pdflatex`: Compile PDF using an external `pdflatex` engine instead of native vector PDF emission.

---

### 2. `compile` (short: `c`)

Compile an existing `.sarv` project file created in the SarvMD UI or generated programmatically into publication-grade vector PDF, SVG, or LaTeX.

```bash
sarvmd compile <file.sarv> [options]
# or using the shortcut:
sarvmd c <file.sarv> [options]
```

#### Arguments:
* `<file.sarv>`: Path to the target `.sarv` JSON document (required).

#### Options:
* `-o, --output <path>`: Destination file or directory path. Defaults to the input file stem with the target format extension (e.g. `score.sarv` -> `score.pdf`).
* `-f, --format <ext>`: Target output format: `pdf` (default), `svg`, or `tex`.
* `--page-count <int>`: Override the page count stored inside the `.sarv` document.
* `--use-pdflatex`: Compile PDF via external `pdflatex` instead of the native vector emitter.

---

### 3. `inspect` (short: `i`)

Inspect and print the metadata, page geometry, Rastral metrics, and hierarchical staff tree of any `.sarv` manuscript file.

```bash
sarvmd inspect <file.sarv> [options]
# or using the shortcut:
sarvmd i <file.sarv> [options]
```

#### Arguments:
* `<file.sarv>`: Path to the `.sarv` manuscript file (required).

#### Options:
* `--json`: Output inspection details as structured JSON (ideal for shell scripts and automated validation).

#### Example Human-Readable Output:
```text
======================================================================
SarvMD Manuscript Inspection: sym9.sarv
======================================================================
Title:       Symphony No. 9
Subtitle:    Choral
Composer:    Ludwig van Beethoven
----------------------------------------------------------------------
Paper Setup:
  Size:        A4 (210.0 x 297.0 mm)
  Orientation: portrait
  Page Count:  2
  Margins:     Top 15.0mm, Bottom 15.0mm, Left 15.0mm, Right 15.0mm
----------------------------------------------------------------------
Layout & Engraving Metrics:
  Systems:     4 systems per page
  Staves:      4 staves per system
  System Gap:  14.0 mm
  Staff Gap:   8.0 mm
  Line Gap:    1.6 mm
----------------------------------------------------------------------
Staves in System:
  Staff 1: "Violin I" [Clef: Treble, Lines: 5, Scale: 1.0]
  Staff 2: "Violin II" [Clef: Treble, Lines: 5, Scale: 1.0]
  Staff 3: "Viola" [Clef: Alto, Lines: 5, Scale: 1.0]
  Staff 4: "Violoncello" [Clef: Bass, Lines: 5, Scale: 1.0]
======================================================================
```

---

### 4. `profiles` (short: `p`)

List, filter, and inspect built-in staff profiles and ensemble presets.

```bash
sarvmd profiles [options]
# or using the shortcut:
sarvmd p [options]
```

#### Options:
* `-c, --category <filter>`: Filter profiles by category (e.g., `solo`, `ensemble`, `keyboard`, `chamber`, `orchestral`).
* `--json`: Emit the profile list as a structured JSON array.

#### Example Output:
```text
SarvMD Built-in Staff Profiles:
--------------------------------------------------------------------------------
ID                   Category   Staves Description                             
--------------------------------------------------------------------------------
treble               Solo            1 Single treble staff (standard 5-line)   
bass                 Solo            1 Single bass staff                       
alto                 Solo            1 Single alto staff                       
tenor                Solo            1 Single tenor staff                      
piano                Keyboard        2 Grand staff with brace (Treble & Bass)  
organ                Keyboard        3 Three-stave organ (Manuals & Pedal)     
stringQuartet        Ensemble        4 String quartet (Vln I, Vln II, Vla, Vc) 
brassQuintet         Ensemble        5 Brass quintet                           
windQuintet          Ensemble        5 Woodwind quintet                        
choirSatb            Ensemble        4 SATB choral score with bracket          
guitarTab            Solo            2 Classical Guitar standard notation + TAB
percussionStandard   Percussion      1 Percussion line with neutral clef       
chamberOrchestra     Ensemble       10 Chamber orchestra with nested brackets  
--------------------------------------------------------------------------------
Total: 15 profile(s) available.
```

---

## Practical How-To Recipes

### Recipe 1: Generate Standard Blank Piano Manuscript

Generate an A4 portrait 3-page manuscript for piano with a score header:

```bash
sarvmd g \
  -p piano \
  -s a4 \
  --page-count 3 \
  --title "Piano Sonata No. 1" \
  --composer "F. Chopin" \
  -o sonata.pdf
```

### Recipe 2: Generate Vector SVG for Graphic Design or Printing

Generate a landscape vector SVG of a string quartet to import into Adobe Illustrator, Inkscape, or web pages:

```bash
sarvmd g \
  -p stringQuartet \
  -s letter \
  --orientation landscape \
  -f svg \
  -o quartet_spread.svg
```

### Recipe 3: Compile `.sarv` Project Files Headlessly in CI/CD

Compile all `.sarv` manuscript files in a project repository into vector PDFs during GitHub Actions or GitLab CI builds:

```bash
#!/usr/bin/env bash
set -e

# Compile all manuscript project files to PDF
for file in scores/*.sarv; do
  echo "Compiling $file..."
  sarvmd c "$file" -f pdf
done
```

### Recipe 4: Automated JSON Inspection with `jq`

Verify that all scores adhere to minimum system spacing rules in an automated test:

```bash
# Extract system gap in millimeters
SYSTEM_GAP=$(sarvmd i score.sarv --json | jq '.layout.systemGapMm')

echo "Score system gap: ${SYSTEM_GAP}mm"
```

### Recipe 5: LaTeX Source Generation and `pdflatex` Fallback

If preparing manuscripts for inclusion in academic TeX papers or thesis documents:

```bash
# Generate standalone .tex file
sarvmd g -p choirSatb -f tex -o choir.tex

# Or compile PDF via local pdflatex installation
sarvmd g -p choirSatb --use-pdflatex -o choir_latex.pdf
```

---

## Architecture & Design Principles

The `sarvmd_cli` application is built following official Dart CLI architecture standards (`dart-build-cli-app`):

1. **`SarvCommandRunner` ([`lib/src/runner.dart`](file:///home/ono/Projects/sarvmd/apps/sarvmd_cli/lib/src/runner.dart))**:
   - Central command dispatcher inheriting from `package:args/command_runner.dart`.
   - Handles global version flags, structured usage help, and log formatting.
   - Preserves backward compatibility for legacy shorthand arguments.
2. **Command Hierarchy ([`lib/src/commands/`](file:///home/ono/Projects/sarvmd/apps/sarvmd_cli/lib/src/commands/))**:
   - Each command encapsulates its options parser, validation, and execution logic.
   - Clean separation between file I/O, error reporting, and core engine invocation.
3. **Structured Logging ([`package:logd`](file:///home/ono/Projects/sarvmd/packages/sarvmd_core/pubspec.yaml))**:
   - High-performance, leveled console logging with quiet default outputs and fine-grained `--verbose` tracing.

---

## Testing & Quality Assurance

The CLI is covered by a test suite under [`apps/sarvmd_cli/test/`](file:///home/ono/Projects/sarvmd/apps/sarvmd_cli/test):

```bash
# Run all CLI automated tests
dart test
```

Test coverage includes:
* **Command Routing**: Verifying all commands execute via long and short names (`g`, `c`, `i`, `p`).
* **Non-Redundancy Assertions**: Verifying arbitrary synonym aliases are rejected with `exitCode == 64`.
* **Direct Vector Output Verification**: Validating that generated PDFs and SVGs contain authentic vector data without running external TeX binaries.
* **Error Handling**: Verifying error exit codes on missing files, malformed arguments, and unknown profiles.

---

## License

Licensed under the **Business Source License 1.1 (BUSL-1.1)**. See the root [LICENSE](file:///home/ono/Projects/sarvmd/LICENSE) file for complete licensing terms.
