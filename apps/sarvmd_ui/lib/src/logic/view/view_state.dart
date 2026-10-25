// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Licensed under the Business Source License 1.1 (BUSL-1.1).

import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// The interaction mode determining whether the UI optimizes for mouse/pointer or direct touch.
enum InputMode {
  pointer,
  touch,
}

/// The active guide overlay lines shown on the sheet music manuscript canvas.
enum GuideType {
  paperEdges,
  paperCenters,
  margins,
  staffBounds,
  rulerWings,
}

/// The canonical settings sections across Pointer and Touch modes.
enum SettingsSection {
  mainMenu,
  profiles,
  pageSetup,
  scoreTypography,
  margins,
  staffSpacing,
  systemHierarchy,
  export,
}

/// Defines how pages of the music manuscript are arranged in the 2D workspace.
enum PageArrangementMode {
  /// Focused single sheet centered on canvas.
  single,

  /// Two-page book spread: Page 1 on the right (recto), then [2 | 3], [4 | 5].
  facingSpread,

  /// Continuous vertical ribbon: pages stacked top-to-bottom.
  continuousVertical,

  /// Continuous horizontal ribbon: pages lined up left-to-right.
  continuousHorizontal,

  /// Multi-page matrix / contact sheet overview.
  grid,
}

/// The immutable state container for user interface display preferences.
class ViewState {
  final ThemeMode themeMode;
  final SarvAccent accent;
  final double calibrationFactor;
  final Set<GuideType> activeGuides;
  final String? activeScrubbingMargin;
  final bool isScrubbing;
  final String? activeScrubbingTelemetry;
  final bool isPanelPeeking;
  final InputMode inputMode;
  final SettingsSection activeTouchSection;
  final Set<SettingsSection> expandedPointerSections;
  final Set<int> collapsedHierarchyGroups;
  final Set<String> selectedHierarchyStaffUids;
  final SettingsSection? jumpTargetSection;
  final int currentPageIndex;
  final PageArrangementMode pageArrangement;
  final int gridColumns;
  final bool autoFocusOnPageChange;
  final bool pageSwipeGestures;

  const ViewState({
    this.themeMode = ThemeMode.system,
    this.accent = SarvAccent.sky,
    this.calibrationFactor = 1.0,
    this.activeGuides = const {GuideType.paperEdges, GuideType.rulerWings},
    this.activeScrubbingMargin,
    this.isScrubbing = false,
    this.activeScrubbingTelemetry,
    this.isPanelPeeking = false,
    this.inputMode = InputMode.pointer,
    this.activeTouchSection = SettingsSection.mainMenu,
    this.expandedPointerSections = const {
      SettingsSection.profiles,
      SettingsSection.pageSetup,
      SettingsSection.scoreTypography,
      SettingsSection.margins,
      SettingsSection.staffSpacing,
      SettingsSection.systemHierarchy,
    },
    this.collapsedHierarchyGroups = const {},
    this.selectedHierarchyStaffUids = const {},
    this.jumpTargetSection,
    this.currentPageIndex = 0,
    this.pageArrangement = PageArrangementMode.single,
    this.gridColumns = 2,
    this.autoFocusOnPageChange = true,
    this.pageSwipeGestures = true,
  });

  ViewState copyWith({
    ThemeMode? themeMode,
    SarvAccent? accent,
    double? calibrationFactor,
    Set<GuideType>? activeGuides,
    String? activeScrubbingMargin,
    bool clearScrubbingMargin = false,
    bool? isScrubbing,
    String? activeScrubbingTelemetry,
    bool clearScrubbingTelemetry = false,
    bool? isPanelPeeking,
    InputMode? inputMode,
    SettingsSection? activeTouchSection,
    Set<SettingsSection>? expandedPointerSections,
    Set<int>? collapsedHierarchyGroups,
    Set<String>? selectedHierarchyStaffUids,
    SettingsSection? jumpTargetSection,
    bool clearJumpTarget = false,
    int? currentPageIndex,
    PageArrangementMode? pageArrangement,
    int? gridColumns,
    bool? autoFocusOnPageChange,
    bool? pageSwipeGestures,
  }) {
    return ViewState(
      themeMode: themeMode ?? this.themeMode,
      accent: accent ?? this.accent,
      calibrationFactor: calibrationFactor ?? this.calibrationFactor,
      activeGuides: activeGuides ?? this.activeGuides,
      activeScrubbingMargin: clearScrubbingMargin
          ? null
          : (activeScrubbingMargin ?? this.activeScrubbingMargin),
      isScrubbing: isScrubbing ?? this.isScrubbing,
      activeScrubbingTelemetry: clearScrubbingTelemetry
          ? null
          : (activeScrubbingTelemetry ?? this.activeScrubbingTelemetry),
      isPanelPeeking: isPanelPeeking ?? this.isPanelPeeking,
      inputMode: inputMode ?? this.inputMode,
      activeTouchSection: activeTouchSection ?? this.activeTouchSection,
      expandedPointerSections:
          expandedPointerSections ?? this.expandedPointerSections,
      collapsedHierarchyGroups:
          collapsedHierarchyGroups ?? this.collapsedHierarchyGroups,
      selectedHierarchyStaffUids:
          selectedHierarchyStaffUids ?? this.selectedHierarchyStaffUids,
      jumpTargetSection: clearJumpTarget
          ? null
          : (jumpTargetSection ?? this.jumpTargetSection),
      currentPageIndex: currentPageIndex ?? this.currentPageIndex,
      pageArrangement: pageArrangement ?? this.pageArrangement,
      gridColumns: gridColumns ?? this.gridColumns,
      autoFocusOnPageChange:
          autoFocusOnPageChange ?? this.autoFocusOnPageChange,
      pageSwipeGestures: pageSwipeGestures ?? this.pageSwipeGestures,
    );
  }

  bool isGuideActive(GuideType guide) => activeGuides.contains(guide);
  bool isPointerSectionExpanded(SettingsSection section) =>
      expandedPointerSections.contains(section);
}
