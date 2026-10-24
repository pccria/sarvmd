import 'package:flutter/material.dart';
import 'package:sarvmd_core/sarvmd_core.dart' as core;
import '../../../core/theme/app_metrics.dart';
import '../../../core/utils/unit_formatter.dart';
import '../common/dropdown_setting.dart';
import '../../../l10n/app_localizations.dart';
import '../../../logic/view/view_state.dart';

class DocumentSettingsGroup extends StatelessWidget {
  const DocumentSettingsGroup({
    super.key,
    required this.pageSize,
    required this.onPageSizeChanged,
    required this.orientation,
    required this.onOrientationChanged,
    this.pageCount = 1,
    this.onPageCountChanged,
    this.arrangementMode = PageArrangementMode.single,
    this.onArrangementModeChanged,
    this.gridColumns = 2,
    this.onGridColumnsChanged,
    this.autoFocusOnPageChange = true,
    this.onAutoFocusChanged,
    this.pageSwipeGestures = true,
    this.onPageSwipeGesturesChanged,
  });

  final core.PageSize pageSize;
  final ValueChanged<core.PageSize> onPageSizeChanged;
  final core.PageOrientation orientation;
  final ValueChanged<core.PageOrientation> onOrientationChanged;
  final int pageCount;
  final ValueChanged<int>? onPageCountChanged;
  final PageArrangementMode arrangementMode;
  final ValueChanged<PageArrangementMode>? onArrangementModeChanged;
  final int gridColumns;
  final ValueChanged<int>? onGridColumnsChanged;
  final bool autoFocusOnPageChange;
  final ValueChanged<bool>? onAutoFocusChanged;
  final bool pageSwipeGestures;
  final ValueChanged<bool>? onPageSwipeGesturesChanged;

  @override
  Widget build(BuildContext context) => Column(
        spacing: 12.0,
        children: [
          DropdownSetting<core.PageSize>(
            value: pageSize,
            options: core.PageSize.values,
            onChanged: onPageSizeChanged,
            labelMapper: (size) {
              final isPortrait = orientation == core.PageOrientation.portrait;
              final w = isPortrait ? size.width : size.height;
              final h = isPortrait ? size.height : size.width;
              return '${size.name.toUpperCase()}  (${UnitFormatter.formatDimensions(w, h)})';
            },
          ),
          OrientationSwitcher(
            current: orientation,
            onChanged: onOrientationChanged,
          ),
          if (onPageCountChanged != null)
            _PageCountRow(
              pageCount: pageCount,
              onChanged: onPageCountChanged!,
            ),
          if (onArrangementModeChanged != null)
            _PageArrangementGroup(
              arrangementMode: arrangementMode,
              onArrangementModeChanged: onArrangementModeChanged!,
              gridColumns: gridColumns,
              onGridColumnsChanged: onGridColumnsChanged,
              autoFocusOnPageChange: autoFocusOnPageChange,
              onAutoFocusChanged: onAutoFocusChanged,
              pageSwipeGestures: pageSwipeGestures,
              onPageSwipeGesturesChanged: onPageSwipeGesturesChanged,
            ),
        ],
      );
}

class _PageCountRow extends StatelessWidget {
  const _PageCountRow({
    required this.pageCount,
    required this.onChanged,
  });

