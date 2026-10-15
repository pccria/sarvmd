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
import '../staff/staff_spacing_group.dart';
import '../../../logic/view/view_state.dart';
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
                  color: isScrubbing
                      ? Colors.transparent
                      : cs.surfaceContainerHigh,
                  border: isScrubbing
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

                    // Controls (Glance, Language & Theme)
                    const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GlanceButton(showLabel: false, compact: true),
                        SizedBox(width: 6.0),
                        TouchLanguageButton(),
                        SizedBox(width: 4.0),
                        TouchThemeButton(),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Drawer Body Content
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                child: currentSection == SettingsSection.mainMenu
                    ? _buildMainMenu(context, cs, l10n)
                    : _buildSectionContent(
                        context, cs, l10n, sectionTextDir, currentSection),
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
            opacity: isScrubbing ? 0.18 : 1.0,
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

    final actualWidth = widget.isPanelDocked ? 320.0 : drawerWidth.clamp(280.0, 420.0);
    final peekSlideFraction = (actualWidth - 56.0) / actualWidth;

    if (widget.isPanelDocked) {
      return AnimatedSlide(
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutCubic,
        offset: isPeeking ? Offset(-peekSlideFraction, 0) : Offset.zero,
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Material(
            color: isScrubbing
                ? Colors.transparent
                : cs.surfaceContainerLow,
            elevation: (isScrubbing || isPeeking) ? 0.0 : 6.0,
            shadowColor: isScrubbing
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
    }

    return AnimatedSlide(
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOutCubic,
      offset: isPeeking ? Offset(-peekSlideFraction, 0) : Offset.zero,
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: SizedBox(
          width: actualWidth,
          child: Drawer(
            backgroundColor: isScrubbing
                ? Colors.transparent
                : cs.surfaceContainerLow,
            elevation: (isScrubbing || isPeeking) ? 0.0 : 6.0,
            child: inner,
          ),
        ),
      ),
    );
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
    SettingsSection currentSection,
  ) {
    String title = '';
    Widget body = const SizedBox.shrink();

    final docState = context.watch<DocumentCubit>().state;
    final cubit = context.read<DocumentCubit>();
    final config = docState.config;
    final isScrubbing = context.watch<ViewCubit>().state.isScrubbing;

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
            color: isScrubbing
                ? Colors.transparent
                : cs.surfaceContainerHigh.withValues(alpha: 0.5),
            border: isScrubbing
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
              const SizedBox(width: 8.0),
              const GlanceButton(showLabel: true, compact: true),
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
          color: isPeeking
              ? cs.primary
              : cs.primary.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(16.0),
          child: InkWell(
            borderRadius: BorderRadius.circular(16.0),
            onTap: () {}, // Handled by Listener for 0ms latency
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: widget.showLabel ? 10.0 : 8.0,
                vertical: widget.compact ? 4.0 : 6.0,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16.0),
                border: Border.all(
                  color: isPeeking
                      ? cs.primary
                      : cs.primary.withValues(alpha: 0.35),
                  width: 1.0,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isPeeking
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    size: 15.0,
                    color: isPeeking ? cs.onPrimary : cs.primary,
                  ),
                  if (widget.showLabel) ...[
                    const SizedBox(width: 5.0),
                    Text(
                      l10n.peekCanvas,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: isPeeking ? cs.onPrimary : cs.primary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
