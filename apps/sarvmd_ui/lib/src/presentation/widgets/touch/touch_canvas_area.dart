// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Licensed under the Business Source License 1.1 (BUSL-1.1).

import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_metrics.dart';
import '../../../core/theme/layout_policy.dart';
import '../../../l10n/app_localizations.dart';
import '../../../logic/document/document_cubit.dart';
import '../../../logic/view/view_cubit.dart';
import '../../../logic/view/view_state.dart';
import '../canvas/canvas_zoom_calculator.dart';
import '../canvas/score_arrangement_canvas.dart';
import '../canvas/ruler_box.dart';
import '../common/integrated_scale_control.dart';

/// Touch & gesture optimized interactive mobile canvas area for SarvMD manuscript rendering.
class TouchCanvasArea extends StatefulWidget {
  const TouchCanvasArea({
    super.key,
    required this.transformationController,
    required this.cursorNotifier,
    this.bottomPadding = 0,
    this.topSafeArea = 0.0,
    this.leftSafeArea = 0.0,
    this.leftInset = 0.0,
    this.onLongPressCanvas,
    this.onLongPressStartCanvas,
    this.onLongPressMoveCanvas,
    this.onLongPressEndCanvas,
    this.onInteractionStart,
    this.onInteractionEnd,
  });

  final TransformationController transformationController;
  final ValueNotifier<Offset?> cursorNotifier;
  final double bottomPadding;
  final double topSafeArea;
  final double leftSafeArea;
  final double leftInset;
  final void Function(Offset localPosition)? onLongPressCanvas;
  final void Function(Offset localPosition)? onLongPressStartCanvas;
  final void Function(Offset localPosition)? onLongPressMoveCanvas;
  final VoidCallback? onLongPressEndCanvas;
  final void Function(ScaleStartDetails details)? onInteractionStart;
  final void Function(ScaleEndDetails details)? onInteractionEnd;

  @override
  State<TouchCanvasArea> createState() => TouchCanvasAreaState();
}

class TouchCanvasAreaState extends State<TouchCanvasArea> with SingleTickerProviderStateMixin {
  BoxConstraints? _lastConstraints;
  bool _hasCentered = false;
  ZoomPreset _currentPreset = ZoomPreset.fitWidth;
  late final AnimationController _cameraAnimationController;
  Animation<double>? _cameraCurveAnimation;
  Matrix4? _startMatrix;
  Matrix4? _targetMatrix;

  // Page Swipe Gesture Tracking
  Offset? _touchStartFocalPoint;
  double _swipeDeltaX = 0.0;
  double _swipeDeltaY = 0.0;
  int _maxTouchPointers = 0;
  bool _swipeHandledInCurrentGesture = false;

