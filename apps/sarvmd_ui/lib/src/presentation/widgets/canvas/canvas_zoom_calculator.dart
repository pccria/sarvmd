// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Licensed under the Business Source License 1.1 (BUSL-1.1).

import 'package:flutter/material.dart';
import 'package:sarvmd_core/sarvmd_core.dart' as core;
import '../../../core/theme/app_metrics.dart';
import '../common/integrated_scale_control.dart';

/// Calculation result containing scale factor, translation offsets, and the corresponding transform matrix.
class CanvasZoomTransform {
  const CanvasZoomTransform({
    required this.scale,
    required this.dx,
    required this.dy,
    required this.matrix,
  });

  final double scale;
  final double dx;
  final double dy;
  final Matrix4 matrix;
}

/// Standardized calculation utility for canvas zoom presets and viewport centering.
abstract final class CanvasZoomCalculator {
  /// Internal canvas coordinate scale in logical pixels per millimeter (96 dpi / 25.4 mm).
  static const double lpmm = 96.0 / 25.4;

  /// Default physical ruler strip dimension in logical pixels.
  static const double defaultRulerSize = 25.0;

  /// Computes the exact zoom scale factor and translation matrix for a given preset and viewport layout.
  static CanvasZoomTransform compute({
    required ZoomPreset preset,
    required BoxConstraints constraints,
    required core.PageConfig config,
    required double calibrationFactor,
    double rulerSize = defaultRulerSize,
    double padding = 40.0,
    double topSafeArea = 0.0,
    double leftSafeArea = 0.0,
    double bottomPadding = 0.0,
    double leftInset = 0.0,
    double rightInset = 0.0,
  }) {
    final paperWidth = config.effectiveWidth * lpmm;
    final paperHeight = config.effectiveHeight * lpmm;

    final totalRulerWidth = rulerSize + leftSafeArea;
    final totalRulerHeight = rulerSize + topSafeArea;
    final canvasWidth = (constraints.maxWidth - totalRulerWidth - leftInset - rightInset).clamp(1.0, double.infinity);
    final canvasHeight = (constraints.maxHeight - totalRulerHeight - bottomPadding).clamp(1.0, double.infinity);
    final availableWidth = (canvasWidth - padding * 2).clamp(1.0, double.infinity);
    final availableHeight = (canvasHeight - padding * 2).clamp(1.0, double.infinity);

    double fitScale;

    switch (preset) {
      case ZoomPreset.actualSize:
        fitScale = calibrationFactor.clamp(ScaleMetrics.minZoom, ScaleMetrics.maxZoom);
        break;
      case ZoomPreset.fitWidth:
        fitScale = (availableWidth / paperWidth).clamp(ScaleMetrics.minZoom, ScaleMetrics.maxZoom);
        break;
      case ZoomPreset.fitScreen:
        final scaleX = availableWidth / paperWidth;
        final scaleY = availableHeight / paperHeight;
        fitScale = (scaleX < scaleY ? scaleX : scaleY).clamp(ScaleMetrics.minZoom, ScaleMetrics.maxZoom);
        break;
    }

    final double dx = leftInset + (canvasWidth - paperWidth * fitScale) / 2;
    double dy;

    if (preset == ZoomPreset.fitScreen) {
      dy = (canvasHeight - paperHeight * fitScale) / 2;
    } else {
      final scaledHeight = paperHeight * fitScale;
      if (scaledHeight < availableHeight) {
        dy = (canvasHeight - scaledHeight) / 2;
      } else {
        dy = padding;
      }
    }

    final matrix = Matrix4.translationValues(dx, dy, 0.0)
      ..multiply(Matrix4.diagonal3Values(fitScale, fitScale, 1.0));

    return CanvasZoomTransform(
      scale: fitScale,
      dx: dx,
      dy: dy,
      matrix: matrix,
    );
  }

