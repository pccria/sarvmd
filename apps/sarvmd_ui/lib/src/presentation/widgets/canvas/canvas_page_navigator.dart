// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Licensed under the Business Source License 1.1 (BUSL-1.1).

import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';
import '../../../logic/view/view_state.dart';

/// Floating, glassmorphic multi-page navigator and sheet manager.
///
/// Provides quick pagination controls (< Page X of Y >), sheet increment (+),
/// sheet decrement (-), and arrangement switcher directly on the scoring canvas.
class CanvasPageNavigator extends StatelessWidget {
  const CanvasPageNavigator({
    super.key,
    required this.currentPageIndex,
    required this.pageCount,
    required this.onPageChanged,
    required this.onAddPage,
    required this.onRemovePage,
    this.arrangementMode = PageArrangementMode.single,
    this.onArrangementModeChanged,
    this.autoFocusOnPageChange = true,
    this.onAutoFocusChanged,
  });

  final int currentPageIndex;
  final int pageCount;
  final ValueChanged<int> onPageChanged;
  final VoidCallback onAddPage;
  final VoidCallback onRemovePage;
  final PageArrangementMode arrangementMode;
  final ValueChanged<PageArrangementMode>? onArrangementModeChanged;
  final bool autoFocusOnPageChange;
  final ValueChanged<bool>? onAutoFocusChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    final hasPrev = currentPageIndex > 0;
    final hasNext = currentPageIndex < pageCount - 1;
    final canRemove = pageCount > 1;

