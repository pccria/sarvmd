// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Licensed under the Business Source License 1.1 (BUSL-1.1).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sarvmd_core/sarvmd_core.dart' as core;
import 'package:sarvmd_ui/src/presentation/widgets/canvas/canvas_zoom_calculator.dart';
import 'package:sarvmd_ui/src/presentation/widgets/common/integrated_scale_control.dart';

void main() {
  group('CanvasZoomCalculator Tests', () {
    const config = core.PageConfig();

    test('actualSize computes scale from calibration factor', () {
      final result = CanvasZoomCalculator.compute(
        preset: ZoomPreset.actualSize,
        constraints: const BoxConstraints(maxWidth: 1000, maxHeight: 1000),
        config: config,
        calibrationFactor: 2.5,
      );

      expect(result.scale, equals(2.5));
      expect(result.matrix, isNotNull);
    });

    test('fitWidth computes correct horizontal scale and centers dx', () {
      final result = CanvasZoomCalculator.compute(
        preset: ZoomPreset.fitWidth,
        constraints: const BoxConstraints(maxWidth: 1000, maxHeight: 800),
        config: config,
        calibrationFactor: 1.0,
        padding: 40.0,
      );

      expect(result.scale, greaterThan(0));
      expect(result.dx, isNotNull);
      expect(result.dy, isNotNull);
    });

    test('fitScreen computes scale constrained by both width and height', () {
      final result = CanvasZoomCalculator.compute(
        preset: ZoomPreset.fitScreen,
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 600),
        config: config,
        calibrationFactor: 1.0,
        padding: 24.0,
      );

      expect(result.scale, greaterThan(0));
      expect(result.dx, isNotNull);
      expect(result.dy, isNotNull);
    });

    test('leftInset shifts dx so canvas paper centers in unobstructed aperture', () {
      final noInset = CanvasZoomCalculator.compute(
        preset: ZoomPreset.fitScreen,
        constraints: const BoxConstraints(maxWidth: 1200, maxHeight: 800),
        config: config,
        calibrationFactor: 1.0,
        padding: 40.0,
      );

      final withInset = CanvasZoomCalculator.compute(
        preset: ZoomPreset.fitScreen,
        constraints: const BoxConstraints(maxWidth: 1200, maxHeight: 800),
        config: config,
        calibrationFactor: 1.0,
        padding: 40.0,
        leftInset: 320.0,
      );

      // dx with 320px left inset must be displaced to the right compared to no inset
      expect(withInset.dx, greaterThan(noInset.dx));
      expect(withInset.dx, greaterThanOrEqualTo(320.0));
    });

    test('isPanelOccludingPaper returns true when paper overlaps left panel', () {
      // Paper starts at translationX = 0, with ruler 25.0 -> screen left = 25.0
      // Panel width = 320 -> screen left (25) < 320 -> occluded!
      final matrix = Matrix4.identity();
      final occluded = CanvasZoomCalculator.isPanelOccludingPaper(
        matrix: matrix,
        config: config,
        panelWidth: 320.0,
      );
      expect(occluded, isTrue);
    });

    test('isPanelOccludingPaper returns false when paper is shifted past panel', () {
      // Paper shifted past 320px panel -> translationX = 350.0 -> screen left = 375.0 > 320.0
      final matrix = Matrix4.translationValues(350.0, 0.0, 0.0);
      final occluded = CanvasZoomCalculator.isPanelOccludingPaper(
        matrix: matrix,
        config: config,
        panelWidth: 320.0,
      );
      expect(occluded, isFalse);
    });

    test('isTargetOccluded checks margin-specific guidelines', () {
      // Paper at translationX = 100.0, scale = 1.0, ruler = 25.0 -> paperScreenLeft = 125.0
      // Paper width for A4 = 210mm * 3.7795 ~ 793.7px -> paperScreenRight ~ 918.7px
      // Panel width = 320.0 (span [0 .. 320])
      final matrix = Matrix4.translationValues(100.0, 0.0, 0.0);

      // Left margin (15mm ~ 56.7px) -> leftMarginX = 125 + 56.7 = 181.7px < 320px -> OCCLUDED
      final leftOccluded = CanvasZoomCalculator.isTargetOccluded(
        matrix: matrix,
        config: config,
        panelWidth: 320.0,
        activeScrubbingMargin: 'left',
      );
      expect(leftOccluded, isTrue);

      // Right margin (15mm ~ 56.7px) -> rightMarginX = 918.7 - 56.7 = 862px > 320px -> NOT OCCLUDED
      final rightOccluded = CanvasZoomCalculator.isTargetOccluded(
        matrix: matrix,
        config: config,
        panelWidth: 320.0,
        activeScrubbingMargin: 'right',
      );
      expect(rightOccluded, isFalse);
    });
  });
}
