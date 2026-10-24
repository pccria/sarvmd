// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Licensed under the Business Source License 1.1 (BUSL-1.1).

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_version.dart';
import '../../../l10n/app_localizations.dart';
import '../../../logic/document/document_cubit.dart';
import '../../../logic/view/view_cubit.dart';
import '../common/ensemble_summary_widget.dart';
import '../common/integrated_scale_control.dart';
import '../common/section_header.dart';
import '../dialogs/about_dialog.dart';
import '../layout/sarv_reactive_brand_logo.dart';
import '../panels/system_hierarchy_panel.dart';
import '../panels/export_panel.dart';
import '../staff/document_settings_group.dart';
import '../staff/margins_settings_group.dart';
import '../staff/profile_picker.dart';
import '../staff/score_typography_settings_group.dart';
import '../staff/staff_spacing_group.dart';
import '../../../logic/view/view_state.dart';
import '../canvas/canvas_zoom_calculator.dart';
import 'touch_language_button.dart';
import 'touch_theme_button.dart';

/// Full-height side drawer and settings panel for touch mode.
/// Implements Progressive Disclosure category navigation with sticky primary actions.
class SettingsPanel extends StatefulWidget {
  const SettingsPanel({
    super.key,
    required this.transformationController,
    required this.onZoomPreset,
    this.isPanelDocked = false,
    this.onClose,
  });

  final TransformationController transformationController;
  final void Function(ZoomPreset preset) onZoomPreset;
  final bool isPanelDocked;
  final VoidCallback? onClose;

  @override
  State<SettingsPanel> createState() => _SettingsPanelState();
}

class _SettingsPanelState extends State<SettingsPanel> {
  @override
  void initState() {
    super.initState();
    widget.transformationController.addListener(_onTransformChanged);
  }

