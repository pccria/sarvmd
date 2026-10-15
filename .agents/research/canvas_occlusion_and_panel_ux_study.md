# UX Architecture Decision: Preserving the Side Panel & Overcoming Canvas Occlusion

**Author:** Antigravity (Google DeepMind Advanced Agentic Coding)  
**Date:** October 2026  
**Status:** Implemented, Tested & Verified (Browser Subagent & Automated Test Suite)  
**Target:** `sarvmd_ui` — `PointerEditorScreen`, `TouchEditorScreen`, `SettingsPanel`, `CanvasZoomCalculator`, `PreviewCanvas`  
**Core Architectural Constraint:** Preserved the existing side panel & drawer design language across Touch and Pointer modes. Bottom sheets discarded in favor of 4-pillar canvas-visible side-panel enhancements.

---

## 1. Problem Statement & Constraints

When adjusting engraving parameters (margins, line gaps, system spacing, clefs, or instrument hierarchy) in `SettingsPanel` (Touch Mode) or `PointerEditorScreen` sidebar (Pointer Mode), the side panel partially or fully occludes the canvas.

### Design Directive
- **Do NOT replace the side panel with a bottom sheet.** The existing side-drawer / sidebar structure is part of SarvMD's core visual identity and works smoothly across viewports.
- **The goal:** Solve the occlusion dilemma *within* the side-panel paradigm, giving the user uninterrupted visual feedback of the score while interacting with controls.

---

## 2. The 4-Pillar Non-Destructive Solution

```
┌─────────────────────────────────────────────────────────────────────────────┐
│               THE 4-PILLAR SIDE-PANEL ENHANCEMENT ARCHITECTURE              │
│                                                                             │
│  1. Scrub-Ghosting: Panel fades to 15% opacity during slider drags          │
│  2. Scrim Purge: Canvas stays 100% bright white & interactively live         │
│  3. Camera Shift: Canvas centers in the visible space right of the panel    │
│  4. Peek Canvas: 1-tap temporary panel collapse/restore without state loss  │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Pillar 1: "Scrub-Ghosting" (See-Through Sliders)
- **The Experience:** When the user touches or drags any slider or scrubber (e.g. Line Gap, System Gap, Margins, or PrecisionSlider):
  1. The entire side panel smoothly transitions to **15% opacity** (or frosted translucent glass).
  2. The score directly behind the panel becomes **100% visible in real time**.
  3. The active slider knob and a sleek floating **Value Pill** (e.g. `Line Gap: 1.75 mm`) remain completely opaque directly under the user's finger or cursor.
  4. On release (`onPanEnd` / `onScrubEnd`), the panel fades back to crisp, solid opacity in 150ms.
- **Why it works:** The user only needs to see the score *while actively dragging*. This allows the panel to remain comfortably wide without blocking the user's view of the result.

### Pillar 2: Purging the Modal Black Scrim & Non-Blocking Canvas
- **The Experience:**
  1. Remove `Colors.black.withValues(alpha: 0.35)` from `PointerEditorScreen` overlay mode and `TouchEditorScreen` landscape side-sheet.
  2. The canvas stays at **true 100% paper-white luminance** at all times.
  3. Make the canvas **interactively live** while the panel is open: the user can pan or pinch-zoom the canvas with their other hand without closing the panel.
  4. Tapping the canvas does NOT dismiss the panel (dismissal is explicit via a close button or edge swipe).

### Pillar 3: "Smart Camera Inset" (Viewport-Aware Score Centering)
- **The Experience:**
  - Currently, the canvas calculates zoom and centering against the whole screen width (`x = screenWidth / 2`). With a 320px left panel, the left half of the score is placed directly behind the panel.
  - **With Camera Insetting:** When the panel is open, the canvas calculates its center within the **unobstructed area** (from the right edge of the panel to the right edge of the screen).
  - In landscape, tablet, and desktop mode, the score automatically glides to the right and is **100% clear of the panel**.

### Pillar 4: Non-Obstructing Header Glance Pill & 0ms Spring-Loaded Response
- **The Experience:**
  - A prominent **`[ 👁️ Glance ]` / `[ 👁️ Peek Canvas ]` Pill** placed in the top header row across the main menu and **all sub-pages** (Margins, Staff Spacing, Page Setup, Profiles, Hierarchy, Export).
  - **Zero Obstruction:** Moved completely off the right edge seam into the header row, eliminating all overlap with margin inputs, sliders, and list items.
  - **0ms Pointer-Down Glance:** Touching or clicking down immediately triggers peek mode without the 500ms long-press delay.
  - **Spring-Loaded Release:** Holding down peeks the canvas for the duration of the touch; releasing immediately snaps the panel back.
  - **Quick Tap:** Tapping briefly (< 180ms) toggles peek mode.
  - **Snappy 120ms Motion:** Cut slide and camera centering durations from 250ms to 120ms for instant, fluid glance perception.
  - **Zero-Latency Restore:** Tapping anywhere on the 56px edge rail triggers immediate restore on pointer-down with 0ms delay.

---

## 3. Concrete Implementation Plan

| Step | Component | Changes | Status |
| :--- | :--- | :--- | :--- |
| **Step 1** | `ViewCubit` & `ViewState` | Added `isScrubbing`, `isPanelPeeking`, telemetry tracking, and camera glides. | ✅ Verified |
| **Step 2** | `SettingsPanel` & `PointerEditorScreen` | 100% transparent panel backgrounds during scrubbing with 0.18 ghosted controls. | ✅ Verified |
| **Step 3** | `MarginsSettingsGroup` & `PrecisionSlider` | Drag capsules trigger live scrubbing and margin boundary guides. | ✅ Verified |
| **Step 4** | `PointerEditorScreen` & `TouchEditorScreen` | Removed scrim overlays. Canvas remains live and paper-white. | ✅ Verified |
| **Step 5** | `CanvasZoomCalculator` | Viewport aperture camera centering with `leftInset` / `rightInset`. | ✅ Verified |
| **Step 6** | `SettingsPanel` & `PointerEditorScreen` | Header Glance Pill with 0ms pointer-down, spring-loaded release, 120ms animation, and zero content obstruction. | ✅ Verified |
| **Step 7** | `CanvasZoomCalculator`, `SettingsPanel` & `PointerEditorScreen` | Smart Geometric Occlusion Detection: dynamically detects if the panel physically occludes the rendered paper or active margin guideline. Keeps panel 100% solid and crisp when docked or clear of the score; only transparentizes when the panel is actually covering the score. | ✅ Verified |

