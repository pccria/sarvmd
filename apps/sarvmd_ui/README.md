# SarvMD UI (`sarvmd_ui`)

The official cross-platform graphical editor and workspace for the SarvMD blank canvas music manuscript generator.

Built with Flutter by **Pooria Askari Moqaddam** for desktop (Linux, Windows, macOS), web, and mobile (Android, iOS).

---

## Table of Contents
- [Overview](#overview)
- [Quickstart & Development](#quickstart--development)
  - [Prerequisites](#prerequisites)
  - [Running Locally](#running-locally)
  - [Building for Production](#building-for-production)
- [Architectural Framework](#architectural-framework)
  - [Three-Tier State Management](#three-tier-state-management)
  - [Adaptive Form Factor System](#adaptive-form-factor-system)
- [Feature Tour & User Manual](#feature-tour--user-manual)
  - [1. Zen Top Bar & Navigation](#1-zen-top-bar--navigation)
  - [2. Multi-Document Tabbed Workspace](#2-multi-document-tabbed-workspace)
  - [3. Interactive Live Canvas](#3-interactive-live-canvas)
  - [4. Hierarchical Staff & Ensemble Builder](#4-hierarchical-staff--ensemble-builder)
  - [5. Profile Presets Gallery](#5-profile-presets-gallery)
  - [6. Export Engine & Format Options](#6-export-engine--format-options)
  - [7. Keyboard Shortcuts Cheat Sheet](#7-keyboard-shortcuts-cheat-sheet)
- [Localization (i18n) & Bidi Support](#localization-i18n--bidi-support)
- [Testing & Quality Assurance](#testing--quality-assurance)
- [License](#license)

---

## Overview

`sarvmd_ui` bridges traditional engraving craftsmanship with modern digital design ergonomics. Unlike rigid scorewriters (Finale, Sibelius, MuseScore) that force note entry, `sarvmd_ui` is dedicated to crafting **blank music manuscript layouts** with mathematical precision, flexible Rastral sizing, and Gouldian hierarchical labeling.

### Key Highlights
* **Vector-Accurate Live Preview**: Direct custom-painted canvas rendering mirroring the final print output down to the sub-millimeter.
* **CAD-Style Drafting Tools**: Live millimeter HUD bubbles, decoupled margin scrubbing, and interactive mouse-wing crosshairs.
* **Hierarchical Labeling**: Full support for MOLA and Gould two-tier instrument and group labeling (Models A, B, and C).
* **Multi-Tabbed Persistence**: Save and reload `.sarv` JSON documents with transactional undo/redo and tab deduplication.
* **Fluid Responsiveness**: Adapts smoothly from ultra-wide multi-monitor desktop setups down to phone touchscreens and tablets.

---

## Quickstart & Development

### Prerequisites
* **Flutter SDK**: `>= 3.24.0` (Dart SDK `>= 3.5.0`)
* **Platform Dependencies**:
  * **Linux**: `libgtk-3-dev`, `ninja-build`, `pkg-config`
  * **Web**: Chrome or any modern HTML5/CanvasKit browser
  * **Android**: Android SDK Platform 34+

### Running Locally

```bash
# Navigate to the UI application package
cd apps/sarvmd_ui

# Fetch packages
flutter pub get

# Run on Linux Desktop (Default Development Target)
flutter run -d linux

# Run on Flutter Web (CanvasKit)
flutter run -d chrome

# Run in Release Mode
flutter run -d linux --release
```

### Building for Production

```bash
# Build Linux Desktop bundle
flutter build linux --release

# Build Web distribution
flutter build web --release --wasm

# Build Android APK
flutter build apk --release
```

---

## Architectural Framework

### Three-Tier State Management

The UI architecture cleanly decouples document geometry, session tabs, and viewport presentation using the BLoC / Cubit pattern:

```text
┌─────────────────────────────────────────────────────────────┐
│                       WorkspaceCubit                        │
│   Manages active tabs, open documents, and session state    │
└──────────────────────────────┬──────────────────────────────┘
                               │
               ┌───────────────┴───────────────┐
               ▼                               ▼
     ┌───────────────────┐           ┌───────────────────┐
     │   DocumentCubit   │           │     ViewCubit     │
     │ Document geometry │           │ Zoom, pan, HUD,   │
     │ Undo/redo stack   │           │ Theme, input mode │
     │ Margins & staves  │           │ Accent seed color │
     └───────────────────┘           └───────────────────┘
```

1. **`WorkspaceCubit` ([`lib/src/application/workspace/workspace_cubit.dart`](file:///home/ono/Projects/sarvmd/apps/sarvmd_ui/lib/src/application/workspace/workspace_cubit.dart))**: Manages concurrent document sessions ([`DocumentSession`](file:///home/ono/Projects/sarvmd/apps/sarvmd_ui/lib/src/application/workspace/document_session.dart)), tab switching, and recent files persistence.
2. **`DocumentCubit` ([`lib/src/application/document_cubit.dart`](file:///home/ono/Projects/sarvmd/apps/sarvmd_ui/lib/src/application/document_cubit.dart))**: Handles transactional mutations to the active [`SarvDocument`](file:///home/ono/Projects/sarvmd/packages/sarvmd_core/lib/src/domain/document.dart), integrating [`CommandHistory`](file:///home/ono/Projects/sarvmd/packages/sarvmd_core/lib/src/command/command_history.dart) for seamless undo (`Ctrl+Z`) and redo (`Ctrl+Shift+Z`).
3. **`ViewCubit` ([`lib/src/application/view_cubit.dart`](file:///home/ono/Projects/sarvmd/apps/sarvmd_ui/lib/src/application/view_cubit.dart))**: Manages non-destructive viewport state: zoom level, panning offsets, CAD guide visibility, theme brightness (dark/light/system), and accent seed colors.

### Adaptive Form Factor System

[`SarvDisplayContext`](file:///home/ono/Projects/sarvmd/apps/sarvmd_ui/lib/src/core/responsive/sarv_display_context.dart) classifies the active viewport independently of physical device hardware:
* **`phone` (< 600 dp)**: Single-column layout with compact bottom navigation and modal bottom sheets.
* **`tablet` (600 - 1024 dp)**: Split layout with collapsible drawer panels and adaptive dialogs.
* **`desktop` (>= 1024 dp)**: Full three-pane editing studio with persistent sidebars, draggable splitters, and top menu bar.

---

## Feature Tour & User Manual

### 1. Zen Top Bar & Navigation
* **Zen Mode (`F11` or View Menu)**: Collapses all sidebars, status bars, and inspection panels to maximize canvas space for composition drafting.
* **Inline Score Header (`EditableScoreHeader`)**: Double-tap on the score title or composer in the top bar to edit metadata inline with real-time canvas reflection.
* **Adaptive Menu Compaction**: For narrower screens (< 760 px), top-level menus collapse automatically into a cascading compact dropdown menu ([`TopBarCompactAppMenu`](file:///home/ono/Projects/sarvmd/apps/sarvmd_ui/lib/src/presentation/widgets/navigation/top_bar_compact_app_menu.dart)).

### 2. Multi-Document Tabbed Workspace
* **Pointer Tab Bar (`PointerTabBar`)**: Desktop tab strip with drag-to-reorder, dirty status indicators (`●`), and unsaved changes confirmation guards.
* **Touch Tab Switcher (`TouchTabSwitcherModal`)**: Compact gesture-driven card strip designed for mobile and touch screens.
* **Empty Workspace Welcome Hub (`EmptyWorkspaceView`)**: Sleek launch pad when all documents are closed, offering 1-tap starter presets, template selection, and drag-and-drop file imports.

### 3. Interactive Live Canvas
* **Bézier Music Glyphs**: Treble curls, Bass spirals, Alto/Tenor bridges, and SMuFL TAB clefs rendered directly on the Flutter canvas with sub-pixel anti-aliasing.
* **Dynamic Millimeter HUD**: Scrubbing margins or staff spacing displays live millimeter floating chips.
* **CAD Guides**: Toggleable horizontal/vertical margin rules and printable boundary indicators.

### 4. Hierarchical Staff & Ensemble Builder
Located under the **System Hierarchy** panel ([`SystemHierarchyPanel`](file:///home/ono/Projects/sarvmd/apps/sarvmd_ui/lib/src/presentation/widgets/panels/hierarchy/system_hierarchy_panel.dart)):
* **Progressive Disclosure (Paradigm A)**: Quick inline styling for instrument labels (~80px card) with deep engraving options delegated to a modal dialog ([`GroupEngravingDialog`](file:///home/ono/Projects/sarvmd/apps/sarvmd_ui/lib/src/presentation/widgets/panels/hierarchy/group_engraving_dialog.dart)).
* **Drag-and-Drop Reordering**: Spatial drop zones allow reordering staves, nesting into sub-brackets, or un-grouping with cycle-prevention logic.
* **Three Labeling Models**:
  * **Model A (Centered)**: Single centered group header across the whole bracket.
  * **Model B (Instrument Numbering)**: Shared group descriptor with auto-incrementing Roman or Arabic numerals (e.g. "Horn in F I, II").
  * **Model C (Section Header)**: Gouldian header printed directly above the upper staff line, eliminating horizontal indentation.

### 5. Profile Presets Gallery
Explore 15 standard built-in scoring profiles via the preset picker:
* **Interactive Category Slider**: Filter by `Solo`, `Keyboard`, `Chamber`, `Orchestral`, and `Percussion`.
* **Mini-Staff Previews**: Live vector-rendered miniature staves representing the exact bracket and staff configuration before selection.

### 6. Export Engine & Format Options
Export your manuscript via **File > Export (`Ctrl+E`)**:
* **Vector PDF**: High-resolution print-ready document generated natively via [`ScoreCompiler.compileToPdf`](file:///home/ono/Projects/sarvmd/packages/sarvmd_core/lib/src/compiler/score_compiler.dart).
* **Vector SVG**: Scalable vector graphics with optional layered XML grouping (`SvgLayeringMode.byStaff` or `.unified`).
* **LaTeX Source (`.tex`)**: Clean TeX source for academic musicology publications.

### 7. Keyboard Shortcuts Cheat Sheet
Press **`F1`** or **`Ctrl+?`** anywhere in the application to open the interactive shortcuts modal:

| Category | Shortcut | Action |
| :--- | :---: | :--- |
| **File & Workspace** | `Ctrl+N` | New Document from default template |
| | `Ctrl+O` | Open `.sarv` file from disk |
| | `Ctrl+S` | Save current document |
| | `Ctrl+Shift+S` | Save As new file |
| | `Ctrl+W` | Close active tab |
| | `Ctrl+E` | Export manuscript (PDF, SVG, TeX) |
| **Edit & History** | `Ctrl+Z` | Undo last change |
| | `Ctrl+Shift+Z` / `Ctrl+Y` | Redo change |
| **View & Canvas** | `Ctrl++` / `Ctrl+=` | Zoom In |
| | `Ctrl+-` | Zoom Out |
| | `Ctrl+0` | Reset Zoom to 100% |
| | `F11` | Toggle Zen Mode |
| **Help & Overlays** | `F1` / `Ctrl+?` | Open Keyboard Shortcuts Cheat Sheet |

---

## Localization (i18n) & Bidi Support

`sarvmd_ui` features complete bidirectional layout support:
* **English (LTR)** and **Persian / فارسی (RTL)** with cultural typographic adaptation.
* Numbers, file paths, and keycaps remain strictly isolated in LTR directionality within Persian contexts.
* Fully localized using Flutter's `intl` and `flutter_localizations` system (`apps/sarvmd_ui/lib/l10n/`).

---

## Testing & Quality Assurance

The UI package maintains an automated test suite across unit, widget, and golden tests:

```bash
# Run all UI tests
flutter test apps/sarvmd_ui
```

Test coverage highlights:
* **`advanced_builder_panel_test.dart`**: Validates labeling status indicators, quick typography bars, and drag-and-drop operations.
* **`file_ui_components_test.dart`**: Tests dirty status dots, tab dismissal guards, and file open workflows.
* **`keyboard_shortcuts_dialog_test.dart`**: Verifies interactive filtering and keyboard shortcut triggers.
* **`touch_back_navigation_test.dart`**: Validates mobile back-button unwinding and drawer ergonomics.

---

## License

Licensed under the **Business Source License 1.1 (BUSL-1.1)**. See the root [LICENSE](file:///home/ono/Projects/sarvmd/LICENSE) file for complete details.
