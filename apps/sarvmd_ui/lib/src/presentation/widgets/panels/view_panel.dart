import 'package:flutter/material.dart';
import '../common/property_row.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_metrics.dart';
import '../../../core/theme/app_theme.dart';
import '../common/section_header.dart';
import '../common/integrated_scale_control.dart';
import '../common/guide_toggle.dart';
import '../common/language_switch_control.dart';
import '../animations/fade_in_slide.dart';
import 'export_panel.dart';
import '../../../logic/view/view_state.dart';
import '../../../logic/view/view_cubit.dart';
import '../../../l10n/app_localizations.dart';

class ViewPanel extends StatelessWidget {
  const ViewPanel({
    super.key,
    required this.transformationController,
    required this.onZoomPreset,
    this.isEmbedded = false,
  });

  final TransformationController transformationController;
  final ValueChanged<ZoomPreset> onZoomPreset;
  final bool isEmbedded;

  @override
  Widget build(BuildContext context) {
    final viewCubit = context.read<ViewCubit>();

    final isFa = Localizations.localeOf(context).languageCode == 'fa';
    final panelTextDir = isFa ? TextDirection.rtl : TextDirection.ltr;

    if (isEmbedded) {
      return Directionality(
        textDirection: panelTextDir,
        child: BlocBuilder<ViewCubit, ViewState>(
          builder: (context, viewState) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                SectionHeader(title: AppLocalizations.of(context)!.appearance),
                const SizedBox(height: AppSpacing.itemGapSmall),
                _AppearanceSettings(
                  themeMode: viewState.themeMode,
                  accent: viewState.accent,
                  onThemeModeChanged: viewCubit.updateThemeMode,
                  onAccentChanged: viewCubit.updateAccent,
                ),
                const SizedBox(height: AppSpacing.sectionGap),
                SectionHeader(title: AppLocalizations.of(context)!.pageArrangementSection),
                const SizedBox(height: AppSpacing.itemGapSmall),
                _PageArrangementControl(
                  current: viewState.pageArrangement,
                  gridColumns: viewState.gridColumns,
                  autoFocusOnPageChange: viewState.autoFocusOnPageChange,
                  pageSwipeGestures: viewState.pageSwipeGestures,
                  onArrangementChanged: viewCubit.setPageArrangement,
                  onGridColumnsChanged: viewCubit.setGridColumns,
                  onAutoFocusChanged: viewCubit.setAutoFocusOnPageChange,
                  onPageSwipeGesturesChanged: viewCubit.setPageSwipeGestures,
                ),
              ],
            );
          },
        ),
      );
    }
    return Directionality(
      textDirection: panelTextDir,
      child: Container(
        color: Theme.of(context).colorScheme.surfaceContainer,
        child: Column(
          children: [
            Expanded(
              child: BlocBuilder<ViewCubit, ViewState>(
                builder: (context, viewState) {
                  return ListView(
                    key: const PageStorageKey('pointer_view_panel_scroll'),
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.paddingLarge),
                    children: [
                      const SizedBox(height: 48),
                      FadeInSlide(
                        delay: 0,
                        child: PropertyRow(
                          label: Text(
                            AppLocalizations.of(context)!.view,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2,
                            ),
                          ),
                          control: const LanguageToggleButton(),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sectionGap),
                      FadeInSlide(
                          delay: 1,
                          child: SectionHeader(
                              title: AppLocalizations.of(context)!.appearance)),
                      FadeInSlide(
                        delay: 2,
                        child: _AppearanceSettings(
                          themeMode: viewState.themeMode,
                          accent: viewState.accent,
                          onThemeModeChanged: viewCubit.updateThemeMode,
                          onAccentChanged: viewCubit.updateAccent,
                        ),
                      ),
                      const FadeInSlide(
                        delay: 3,
                        child: Divider(height: 32),
                      ),
                      FadeInSlide(
                        delay: 4,
                        child: SectionHeader(
                          title: AppLocalizations.of(context)!.pageArrangementSection,
                        ),
                      ),
                      FadeInSlide(
                        delay: 5,
                        child: _PageArrangementControl(
                          current: viewState.pageArrangement,
                          gridColumns: viewState.gridColumns,
                          autoFocusOnPageChange: viewState.autoFocusOnPageChange,
                          pageSwipeGestures: viewState.pageSwipeGestures,
                          onArrangementChanged: viewCubit.setPageArrangement,
                          onGridColumnsChanged: viewCubit.setGridColumns,
                          onAutoFocusChanged: viewCubit.setAutoFocusOnPageChange,
                          onPageSwipeGesturesChanged: viewCubit.setPageSwipeGestures,
                        ),
                      ),
                      const FadeInSlide(
                        delay: 6,
                        child: Divider(height: 32),
                      ),
                      FadeInSlide(
                          delay: 7, child: SectionHeader(title: AppLocalizations.of(context)!.zoom)),
                      FadeInSlide(
                        delay: 8,
                        child: IntegratedScaleControl(
                          viewState: viewState,
                          viewCubit: viewCubit,
                          transformationController: transformationController,
                          onZoomPreset: onZoomPreset,
                        ),
                      ),
                      const FadeInSlide(
                        delay: 9,
                        child: Divider(height: 32),
                      ),
                      FadeInSlide(
                          delay: 10, child: SectionHeader(title: AppLocalizations.of(context)!.guides)),
                      FadeInSlide(
                        delay: 11,
                        child: Column(
                          children: [
                            GuideToggle(
                              label: AppLocalizations.of(context)!.mouseWings,
                              value:
                                  viewState.isGuideActive(GuideType.rulerWings),
                              onChanged: (v) => viewCubit.toggleGuide(
                                  GuideType.rulerWings, v ?? false),
                            ),
                            GuideToggle(
                              label: AppLocalizations.of(context)!.paperEdges,
                              value:
                                  viewState.isGuideActive(GuideType.paperEdges),
                              onChanged: (v) => viewCubit.toggleGuide(
                                  GuideType.paperEdges, v ?? false),
                            ),
                            GuideToggle(
                              label: AppLocalizations.of(context)!.paperCenters,
                              value:
                                  viewState.isGuideActive(GuideType.paperCenters),
                              onChanged: (v) => viewCubit.toggleGuide(
                                  GuideType.paperCenters, v ?? false),
                            ),
                            GuideToggle(
                              label: AppLocalizations.of(context)!.documentMargins,
                              value: viewState.isGuideActive(GuideType.margins),
                              onChanged: (v) => viewCubit.toggleGuide(
                                  GuideType.margins, v ?? false),
                            ),
                            GuideToggle(
                              label: AppLocalizations.of(context)!.staffBounds,
                              value:
                                  viewState.isGuideActive(GuideType.staffBounds),
                              onChanged: (v) => viewCubit.toggleGuide(
                                  GuideType.staffBounds, v ?? false),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  );
                },
              ),
            ),
            const FadeInSlide(
              delay: 3,
              child: ExportPanel(),
            ),
          ],
        ),
      ),
    );
  }
}

class _AppearanceSettings extends StatelessWidget {
  const _AppearanceSettings({
    required this.themeMode,
    required this.accent,
    required this.onThemeModeChanged,
    required this.onAccentChanged,
  });

  final ThemeMode themeMode;
  final SarvAccent accent;
  final ValueChanged<ThemeMode> onThemeModeChanged;
  final ValueChanged<SarvAccent> onAccentChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ThemeModeSwitcher(
          current: themeMode,
          onChanged: onThemeModeChanged,
        ),
        const SizedBox(height: AppSpacing.itemGap),
        _AccentPillPicker(
          selected: accent,
          onChanged: onAccentChanged,
        ),
      ],
    );
  }
}