    return ClipRRect(
      borderRadius: BorderRadius.circular(24.0),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
          decoration: BoxDecoration(
            color: cs.surface.withValues(alpha: 0.88),
            borderRadius: BorderRadius.circular(24.0),
            border: Border.all(
              color: cs.outlineVariant.withValues(alpha: 0.4),
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 16.0,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Previous Page Button
              IconButton(
                icon: const Icon(Icons.chevron_left_rounded, size: 20.0),
                tooltip: l10n.pageNavigatorPrevTooltip,
                onPressed: hasPrev ? () => onPageChanged(currentPageIndex - 1) : null,
                visualDensity: VisualDensity.compact,
                splashRadius: 18.0,
              ),

              // Page Indicator Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
                decoration: BoxDecoration(
                  color: cs.primaryContainer.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Text(
                  l10n.pageNavigatorPageOf(currentPageIndex + 1, pageCount),
                  style: TextStyle(
                    fontSize: 12.0,
                    fontWeight: FontWeight.bold,
                    color: cs.primary,
                  ),
                ),
              ),

              // Next Page Button
              IconButton(
                icon: const Icon(Icons.chevron_right_rounded, size: 20.0),
                tooltip: l10n.pageNavigatorNextTooltip,
                onPressed: hasNext ? () => onPageChanged(currentPageIndex + 1) : null,
                visualDensity: VisualDensity.compact,
                splashRadius: 18.0,
              ),

              // Vertical Divider
              Container(
                height: 18.0,
                width: 1.0,
                margin: const EdgeInsets.symmetric(horizontal: 2.0),
                color: cs.outlineVariant.withValues(alpha: 0.4),
              ),

              // Add Page (+) Button
              IconButton(
                icon: const Icon(Icons.add_rounded, size: 18.0),
                tooltip: l10n.pageNavigatorAddPageTooltip,
                onPressed: onAddPage,
                visualDensity: VisualDensity.compact,
                splashRadius: 18.0,
              ),

              // Remove Page (-) Button
              if (canRemove)
                IconButton(
                  icon: const Icon(Icons.remove_rounded, size: 18.0),
                  tooltip: l10n.pageNavigatorRemovePageTooltip,
                  onPressed: onRemovePage,
                  visualDensity: VisualDensity.compact,
                  splashRadius: 18.0,
                ),

              // Arrangement Mode Quick Switcher
              if (onArrangementModeChanged != null) ...[
                Container(
                  height: 18.0,
                  width: 1.0,
                  margin: const EdgeInsets.symmetric(horizontal: 2.0),
                  color: cs.outlineVariant.withValues(alpha: 0.4),
                ),
                PopupMenuButton<dynamic>(
                  tooltip: l10n.pageArrangementSection,
                  icon: Icon(_arrangementIcon(arrangementMode), size: 18.0),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 220),
                  onSelected: (val) {
                    if (val is PageArrangementMode) {
                      onArrangementModeChanged?.call(val);
                    } else if (val == 'toggle_auto_focus') {
                      onAutoFocusChanged?.call(!autoFocusOnPageChange);
                    }
                  },
                  itemBuilder: (context) => [
                    _buildArrangementItem(
                      context,
                      PageArrangementMode.single,
                      Icons.crop_portrait_rounded,
                      l10n.pageArrangementSingle,
                    ),
                    _buildArrangementItem(
                      context,
                      PageArrangementMode.facingSpread,
                      Icons.auto_stories_rounded,
                      l10n.pageArrangementFacing,
                    ),
                    _buildArrangementItem(
                      context,
                      PageArrangementMode.continuousVertical,
                      Icons.view_day_rounded,
                      l10n.pageArrangementContinuousVertical,
                    ),
                    _buildArrangementItem(
                      context,
                      PageArrangementMode.continuousHorizontal,
                      Icons.view_column_rounded,
                      l10n.pageArrangementContinuousHorizontal,
                    ),
                    _buildArrangementItem(
                      context,
                      PageArrangementMode.grid,
                      Icons.grid_view_rounded,
                      l10n.pageArrangementGrid,
                    ),
                    if (onAutoFocusChanged != null) ...[
                      const PopupMenuDivider(),
                      PopupMenuItem<dynamic>(
                        value: 'toggle_auto_focus',
                        child: Row(
                          children: [
                            Icon(
                              autoFocusOnPageChange
                                  ? Icons.center_focus_strong_rounded
                                  : Icons.center_focus_weak_rounded,
                              size: 18.0,
                              color: autoFocusOnPageChange
                                  ? cs.primary
                                  : cs.onSurfaceVariant,
                            ),
                            const SizedBox(width: 10.0),
                            Expanded(
                              child: Text(
                                l10n.autoFocusOnPageChange,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: autoFocusOnPageChange
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: autoFocusOnPageChange
                                      ? cs.primary
                                      : cs.onSurface,
                                ),
                              ),
                            ),
                            if (autoFocusOnPageChange)
                              Icon(Icons.check_rounded,
                                  size: 16.0, color: cs.primary),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  IconData _arrangementIcon(PageArrangementMode mode) {
    switch (mode) {
      case PageArrangementMode.single:
        return Icons.crop_portrait_rounded;
      case PageArrangementMode.facingSpread:
        return Icons.auto_stories_rounded;
      case PageArrangementMode.continuousVertical:
        return Icons.view_day_rounded;
      case PageArrangementMode.continuousHorizontal:
        return Icons.view_column_rounded;
      case PageArrangementMode.grid:
        return Icons.grid_view_rounded;
    }
  }

  PopupMenuItem<PageArrangementMode> _buildArrangementItem(
    BuildContext context,
    PageArrangementMode mode,
    IconData icon,
    String title,
  ) {
    final isSelected = (mode == arrangementMode);
    final cs = Theme.of(context).colorScheme;
    return PopupMenuItem<PageArrangementMode>(
      value: mode,
      child: Row(
        children: [
          Icon(
            icon,
            size: 18.0,
            color: isSelected ? cs.primary : cs.onSurfaceVariant,
          ),
          const SizedBox(width: 10.0),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? cs.primary : cs.onSurface,
              ),
            ),
          ),
          if (isSelected)
            Icon(Icons.check_rounded, size: 16.0, color: cs.primary),
        ],
      ),
    );
  }
}
