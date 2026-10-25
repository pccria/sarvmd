// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Licensed under the Business Source License 1.1 (BUSL-1.1).

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sarvmd_core/sarvmd_core.dart' as core;
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/staff/document_settings_group.dart';
import '../widgets/staff/margins_settings_group.dart';
import '../widgets/staff/score_typography_settings_group.dart';
import '../../core/theme/app_metrics.dart';
import '../../core/theme/layout_policy.dart';
import '../widgets/staff/staff_spacing_group.dart';
import '../widgets/layout/pointer_top_bar.dart';
import '../widgets/workspace/pointer_tab_bar.dart';

import '../widgets/common/shortcut_gateway.dart';
import '../../l10n/app_localizations.dart';
import '../widgets/staff/profile_picker.dart';
import '../widgets/canvas/canvas_zoom_calculator.dart';
import '../widgets/canvas/canvas_page_navigator.dart';
import '../widgets/canvas/score_arrangement_canvas.dart';
import '../widgets/panels/view_panel.dart';
import '../widgets/canvas/ruler_box.dart';
import '../widgets/common/integrated_scale_control.dart';
import '../widgets/panels/system_hierarchy_panel.dart';
import '../widgets/panels/collapsible_section_card.dart';
import '../widgets/panels/section_spine.dart';
import '../../logic/document/document_cubit.dart';
import '../../logic/document/document_state.dart';
import '../../logic/view/view_cubit.dart';
import '../../logic/view/view_state.dart';


class PointerEditorScreen extends StatefulWidget {
  const PointerEditorScreen({super.key});

  @override
  State<PointerEditorScreen> createState() => _PointerEditorScreenState();
}

