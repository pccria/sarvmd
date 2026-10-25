// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Use of this source code is governed by a Business Source License 1.1
// license that can be found in the LICENSE file in the root of this project.

/// Saddle-stitch booklet imposition model and signature calculator for music publishing.
///
/// Imposition re-orders and pairs pages side-by-side (2-up) so that folded,
/// stapled sheets produce a correctly sequenced score booklet.

/// Sizing strategy for the imposed physical sheet.
enum BookletSheetMode {
  /// Double-width sheet maintaining 1:1 scale (e.g. A4 Portrait -> A3 Landscape,
  /// A5 Portrait -> A4 Landscape, US Letter Portrait -> Tabloid 11x17 Landscape).
  doubleSize,

  /// Same paper size in Landscape orientation, scaling two pages side-by-side to fit
  /// (e.g. A4 Portrait -> A4 Landscape with ~70.7% scale down to A5).
  sameSizeScaled,
}

/// Configuration options for saddle-stitch booklet imposition.
class BookletConfig {
  const BookletConfig({
    this.sheetMode = BookletSheetMode.doubleSize,
    this.drawFoldGuide = true,
    this.drawSpineTicks = true,
  });

  /// The target sheet sizing strategy.
  final BookletSheetMode sheetMode;

  /// Whether to draw subtle dashed fold guide down the center spine.
  final bool drawFoldGuide;

  /// Whether to draw subtle hairline tick marks at the top and bottom spine edges.
  final bool drawSpineTicks;

  /// Creates a copy of this [BookletConfig] with updated properties.
  BookletConfig copyWith({
    BookletSheetMode? sheetMode,
    bool? drawFoldGuide,
    bool? drawSpineTicks,
  }) {
    return BookletConfig(
      sheetMode: sheetMode ?? this.sheetMode,
      drawFoldGuide: drawFoldGuide ?? this.drawFoldGuide,
      drawSpineTicks: drawSpineTicks ?? this.drawSpineTicks,
    );
  }
}

/// Represents a single physical side of an imposed sheet (containing two 2-up pages).
class BookletSpread {
  const BookletSpread({
    required this.sheetIndex,
    required this.isFrontSide,
    required this.leftPageIndex,
    required this.rightPageIndex,
    required this.totalBookletPages,
  });

  /// 0-indexed physical sheet number.
  final int sheetIndex;

  /// Whether this is the front (outside) or back (inside) of the sheet.
  final bool isFrontSide;

  /// 0-indexed page number for the left half of the spread, or `null` if blank padding.
  final int? leftPageIndex;

  /// 0-indexed page number for the right half of the spread, or `null` if blank padding.
  final int? rightPageIndex;

  /// Total padded booklet page count (always a multiple of 4).
  final int totalBookletPages;

  /// 1-indexed sheet display number.
  int get sheetNumber => sheetIndex + 1;

  /// Human-readable label for the left page (e.g. "4", "Blank").
  String get leftLabel => leftPageIndex != null ? '${leftPageIndex! + 1}' : 'Blank';

  /// Human-readable label for the right page (e.g. "1", "Blank").
  String get rightLabel => rightPageIndex != null ? '${rightPageIndex! + 1}' : 'Blank';

  @override
  String toString() {
    final side = isFrontSide ? 'Front' : 'Back';
    return 'Sheet $sheetNumber ($side): [$leftLabel | $rightLabel]';
  }
}

/// Mathematical calculator for saddle-stitch booklet page imposition signatures.
abstract final class BookletImpositionCalculator {
  /// Calculates the total booklet page count rounded up to the nearest multiple of 4 (minimum 4).
  static int calculateTotalBookletPages(int pageCount) {
    if (pageCount <= 0) return 4;
    return ((pageCount + 3) ~/ 4) * 4;
  }

  /// Calculates the total number of physical double-sided sheets required.
  static int calculateSheetCount(int pageCount) {
    return calculateTotalBookletPages(pageCount) ~/ 4;
  }

  /// Computes all 2-up spreads (front and back) for a document with [pageCount] pages.
  ///
  /// For $S$ sheets ($M = 4S$ pages):
  /// On sheet $s$ ($0 \le s < S$):
  /// - Front side: Left = $M - 2s - 1$, Right = $2s$
  /// - Back side: Left = $2s + 1$, Right = $M - 2s - 2$
  ///
  /// If a calculated page index is $\ge pageCount$, it is treated as a blank page (`null`).
  static List<BookletSpread> computeSpreads(int pageCount) {
    final total = calculateTotalBookletPages(pageCount);
    final sheetCount = total ~/ 4;
    final spreads = <BookletSpread>[];

    for (var s = 0; s < sheetCount; s++) {
      // Front side (Odd side: 1, 3, 5...)
      final frontLeft = total - 2 * s - 1;
      final frontRight = 2 * s;
      spreads.add(BookletSpread(
        sheetIndex: s,
        isFrontSide: true,
        leftPageIndex: frontLeft < pageCount ? frontLeft : null,
        rightPageIndex: frontRight < pageCount ? frontRight : null,
        totalBookletPages: total,
      ));

      // Back side (Even side: 2, 4, 6...)
      final backLeft = 2 * s + 1;
      final backRight = total - 2 * s - 2;
      spreads.add(BookletSpread(
        sheetIndex: s,
        isFrontSide: false,
        leftPageIndex: backLeft < pageCount ? backLeft : null,
        rightPageIndex: backRight < pageCount ? backRight : null,
        totalBookletPages: total,
      ));
    }

    return spreads;
  }
}
