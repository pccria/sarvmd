# SarvMD Workspace Instructions & Rules

## Release Versioning Procedure (Synchronized Monorepo Architecture)

### 1. Source-of-Truth Hierarchy
- **Dynamic Authority:** Top version section in individual package changelogs:
  - `apps/sarvmd_ui/CHANGELOG.md` (`## [X.Y.Z] - YYYY-MM-DD`)
  - `apps/sarvmd_cli/CHANGELOG.md` (`## [X.Y.Z] - YYYY-MM-DD`)
  - `packages/sarvmd_core/CHANGELOG.md` (`## [X.Y.Z] - YYYY-MM-DD`)
- **Static Baseline Constants:**
  - `AppVersion.version` in `apps/sarvmd_ui/lib/src/core/constants/app_version.dart`.
  - `SarvCommandRunner.currentVersion` in `apps/sarvmd_cli/lib/src/runner.dart`.
- **Package Manifests (Synchronized Lockstep):** `version: X.Y.Z` field in:
  - `packages/sarvmd_core/pubspec.yaml`
  - `apps/sarvmd_cli/pubspec.yaml`
  - `apps/sarvmd_ui/pubspec.yaml`

### 2. Release Procedure Checklist
When cutting a new application release:
1. **Promote Changelog Entries:** In each package's `CHANGELOG.md` (`core`, `cli`, `ui`), convert package-specific items under `## [Unreleased]` into a synchronized version header `## [X.Y.Z] - YYYY-MM-DD` and reset a fresh `## [Unreleased]` section above it.
2. **Update Version Constants:**
   - Update `static const String version = 'X.Y.Z';` in `apps/sarvmd_ui/lib/src/core/constants/app_version.dart`.
   - Update `static const String currentVersion = 'X.Y.Z';` in `apps/sarvmd_cli/lib/src/runner.dart`.
3. **Update Package Manifests:** Update `version: X.Y.Z` across all three `pubspec.yaml` manifests.
4. **Run Verification Tests:**
   - Execute `flutter test` in `apps/sarvmd_ui` to ensure `ChangelogService` parses `X.Y.Z` and all UI tests pass.
   - Execute `dart test` in `apps/sarvmd_cli` and `flutter test` in `packages/sarvmd_core`.
   - Run `dart analyze` across the repository.
5. **Git Tagging:** Commit changes (`git commit -s -m "release: bump version to vX.Y.Z"`) and tag (`git tag -a vX.Y.Z -m "Release vX.Y.Z"`).

### 3. Architectural Versioning Rules
- **Separate Package Changelogs**: Each package (`sarvmd_core`, `sarvmd_cli`, `sarvmd_ui`) must maintain its own dedicated `CHANGELOG.md` strictly capturing changes relevant to that package. Do not cross-pollinate UI changes into CLI or core changelogs.
- **No Hardcoded Versions in UI**: Widgets (`SarvSplashScreen`, `LaunchCoordinator`, `AboutSarvDialog`, etc.) must never introduce inline version string literals. They must consume `ChangelogService.getLatestVersion()` or fall back to `AppVersion.version`.
- **No Alias Constants**: Do not create duplicate version alias fields (e.g. `fallbackVersion`). Reference `AppVersion.version` directly.

## 4. Architectural & Engraving Knowledge Base
- **Hierarchical Labeling & Nesting Standards:** [knowledge/hierarchical_labeling_and_nesting_standards.md](knowledge/hierarchical_labeling_and_nesting_standards.md)
- **UI State Preservation & Panel Architecture:** [knowledge/ui_state_preservation_and_panel_architecture.md](knowledge/ui_state_preservation_and_panel_architecture.md)
- **Engraving Research & Calculations:** [research/group_and_staff_hierarchical_labeling_standards.md](research/group_and_staff_hierarchical_labeling_standards.md)
- **ADR-0001: Single-Staff Group Lifecycle & Preservation Policy:** [adr/0001-single-staff-group-lifecycle.md](adr/0001-single-staff-group-lifecycle.md)