  /// Evaluates whether a panel (occupying screen interval [panelLeft, panelLeft + panelWidth])
  /// geometrically occludes the rendered manuscript paper.
  ///
  /// [matrix] is the current canvas transform [TransformationController.value].
  /// [config] is the document page configuration (determining dimensions in mm).
  /// [panelWidth] is the horizontal width of the panel.
  /// [panelLeft] is the left coordinate of the panel in global screen space (defaults to 0.0 for left-side panels).
  /// [canvasLeft] is the left coordinate of the canvas viewport in global screen space (defaults to 0.0).
  /// [rulerSize] is the physical ruler strip width (defaults to [defaultRulerSize]).
  /// [leftSafeArea] is the device left safe-area insets.
  static bool isPanelOccludingPaper({
    required Matrix4 matrix,
    required core.PageConfig config,
    required double panelWidth,
    double panelLeft = 0.0,
    double canvasLeft = 0.0,
    double rulerSize = defaultRulerSize,
    double leftSafeArea = 0.0,
  }) {
    if (panelWidth <= 0) return false;

    final scale = matrix.getMaxScaleOnAxis();
    if (scale <= 0) return false;

    final translationX = matrix.storage[12];
    final paperPixelWidth = config.effectiveWidth * lpmm;

    final paperScreenLeft = canvasLeft + rulerSize + leftSafeArea + translationX;
    final paperScreenRight = paperScreenLeft + (paperPixelWidth * scale);

    final panelRight = panelLeft + panelWidth;

    return paperScreenLeft < panelRight && paperScreenRight > panelLeft;
  }

  /// Evaluates whether the active target (either a specific margin guideline or the paper generally)
  /// is physically occluded by the panel.
  static bool isTargetOccluded({
    required Matrix4 matrix,
    required core.PageConfig config,
    required double panelWidth,
    String? activeScrubbingMargin,
    double panelLeft = 0.0,
    double canvasLeft = 0.0,
    double rulerSize = defaultRulerSize,
    double leftSafeArea = 0.0,
  }) {
    // If the paper does not overlap the panel at all, the target is definitely not occluded.
    if (!isPanelOccludingPaper(
      matrix: matrix,
      config: config,
      panelWidth: panelWidth,
      panelLeft: panelLeft,
      canvasLeft: canvasLeft,
      rulerSize: rulerSize,
      leftSafeArea: leftSafeArea,
    )) {
      return false;
    }

    // General scrubbing (staff spacing, document page setup, etc.) - paper is occluded.
    if (activeScrubbingMargin == null) {
      return true;
    }

    final scale = matrix.getMaxScaleOnAxis();
    final translationX = matrix.storage[12];
    final paperPixelWidth = config.effectiveWidth * lpmm;
    final paperScreenLeft = canvasLeft + rulerSize + leftSafeArea + translationX;
    final paperScreenRight = paperScreenLeft + (paperPixelWidth * scale);
    final panelRight = panelLeft + panelWidth;

    switch (activeScrubbingMargin) {
      case 'left':
        final leftMarginX = paperScreenLeft + (config.margins.left * lpmm * scale);
        // Occluded if the left margin guideline or paper margin area is under the panel
        return leftMarginX > panelLeft && paperScreenLeft < panelRight;

      case 'right':
        final rightMarginX = paperScreenRight - (config.margins.right * lpmm * scale);
        // Occluded if the right margin guideline or paper margin area is under the panel
        return paperScreenRight > panelLeft && rightMarginX < panelRight;

      case 'horizontal':
        final leftMarginX = paperScreenLeft + (config.margins.left * lpmm * scale);
        final rightMarginX = paperScreenRight - (config.margins.right * lpmm * scale);
        final leftOccluded = leftMarginX > panelLeft && paperScreenLeft < panelRight;
        final rightOccluded = paperScreenRight > panelLeft && rightMarginX < panelRight;
        return leftOccluded || rightOccluded;

      default:
        // For vertical margins (top/bottom) or other properties, since the paper
        // is horizontally occluded by the panel, return true.
        return true;
    }
  }
}
