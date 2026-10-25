// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Licensed under the Business Source License 1.1 (BUSL-1.1).

import 'package:flutter/material.dart';
import '../../../logic/document/document_cubit.dart';
import '../../../logic/view/view_state.dart';
import 'preview_canvas.dart';

/// Top-level score canvas coordinator that arranges manuscript pages according
/// to [ViewState.pageArrangement] (single, facingSpread, continuousVertical,
/// continuousHorizontal, or grid).
class ScoreArrangementCanvas extends StatelessWidget {
  const ScoreArrangementCanvas({
    super.key,
    required this.documentCubit,
    required this.viewState,
    this.onPageTapped,
  });

  final DocumentCubit documentCubit;
  final ViewState viewState;
  final ValueChanged<int>? onPageTapped;

  @override
  Widget build(BuildContext context) {
    final totalPages = documentCubit.state.pageCount;
    final effectivePageIndex = viewState.currentPageIndex.clamp(
      0,
      totalPages > 0 ? totalPages - 1 : 0,
    );

    switch (viewState.pageArrangement) {
      case PageArrangementMode.single:
        return _buildPageCard(context, effectivePageIndex, showIndicator: false);

      case PageArrangementMode.facingSpread:
        return _buildFacingSpread(context, effectivePageIndex, totalPages);

      case PageArrangementMode.continuousVertical:
        return _buildContinuousVertical(context, totalPages, effectivePageIndex);

      case PageArrangementMode.continuousHorizontal:
        return _buildContinuousHorizontal(context, totalPages, effectivePageIndex);

      case PageArrangementMode.grid:
        return _buildGrid(context, totalPages, effectivePageIndex);
    }
  }

  /// Builds a two-page Gouldian book spread.
  ///
  /// Spread 0: [ Placeholder / Blank (Verso) | Page 1 (Recto) ]
  /// Spread 1: [ Page 2 (Verso)              | Page 3 (Recto) ]
  /// Spread S: [ Page 2S (Verso)             | Page 2S + 1 (Recto) ]
  Widget _buildFacingSpread(
    BuildContext context,
    int effectivePageIndex,
    int totalPages,
  ) {
    final int spreadIndex =
        (effectivePageIndex == 0) ? 0 : (effectivePageIndex + 1) ~/ 2;

    final int? leftIndex = (spreadIndex == 0) ? null : (2 * spreadIndex - 1);
    final int? rightIndex = (spreadIndex == 0)
        ? 0
        : (2 * spreadIndex < totalPages ? 2 * spreadIndex : null);

    final config = documentCubit.state.config;
    const double lpmm = 96 / 25.4;
    final double pageWidth = config.effectiveWidth * lpmm;
    final double pageHeight = config.effectiveHeight * lpmm;

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Verso (Left Page)
        if (leftIndex != null && leftIndex < totalPages)
          _buildPageCard(context, leftIndex, showIndicator: true)
        else
          _buildGhostPagePlaceholder(context, pageWidth, pageHeight, isVerso: true),

        // Spine Gutter with subtle shading
        _buildSpineGutter(pageHeight),

        // Recto (Right Page)
        if (rightIndex != null && rightIndex < totalPages)
          _buildPageCard(context, rightIndex, showIndicator: true)
        else
          _buildGhostPagePlaceholder(context, pageWidth, pageHeight, isVerso: false),
      ],
    );
  }

  /// Builds a continuous vertical ribbon of pages stacked top-to-bottom.
  Widget _buildContinuousVertical(
    BuildContext context,
    int totalPages,
    int effectivePageIndex,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        for (int i = 0; i < totalPages; i++) ...[
          if (i > 0) const SizedBox(height: 32.0),
          _buildPageCard(context, i, showIndicator: true),
        ],
      ],
    );
  }

  /// Builds a continuous horizontal ribbon of pages lined up left-to-right.
  Widget _buildContinuousHorizontal(
    BuildContext context,
    int totalPages,
    int effectivePageIndex,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < totalPages; i++) ...[
          if (i > 0) const SizedBox(width: 32.0),
          _buildPageCard(context, i, showIndicator: true),
        ],
      ],
    );
  }

  /// Builds a multi-page matrix / contact sheet overview.
  Widget _buildGrid(
    BuildContext context,
    int totalPages,
    int effectivePageIndex,
  ) {
    final cols = viewState.gridColumns.clamp(1, 6);
    final rows = <List<int>>[];
    for (int i = 0; i < totalPages; i += cols) {
      rows.add([
        for (int j = i; j < i + cols && j < totalPages; j++) j,
      ]);
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        for (int r = 0; r < rows.length; r++) ...[
          if (r > 0) const SizedBox(height: 32.0),
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (int c = 0; c < rows[r].length; c++) ...[
                if (c > 0) const SizedBox(width: 32.0),
                _buildPageCard(context, rows[r][c], showIndicator: true),
              ],
            ],
          ),
        ],
      ],
    );
  }

  /// Builds a single paper card wrapping [PreviewCanvas] with page selection highlight.
  Widget _buildPageCard(
    BuildContext context,
    int pageIndex, {
    required bool showIndicator,
  }) {
    final cs = Theme.of(context).colorScheme;
    final isActive = (pageIndex == viewState.currentPageIndex);
    final layout = documentCubit.layoutForPage(pageIndex);
    final metadata = documentCubit.state.metadata;

    final canvasWidget = PreviewCanvas(
      layout: layout,
      viewState: viewState,
      metadata: metadata,
      pageIndex: pageIndex,
    );

    if (!showIndicator) {
      return canvasWidget;
    }

    return MouseRegion(
      cursor: onPageTapped != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onPageTapped?.call(pageIndex),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Active border indicator wrapper
            DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(
                  color: isActive
                      ? cs.primary
                      : Colors.transparent,
                  width: isActive ? 2.5 : 0.0,
                ),
              ),
              child: canvasWidget,
            ),

            // Floating Page Badge
            Positioned(
              top: 8.0,
              left: 8.0,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8.0,
                  vertical: 4.0,
                ),
                decoration: BoxDecoration(
                  color: isActive
                      ? cs.primary
                      : cs.surface.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(10.0),
                  border: Border.all(
                    color: isActive
                        ? cs.primary
                        : cs.outlineVariant.withValues(alpha: 0.5),
                    width: 1.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 4.0,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  'p. ${pageIndex + 1}',
                  style: TextStyle(
                    fontSize: 11.0,
                    fontWeight: FontWeight.bold,
                    color: isActive ? cs.onPrimary : cs.onSurface,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the book spine gutter separating verso and recto pages in [PageArrangementMode.facingSpread].
  Widget _buildSpineGutter(double height) {
    return Container(
      width: 18.0,
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Colors.black.withValues(alpha: 0.08),
            Colors.black.withValues(alpha: 0.02),
            Colors.black.withValues(alpha: 0.08),
          ],
        ),
      ),
    );
  }

  /// Builds a translucent ghost paper placeholder for empty spread slots.
  Widget _buildGhostPagePlaceholder(
    BuildContext context,
    double width,
    double height, {
    required bool isVerso,
  }) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: cs.surface.withValues(alpha: 0.03),
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: 0.2),
          width: 1.0,
          style: BorderStyle.solid,
        ),
      ),
      child: Center(
        child: Text(
          isVerso ? '— (Verso) —' : '— (Recto) —',
          style: TextStyle(
            fontSize: 14.0,
            letterSpacing: 2.0,
            color: cs.onSurface.withValues(alpha: 0.25),
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