  final int pageCount;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: cs.onSurface.withValues(alpha: AppOpacities.border),
        borderRadius: BorderRadius.circular(10.0),
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 8.0,
        children: [
          Row(
            children: [
              Icon(Icons.auto_stories_outlined, size: 18.0, color: cs.primary),
              const SizedBox(width: 8.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.documentPageCountLabel,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      l10n.documentPageCountDesc,
                      style: TextStyle(
                        fontSize: 10.5,
                        color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove_rounded, size: 16.0),
                    onPressed:
                        pageCount > 1 ? () => onChanged(pageCount - 1) : null,
                    visualDensity: VisualDensity.compact,
                    splashRadius: 16.0,
                  ),
                  Container(
                    constraints: const BoxConstraints(minWidth: 28.0),
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6.0, vertical: 2.0),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(6.0),
                    ),
                    child: Text(
                      '$pageCount',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                        color: cs.primary,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_rounded, size: 16.0),
                    onPressed:
                        pageCount < 100 ? () => onChanged(pageCount + 1) : null,
                    visualDensity: VisualDensity.compact,
                    splashRadius: 16.0,
                  ),
                ],
              ),
            ],
          ),
          // Preset Quick Chips
          Row(
            spacing: 6.0,
            children: [1, 2, 4, 8].map((count) {
              final isSelected = pageCount == count;
              return Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(6.0),
                  onTap: () => onChanged(count),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? cs.primary
                          : cs.surfaceContainerHighest.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(6.0),
                      border: Border.all(
                        color: isSelected
                            ? cs.primary
                            : cs.outlineVariant.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      '$count',
                      style: TextStyle(
                        fontSize: 11.0,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected ? cs.onPrimary : cs.onSurface,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class OrientationSwitcher extends StatelessWidget {
  const OrientationSwitcher({
    super.key,
    required this.current,
    required this.onChanged,
  });

  final core.PageOrientation current;
  final ValueChanged<core.PageOrientation> onChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final int selectedIndex = current == core.PageOrientation.portrait ? 0 : 1;

    return Container(
      height: 40,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colorScheme.onSurface.withValues(alpha: AppOpacities.border),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double segmentWidth = (constraints.maxWidth) / 2;
          return Stack(
            children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 300),
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
                  _OrientationOption(
                    orientation: core.PageOrientation.portrait,
                    label: AppLocalizations.of(context)!.portrait,
                    isSelected: current == core.PageOrientation.portrait,
                    onTap: () => onChanged(core.PageOrientation.portrait),
                  ),
                  _OrientationOption(
                    orientation: core.PageOrientation.landscape,
                    label: AppLocalizations.of(context)!.landscape,
                    isSelected: current == core.PageOrientation.landscape,
                    onTap: () => onChanged(core.PageOrientation.landscape),
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

class _OrientationOption extends StatelessWidget {
  const _OrientationOption({
    required this.orientation,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final core.PageOrientation orientation;
  final String label;
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
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: _MiniPaperOrientationIcon(
                  key: ValueKey(isSelected),
                  orientation: orientation,
                  isSelected: isSelected,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                label.toUpperCase(),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      letterSpacing: 0.8,
                      fontWeight:
                          isSelected ? FontWeight.w800 : FontWeight.w600,
                      color: isSelected
                          ? colorScheme.onSurface
                          : colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniPaperOrientationIcon extends StatelessWidget {
  const _MiniPaperOrientationIcon({
    super.key,
    required this.orientation,
    required this.isSelected,
  });

  final core.PageOrientation orientation;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isPortrait = orientation == core.PageOrientation.portrait;

    final color = isSelected
        ? colorScheme.primary
        : colorScheme.onSurfaceVariant.withValues(alpha: 0.6);

    return Container(
      width: isPortrait ? 12 : 16,
      height: isPortrait ? 16 : 12,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(2),
        border: Border.all(color: color, width: 1.2),
        color: isSelected ? color.withValues(alpha: 0.1) : Colors.transparent,
      ),
      padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(
          3,
          (_) => Container(
            height: 0.8,
            width: double.infinity,
            color: color.withValues(alpha: 0.5),
          ),
        ),
      ),
    );
  }
}

class _PageArrangementGroup extends StatelessWidget {
  const _PageArrangementGroup({
    required this.arrangementMode,
    required this.onArrangementModeChanged,
    required this.gridColumns,
    this.onGridColumnsChanged,
    this.autoFocusOnPageChange = true,
    this.onAutoFocusChanged,
    this.pageSwipeGestures = true,
    this.onPageSwipeGesturesChanged,
  });

  final PageArrangementMode arrangementMode;
  final ValueChanged<PageArrangementMode> onArrangementModeChanged;
  final int gridColumns;
  final ValueChanged<int>? onGridColumnsChanged;
  final bool autoFocusOnPageChange;
  final ValueChanged<bool>? onAutoFocusChanged;
  final bool pageSwipeGestures;
  final ValueChanged<bool>? onPageSwipeGesturesChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    final modes = [
      (PageArrangementMode.single, Icons.crop_portrait_rounded, l10n.pageArrangementSingle),
      (PageArrangementMode.facingSpread, Icons.auto_stories_rounded, l10n.pageArrangementFacing),
      (PageArrangementMode.continuousVertical, Icons.view_day_rounded, l10n.pageArrangementContinuousVertical),
      (PageArrangementMode.continuousHorizontal, Icons.view_column_rounded, l10n.pageArrangementContinuousHorizontal),
      (PageArrangementMode.grid, Icons.grid_view_rounded, l10n.pageArrangementGrid),
    ];

    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 10.0,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome_mosaic_outlined, size: 16.0, color: cs.primary),
              const SizedBox(width: 6.0),
              Text(
                l10n.pageArrangementSection,
                style: const TextStyle(fontSize: 12.0, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          Wrap(
            spacing: 6.0,
            runSpacing: 6.0,
            children: modes.map((m) {
              final isSelected = m.$1 == arrangementMode;
              return ChoiceChip(
                showCheckmark: false,
                avatar: Icon(
                  m.$2,
                  size: 14.0,
                  color: isSelected ? cs.onPrimary : cs.onSurfaceVariant,
                ),
                label: Text(
                  m.$3,
                  style: TextStyle(
                    fontSize: 11.0,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                selected: isSelected,
                selectedColor: cs.primary,
                labelStyle: TextStyle(
                  color: isSelected ? cs.onPrimary : cs.onSurface,
                ),
                onSelected: (_) => onArrangementModeChanged(m.$1),
                visualDensity: VisualDensity.compact,
              );
            }).toList(),
          ),
          if (arrangementMode == PageArrangementMode.grid && onGridColumnsChanged != null)
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.pageArrangementColumnsLabel,
                    style: const TextStyle(fontSize: 11.0),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.remove_rounded, size: 16.0),
                  onPressed: gridColumns > 1
                      ? () => onGridColumnsChanged!(gridColumns - 1)
                      : null,
                  visualDensity: VisualDensity.compact,
                  splashRadius: 16.0,
                ),
                Text(
                  l10n.pageArrangementColumnsCount(gridColumns),
                  style: TextStyle(
                    fontSize: 11.0,
                    fontWeight: FontWeight.bold,
                    color: cs.primary,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_rounded, size: 16.0),
                  onPressed: gridColumns < 6
                      ? () => onGridColumnsChanged!(gridColumns + 1)
                      : null,
                  visualDensity: VisualDensity.compact,
                  splashRadius: 16.0,
                ),
              ],
            ),
          if (onAutoFocusChanged != null)
            Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Row(
                children: [
                  Expanded(
                    child: Tooltip(
                      message: l10n.autoFocusOnPageChangeTooltip,
                      child: Text(
                        l10n.autoFocusOnPageChange,
                        style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w500),
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
            Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Row(
                children: [
                  Expanded(
                    child: Tooltip(
                      message: l10n.pageSwipeGesturesTooltip,
                      child: Text(
                        l10n.pageSwipeGestures,
                        style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w500),
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
      ),
    );
  }
}
