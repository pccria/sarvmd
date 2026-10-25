# Sarv Manuscript Designer
<picture>
  <source media="(prefers-color-scheme: dark)" srcset="apps/sarvmd_ui/assets/handwriting/sarv_banner_dark.png">
  <img alt="SarvMD" src="apps/sarvmd_ui/assets/handwriting/sarv_banner_light.png">
</picture>

<p align="center">
  <b>English</b> | <a href="README.fa.md"><b>فارسی</b></a>
</p>

<p align="center">
  <a href="https://pooriaaskarim.github.io/sarvmd/?lang=en">
    <img src="https://img.shields.io/badge/Try%20SarvMD-Live%20Web%20App-6C5CE7?style=for-the-badge&logo=flutter" alt="Try SarvMD Live Web App">
  </a>
</p>

## What is SarvMD?
SarvMD is a music manuscript generator designed to provide a flexible environment for composers, educators, and musicians to create customizable manuscript papers. SarvMD offers control over various dimensions of the workspace, ensuring clean and legible outputs.

## Intentions
The motivation for SarvMD is to bridge the gap between static manuscript templates and the struggle of using complicated software to create manuscript layouts.
SarvMD was designed to boost the creative and diverse workflow of musicians. It provides a flexible interface that stays out of your way, while offering granular control over every aspect of the layout.

## Documentation & Manuals

Comprehensive user and developer documentation is available for each component:

* 📖 **[CLI User Manual & How-To Guide](apps/sarvmd_cli/README.md)**: Command-line reference, single-character shortcuts (`g`, `c`, `i`, `p`), batch rendering, and CI/CD automation recipes.
* 🛠️ **[Core Engine API Reference](packages/sarvmd_core/README.md)**: Developer guide for embedding `sarvmd_core`, constructing `SystemLayout` trees, and compiling vector PDF/SVG documents.
* 🖥️ **[UI Application Manual & Development Guide](apps/sarvmd_ui/README.md)**: User guide covering canvas drafting, Rastral sizing, hierarchical labeling, and desktop/web builds.
* 🎵 **[Musical Engraving Terminology Guide](TERMINOLOGY.md)**: Comprehensive glossary of Gouldian engraving concepts, barlines, Rastral sizes, and brackets.
* 📜 **[Contributing Guidelines](CONTRIBUTING.md)**: Code contribution standards and Developer Certificate of Origin (DCO) setup.

## How It Works
SarvMD operates through a clean, layered pipeline to ensure reliable rendering and positioning:

1. **Config & Hierarchical Tree**: The user or code defines the manuscript geometry (`PageConfig`), paper size, Rastral line spacing, and composite staff tree (`SystemLayout`).
2. **Layout Engine**: A zero-dependency geometric calculator (`SystemLayoutCalculator`) computes millimeter coordinates, dynamic label indentation, and bracket clearances based on Gouldian engraving principles.
3. **Emitter & Compiler**:
   - **Native Vector PDF & SVG**: Emits resolution-independent vector PDF and SVG graphics directly in memory via `ScoreCompiler` without requiring any external tools.
   - **LaTeX Source**: Emits standalone `.tex` files with `\pdfliteral` and `picture` environments with optional `pdflatex` compilation.
   - **Interactive UI Canvas**: Renders Bézier paths and SMuFL glyphs natively on the Flutter canvas with sub-millimeter precision.

## Technical Brief

SarvMD is architected as a modular Dart Workspace (monorepo). This structure maintains a single source of truth for the core logic across all interfaces.

### Workspace Structure
- **[`packages/sarvmd_core`](packages/sarvmd_core/README.md)**: The foundational engine. It contains the configuration models, layout calculations, symbol path data, vector PDF/SVG emitters, and `.sarv` document serialization. Operates independently of any UI framework.
- **[`apps/sarvmd_ui`](apps/sarvmd_ui/README.md)**: A Flutter-based cross-platform studio optimized for Linux desktop, Web, Windows, and Android:
  - **State Management**: A decoupled Cubit architecture (`WorkspaceCubit` for multi-tab sessions, `DocumentCubit` with undo/redo history, and `ViewCubit` for viewport controls).
  - **Premium UI**: Dynamic accent theming, CAD alignment crosshairs, millimeter HUD chips, and two-tier progressive disclosure panels.
- **[`apps/sarvmd_cli`](apps/sarvmd_cli/README.md)**: A scriptable, headless command-line interface with single-character shortcuts (`g`, `c`, `i`, `p`) for batch score generation and CI/CD pipelines.

### Design Philosophy
- **Desktop-First**: The UI is optimized for desktop environments to support detailed layout adjustments, fluid keyboard-and-mouse navigation, and seamless system-level export handling.
- **Zero-Dependency Core**: The core layout engine relies entirely on pure Dart, minimizing external dependencies to ensure long-term stability and performance.

## License & Contributing

### License
SarvMD is licensed under the **Business Source License 1.1 (BUSL-1.1)**. 
*   **Non-Commercial Use**: Free to copy, modify, and run the code for personal, educational, or testing purposes.
*   **Commercial Use**: Commercial production use, including hosting a commercial service, embedding the layout engine in proprietary software, or selling compiled versions of the applications, is prohibited unless authorized by the copyright owner (**Pooria Askari Moqaddam**).
*   **Open-Source Transition**: On **June, 2031**, this license automatically transitions to the standard, highly permissive **Apache License 2.0**.

For the full legal terms, please read the [LICENSE](LICENSE) file.

### Contributing
We welcome contributions! To keep our codebase legally clean and secure, we require all contributors to sign off on their commits using the **Developer Certificate of Origin (DCO)**. 

Please read our [Contributing Guidelines](CONTRIBUTING.md) for step-by-step instructions on how to sign off on your commits (`git commit -s`).