  @override
  void didUpdateWidget(SettingsPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.transformationController != widget.transformationController) {
      oldWidget.transformationController.removeListener(_onTransformChanged);
      widget.transformationController.addListener(_onTransformChanged);
    }
  }

  @override
  void dispose() {
    widget.transformationController.removeListener(_onTransformChanged);
    super.dispose();
  }

  void _onTransformChanged() {
    if (mounted) setState(() {});
  }

  void _navigateTo(BuildContext context, SettingsSection section) {
    context.read<ViewCubit>().setTouchSection(section);
  }

  void _goBack(BuildContext context) {
    context.read<ViewCubit>().setTouchSection(SettingsSection.mainMenu);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final isFa = Localizations.localeOf(context).languageCode == 'fa';
    final sectionTextDir = isFa ? TextDirection.rtl : TextDirection.ltr;
    final drawerWidth = MediaQuery.sizeOf(context).width * 0.85;

    final viewState = context.watch<ViewCubit>().state;
    final isScrubbing = viewState.isScrubbing;
    final isPeeking = viewState.isPanelPeeking;
    final telemetry = viewState.activeScrubbingTelemetry;

    final docState = context.watch<DocumentCubit>().state;
    final actualWidth = widget.isPanelDocked ? 320.0 : drawerWidth.clamp(280.0, 420.0);

    final isCovering = CanvasZoomCalculator.isTargetOccluded(
      matrix: widget.transformationController.value,
      config: docState.config,
      panelWidth: actualWidth,
      panelLeft: 0.0,
      canvasLeft: 0.0,
      activeScrubbingMargin: viewState.activeScrubbingMargin,
    );
    final shouldTransparentize = isScrubbing && isCovering;

    final currentSection = viewState.activeTouchSection;

    final viewInsets = MediaQuery.viewInsetsOf(context);

    final content = AnimatedPadding(
      padding: EdgeInsets.only(bottom: viewInsets.bottom),
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOutQuad,
      child: SafeArea(
        top: !widget.isPanelDocked,
        bottom: viewInsets.bottom == 0,
        child: Column(
          children: [
            // Drawer Header with Swipe-Left to Peek & Double-Tap to Peek
            GestureDetector(
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
                padding: EdgeInsets.symmetric(
                  horizontal: 14.0,
                  vertical: widget.isPanelDocked ? 8.0 : 12.0,
                ),
                decoration: BoxDecoration(
                  color: shouldTransparentize
                      ? Colors.transparent
                      : cs.surfaceContainerHigh,
                  border: shouldTransparentize
                      ? null
                      : Border(
                          bottom: BorderSide(
                            color: cs.outlineVariant.withValues(alpha: 0.4),
                            width: 1.0,
                          ),
                        ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Brand Logo + Version (Double-tap to peek/restore)
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onDoubleTap: () =>
                            context.read<ViewCubit>().togglePanelPeeking(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SarvReactiveBrandLogo(
                              logoHeight: 20.0,
                              enableExpandAnimation: false,
                            ),
                            const SizedBox(height: 2.0),
                            Padding(
                              padding: const EdgeInsets.only(left: 4.0),
                              child: Text(
                                'v${AppVersion.version}',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                  color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                                  letterSpacing: 0.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Controls (Language, Theme & Peek)
                    const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TouchLanguageButton(),
                        SizedBox(width: 6.0),
                        TouchThemeButton(),
                        SizedBox(width: 6.0),
                        GlanceButton(showLabel: false, compact: true),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Drawer Body Content (Touch Section Spine + Active Section Content)
            Expanded(
              child: Row(
                children: [
                  _TouchSectionSpine(
                    activeSection: currentSection,
                    onSectionSelected: (section) => _navigateTo(context, section),
                    shouldTransparentize: shouldTransparentize,
                  ),
                  Container(
                    width: 1.0,
                    color: shouldTransparentize
                        ? Colors.transparent
                        : cs.outlineVariant.withValues(alpha: 0.25),
                  ),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      switchInCurve: Curves.easeOut,
                      switchOutCurve: Curves.easeIn,
                      child: currentSection == SettingsSection.mainMenu
                          ? _buildMainMenu(context, cs, l10n)
                          : _buildSectionContent(
                              context,
                              cs,
                              l10n,
                              sectionTextDir,
                              currentSection,
                              shouldTransparentize: shouldTransparentize,
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    final inner = Stack(
      children: [
        Positioned.fill(
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOutCubic,
            opacity: shouldTransparentize ? 0.18 : 1.0,
            child: content,
          ),
        ),
        if (isScrubbing && telemetry != null)
          Positioned(
            top: 14.0,
            left: 20.0,
            right: 20.0,
            child: Center(
              child: Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(20),
                color: cs.primary,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 8.0),
                  child: Text(
                    telemetry,
                    style: TextStyle(
                      color: cs.onPrimary,
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ),
            ),
          ),
        if (isPeeking)
          Positioned(
            top: 0,
            bottom: 0,
            right: 0,
            width: 56.0,
            child: Listener(
              onPointerDown: (_) {
                HapticFeedback.selectionClick();
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
                      FloatingActionButton.small(
                        heroTag: 'restore_panel_peek',
                        onPressed: () =>
                            context.read<ViewCubit>().togglePanelPeeking(false),
                        backgroundColor: cs.primary,
                        foregroundColor: cs.onPrimary,
                        elevation: 4,
                        child: const Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 16,
                        ),
                      ),
                      const SizedBox(height: 12),
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
    );

    final peekSlideFraction = (actualWidth - 56.0) / actualWidth;

    final Widget panelBody;
    if (widget.isPanelDocked) {
      panelBody = AnimatedSlide(
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutCubic,
        offset: isPeeking ? Offset(-peekSlideFraction, 0) : Offset.zero,
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Material(
            color: shouldTransparentize
                ? Colors.transparent
                : cs.surfaceContainerLow,
            elevation: (shouldTransparentize || isPeeking) ? 0.0 : 6.0,
            shadowColor: shouldTransparentize
                ? Colors.transparent
                : Colors.black.withValues(alpha: 0.35),
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.only(
                topRight: Radius.circular(16.0),
                bottomRight: Radius.circular(16.0),
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: inner,
          ),
        ),
      );
    } else {
      panelBody = AnimatedSlide(
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutCubic,
        offset: isPeeking ? Offset(-peekSlideFraction, 0) : Offset.zero,
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: SizedBox(
            width: actualWidth,
            child: Drawer(
              backgroundColor: shouldTransparentize
                  ? Colors.transparent
                  : cs.surfaceContainerLow,
              elevation: (shouldTransparentize || isPeeking) ? 0.0 : 6.0,
              child: inner,
            ),
          ),
        ),
      );
    }

    return panelBody;
  }

  Widget _buildFooterContent(BuildContext context, ColorScheme cs, AppLocalizations l10n) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const EnsembleSummaryWidget(showPageBadge: true),
        const SizedBox(height: 6.0),
        TextButton.icon(
          onPressed: () {
            if (widget.onClose != null) {
              widget.onClose!();
            } else {
              Navigator.of(context).maybePop();
            }
            showSarvAboutDialog(context);
          },
          icon: const Icon(Icons.info_outline, size: 16),
          label: Text(l10n.aboutSarvMD),
          style: TextButton.styleFrom(
            visualDensity: VisualDensity.compact,
          ),
        ),
      ],
    );
  }

  Widget _buildMainMenu(BuildContext context, ColorScheme cs, AppLocalizations l10n) {
    final isDense = widget.isPanelDocked;

    return Column(
      key: const ValueKey('main_menu'),
      children: [
        Expanded(
          child: ListView(
            key: const PageStorageKey('touch_settings_main_menu_scroll'),
            padding: EdgeInsets.symmetric(
              horizontal: isDense ? 12.0 : 14.0,
              vertical: isDense ? 8.0 : 14.0,
            ),
            children: [
              _DrawerCategoryTile(
                icon: Icons.queue_music,
                title: l10n.headerEnsembleProfiles,
                subtitle: isDense ? null : 'Standard, Solo, Choir & Orchestra',
                isDense: isDense,
                onTap: () => _navigateTo(context, SettingsSection.profiles),
              ),
              _DrawerCategoryTile(
                icon: Icons.description_outlined,
                title: l10n.pageSettings,
                subtitle: isDense ? null : 'Paper size & orientation',
                isDense: isDense,
                onTap: () => _navigateTo(context, SettingsSection.pageSetup),
              ),
              _DrawerCategoryTile(
                icon: Icons.title_rounded,
                title: l10n.sectionScoreTypography,
                subtitle: isDense ? null : l10n.sectionScoreTypographySubtitle,
                isDense: isDense,
                onTap: () =>
                    _navigateTo(context, SettingsSection.scoreTypography),
              ),
              _DrawerCategoryTile(
                icon: Icons.space_dashboard_outlined,
                title: l10n.marginsLabel,
                subtitle: isDense ? null : 'Paper margins & padding',
                isDense: isDense,
                onTap: () => _navigateTo(context, SettingsSection.margins),
              ),
              _DrawerCategoryTile(
                icon: Icons.format_line_spacing,
                title: l10n.staffSpacing,
                subtitle: isDense ? null : 'Line gap, system gap, inter-staff gap',
                isDense: isDense,
                onTap: () => _navigateTo(context, SettingsSection.staffSpacing),
              ),
              _DrawerCategoryTile(
                icon: Icons.account_tree_outlined,
                title: l10n.systemHierarchy,
                subtitle: isDense ? null : 'Staves, parts & system hierarchy',
                isDense: isDense,
                onTap: () => _navigateTo(context, SettingsSection.systemHierarchy),
              ),
              _DrawerCategoryTile(
                icon: Icons.ios_share,
                title: l10n.exportManuscriptTitle,
                subtitle: isDense ? null : 'Vector SVG, high-res PNG, PDF & print',
                isDense: isDense,
                onTap: () => _navigateTo(context, SettingsSection.export),
              ),
              // In landscape side sheet mode, unpin footer so it scrolls below the 6 categories
              if (isDense) ...[
                const SizedBox(height: 6.0),
                Divider(
                  color: cs.outlineVariant.withValues(alpha: 0.3),
                  height: 12.0,
                ),
                const SizedBox(height: 6.0),
                _buildFooterContent(context, cs, l10n),
                const SizedBox(height: 8.0),
              ],
            ],
          ),
        ),

        // Sticky Drawer Footer Actions (Portrait Mode only)
        if (!isDense)
          Container(
            padding: const EdgeInsets.all(14.0),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHigh.withValues(alpha: 0.5),
              border: Border(
                top: BorderSide(
                  color: cs.outlineVariant.withValues(alpha: 0.3),
                ),
              ),
            ),
            child: _buildFooterContent(context, cs, l10n),
          ),
      ],
    );
  }

  Widget _buildSectionContent(
    BuildContext context,
    ColorScheme cs,
    AppLocalizations l10n,
    TextDirection sectionTextDir,
    SettingsSection currentSection, {
    bool shouldTransparentize = false,
  }) {
    String title = '';
    Widget body = const SizedBox.shrink();

    final docState = context.watch<DocumentCubit>().state;
    final cubit = context.read<DocumentCubit>();
    final config = docState.config;

    switch (currentSection) {
      case SettingsSection.profiles:
        title = l10n.headerEnsembleProfiles;
        body = ProfilePicker(
          currentConfig: config,
          onProfileSelected: (p) => cubit.applyProfile(p),
        );
        break;

      case SettingsSection.pageSetup:
        title = l10n.pageSettings;
        body = DocumentSettingsGroup(
          pageSize: config.pageSize,
          onPageSizeChanged: cubit.updatePageSize,
          orientation: config.orientation,
          onOrientationChanged: cubit.updateOrientation,
        );
        break;

      case SettingsSection.scoreTypography:
        title = l10n.sectionScoreTypography;
        body = ScoreTypographySettingsGroup(
          metadata: cubit.state.metadata,
          onMetadataChanged: cubit.updateMetadata,
        );
        break;

      case SettingsSection.margins:
        title = l10n.marginsLabel;
        body = MarginsSettingsGroup(
          margins: config.margins,
          onLeftChanged: cubit.updateLeftMargin,
          onRightChanged: cubit.updateRightMargin,
          onTopChanged: cubit.updateTopMargin,
          onBottomChanged: cubit.updateBottomMargin,
          onHorizontalChanged: cubit.updateHorizontalMargins,
          onVerticalChanged: cubit.updateVerticalMargins,
          onReset: cubit.resetMargins,
          onLinkChanged: cubit.setMarginsLinked,
          onScrubStart: (side) => context
              .read<ViewCubit>()
              .setActiveScrubbingMargin(side),
          onScrubEnd: () => context
              .read<ViewCubit>()
              .setActiveScrubbingMargin(null),
        );
        break;

      case SettingsSection.staffSpacing:
        title = l10n.staffSpacing;
        body = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(
              title: l10n.staffSpacing,
              onReset: cubit.resetSpacing,
            ),
            const SizedBox(height: 8),
            StaffSpacingGroup(
              staffConfig: config.staffConfig,
              isDoubleLine: config.staffCount > 1,
              lines: cubit.primaryLines,
              onLineGapChanged: cubit.updateLineGap,
              onSystemGapChanged: cubit.updateSystemGap,
              onInterStaffGapChanged: cubit.updateInterStaffGap,
            ),
          ],
        );
        break;

      case SettingsSection.systemHierarchy:
        title = l10n.systemHierarchy;
        body = SystemHierarchyPanel(
          key: const ValueKey('advanced_panel_touch'),
          notifier: cubit,
        );
        break;

      case SettingsSection.export:
        title = l10n.exportManuscriptTitle;
        body = const ExportPanel();
        break;

      case SettingsSection.mainMenu:
        break;
    }

    return Column(
      key: ValueKey(currentSection.name),
      children: [
        // Sub-page Back Header
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: 8.0,
            vertical: widget.isPanelDocked ? 4.0 : 8.0,
          ),
          decoration: BoxDecoration(
            color: shouldTransparentize
                ? Colors.transparent
                : cs.surfaceContainerHigh.withValues(alpha: 0.5),
            border: shouldTransparentize
                ? null
                : Border(
                    bottom: BorderSide(
                      color: cs.outlineVariant.withValues(alpha: 0.3),
                    ),
                  ),
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, size: 20),
                onPressed: () => _goBack(context),
                tooltip: 'Back to Menu',
              ),
              const SizedBox(width: 4.0),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: cs.onSurface,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Sub-page Content Body
        Expanded(
          child: Directionality(
            textDirection: sectionTextDir,
            child: ListView(
              key: PageStorageKey('touch_settings_${currentSection.name}_scroll'),
              padding: const EdgeInsets.all(14.0),
              children: [body],
            ),
          ),
        ),
      ],
    );
  }
}

class _DrawerCategoryTile extends StatelessWidget {
  const _DrawerCategoryTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.isDense = false,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final bool isDense;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.only(bottom: isDense ? 5.0 : 8.0),
      child: Material(
        color: cs.surfaceContainerHigh.withValues(alpha: 0.6),
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(isDense ? 10.0 : 14.0),
          side: BorderSide(
            color: cs.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
        child: ListTile(
          dense: isDense,
          visualDensity: isDense ? VisualDensity.compact : VisualDensity.standard,
          contentPadding: EdgeInsets.symmetric(
            horizontal: isDense ? 10.0 : 14.0,
            vertical: 0.0,
          ),
          leading: Container(
            padding: EdgeInsets.all(isDense ? 5.0 : 8.0),
            decoration: BoxDecoration(
              color: cs.primaryContainer.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(isDense ? 8.0 : 10.0),
            ),
            child: Icon(icon, color: cs.primary, size: isDense ? 18 : 20),
          ),
          title: Text(
            title,
            style: TextStyle(
              fontSize: isDense ? 13 : 14,
              fontWeight: FontWeight.bold,
              color: cs.onSurface,
            ),
          ),
          subtitle: subtitle != null
              ? Text(
                  subtitle!,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: cs.onSurfaceVariant,
                  ),
                )
              : null,
          trailing: Icon(
            Icons.chevron_right,
            color: cs.onSurfaceVariant.withValues(alpha: 0.7),
            size: isDense ? 18 : 20,
          ),
          onTap: onTap,
        ),
      ),
    );
  }
}

/// Spring-loaded, zero-latency glance button for score inspection.
/// Touch/click down instantly folds the panel into peek mode (0ms delay).
/// Holding down peeks for the duration of the touch and restores immediately on release.
/// Quick tap (< 180ms) toggles peek mode.
class GlanceButton extends StatefulWidget {
  const GlanceButton({
    super.key,
    this.showLabel = false,
    this.compact = false,
  });

  final bool showLabel;
  final bool compact;

  @override
  State<GlanceButton> createState() => _GlanceButtonState();
}

class _GlanceButtonState extends State<GlanceButton> {
  DateTime? _pointerDownTime;
  bool _isHeld = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final isPeeking = context.watch<ViewCubit>().state.isPanelPeeking;

    return Listener(
      onPointerDown: (_) {
        _pointerDownTime = DateTime.now();
        _isHeld = true;
        HapticFeedback.selectionClick();
        if (isPeeking) {
          context.read<ViewCubit>().togglePanelPeeking(false);
        } else {
          context.read<ViewCubit>().togglePanelPeeking(true);
        }
      },
      onPointerUp: (_) {
        final downTime = _pointerDownTime;
        _pointerDownTime = null;
        if (_isHeld && downTime != null) {
          final heldDuration = DateTime.now().difference(downTime);
          if (heldDuration.inMilliseconds >= 180) {
            _isHeld = false;
            HapticFeedback.lightImpact();
            context.read<ViewCubit>().togglePanelPeeking(false);
          } else {
            _isHeld = false;
          }
        }
      },
      onPointerCancel: (_) {
        if (_isHeld) {
          _isHeld = false;
          context.read<ViewCubit>().togglePanelPeeking(false);
        }
      },
      child: Tooltip(
        message: l10n.peekCanvas,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(14.0),
            onTap: () {}, // Handled by Listener for 0ms latency
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeOutCubic,
              height: 40.0,
              width: widget.showLabel ? null : 44.0,
              constraints: widget.showLabel
                  ? const BoxConstraints(minWidth: 44.0)
                  : null,
              padding: widget.showLabel
                  ? const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0)
                  : const EdgeInsets.all(4.0),
              decoration: BoxDecoration(
                color: isPeeking
                    ? cs.primary
                    : cs.surfaceContainerHighest.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(14.0),
                border: Border.all(
                  color: isPeeking
                      ? cs.primary
                      : cs.outlineVariant.withValues(alpha: 0.6),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isPeeking
                        ? cs.primary.withValues(alpha: 0.35)
                        : Colors.black.withValues(alpha: 0.08),
                    blurRadius: 4.0,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: widget.showLabel
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 26.0,
                          height: 26.0,
                          decoration: BoxDecoration(
                            color: isPeeking
                                ? cs.onPrimary.withValues(alpha: 0.22)
                                : cs.primary.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isPeeking
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            size: 16.0,
                            color: isPeeking ? cs.onPrimary : cs.primary,
                          ),
                        ),
                        const SizedBox(width: 6.0),
                        Text(
                          l10n.peekCanvas,
                          style: TextStyle(
                            fontSize: 12.0,
                            fontWeight: FontWeight.bold,
                            color: isPeeking ? cs.onPrimary : cs.onSurface,
                          ),
                        ),
                      ],
                    )
                  : Center(
                      child: Container(
                        width: 26.0,
                        height: 26.0,
                        decoration: BoxDecoration(
                          color: isPeeking
                              ? cs.onPrimary.withValues(alpha: 0.22)
                              : cs.primary.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isPeeking
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          size: 16.0,
                          color: isPeeking ? cs.onPrimary : cs.primary,
                        ),
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Slender vertical navigation spine for Touch Mode.
///
/// Provides rapid 1-tap direct inter-section jumps across all 7 panel categories
/// without forcing the user through the nested `Back -> Menu -> Category` drill-down loop.
/// Adapts gracefully to both portrait drawers and docked landscape side sheets with zero overflow.
class _TouchSectionSpine extends StatelessWidget {
  const _TouchSectionSpine({
    required this.activeSection,
    required this.onSectionSelected,
    required this.shouldTransparentize,
  });

  final SettingsSection activeSection;
  final ValueChanged<SettingsSection> onSectionSelected;
  final bool shouldTransparentize;

  static const List<_SpineItem> _items = [
    _SpineItem(
      section: SettingsSection.mainMenu,
      icon: Icons.grid_view_rounded,
    ),
    _SpineItem(
      section: SettingsSection.profiles,
      icon: Icons.queue_music_rounded,
    ),
    _SpineItem(
      section: SettingsSection.pageSetup,
      icon: Icons.description_outlined,
    ),
    _SpineItem(
      section: SettingsSection.scoreTypography,
      icon: Icons.title_rounded,
    ),
    _SpineItem(
      section: SettingsSection.margins,
      icon: Icons.space_dashboard_outlined,
    ),
    _SpineItem(
      section: SettingsSection.staffSpacing,
      icon: Icons.format_line_spacing_rounded,
    ),
    _SpineItem(
      section: SettingsSection.systemHierarchy,
      icon: Icons.account_tree_outlined,
    ),
    _SpineItem(
      section: SettingsSection.export,
      icon: Icons.ios_share_rounded,
    ),
  ];

  String _getSectionLabel(
    SettingsSection section,
    AppLocalizations l10n,
    bool isFa,
  ) {
    switch (section) {
      case SettingsSection.mainMenu:
        return isFa ? 'منوی اصلی' : 'Main Menu';
      case SettingsSection.profiles:
        return l10n.headerEnsembleProfiles;
      case SettingsSection.pageSetup:
        return l10n.pageSettings;
      case SettingsSection.scoreTypography:
        return l10n.sectionScoreTypography;
      case SettingsSection.margins:
        return l10n.marginsLabel;
      case SettingsSection.staffSpacing:
        return l10n.staffSpacing;
      case SettingsSection.systemHierarchy:
        return l10n.systemHierarchy;
      case SettingsSection.export:
        return l10n.exportManuscriptTitle;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final isFa = Localizations.localeOf(context).languageCode == 'fa';

    return Container(
      width: 42.0,
      decoration: BoxDecoration(
        color: shouldTransparentize
            ? Colors.transparent
            : cs.surfaceContainerHighest.withValues(alpha: 0.16),
      ),
      child: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: CustomPaint(
            painter: _SpineTrackPainter(
              color: shouldTransparentize
                  ? Colors.transparent
                  : cs.outlineVariant.withValues(alpha: 0.35),
              trackWidth: 1.5,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (int i = 0; i < _items.length; i++) ...[
                  if (i > 0) const SizedBox(height: 6.0),
                  _buildBead(context, _items[i], cs, l10n, isFa),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBead(
    BuildContext context,
    _SpineItem item,
    ColorScheme cs,
    AppLocalizations l10n,
    bool isFa,
  ) {
    final isActive = item.section == activeSection;
    final label = _getSectionLabel(item.section, l10n, isFa);

    return Tooltip(
      message: label,
      preferBelow: false,
      verticalOffset: 16,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: ValueKey('touch_spine_${item.section.name}'),
          borderRadius: BorderRadius.circular(8.0),
          onTap: () {
            HapticFeedback.selectionClick();
            onSectionSelected(item.section);
          },
          child: Container(
            width: 38.0,
            height: 34.0,
            alignment: Alignment.center,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeOutCubic,
              width: 28.0,
              height: 28.0,
              decoration: BoxDecoration(
                color: isActive
                    ? cs.primary
                    : (shouldTransparentize
                        ? Colors.transparent
                        : cs.surfaceContainerHighest.withValues(alpha: 0.45)),
                borderRadius: BorderRadius.circular(8.0),
                border: isActive
                    ? null
                    : Border.all(
                        color: shouldTransparentize
                            ? Colors.transparent
                            : cs.outlineVariant.withValues(alpha: 0.35),
                        width: 1.0,
                      ),
                boxShadow: isActive && !shouldTransparentize
                    ? [
                        BoxShadow(
                          color: cs.primary.withValues(alpha: 0.35),
                          blurRadius: 6.0,
                          offset: const Offset(0, 1.5),
                        ),
                      ]
                    : null,
              ),
              child: Icon(
                item.icon,
                size: isActive ? 16.5 : 15.5,
                color: isActive
                    ? cs.onPrimary
                    : cs.onSurfaceVariant.withValues(
                        alpha: shouldTransparentize ? 0.3 : 0.85,
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SpineItem {
  const _SpineItem({
    required this.section,
    required this.icon,
  });

  final SettingsSection section;
  final IconData icon;
}

class _SpineTrackPainter extends CustomPainter {
  const _SpineTrackPainter({
    required this.color,
    required this.trackWidth,
  });

  final Color color;
  final double trackWidth;

  @override
  void paint(Canvas canvas, Size size) {
    if (color.a == 0.0 || size.height <= 36.0) return;
    final paint = Paint()
      ..color = color
      ..strokeWidth = trackWidth
      ..strokeCap = StrokeCap.round;

    final centerX = size.width / 2.0;
    canvas.drawLine(
      Offset(centerX, 17.0),
      Offset(centerX, size.height - 17.0),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _SpineTrackPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.trackWidth != trackWidth;
  }
}