  // Visual Page Turn HUD State
  String? _swipeToastMessage;
  IconData? _swipeToastIcon;
  Timer? _swipeToastDismissTimer;

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
        widget.transformationController.value = lerped;
      });
    _cameraCurveAnimation = CurvedAnimation(
      parent: _cameraAnimationController,
      curve: Curves.easeOutCubic,
    );
  }



  @override
  void dispose() {
    _swipeToastDismissTimer?.cancel();
    _cameraAnimationController.dispose();
    super.dispose();
  }

  void toggleFitZoom() {
    final next = _currentPreset == ZoomPreset.fitWidth
        ? ZoomPreset.fitScreen
        : ZoomPreset.fitWidth;
    applyZoomPreset(next, animate: true);
  }

  void applyZoomPreset(ZoomPreset preset, {bool animate = false}) {
    _currentPreset = preset;
    final constraints = _lastConstraints;
    if (constraints == null) return;

    final config = context.read<DocumentCubit>().state.config;
    final viewState = context.read<ViewCubit>().state;

    final effectiveLeftInset = viewState.isPanelPeeking ? 48.0 : widget.leftInset;

    final transform = CanvasZoomCalculator.compute(
      preset: preset,
      constraints: constraints,
      config: config,
      calibrationFactor: viewState.calibrationFactor,
      padding: 24.0,
      topSafeArea: widget.topSafeArea,
      leftSafeArea: widget.leftSafeArea,
      bottomPadding: widget.bottomPadding,
      leftInset: effectiveLeftInset,
    );

    if (animate && _hasCentered) {
      _cameraAnimationController.duration = const Duration(milliseconds: 150);
      _animateMatrixTo(transform.matrix);
    } else {
      widget.transformationController.value = transform.matrix;
    }
  }

  int? _lastObservedPageIndex;
  PageArrangementMode? _lastObservedArrangement;

  void focusPage(int pageIndex, {bool animate = true}) {
    final constraints = _lastConstraints;
    if (constraints == null) return;

    final docCubit = context.read<DocumentCubit>();
    final viewState = context.read<ViewCubit>().state;
    final config = docCubit.state.config;
    final effectiveLeftInset = viewState.isPanelPeeking ? 48.0 : widget.leftInset;

    final currentMatrix = widget.transformationController.value;
    final currentScale = currentMatrix.row0[0];

    final targetMatrix = CanvasZoomCalculator.computePageFocusMatrix(
      arrangement: viewState.pageArrangement,
      pageIndex: pageIndex,
      constraints: constraints,
      config: config,
      currentScale: currentScale,
      gridColumns: viewState.gridColumns,
      topSafeArea: widget.topSafeArea,
      leftSafeArea: widget.leftSafeArea,
      bottomPadding: widget.bottomPadding,
      leftInset: effectiveLeftInset,
      padding: 24.0,
    );

    if (animate && _hasCentered) {
      _cameraAnimationController.duration = const Duration(milliseconds: 250);
      _animateMatrixTo(targetMatrix);
    } else {
      widget.transformationController.value = targetMatrix;
    }
  }

  void _animateMatrixTo(Matrix4 target) {
    _startMatrix = widget.transformationController.value.clone();
    _targetMatrix = target;
    _cameraAnimationController.stop();
    _cameraAnimationController.reset();
    _cameraAnimationController.forward();
  }

  void _handleInteractionStart(ScaleStartDetails details) {
    _touchStartFocalPoint = details.localFocalPoint;
    _swipeDeltaX = 0.0;
    _swipeDeltaY = 0.0;
    _maxTouchPointers = details.pointerCount;
    _swipeHandledInCurrentGesture = false;
    widget.onInteractionStart?.call(details);
  }

  void _handleInteractionUpdate(ScaleUpdateDetails details) {
    if (details.pointerCount > _maxTouchPointers) {
      _maxTouchPointers = details.pointerCount;
    }
    _swipeDeltaX += details.focalPointDelta.dx;
    _swipeDeltaY += details.focalPointDelta.dy;

    final viewState = context.read<ViewCubit>().state;
    if (viewState.pageSwipeGestures &&
        !_swipeHandledInCurrentGesture &&
        _maxTouchPointers >= 2 &&
        (details.scale - 1.0).abs() < 0.20) {
      const double twoFingerDisplacementThreshold = 80.0;
      if (_swipeDeltaX < -twoFingerDisplacementThreshold &&
          _swipeDeltaX.abs() > _swipeDeltaY.abs() * 1.5) {
        _triggerSwipeNavigation(isNext: true);
        _swipeHandledInCurrentGesture = true;
      } else if (_swipeDeltaX > twoFingerDisplacementThreshold &&
          _swipeDeltaX.abs() > _swipeDeltaY.abs() * 1.5) {
        _triggerSwipeNavigation(isNext: false);
        _swipeHandledInCurrentGesture = true;
      }
    }
  }

  void _handleInteractionEnd(ScaleEndDetails details) {
    widget.onInteractionEnd?.call(details);

    final viewState = context.read<ViewCubit>().state;
    if (!viewState.pageSwipeGestures || _swipeHandledInCurrentGesture) return;

    final vx = details.velocity.pixelsPerSecond.dx;
    final vy = details.velocity.pixelsPerSecond.dy;

    final bool isHorizFling = vx.abs() > 350.0 && vx.abs() > vy.abs() * 1.3;
    final bool isDisplacementSwipe =
        _swipeDeltaX.abs() > 45.0 && _swipeDeltaX.abs() > _swipeDeltaY.abs() * 1.3;

    // A. Two-finger horizontal swipe/fling
    if (_maxTouchPointers >= 2) {
      if (isHorizFling || isDisplacementSwipe) {
        final bool isNext = (vx != 0) ? (vx < 0) : (_swipeDeltaX < 0);
        _triggerSwipeNavigation(isNext: isNext);
        _swipeHandledInCurrentGesture = true;
        return;
      }
    }

    // B. Edge swipe (started within 36dp of left or right canvas boundaries)
    final constraints = _lastConstraints;
    if (_touchStartFocalPoint != null && constraints != null && _maxTouchPointers == 1) {
      final startX = _touchStartFocalPoint!.dx;
      final canvasWidth = constraints.maxWidth;
      const edgeThreshold = 36.0;

      // Swipe inward from right edge
      if (startX >= canvasWidth - edgeThreshold &&
          (_swipeDeltaX < -25.0 || vx < -250.0)) {
        _triggerSwipeNavigation(isNext: true);
        _swipeHandledInCurrentGesture = true;
        return;
      }

      // Swipe inward from left edge
      if (startX <= edgeThreshold &&
          (_swipeDeltaX > 25.0 || vx > 250.0)) {
        _triggerSwipeNavigation(isNext: false);
        _swipeHandledInCurrentGesture = true;
        return;
      }
    }

    // C. Single-finger horizontal swipe in single or facingSpread modes
    if (_maxTouchPointers == 1 &&
        (viewState.pageArrangement == PageArrangementMode.single ||
         viewState.pageArrangement == PageArrangementMode.facingSpread)) {
      if ((isHorizFling || isDisplacementSwipe) && _swipeDeltaX.abs() > 30.0) {
        final bool isNext = (vx != 0) ? (vx < 0) : (_swipeDeltaX < 0);
        _triggerSwipeNavigation(isNext: isNext);
        _swipeHandledInCurrentGesture = true;
        return;
      }
    }
  }

  @visibleForTesting
  void handleInteractionStart(ScaleStartDetails details) => _handleInteractionStart(details);

  @visibleForTesting
  void handleInteractionUpdate(ScaleUpdateDetails details) => _handleInteractionUpdate(details);

  @visibleForTesting
  void handleInteractionEnd(ScaleEndDetails details) => _handleInteractionEnd(details);

  void _triggerSwipeNavigation({required bool isNext}) {
    final docCubit = context.read<DocumentCubit>();
    final viewCubit = context.read<ViewCubit>();
    final totalPages = docCubit.state.pageCount;
    final currentIdx = viewCubit.state.currentPageIndex;
    final l10n = AppLocalizations.of(context)!;

    if (totalPages <= 1) return;

    if (isNext) {
      final bool isLast;
      if (viewCubit.state.pageArrangement == PageArrangementMode.facingSpread) {
        final currentSpread = (currentIdx == 0) ? 0 : (currentIdx + 1) ~/ 2;
        final nextSpread = currentSpread + 1;
        final targetPage = (nextSpread == 0) ? 0 : (2 * nextSpread - 1);
        isLast = (targetPage >= totalPages);
      } else {
        isLast = (currentIdx >= totalPages - 1);
      }

      if (isLast) {
        HapticFeedback.lightImpact();
        _showSwipeToast(
          message: l10n.swipeLastPageReached,
          icon: Icons.last_page_rounded,
        );
        focusPage(currentIdx, animate: true);
        return;
      }

      HapticFeedback.selectionClick();
      viewCubit.nextSpread(totalPages);
      final newIdx = viewCubit.state.currentPageIndex;
      _showSwipeToast(
        message: l10n.swipeTurnedToPage(newIdx + 1, totalPages),
        icon: Icons.chevron_right_rounded,
      );
    } else {
      final bool isFirst = (currentIdx == 0);
      if (isFirst) {
        HapticFeedback.lightImpact();
        _showSwipeToast(
          message: l10n.swipeFirstPageReached,
          icon: Icons.first_page_rounded,
        );
        focusPage(currentIdx, animate: true);
        return;
      }

      HapticFeedback.selectionClick();
      viewCubit.previousSpread();
      final newIdx = viewCubit.state.currentPageIndex;
      _showSwipeToast(
        message: l10n.swipeTurnedToPage(newIdx + 1, totalPages),
        icon: Icons.chevron_left_rounded,
      );
    }
  }

  void _showSwipeToast({required String message, required IconData icon}) {
    _swipeToastDismissTimer?.cancel();
    setState(() {
      _swipeToastMessage = message;
      _swipeToastIcon = icon;
    });
    _swipeToastDismissTimer = Timer(const Duration(milliseconds: 900), () {
      if (mounted) {
        setState(() {
          _swipeToastMessage = null;
          _swipeToastIcon = null;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final documentCubit = context.watch<DocumentCubit>();
    final docState = documentCubit.state;
    final configState = docState.config;
    final viewState = context.watch<ViewCubit>().state;

    return BlocListener<ViewCubit, ViewState>(
      listenWhen: (prev, curr) =>
          prev.isPanelPeeking != curr.isPanelPeeking ||
          prev.currentPageIndex != curr.currentPageIndex ||
          prev.pageArrangement != curr.pageArrangement,
      listener: (context, state) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          final pageChanged = _lastObservedPageIndex != null &&
              _lastObservedPageIndex != state.currentPageIndex;
          final arrangementChanged = _lastObservedArrangement != null &&
              _lastObservedArrangement != state.pageArrangement;
          _lastObservedPageIndex = state.currentPageIndex;
          _lastObservedArrangement = state.pageArrangement;

          if ((pageChanged || arrangementChanged) &&
              state.autoFocusOnPageChange) {
            focusPage(state.currentPageIndex, animate: true);
          } else {
            applyZoomPreset(_currentPreset, animate: true);
          }
        });
      },
      child: Container(
        color: Theme.of(context).colorScheme.surface,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final hasSizeChanged = _lastConstraints != null &&
                (_lastConstraints!.maxWidth != constraints.maxWidth ||
                 _lastConstraints!.maxHeight != constraints.maxHeight);
            _lastConstraints = constraints;
            if (!_hasCentered) {
              _hasCentered = true;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  final isPortrait = MediaQuery.orientationOf(context) == Orientation.portrait;
                  applyZoomPreset(isPortrait ? ZoomPreset.fitWidth : ZoomPreset.fitScreen);
                }
              });
            } else if (hasSizeChanged) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  applyZoomPreset(_currentPreset, animate: true);
                }
              });
            }

          return CanvasStrictScope(
            child: RulerBox(
              transformationController: widget.transformationController,
              viewState: viewState,
              cursorNotifier: widget.cursorNotifier,
              showCoordinateHud: false,
              topSafeArea: widget.topSafeArea,
              leftSafeArea: widget.leftSafeArea,
              paperSizeMm: Size(
                configState.effectiveWidth,
                configState.effectiveHeight,
              ),
              child: Stack(
                children: [
                    Positioned.fill(
                      child: InteractiveViewer(
                        transformationController: widget.transformationController,
                        boundaryMargin: const EdgeInsets.all(100000),
                        minScale: ScaleMetrics.minZoom,
                        maxScale: ScaleMetrics.maxZoom,
                        constrained: false,
                        alignment: Alignment.topLeft,
                        onInteractionStart: _handleInteractionStart,
                        onInteractionUpdate: _handleInteractionUpdate,
                        onInteractionEnd: _handleInteractionEnd,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onDoubleTap: toggleFitZoom,
                          onLongPressStart: (details) {
                            if (widget.onLongPressStartCanvas != null) {
                              widget.onLongPressStartCanvas!(details.localPosition);
                            } else if (widget.onLongPressCanvas != null) {
                              widget.onLongPressCanvas!(details.localPosition);
                            }
                          },
                          onLongPressMoveUpdate: widget.onLongPressMoveCanvas != null
                              ? (details) => widget.onLongPressMoveCanvas!(details.localPosition)
                              : null,
                          onLongPressEnd: widget.onLongPressEndCanvas != null
                              ? (_) => widget.onLongPressEndCanvas!()
                              : null,
                          onLongPressCancel: widget.onLongPressEndCanvas != null
                              ? () => widget.onLongPressEndCanvas!()
                              : null,
                          child: ScoreArrangementCanvas(
                            documentCubit: documentCubit,
                            viewState: viewState,
                            onPageTapped: (index) => context.read<ViewCubit>().setPageIndex(
                              index,
                              maxPages: documentCubit.state.pageCount,
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Floating Glassmorphic Page Turn HUD
                    if (_swipeToastMessage != null)
                      Positioned(
                        top: widget.topSafeArea + 48.0,
                        left: 0.0,
                        right: 0.0,
                        child: Center(
                          child: IgnorePointer(
                            child: AnimatedOpacity(
                              duration: const Duration(milliseconds: 200),
                              opacity: 1.0,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(20.0),
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16.0,
                                      vertical: 8.0,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .surfaceContainerHighest
                                          .withValues(alpha: 0.88),
                                      borderRadius: BorderRadius.circular(20.0),
                                      border: Border.all(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .outlineVariant
                                            .withValues(alpha: 0.35),
                                        width: 1.0,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.12),
                                          blurRadius: 12.0,
                                          offset: const Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (_swipeToastIcon != null) ...[
                                          Icon(
                                            _swipeToastIcon,
                                            size: 18.0,
                                            color: Theme.of(context).colorScheme.primary,
                                          ),
                                          const SizedBox(width: 8.0),
                                        ],
                                        Text(
                                          _swipeToastMessage!,
                                          style: TextStyle(
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 0.2,
                                            color: Theme.of(context).colorScheme.onSurface,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
