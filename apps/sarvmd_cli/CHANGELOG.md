# Changelog - SarvMD CLI (`sarvmd_cli`)

All notable changes to the `sarvmd_cli` command-line interface tool will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [Unreleased]

### Added
- **Modernized `CommandRunner` Architecture (`lib/src/runner.dart`)**:
  - Refactored `sarvmd_cli` to use `package:args/command_runner.dart` following Dart CLI best practices (`dart-build-cli-app`).
  - Added global flags: `--help` (`-h`), `--version`, `--verbose` (`-v`), and `--lang` (`en`, `fa`).
- **Canonical Single-Character Command Shortcuts**:
  - Implemented strict 1:1 pairing between long-form commands and single-character shortcuts:
    - `generate` (`g`): Generate blank manuscript directly to vector PDF, SVG, or TeX.
    - `compile` (`c`): Compile an existing `.sarv` project file headlessly into final publication formats.
    - `inspect` (`i`): Print score metadata, paper setup, Rastral spacing, and staff tree with `--json` option.
    - `profiles` (`p`): List and filter built-in staff profiles and presets with category filters.
  - **Strict Non-Redundancy Policy**: Purged all arbitrary synonym aliases (`new`, `create`, `build`, `info`, `presets`, `list-profiles`) and multi-character abbreviations (`gen`, `cmp`, `ins`, `prof`).
- **Zero-Dependency Direct Vector PDF & SVG Generation**:
  - Replaced mandatory external `pdflatex` compilation with native vector PDF and SVG emission via `sarvmd_core`'s `ScoreCompiler`.
  - Maintained `--use-pdflatex` as an optional fallback flag.
- **Automated Test Suite (`test/`)**:
  - Added 29 automated tests verifying command execution, single-character shortcuts, non-redundancy rejection (exit code `64`), and file generation.
- **User Documentation & Manual (`apps/sarvmd_cli/README.md`)**:
  - Published comprehensive CLI manual with compilation instructions (`dart compile exe`), command references, and practical script recipes (CI/CD batch compilation, `jq` integration).

## [0.12.4] - 2026-10-22

### Added
- Initial proof-of-concept CLI supporting basic flags (`-l`, `--layout`, `-s`, `--size`, `-o`, `--output`) and external `pdflatex` compilation wrapper.