class _PointerEditorScreenState extends State<PointerEditorScreen>
    with TickerProviderStateMixin {
  final TransformationController _transformationController =
      TransformationController();
  final ValueNotifier<Offset?> _cursorNotifier = ValueNotifier(null);
  final ScrollController _sidebarScrollController = ScrollController();
  final GlobalKey _profilesAnchorKey = GlobalKey();
  final GlobalKey _pageSetupAnchorKey = GlobalKey();
  final GlobalKey _scoreTypographyAnchorKey = GlobalKey();
  final GlobalKey _marginsAnchorKey = GlobalKey();
  final GlobalKey _staffSpacingAnchorKey = GlobalKey();
  final GlobalKey _hierarchyAnchorKey = GlobalKey();
  BoxConstraints? _lastConstraints;
  bool _hasCentered = false;
  ZoomPreset _currentPreset = ZoomPreset.fitScreen;
  late final AnimationController _cameraAnimationController;
  Animation<double>? _cameraCurveAnimation;
  Matrix4? _startMatrix;
  Matrix4? _targetMatrix;
  bool _isDraggingSidebar = false;
  bool _isDraggingViewPanel = false;
  bool _isHoveringSidebarHandle = false;
  bool _isHoveringViewPanelHandle = false;
  double _sidebarWidth = 320;
  double _viewPanelWidth = 280;
  bool _sidebarCollapsed = false;
  bool _viewPanelCollapsed = false;
  double? _lastScreenWidth;

  @override
  void initState() {
    super.initState();
    _cameraAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    )..addListener(() {
        if (_startMatrix == null || _targetMatrix == null) return;
        final t = _cameraCurveAnimation?.value ?? _cameraAnimationController.value;
        final lerped = Matrix4.zero();
        for (int i = 0; i < 16; i++) {
          lerped.storage[i] = _startMatrix!.storage[i] +
              (_targetMatrix!.storage[i] - _startMatrix!.storage[i]) * t;
        }
        _transformationController.value = lerped;
      });
    _cameraCurveAnimation = CurvedAnimation(
      parent: _cameraAnimationController,
      curve: Curves.easeOutCubic,
    );
    _loadLayoutPrefs();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final currentWidth = MediaQuery.sizeOf(context).width;
    if (_lastScreenWidth == null) {
      if (currentWidth < SarvBreakpoints.bothSidebarsDockedMinWidth) {
        _viewPanelCollapsed = true;
      }
      if (currentWidth < SarvBreakpoints.primarySidebarDockedMinWidth) {
        _sidebarCollapsed = true;
      }
    } else {
      if (_lastScreenWidth! >= SarvBreakpoints.bothSidebarsDockedMinWidth &&
          currentWidth < SarvBreakpoints.bothSidebarsDockedMinWidth) {
        _viewPanelCollapsed = true;
      }
      if (_lastScreenWidth! >= SarvBreakpoints.primarySidebarDockedMinWidth &&
          currentWidth < SarvBreakpoints.primarySidebarDockedMinWidth) {
        _sidebarCollapsed = true;
      }
    }
    _lastScreenWidth = currentWidth;
  }

  void _toggleLeftSidebar(bool canDockLeft, bool canDockRight) {
    setState(() {
      _sidebarCollapsed = !_sidebarCollapsed;
      if (!_sidebarCollapsed && !canDockLeft && !canDockRight) {
        _viewPanelCollapsed = true;
      }
    });
  }

  void _toggleViewPanel(bool canDockLeft, bool canDockRight) {
    setState(() {
      _viewPanelCollapsed = !_viewPanelCollapsed;
      if (!_viewPanelCollapsed && !canDockLeft && !canDockRight) {
        _sidebarCollapsed = true;
      }
    });
  }

  Future<void> _loadLayoutPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _sidebarWidth = prefs.getDouble('sidebar_width') ?? 320;
      _viewPanelWidth = prefs.getDouble('view_panel_width') ?? 280;
    });
  }

  Future<void> _saveLayoutPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('sidebar_width', _sidebarWidth);
    await prefs.setDouble('view_panel_width', _viewPanelWidth);
  }

  static const double minSidebarWidth = 280;
  static const double maxSidebarWidth = 500;
  static const double minViewPanelWidth = 240;
  static const double maxViewPanelWidth = 400;

  Widget _buildLeftResizeHandle(BuildContext context, {double? maxWidth}) {
    final isActive = _isDraggingSidebar || _isHoveringSidebarHandle;
    return MouseRegion(
      cursor: SystemMouseCursors.resizeLeftRight,
      onEnter: (_) => setState(() => _isHoveringSidebarHandle = true),
      onExit: (_) => setState(() => _isHoveringSidebarHandle = false),
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onPanStart: (_) => setState(() => _isDraggingSidebar = true),
        onPanEnd: (_) {
          setState(() => _isDraggingSidebar = false);
          _saveLayoutPrefs();
        },
        onPanUpdate: (details) {
          setState(() {
            final maxAllowed = maxWidth ?? maxSidebarWidth;
            final minAllowed = math.min(minSidebarWidth, maxAllowed);
            _sidebarWidth = (_sidebarWidth + details.delta.dx)
                .clamp(minAllowed, maxAllowed);
          });
        },
        child: Container(
          width: 12,
          color: isActive
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.08)
              : Colors.transparent,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Full-height subtle divider track line
              Container(
                width: 1,
                color: Theme.of(context)
                    .colorScheme
                    .outlineVariant
                    .withValues(alpha: isActive ? 0.8 : 0.4),
              ),
              // Centered grip indicator pill
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                width: isActive ? 4 : 2.5,
                height: isActive ? 64 : 44,
                decoration: BoxDecoration(
                  color: isActive
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.outline,
                  borderRadius: BorderRadius.circular(2),
                  boxShadow: isActive
                      ? [
                          BoxShadow(
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withValues(alpha: 0.35),
                            blurRadius: 4,
                            spreadRadius: 1,
                          ),
                        ]
                      : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRightResizeHandle(BuildContext context, {double? maxWidth}) {
    final isActive = _isDraggingViewPanel || _isHoveringViewPanelHandle;
    return MouseRegion(
      cursor: SystemMouseCursors.resizeLeftRight,
      onEnter: (_) => setState(() => _isHoveringViewPanelHandle = true),
      onExit: (_) => setState(() => _isHoveringViewPanelHandle = false),
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onPanStart: (_) => setState(() => _isDraggingViewPanel = true),
        onPanEnd: (_) {
          setState(() => _isDraggingViewPanel = false);
          _saveLayoutPrefs();
        },
        onPanUpdate: (details) {
          setState(() {
            final maxAllowed = maxWidth ?? maxViewPanelWidth;
            final minAllowed = math.min(minViewPanelWidth, maxAllowed);
            _viewPanelWidth = (_viewPanelWidth - details.delta.dx)
                .clamp(minAllowed, maxAllowed);
          });
        },
        child: Container(
          width: 12,
          color: isActive
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.08)
              : Colors.transparent,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Full-height subtle divider track line
              Container(
                width: 1,
                color: Theme.of(context)
                    .colorScheme
                    .outlineVariant
                    .withValues(alpha: isActive ? 0.8 : 0.4),
              ),
              // Centered grip indicator pill
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                width: isActive ? 4 : 2.5,
                height: isActive ? 64 : 44,
                decoration: BoxDecoration(
                  color: isActive
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.outline,
                  borderRadius: BorderRadius.circular(2),
                  boxShadow: isActive
                      ? [
                          BoxShadow(
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withValues(alpha: 0.35),
                            blurRadius: 4,
                            spreadRadius: 1,
                          ),
                        ]
                      : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLeftOverlay({
    required BuildContext context,
    required DocumentCubit documentCubit,
    required core.PageConfig configState,
    required TextDirection sidebarTextDir,
    required double screenWidth,
  }) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final viewState = context.watch<ViewCubit>().state;
    final isScrubbing = viewState.isScrubbing;
    final isPeeking = viewState.isPanelPeeking;

    final maxAllowed = screenWidth * 0.85;
    final minAllowed = math.min(minSidebarWidth, maxAllowed);
    final overlayWidth = _sidebarWidth.clamp(minAllowed, maxAllowed);
    final totalWidth = overlayWidth + 12;
    final peekSlideFraction = (totalWidth - 56.0) / totalWidth;

    final isCovering = CanvasZoomCalculator.isTargetOccluded(
      matrix: _transformationController.value,
      config: configState,
      panelWidth: totalWidth,
      panelLeft: 0.0,
      canvasLeft: 0.0,
      activeScrubbingMargin: viewState.activeScrubbingMargin,
    );
    final shouldTransparentize = isScrubbing && isCovering;

    return Positioned(
      top: 0,
      bottom: 0,
      left: 0,
      width: totalWidth,
      child: AnimatedSlide(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        offset: isPeeking ? Offset(-peekSlideFraction, 0) : Offset.zero,
        child: Material(
          elevation: (shouldTransparentize || isPeeking) ? 0.0 : 16.0,
          shadowColor:
              (shouldTransparentize || isPeeking) ? Colors.transparent : Colors.black54,
          color: shouldTransparentize
              ? Colors.transparent
              : cs.surfaceContainer,
          child: Stack(
            children: [
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border(
                      right: BorderSide(
                        color: shouldTransparentize
                            ? Colors.transparent
                            : cs.outlineVariant.withValues(alpha: 0.5),
                        width: 1,
                      ),
                    ),
                  ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildSidebarContent(
                            context: context,
                            documentCubit: documentCubit,
                            configState: configState,
                            sidebarTextDir: sidebarTextDir,
                            isOverlay: true,
                          ),
                        ),
                        if (!isPeeking)
                          _buildLeftResizeHandle(context, maxWidth: maxAllowed),
                      ],
                    ),
                  ),
                ),
                // Full-Height 56px Edge Restore Strip
                if (isPeeking)
                  Positioned(
                    top: 0,
                    bottom: 0,
                    right: 0,
                    width: 56.0,
                    child: Listener(
                      onPointerDown: (_) {
                        context.read<ViewCubit>().togglePanelPeeking(false);
                      },
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () =>
                            context.read<ViewCubit>().togglePanelPeeking(false),
                      onHorizontalDragUpdate: (details) {
                        if (details.primaryDelta != null && details.primaryDelta! > 6) {
                          context.read<ViewCubit>().togglePanelPeeking(false);
                        }
                      },
                      onHorizontalDragEnd: (details) {
                        if (details.primaryVelocity != null &&
                            details.primaryVelocity! > 60) {
                          context.read<ViewCubit>().togglePanelPeeking(false);
                        }
                      },
                      child: Tooltip(
                        message: l10n.restorePanel,
                        child: Container(
                          decoration: BoxDecoration(
                            color: cs.primary.withValues(alpha: 0.15),
                            border: Border(
                              left: BorderSide(
                                color: cs.primary.withValues(alpha: 0.5),
                                width: 2.0,
                              ),
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: cs.primary,
                                  boxShadow: [
                                    BoxShadow(
                                      color: cs.primary.withValues(alpha: 0.4),
                                      blurRadius: 8,
                                      offset: const Offset(1, 2),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  size: 16,
                                  color: cs.onPrimary,
                                ),
                              ),
                              const SizedBox(height: 14),
                              RotatedBox(
                                quarterTurns: 3,
                                child: Text(
                                  l10n.restorePanel.toUpperCase(),
                                  style: TextStyle(
                                    color: cs.primary,
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
  }

  Widget _buildRightOverlay({
    required BuildContext context,
    required TextDirection textDir,
    required double screenWidth,
  }) {
    final maxAllowed = screenWidth * 0.85;
    final minAllowed = math.min(minViewPanelWidth, maxAllowed);
    final overlayWidth = _viewPanelWidth.clamp(minAllowed, maxAllowed);

    return Positioned(
      top: 0,
      bottom: 0,
      right: 0,
      width: overlayWidth + 12,
      child: Material(
        elevation: 16,
        shadowColor: Colors.black54,
        color: Theme.of(context).colorScheme.surfaceContainer,
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                color: Theme.of(context)
                    .colorScheme
                    .outlineVariant
                    .withValues(alpha: 0.5),
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              _buildRightResizeHandle(context, maxWidth: maxAllowed),
              Expanded(
                child: _buildViewPanelContent(
                  context: context,
                  textDir: textDir,
                  isOverlay: true,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<SectionSpineEntry> _buildSpineEntries(
    ViewState viewState,
    AppLocalizations l10n,
  ) {
    return [
      SectionSpineEntry(
        section: SettingsSection.profiles,
        label: l10n.headerEnsembleProfiles,
        icon: Icons.queue_music_rounded,
        key: _profilesAnchorKey,
        isExpanded: viewState.isPointerSectionExpanded(SettingsSection.profiles),
      ),
      SectionSpineEntry(
        section: SettingsSection.pageSetup,
        label: l10n.pageSettings,
        icon: Icons.description_outlined,
        key: _pageSetupAnchorKey,
        isExpanded: viewState.isPointerSectionExpanded(SettingsSection.pageSetup),
      ),
      SectionSpineEntry(
        section: SettingsSection.scoreTypography,
        label: l10n.sectionScoreTypography,
        icon: Icons.title_rounded,
        key: _scoreTypographyAnchorKey,
        isExpanded: viewState.isPointerSectionExpanded(SettingsSection.scoreTypography),
      ),
      SectionSpineEntry(
        section: SettingsSection.margins,
        label: l10n.marginsLabel,
        icon: Icons.space_dashboard_outlined,
        key: _marginsAnchorKey,
        isExpanded: viewState.isPointerSectionExpanded(SettingsSection.margins),
      ),
      SectionSpineEntry(
        section: SettingsSection.staffSpacing,
        label: l10n.staffSpacing,
        icon: Icons.format_line_spacing_rounded,
        key: _staffSpacingAnchorKey,
        isExpanded: viewState.isPointerSectionExpanded(SettingsSection.staffSpacing),
      ),
      SectionSpineEntry(
        section: SettingsSection.systemHierarchy,
        label: l10n.systemHierarchy,
        icon: Icons.account_tree_outlined,
        key: _hierarchyAnchorKey,
        isExpanded: viewState.isPointerSectionExpanded(SettingsSection.systemHierarchy),
      ),
    ];
  }

  Widget _buildSidebarContent({
    required BuildContext context,
    required DocumentCubit documentCubit,
    required core.PageConfig configState,
    required TextDirection sidebarTextDir,
    bool isOverlay = false,
  }) {
    final viewState = context.watch<ViewCubit>().state;
    final isCovering = isOverlay &&
        CanvasZoomCalculator.isTargetOccluded(
          matrix: _transformationController.value,
          config: configState,
          panelWidth: _sidebarWidth + 12,
          panelLeft: 0.0,
          canvasLeft: 0.0,
          activeScrubbingMargin: viewState.activeScrubbingMargin,
        );
    final shouldTransparentize = isCovering && viewState.isScrubbing;

    return Column(
      children: [
        if (isOverlay)
          Directionality(
            textDirection: sidebarTextDir,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onHorizontalDragUpdate: (details) {
                if (details.primaryDelta != null && details.primaryDelta! < -8) {
                  context.read<ViewCubit>().togglePanelPeeking(true);
                }
              },
              onHorizontalDragEnd: (details) {
                if (details.primaryVelocity != null && details.primaryVelocity! < -50) {
                  context.read<ViewCubit>().togglePanelPeeking(true);
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.paddingLarge,
                  vertical: AppSpacing.paddingSmall,
                ),
                decoration: BoxDecoration(
                  color: shouldTransparentize
                      ? Colors.transparent
                      : Theme.of(context).colorScheme.surfaceContainerHigh,
                  border: shouldTransparentize
                      ? null
                      : Border(
                          bottom: BorderSide(
                            color: Theme.of(context)
                                .colorScheme
                                .outlineVariant
                                .withValues(alpha: 0.5),
                            width: 1,
                          ),
                        ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Header Title Area (Double-tap to peek/restore)
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onDoubleTap: () =>
                            context.read<ViewCubit>().togglePanelPeeking(),
                        child: Row(
                          children: [
                            Icon(
                              Icons.tune_rounded,
                              size: 18,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: AppSpacing.itemGapSmall),
                            Expanded(
                              child: Text(
                                AppLocalizations.of(context)!.pageSettings,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Tooltip(
                          message: AppLocalizations.of(context)!.peekCanvas,
                          child: Listener(
                            onPointerDown: (_) {
                              context.read<ViewCubit>().togglePanelPeeking(true);
                            },
                            onPointerUp: (_) {
                              context.read<ViewCubit>().togglePanelPeeking(false);
                            },
                            onPointerCancel: (_) {
                              context.read<ViewCubit>().togglePanelPeeking(false);
                            },
                            child: IconButton(
                              icon: Icon(
                                context.watch<ViewCubit>().state.isPanelPeeking
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                size: 18,
                              ),
                              visualDensity: VisualDensity.compact,
                              tooltip: AppLocalizations.of(context)!.peekCanvas,
                              onPressed: () => context
                                  .read<ViewCubit>()
                                  .togglePanelPeeking(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 4.0),
                        IconButton(
                          icon: const Icon(Icons.close, size: 20),
                          visualDensity: VisualDensity.compact,
                          tooltip: AppLocalizations.of(context)!.close,
                          onPressed: () {
                            setState(() => _sidebarCollapsed = true);
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        Expanded(
          child: Directionality(
            textDirection: sidebarTextDir,
            child: Builder(
              builder: (context) {
                final viewCubit = context.read<ViewCubit>();
                final viewState = context.watch<ViewCubit>().state;
                final l10n = AppLocalizations.of(context)!;

                final spineEntries = _buildSpineEntries(viewState, l10n);

                return Stack(
                  children: [
                    Positioned.fill(
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 150),
                        curve: Curves.easeOutCubic,
                        opacity: shouldTransparentize ? 0.10 : 1.0,
                        child: ScrollConfiguration(
                          behavior: ScrollConfiguration.of(context).copyWith(
                            scrollbars: false,
                          ),
                          child: ListView(
                          key: const PageStorageKey('pointer_primary_sidebar'),
                          controller: _sidebarScrollController,
                          padding: const EdgeInsets.fromLTRB(
                            28.0,
                            AppSpacing.paddingMedium,
                            8.0,
                            AppSpacing.paddingLarge,
                          ),
                          children: [
                            CollapsibleSectionCard(
                              section: SettingsSection.profiles,
                              title: l10n.headerEnsembleProfiles,
                              icon: Icons.queue_music_rounded,
                              isExpanded: viewState.isPointerSectionExpanded(
                                  SettingsSection.profiles),
                              onToggle: () => viewCubit.togglePointerSection(
                                  SettingsSection.profiles),
                              anchorKey: _profilesAnchorKey,
                              child: ProfilePicker(
                                currentConfig: configState,
                                onProfileSelected: (p) =>
                                    context.read<DocumentCubit>().applyProfile(p),
                              ),
                            ),
                            CollapsibleSectionCard(
                              section: SettingsSection.pageSetup,
                              title: l10n.pageSettings,
                              icon: Icons.description_outlined,
                              isExpanded: viewState.isPointerSectionExpanded(
                                  SettingsSection.pageSetup),
                              onToggle: () => viewCubit.togglePointerSection(
                                  SettingsSection.pageSetup),
                              anchorKey: _pageSetupAnchorKey,
                              child: DocumentSettingsGroup(
                                pageSize: configState.pageSize,
                                onPageSizeChanged: documentCubit.updatePageSize,
                                orientation: configState.orientation,
                                onOrientationChanged:
                                    documentCubit.updateOrientation,
                                pageCount: documentCubit.state.pageCount,
                                onPageCountChanged: documentCubit.setPageCount,
                                arrangementMode: viewState.pageArrangement,
                                onArrangementModeChanged: viewCubit.setPageArrangement,
                                gridColumns: viewState.gridColumns,
                                onGridColumnsChanged: viewCubit.setGridColumns,
                                autoFocusOnPageChange: viewState.autoFocusOnPageChange,
                                onAutoFocusChanged: viewCubit.setAutoFocusOnPageChange,
                                pageSwipeGestures: viewState.pageSwipeGestures,
                                onPageSwipeGesturesChanged: viewCubit.setPageSwipeGestures,
                              ),
                            ),
                            CollapsibleSectionCard(
                              section: SettingsSection.scoreTypography,
                              title: l10n.sectionScoreTypography,
                              icon: Icons.title_rounded,
                              isExpanded: viewState.isPointerSectionExpanded(
                                  SettingsSection.scoreTypography),
                              onToggle: () => viewCubit.togglePointerSection(
                                  SettingsSection.scoreTypography),
                              anchorKey: _scoreTypographyAnchorKey,
                              child: ScoreTypographySettingsGroup(
                                metadata: documentCubit.state.metadata,
                                onMetadataChanged: documentCubit.updateMetadata,
                              ),
                            ),
                            CollapsibleSectionCard(
                              section: SettingsSection.margins,
                              title: l10n.marginsLabel,
                              icon: Icons.space_dashboard_outlined,
                              isExpanded: viewState.isPointerSectionExpanded(
                                  SettingsSection.margins),
                              onToggle: () => viewCubit.togglePointerSection(
                                  SettingsSection.margins),
                              anchorKey: _marginsAnchorKey,
                              action: Tooltip(
                                message: l10n.reset,
                                child: InkWell(
                                  onTap: documentCubit.resetMargins,
                                  borderRadius: BorderRadius.circular(4.0),
                                  child: Padding(
                                    padding: const EdgeInsets.all(4.0),
                                    child: Icon(
                                      Icons.restore,
                                      size: 14.0,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                                  ),
                                ),
                              ),
                              child: MarginsSettingsGroup(
                                margins: configState.margins,
                                onLeftChanged: documentCubit.updateLeftMargin,
                                onRightChanged: documentCubit.updateRightMargin,
                                onTopChanged: documentCubit.updateTopMargin,
                                onBottomChanged:
                                    documentCubit.updateBottomMargin,
                                onHorizontalChanged:
                                    documentCubit.updateHorizontalMargins,
                                onVerticalChanged:
                                    documentCubit.updateVerticalMargins,
                                onReset: documentCubit.resetMargins,
                                onLinkChanged: documentCubit.setMarginsLinked,
                                onScrubStart: (side) => context
                                    .read<ViewCubit>()
                                    .setActiveScrubbingMargin(side),
                                onScrubEnd: () => context
                                    .read<ViewCubit>()
                                    .setActiveScrubbingMargin(null),
                              ),
                            ),
                            CollapsibleSectionCard(
                              section: SettingsSection.staffSpacing,
                              title: l10n.staffSpacing,
                              icon: Icons.format_line_spacing_rounded,
                              isExpanded: viewState.isPointerSectionExpanded(
                                  SettingsSection.staffSpacing),
                              onToggle: () => viewCubit.togglePointerSection(
                                  SettingsSection.staffSpacing),
                              anchorKey: _staffSpacingAnchorKey,
                              action: Tooltip(
                                message: l10n.reset,
                                child: InkWell(
                                  onTap: documentCubit.resetSpacing,
                                  borderRadius: BorderRadius.circular(4.0),
                                  child: Padding(
                                    padding: const EdgeInsets.all(4.0),
                                    child: Icon(
                                      Icons.restore,
                                      size: 14.0,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                                  ),
                                ),
                              ),
                              child: StaffSpacingGroup(
                                staffConfig: configState.staffConfig,
                                isDoubleLine: configState.staffCount > 1,
                                lines: documentCubit.primaryLines,
                                onLineGapChanged: documentCubit.updateLineGap,
                                onSystemGapChanged:
                                    documentCubit.updateSystemGap,
                                onInterStaffGapChanged:
                                    documentCubit.updateInterStaffGap,
                                hints: documentCubit.uiHints,
                              ),
                            ),
                            CollapsibleSectionCard(
                              section: SettingsSection.systemHierarchy,
                              title: l10n.systemHierarchy,
                              icon: Icons.account_tree_outlined,
                              isExpanded: viewState.isPointerSectionExpanded(
                                  SettingsSection.systemHierarchy),
                              onToggle: () => viewCubit.togglePointerSection(
                                  SettingsSection.systemHierarchy),
                              anchorKey: _hierarchyAnchorKey,
                              child: SystemHierarchyPanel(
                                key: const ValueKey('advanced_panel'),
                                notifier: documentCubit,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.paddingLarge),
                          ],
                        ),
                      ),
                    ),
                  ),
                    Positioned(
                      top: 0,
                      bottom: 0,
                      left: 2.0,
                      child: SectionSpine(
                        entries: spineEntries,
                        scrollController: _sidebarScrollController,
                        onJumpToSection: (section) =>
                            viewCubit.jumpToSection(section),
                        activeSection: viewState.activeTouchSection,
                        jumpTargetSection: viewState.jumpTargetSection,
                        onActiveSectionChanged: (section) =>
                            viewCubit.setActiveSection(section),
                      ),
                    ),
                    if (viewState.isScrubbing &&
                        viewState.activeScrubbingTelemetry != null)
                      Positioned(
                        top: 14.0,
                        left: 36.0,
                        right: 16.0,
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14.0,
                              vertical: 7.0,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              borderRadius: BorderRadius.circular(20.0),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.28),
                                  blurRadius: 8.0,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              viewState.activeScrubbingTelemetry!,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onPrimary,
                                fontSize: 12.0,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ),
        Divider(
            color: Theme.of(context).colorScheme.outline,
            height: 1),
        BlocBuilder<ViewCubit, ViewState>(
          builder: (context, viewState) {
            return Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.paddingLarge,
                  vertical: AppSpacing.paddingMedium),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    AppLocalizations.of(context)!
                        .systemsCount(documentCubit.layout.systemCount),
                    style: TextStyle(
                        fontSize: 11,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurfaceVariant),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(
                          viewState.expandedPointerSections.isEmpty
                              ? Icons.unfold_more_rounded
                              : Icons.unfold_less_rounded,
                          size: 16,
                        ),
                        tooltip: viewState.expandedPointerSections.isEmpty
                            ? 'Expand All Sections'
                            : 'Collapse All Sections',
                        visualDensity: VisualDensity.compact,
                        onPressed: () {
                          if (viewState.expandedPointerSections.isEmpty) {
                            context
                                .read<ViewCubit>()
                                .expandAllPointerSections();
                          } else {
                            context
                                .read<ViewCubit>()
                                .collapseAllPointerSections();
                          }
                        },
                      ),
                      const SizedBox(width: 4.0),
                      Tooltip(
                        message: AppLocalizations.of(context)!.resetAllSettings,
                        child: TextButton.icon(
                          onPressed: documentCubit.resetToDefaults,
                          icon: const Icon(Icons.restore, size: 14),
                          label: Text(AppLocalizations.of(context)!.reset,
                              style: const TextStyle(fontSize: 12)),
                          style: TextButton.styleFrom(
                            minimumSize: Size.zero,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4)),
                            foregroundColor: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildViewPanelContent({
    required BuildContext context,
    required TextDirection textDir,
    bool isOverlay = false,
  }) {
    return Column(
      children: [
        if (isOverlay)
          Directionality(
            textDirection: textDir,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.paddingLarge,
                vertical: AppSpacing.paddingSmall,
              ),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: Theme.of(context)
                        .colorScheme
                        .outlineVariant
                        .withValues(alpha: 0.5),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.visibility_outlined,
                        size: 18,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: AppSpacing.itemGapSmall),
                      Text(
                        AppLocalizations.of(context)!.view,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    tooltip: AppLocalizations.of(context)!.close,
                    onPressed: () => setState(() => _viewPanelCollapsed = true),
                  ),
                ],
              ),
            ),
          ),
        Expanded(
          child: ViewPanel(
            transformationController: _transformationController,
            onZoomPreset: _applyZoomPreset,
          ),
        ),
      ],
    );
  }

  void _animateMatrixTo(Matrix4 target) {
    _startMatrix = _transformationController.value.clone();
    _targetMatrix = target;
    _cameraAnimationController.stop();
    _cameraAnimationController.reset();
    _cameraAnimationController.forward();
  }

  void _applyZoomPreset(ZoomPreset preset, {bool animate = false}) {
    _currentPreset = preset;
    final constraints = _lastConstraints;
    if (constraints == null) return;

    final config = context.read<DocumentCubit>().state.config;
    final viewState = context.read<ViewCubit>().state;

    final transform = CanvasZoomCalculator.compute(
      preset: preset,
      constraints: constraints,
      config: config,
      calibrationFactor: viewState.calibrationFactor,
      padding: 40.0,
      leftInset: 0.0,
      rightInset: 0.0,
    );

    if (animate && _hasCentered) {
      _cameraAnimationController.duration = const Duration(milliseconds: 150);
      _animateMatrixTo(transform.matrix);
    } else {
      _transformationController.value = transform.matrix;
    }
  }

  void _focusPage(int pageIndex, {bool animate = true}) {
    final constraints = _lastConstraints;
    if (constraints == null) return;

    final docCubit = context.read<DocumentCubit>();
    final viewState = context.read<ViewCubit>().state;
    final config = docCubit.state.config;

    final currentMatrix = _transformationController.value;
    final currentScale = currentMatrix.row0[0];

    final targetMatrix = CanvasZoomCalculator.computePageFocusMatrix(
      arrangement: viewState.pageArrangement,
      pageIndex: pageIndex,
      constraints: constraints,
      config: config,
      currentScale: currentScale,
      gridColumns: viewState.gridColumns,
      padding: 40.0,
    );

    if (animate && _hasCentered) {
      _cameraAnimationController.duration = const Duration(milliseconds: 250);
      _animateMatrixTo(targetMatrix);
    } else {
      _transformationController.value = targetMatrix;
    }
  }

  void _zoomIn() => _zoomBy(1.2);
  void _zoomOut() => _zoomBy(1.0 / 1.2);

  void _zoomBy(double factor) {
    final constraints = _lastConstraints;
    final currentMatrix = _transformationController.value;
    final currentScale = currentMatrix.row0[0];
    final targetScale = (currentScale * factor).clamp(0.1, 8.0);
    final scaleRatio = targetScale / currentScale;

    if (constraints != null) {
      final focalPoint = Offset(constraints.maxWidth / 2, constraints.maxHeight / 2);
      final translation = currentMatrix.getTranslation();
      final newTx = focalPoint.dx - (focalPoint.dx - translation.x) * scaleRatio;
      final newTy = focalPoint.dy - (focalPoint.dy - translation.y) * scaleRatio;
      _transformationController.value = Matrix4.translationValues(newTx, newTy, 0.0)
        ..scaleByDouble(targetScale, targetScale, 1.0, 1.0);
    } else {
      final t = currentMatrix.getTranslation();
      _transformationController.value = Matrix4.translationValues(t.x, t.y, 0.0)
        ..scaleByDouble(targetScale, targetScale, 1.0, 1.0);
    }
  }

  @override
  void dispose() {
    _cameraAnimationController.dispose();
    _sidebarScrollController.dispose();
    _transformationController.dispose();
    _cursorNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final documentCubit = context.watch<DocumentCubit>();
    return MultiBlocListener(
      listeners: [
        BlocListener<DocumentCubit, DocumentState>(
          listenWhen: (previous, current) =>
              previous.config.effectiveWidth != current.config.effectiveWidth ||
              previous.config.effectiveHeight != current.config.effectiveHeight,
          listener: (context, state) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _applyZoomPreset(_currentPreset, animate: true);
            });
          },
        ),
        BlocListener<ViewCubit, ViewState>(
          listenWhen: (previous, current) =>
              previous.currentPageIndex != current.currentPageIndex ||
              previous.pageArrangement != current.pageArrangement,
          listener: (context, state) {
            if (state.autoFocusOnPageChange) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) _focusPage(state.currentPageIndex, animate: true);
              });
            }
          },
        ),
      ],
      child: BlocBuilder<DocumentCubit, DocumentState>(
        builder: (context, docState) {
          final configState = docState.config;
          final isFa = Localizations.localeOf(context).languageCode == 'fa';
          final sidebarTextDir = isFa ? TextDirection.rtl : TextDirection.ltr;
          final screenWidth = MediaQuery.sizeOf(context).width;
          final canDockLeft = SarvBreakpoints.canDockPrimarySidebar(context);
          final canDockRight = SarvBreakpoints.canDockBothSidebars(context);

          return BlocBuilder<ViewCubit, ViewState>(
            builder: (context, viewState) {
              return SarvShortcutGateway(
                onZoomIn: _zoomIn,
                onZoomOut: _zoomOut,
                onZoomReset: () => _applyZoomPreset(ZoomPreset.actualSize),
                onToggleSidebar: () => _toggleLeftSidebar(canDockLeft, canDockRight),
                onToggleViewPanel: () {
                  setState(() {
                    _viewPanelCollapsed = !_viewPanelCollapsed;
                  });
                },
                onToggleZenMode: () {
                  setState(() {
                    final isZen = _sidebarCollapsed && _viewPanelCollapsed;
                    if (isZen) {
                      _sidebarCollapsed = false;
                      _viewPanelCollapsed = false;
                    } else {
                      _sidebarCollapsed = true;
                      _viewPanelCollapsed = true;
                    }
                  });
                },
                child: Scaffold(
                  backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                  body: Column(
                    children: [
                      const PointerTopBar(),
                      const PointerTabBar(),
                      Expanded(
                        child: Directionality(
                          textDirection: TextDirection.ltr,
                          child: Row(
                            children: [
                              // Sidebar (Left) - docked when viewport allows
                              if (canDockLeft) ...[
                                AnimatedContainer(
                                  duration: _isDraggingSidebar
                                      ? Duration.zero
                                      : const Duration(milliseconds: 300),
                                  curve: Curves.easeOutCubic,
                                  width: _sidebarCollapsed ? 0 : _sidebarWidth,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .surfaceContainer,
                                  child: ClipRect(
                                    child: OverflowBox(
                                      minWidth: 0,
                                      maxWidth: _sidebarWidth,
                                      alignment: Alignment.topLeft,
                                      child: _buildSidebarContent(
                                        context: context,
                                        documentCubit: documentCubit,
                                        configState: configState,
                                        sidebarTextDir: sidebarTextDir,
                                        isOverlay: false,
                                      ),
                                    ),
                                  ),
                                ),
                                // Resize Handle (Left)
                                if (!_sidebarCollapsed)
                                  _buildLeftResizeHandle(context),
                              ],
                              // Preview Area
                              Expanded(
                                child: Listener(
                                  behavior: HitTestBehavior.translucent,
                                  onPointerDown: (_) {
                                    SarvShortcutGateway.requestFocus(context);
                                  },
                                  child: Container(
                                    color: Theme.of(context).colorScheme.surface,
                                    child: LayoutBuilder(
                                      builder: (context, constraints) {
                                        _lastConstraints = constraints;
                                        final pageCount = documentCubit.state.pageCount;
                                        final int effectivePageIndex = viewState.currentPageIndex.clamp(
                                          0,
                                          math.max(0, pageCount - 1),
                                        ).toInt();
                                        if (!_hasCentered) {
                                          _hasCentered = true;
                                          WidgetsBinding.instance
                                              .addPostFrameCallback((_) {
                                            if (mounted) _applyZoomPreset(_currentPreset, animate: false);
                                          });
                                        }

                                        return Stack(
                                          children: [
                                            Positioned.fill(
                                              child: CanvasStrictScope(
                                                child: RulerBox(
                                                  transformationController:
                                                      _transformationController,
                                                  viewState: viewState,
                                                  cursorNotifier: _cursorNotifier,
                                                  paperSizeMm: Size(
                                                    configState.effectiveWidth,
                                                    configState.effectiveHeight,
                                                  ),
                                                  child: MouseRegion(
                                                    onHover: (event) {
                                                      _cursorNotifier.value =
                                                          event.localPosition;
                                                    },
                                                    onExit: (_) {
                                                      _cursorNotifier.value = null;
                                                    },
                                                    child: Stack(
                                                      children: [
                                                        Positioned.fill(
                                                          child: InteractiveViewer(
                                                            transformationController:
                                                                _transformationController,
                                                            boundaryMargin:
                                                                const EdgeInsets.all(
                                                                    100000),
                                                            minScale:
                                                                ScaleMetrics.minZoom,
                                                            maxScale:
                                                                ScaleMetrics.maxZoom,
                                                            constrained: false,
                                                            alignment:
                                                                Alignment.topLeft,
                                                            child: ScoreArrangementCanvas(
                                                              documentCubit: documentCubit,
                                                              viewState: viewState,
                                                              onPageTapped: (index) => context
                                                                  .read<ViewCubit>()
                                                                  .setPageIndex(
                                                                    index,
                                                                    maxPages: documentCubit.state.pageCount,
                                                                  ),
                                                            ),
                                                          ),
                                                        ),
                                                        // Sidebar Toggle (Left)
                                                        Positioned(
                                                          top: 16,
                                                          left: 16,
                                                          child: FloatingActionButton.small(
                                                            heroTag: 'left_toggle',
                                                            onPressed: () =>
                                                                _toggleLeftSidebar(
                                                                    canDockLeft,
                                                                    canDockRight),
                                                            backgroundColor:
                                                                Theme.of(context)
                                                                    .colorScheme
                                                                    .surface,
                                                            foregroundColor:
                                                                Theme.of(context)
                                                                    .colorScheme
                                                                    .onSurfaceVariant,
                                                            elevation: 2,
                                                            tooltip: _sidebarCollapsed
                                                                ? (canDockLeft
                                                                    ? 'Expand Left Sidebar'
                                                                    : 'Open Sidebar')
                                                                : 'Collapse Left Sidebar',
                                                            child: Icon(
                                                              _sidebarCollapsed
                                                                  ? Icons.menu
                                                                  : Icons
                                                                      .arrow_back_ios_new,
                                                              size: 20,
                                                            ),
                                                          ),
                                                        ),
                                                        // View Panel Toggle (Right)
                                                        Positioned(
                                                          top: 16,
                                                          right: 16,
                                                          child: FloatingActionButton.small(
                                                            heroTag: 'right_toggle',
                                                            onPressed: () =>
                                                                _toggleViewPanel(
                                                                    canDockLeft,
                                                                    canDockRight),
                                                            backgroundColor:
                                                                Theme.of(context)
                                                                    .colorScheme
                                                                    .surface,
                                                            foregroundColor:
                                                                Theme.of(context)
                                                                    .colorScheme
                                                                    .onSurfaceVariant,
                                                            elevation: 2,
                                                            tooltip: _viewPanelCollapsed
                                                                ? (canDockRight
                                                                    ? 'Expand Settings'
                                                                    : 'Open Settings')
                                                                : 'Collapse Settings',
                                                            child: Icon(
                                                              _viewPanelCollapsed
                                                                  ? Icons.tune
                                                                  : Icons
                                                                      .arrow_forward_ios,
                                                              size: 20,
                                                            ),
                                                          ),
                                                        ),
                                                        // Floating Page Navigator (Bottom Center)
                                                        Positioned(
                                                          bottom: 24,
                                                          left: 0,
                                                          right: 0,
                                                          child: Center(
                                                            child: CanvasPageNavigator(
                                                              currentPageIndex: effectivePageIndex,
                                                              pageCount: pageCount,
                                                              arrangementMode: viewState.pageArrangement,
                                                              onArrangementModeChanged: (mode) => context
                                                                  .read<ViewCubit>()
                                                                  .setPageArrangement(mode),
                                                              autoFocusOnPageChange: viewState.autoFocusOnPageChange,
                                                              onAutoFocusChanged: (val) => context
                                                                  .read<ViewCubit>()
                                                                  .setAutoFocusOnPageChange(val),
                                                              onPageChanged: (idx) => context
                                                                  .read<ViewCubit>()
                                                                  .setPageIndex(idx, maxPages: pageCount),
                                                              onAddPage: () => documentCubit.addPage(),
                                                              onRemovePage: () => documentCubit.removeLastPage(),
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            // Non-blocking translucent click-outside listener for overlay drawer(s) (no dark scrim)
                                            if ((!canDockLeft &&
                                                    !_sidebarCollapsed) ||
                                                (!canDockRight &&
                                                    !_viewPanelCollapsed))
                                              Positioned.fill(
                                                child: GestureDetector(
                                                  behavior:
                                                      HitTestBehavior.translucent,
                                                  onTap: () {
                                                    if (viewState.isPanelPeeking) {
                                                      context
                                                          .read<ViewCubit>()
                                                          .togglePanelPeeking(false);
                                                      return;
                                                    }
                                                    setState(() {
                                                      if (!canDockLeft) {
                                                        _sidebarCollapsed =
                                                            true;
                                                      }
                                                      if (!canDockRight) {
                                                        _viewPanelCollapsed =
                                                            true;
                                                      }
                                                    });
                                                  },
                                                  child: const SizedBox.expand(),
                                                ),
                                              ),
                                          // Left Sidebar Overlay (flush with top bar and screen edges)
                                          if (!canDockLeft &&
                                              !_sidebarCollapsed)
                                            _buildLeftOverlay(
                                              context: context,
                                              documentCubit:
                                                  documentCubit,
                                              configState: configState,
                                              sidebarTextDir:
                                                  sidebarTextDir,
                                              screenWidth: screenWidth,
                                            ),
                                          // Right View Panel Overlay (flush with top bar and screen edges)
                                          if (!canDockRight &&
                                              !_viewPanelCollapsed)
                                            _buildRightOverlay(
                                              context: context,
                                              textDir: sidebarTextDir,
                                              screenWidth: screenWidth,
                                            ),
                                        ],
                                      );
                                    },
                                  ),
                                ),
                              ),
                              ),
                              // Docked Right View Panel
                              if (canDockRight) ...[
                                if (!_viewPanelCollapsed)
                                  _buildRightResizeHandle(context),
                                AnimatedContainer(
                                  duration: _isDraggingViewPanel
                                      ? Duration.zero
                                      : const Duration(milliseconds: 300),
                                  curve: Curves.easeOutCubic,
                                  width: _viewPanelCollapsed
                                      ? 0
                                      : _viewPanelWidth,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .surfaceContainer,
                                  child: ClipRect(
                                    child: OverflowBox(
                                      minWidth: 0,
                                      maxWidth: _viewPanelWidth,
                                      alignment: Alignment.topRight,
                                      child: _buildViewPanelContent(
                                        context: context,
                                        textDir: sidebarTextDir,
                                        isOverlay: false,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}