class _ThemeModeSwitcher extends StatelessWidget {
  const _ThemeModeSwitcher({
    required this.current,
    required this.onChanged,
  });

  final ThemeMode current;
  final ValueChanged<ThemeMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final int selectedIndex = switch (current) {
      ThemeMode.light => 0,
      ThemeMode.dark => 1,
      ThemeMode.system => 2,
    };

    return Container(
      height: 40,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colorScheme.onSurface.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double segmentWidth = (constraints.maxWidth) / 3;
          return Stack(
            children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                left: selectedIndex * segmentWidth,
                width: segmentWidth,
                height: 32,
                child: Container(
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
              Row(
                children: [
                  _ThemeOption(
                    icon: Icons.light_mode_outlined,
                    activeIcon: Icons.light_mode,
                    isSelected: current == ThemeMode.light,
                    onTap: () => onChanged(ThemeMode.light),
                  ),
                  _ThemeOption(
                    icon: Icons.dark_mode_outlined,
                    activeIcon: Icons.dark_mode,
                    isSelected: current == ThemeMode.dark,
                    onTap: () => onChanged(ThemeMode.dark),
                  ),
                  _ThemeOption(
                    icon: Icons.brightness_auto_outlined,
                    activeIcon: Icons.brightness_auto,
                    isSelected: current == ThemeMode.system,
                    onTap: () => onChanged(ThemeMode.system),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  const _ThemeOption({
    required this.icon,
    required this.activeIcon,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final IconData activeIcon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Center(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Icon(
              isSelected ? activeIcon : icon,
              key: ValueKey(isSelected),
              size: 18,
              color: isSelected
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
            ),
          ),
        ),
      ),
    );
  }
}

class _AccentPillPicker extends StatefulWidget {
  const _AccentPillPicker({
    required this.selected,
    required this.onChanged,
  });

  final SarvAccent selected;
  final ValueChanged<SarvAccent> onChanged;

  @override
  State<_AccentPillPicker> createState() => _AccentPillPickerState();
}

class _AccentPillPickerState extends State<_AccentPillPicker>
    with SingleTickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: SarvAccent.values.map((a) {
        final isSelected = a == widget.selected;
        return GestureDetector(
          onTap: () => widget.onChanged(a),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: isSelected
                  ? a.pastelContainer
                  : a.seed.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? a.primary : Colors.transparent,
                width: 1.5,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: a.primary.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? a.onPastelContainer
                        : a.primary.withValues(alpha: 0.4),
                    shape: BoxShape.circle,
                  ),
                ),
                ClipRect(
                  child: AnimatedSize(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutBack,
                    child: SizedBox(
                      width: isSelected ? null : 0,
                      child: isSelected
                          ? Padding(
                              padding:
                                  const EdgeInsetsDirectional.only(start: 8),
                              child: Text(
                                a.label,
                                maxLines: 1,
                                overflow: TextOverflow.clip,
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: a.onPastelContainer,
                                    ),
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _PageArrangementControl extends StatelessWidget {
  const _PageArrangementControl({
    required this.current,
    required this.gridColumns,
    this.autoFocusOnPageChange = true,
    this.pageSwipeGestures = true,
    required this.onArrangementChanged,
    required this.onGridColumnsChanged,
    this.onAutoFocusChanged,
    this.onPageSwipeGesturesChanged,
  });

  final PageArrangementMode current;
  final int gridColumns;
  final bool autoFocusOnPageChange;
  final bool pageSwipeGestures;
  final ValueChanged<PageArrangementMode> onArrangementChanged;
  final ValueChanged<int> onGridColumnsChanged;
  final ValueChanged<bool>? onAutoFocusChanged;
  final ValueChanged<bool>? onPageSwipeGesturesChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final int selectedIndex = switch (current) {
      PageArrangementMode.single => 0,
      PageArrangementMode.facingSpread => 1,
      PageArrangementMode.continuousVertical => 2,
      PageArrangementMode.continuousHorizontal => 3,
      PageArrangementMode.grid => 4,
    };

    final String modeTitle = switch (current) {
      PageArrangementMode.single => l10n.pageArrangementSingle,
      PageArrangementMode.facingSpread => l10n.pageArrangementFacing,
      PageArrangementMode.continuousVertical => l10n.pageArrangementContinuousVertical,
      PageArrangementMode.continuousHorizontal => l10n.pageArrangementContinuousHorizontal,
      PageArrangementMode.grid => l10n.pageArrangementGrid,
    };

    final String modeDesc = switch (current) {
      PageArrangementMode.single => l10n.pageArrangementSingleDesc,
      PageArrangementMode.facingSpread => l10n.pageArrangementFacingDesc,
      PageArrangementMode.continuousVertical => l10n.pageArrangementContinuousVerticalDesc,
      PageArrangementMode.continuousHorizontal => l10n.pageArrangementContinuousHorizontalDesc,
      PageArrangementMode.grid => l10n.pageArrangementGridDesc,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 40,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: cs.onSurface.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final double segmentWidth = constraints.maxWidth / 5;
              return Stack(
                children: [
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOutCubic,
                    left: selectedIndex * segmentWidth,
                    width: segmentWidth,
                    height: 32,
                    child: Container(
                      decoration: BoxDecoration(
                        color: cs.surface,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      _ArrangementOption(
                        icon: Icons.crop_portrait_rounded,
                        tooltip: l10n.pageArrangementSingle,
                        isSelected: current == PageArrangementMode.single,
                        onTap: () => onArrangementChanged(PageArrangementMode.single),
                      ),
                      _ArrangementOption(
                        icon: Icons.auto_stories_rounded,
                        tooltip: l10n.pageArrangementFacing,
                        isSelected: current == PageArrangementMode.facingSpread,
                        onTap: () => onArrangementChanged(PageArrangementMode.facingSpread),
                      ),
                      _ArrangementOption(
                        icon: Icons.view_day_rounded,
                        tooltip: l10n.pageArrangementContinuousVertical,
                        isSelected: current == PageArrangementMode.continuousVertical,
                        onTap: () => onArrangementChanged(PageArrangementMode.continuousVertical),
                      ),
                      _ArrangementOption(
                        icon: Icons.view_column_rounded,
                        tooltip: l10n.pageArrangementContinuousHorizontal,
                        isSelected: current == PageArrangementMode.continuousHorizontal,
                        onTap: () => onArrangementChanged(PageArrangementMode.continuousHorizontal),
                      ),
                      _ArrangementOption(
                        icon: Icons.grid_view_rounded,
                        tooltip: l10n.pageArrangementGrid,
                        isSelected: current == PageArrangementMode.grid,
                        onTap: () => onArrangementChanged(PageArrangementMode.grid),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Text(
          modeTitle,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: cs.primary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          modeDesc,
          style: TextStyle(
            fontSize: 11,
            color: cs.onSurfaceVariant.withValues(alpha: 0.7),
          ),
        ),
        if (current == PageArrangementMode.grid) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: cs.outlineVariant.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.pageArrangementColumnsLabel,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.remove_rounded, size: 16),
                  onPressed: gridColumns > 1
                      ? () => onGridColumnsChanged(gridColumns - 1)
                      : null,
                  visualDensity: VisualDensity.compact,
                  splashRadius: 16,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text(
                    l10n.pageArrangementColumnsCount(gridColumns),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: cs.primary,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_rounded, size: 16),
                  onPressed: gridColumns < 6
                      ? () => onGridColumnsChanged(gridColumns + 1)
                      : null,
                  visualDensity: VisualDensity.compact,
                  splashRadius: 16,
                ),
              ],
            ),
          ),
        ],
        if (onAutoFocusChanged != null) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: cs.outlineVariant.withValues(alpha: 0.25),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Tooltip(
                    message: l10n.autoFocusOnPageChangeTooltip,
                    child: Text(
                      l10n.autoFocusOnPageChange,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                  ),
                ),
                Transform.scale(
                  scale: 0.8,
                  child: Switch(
                    value: autoFocusOnPageChange,
                    onChanged: onAutoFocusChanged,
                  ),
                ),
              ],
            ),
          ),
          if (onPageSwipeGesturesChanged != null)
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: cs.outlineVariant.withValues(alpha: 0.25),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Tooltip(
                      message: l10n.pageSwipeGesturesTooltip,
                      child: Text(
                        l10n.pageSwipeGestures,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ),
                  Transform.scale(
                    scale: 0.8,
                    child: Switch(
                      value: pageSwipeGestures,
                      onChanged: onPageSwipeGesturesChanged,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ],
    );
  }
}

class _ArrangementOption extends StatelessWidget {
  const _ArrangementOption({
    required this.icon,
    required this.tooltip,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Expanded(
      child: Tooltip(
        message: tooltip,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Center(
            child: Icon(
              icon,
              size: 18,
              color: isSelected ? cs.primary : cs.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}
