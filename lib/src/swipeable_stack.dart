import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'callbacks.dart';
import 'card_display_information.dart';
import 'card_property.dart';
import 'identifiable.dart';
import 'swipe_direction.dart';

class SwipeableStackController<T extends SwipeableStackIdentifiable>
    extends ChangeNotifier {
  SwipeableStackController();

  final _swipeableStackStateKey = GlobalKey<_SwipeableStackState>();

  var _cardProperties = <CardProperty<T>>[];

  int get size => _cardProperties.length;

  T? get currentData => _focusCardProperty?.data;

  int get currentIndex => _focusIndex ?? _cardProperties.length;

  void next({
    required SwipeDirection swipeDirection,
    bool shouldCallCompletionCallback = true,
    bool ignoreOnWillMoveNext = false,
    Duration? duration,
  }) {
    _swipeableStackStateKey.currentState?._next(
      swipeDirection: swipeDirection,
      shouldCallCompletionCallback: shouldCallCompletionCallback,
      ignoreOnWillMoveNext: ignoreOnWillMoveNext,
      duration: duration,
    );
  }

  void rewind({
    Duration duration = const Duration(milliseconds: 650),
  }) {
    _swipeableStackStateKey.currentState?._rewind(
      duration: duration,
    );
  }

  List<CardProperty<T>> get _visibleCardProperties {
    final notJudgedCardProperties =
        _cardProperties.where((element) => !element.isJudged).toList();
    return notJudgedCardProperties.sublist(
      0,
      math.min(3, notJudgedCardProperties.length),
    );
  }

  CardProperty<T>? get _focusCardProperty =>
      _visibleCardProperties.isNotEmpty ? _visibleCardProperties.first : null;

  int? get _focusIndex {
    final focusId = _focusCardProperty?.id;
    if (focusId == null) {
      return null;
    }
    final index = _cardProperties.indexWhereOrNull(
      (cp) => cp.id == focusId,
    );
    return index;
  }

  CardProperty<T>? get _rewindTarget {
    final targetIndex = currentIndex - 1;
    if (targetIndex < 0) {
      return null;
    }
    return _cardProperties[targetIndex];
  }

  // Return whether removed focus card or not.
  //
  // true: removed focus card
  // false: didn't remove focus card.
  bool _arrangeCardProperties({
    required List<T> newDataSet,
    required bool persistJudgedCard,
  }) {
    var _markRemovedFocusProperty = false;
    final newCardProperties = newDataSet
        .map(
          (data) => CardProperty<T>(data: data),
        )
        .toList();
    final removed = _removedItems(
      newCardProperties: newCardProperties,
      persistJudgedCard: persistJudgedCard,
    );
    final added = _cardProperties.addedDifference(
      newData: newCardProperties,
    );
    for (final item in removed) {
      if (_focusCardProperty?.id == item.id) {
        _markRemovedFocusProperty = true;
      }
      _cardProperties.removeWhere(
        (cp) => cp.id == item.id,
      );
    }
    for (final item in added) {
      _cardProperties.add(item);
    }
    notifyListeners();
    return _markRemovedFocusProperty;
  }

  List<CardProperty<T>> _removedItems({
    required List<CardProperty<T>> newCardProperties,
    required bool persistJudgedCard,
  }) {
    final removed = _cardProperties.removedDifference(
      newData: newCardProperties,
    );
    if (!persistJudgedCard) {
      return removed;
    }
    return removed.where((cp) => !cp.isJudged).toList();
  }

  void _judge({
    required String targetId,
    required bool isJudged,
    required CardDisplayInformation? lastCardDisplayInformation,
  }) {
    _cardProperties.judgeWithId(
      targetId,
      isJudged: isJudged,
      lastCardDisplayInformation: lastCardDisplayInformation,
    );
    notifyListeners();
  }
}

extension _IndexWhereOrNull<E> on List<E> {
  int? indexWhereOrNull(bool test(E element), [int start = 0]) {
    final index = indexWhere(test, start);
    if (index < 0) {
      return null;
    }
    return index;
  }
}

extension _CardPropertiesX<T extends SwipeableStackIdentifiable>
    on List<CardProperty<T>> {
  void _replaceAt(
    int index, {
    required CardProperty<T> replacement,
  }) =>
      this.replaceRange(
        index,
        index + 1,
        [replacement],
      );

  void judgeWithId(
    String id, {
    required bool isJudged,
    required CardDisplayInformation? lastCardDisplayInformation,
  }) {
    final index = indexWhereOrNull(
      (element) => element.id == id,
    );
    if (index == null) {
      return;
    }
    _replaceAt(
      index,
      replacement: this[index].copyWith(
        isJudged: isJudged,
        lastDisplayInformation: lastCardDisplayInformation,
      ),
    );
  }
}

extension _DifferenceX on List<SwipeableStackIdentifiable> {
  List<T> addedDifference<T extends SwipeableStackIdentifiable>({
    required List<T> newData,
  }) {
    final oldDataSet = Set<T>.from(this);
    final newDataSet = Set<T>.from(newData);
    return newDataSet.difference(oldDataSet).toList();
  }

  List<T> removedDifference<T extends SwipeableStackIdentifiable>({
    required List<T> newData,
  }) {
    final oldDataSet = Set<T>.from(this);
    final newDataSet = Set<T>.from(newData);
    return oldDataSet.difference(newDataSet).toList();
  }
}

class _SwipeRatePerThreshold {
  _SwipeRatePerThreshold({
    required this.direction,
    required this.rate,
  }) : assert(rate >= 0);

  final SwipeDirection direction;
  final double rate;
}

extension _SwipeDirectionX on SwipeDirection {
  Offset get _defaultOffset {
    switch (this) {
      case SwipeDirection.left:
        return const Offset(-1, 0);
      case SwipeDirection.right:
        return const Offset(1, 0);
      case SwipeDirection.up:
        return const Offset(0, -1);
      case SwipeDirection.down:
        return const Offset(0, 1);
    }
  }

  bool get _isHorizontal =>
      this == SwipeDirection.right || this == SwipeDirection.left;
}

extension _AnimationControllerX on AnimationController {
  bool get _animating =>
      status == AnimationStatus.forward || status == AnimationStatus.reverse;

  Animation<Offset> _cancelAnimation({
    required Offset startPosition,
    required Offset currentPosition,
  }) {
    return Tween<Offset>(
      begin: currentPosition,
      end: startPosition,
    ).animate(
      CurvedAnimation(
        parent: this,
        curve: const ElasticOutCurve(0.95),
      ),
    );
  }

  Animation<Offset> _swipeAnimation({
    required Offset startPosition,
    required Offset endPosition,
  }) {
    return Tween<Offset>(
      begin: startPosition,
      end: endPosition,
    ).animate(
      CurvedAnimation(
        parent: this,
        curve: const Cubic(0.7, 1, 0.73, 1),
      ),
    );
  }
}

extension _SwipeSessionX on CardDisplayInformation {
  _SwipeRatePerThreshold swipeDirectionRate({
    required BoxConstraints constraints,
    required double horizontalSwipeThreshold,
    required double verticalSwipeThreshold,
  }) {
    final horizontalRate = (difference.dx.abs() / constraints.maxWidth) /
        (horizontalSwipeThreshold / 2);
    final verticalRate = (difference.dy.abs() / constraints.maxHeight) /
        (verticalSwipeThreshold / 2);
    final horizontalRateGreater = horizontalRate >= verticalRate;
    if (horizontalRateGreater) {
      return _SwipeRatePerThreshold(
        direction:
            difference.dx >= 0 ? SwipeDirection.right : SwipeDirection.left,
        rate: horizontalRate,
      );
    } else {
      return _SwipeRatePerThreshold(
        direction: difference.dy >= 0 ? SwipeDirection.down : SwipeDirection.up,
        rate: verticalRate,
      );
    }
  }

  SwipeDirection? swipeAssistDirection({
    required BoxConstraints constraints,
    required double horizontalSwipeThreshold,
    required double verticalSwipeThreshold,
  }) {
    final directionRate = swipeDirectionRate(
      constraints: constraints,
      horizontalSwipeThreshold: horizontalSwipeThreshold,
      verticalSwipeThreshold: verticalSwipeThreshold,
    );
    if (directionRate.rate < 1) {
      return null;
    } else {
      return directionRate.direction;
    }
  }
}

class SwipeableStack<T extends SwipeableStackIdentifiable>
    extends StatefulWidget {
  SwipeableStack({
    SwipeableStackController<T>? controller,
    required this.dataSet,
    required this.builder,
    this.overlayBuilder,
    this.onSwipeCompleted,
    this.onWillMoveNext,
    this.horizontalSwipeThreshold = 0.44,
    this.verticalSwipeThreshold = 0.32,
    this.swipeAssistDuration = const Duration(milliseconds: 650),
    this.viewFraction = 0.92,
    this.stackClipBehaviour = Clip.hardEdge,
    this.persistJudgedCard = false,
  })  : controller = controller ?? SwipeableStackController<T>(),
        assert(0 <= viewFraction && viewFraction <= 1),
        assert(0 <= horizontalSwipeThreshold && horizontalSwipeThreshold <= 1),
        assert(0 <= verticalSwipeThreshold && verticalSwipeThreshold <= 1),
        super(key: controller?._swipeableStackStateKey);

  final SwipeableStackController<T> controller;
  final List<T> dataSet;
  final SwipeableStackItemBuilder<T> builder;
  final SwipeableStackOverlayBuilder<T>? overlayBuilder;
  final SwipeCompletionCallback<T>? onSwipeCompleted;
  final OnWillMoveNext<T>? onWillMoveNext;
  final double viewFraction;
  final double horizontalSwipeThreshold;
  final double verticalSwipeThreshold;
  final Duration swipeAssistDuration;
  final Clip stackClipBehaviour;
  final bool persistJudgedCard;

  @override
  _SwipeableStackState<T> createState() => _SwipeableStackState<T>();
}

class _SwipeableStackState<T extends SwipeableStackIdentifiable>
    extends State<SwipeableStack<T>> with TickerProviderStateMixin {
  late final SwipeableStackController<T> _controller = widget.controller;

  late final AnimationController _swipeCancelAnimationController =
      AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 500),
  );

  late final AnimationController _rewindAnimationController =
      AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 800),
  );

  late final AnimationController _swipeAnimationController =
      AnimationController(
    vsync: this,
  );

  late final AnimationController _swipeAssistController = AnimationController(
    vsync: this,
  );

  bool get _rewinding => _rewindAnimationController._animating;

  bool get _canSwipe =>
      !_swipeAssistController._animating &&
      !_swipeAnimationController._animating &&
      !_rewindAnimationController._animating;

  bool get _canAnimationStart =>
      !_swipeAssistController._animating &&
      !_swipeAnimationController._animating &&
      !_swipeCancelAnimationController._animating &&
      !_rewindAnimationController._animating;

  CardDisplayInformation? _focusCardDisplayInformation;
  BoxConstraints? _areConstraints;

  @override
  void initState() {
    super.initState();
    _controller._cardProperties =
        widget.dataSet.map((data) => CardProperty<T>(data: data)).toList();
    _controller.addListener(_setState);
  }

  @override
  void didUpdateWidget(covariant SwipeableStack<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    final removedFocusProperty = _controller._arrangeCardProperties(
      newDataSet: widget.dataSet,
      persistJudgedCard: widget.persistJudgedCard,
    );
    if (!removedFocusProperty) {
      return;
    }
    _resetAnimations();
    setState(() {
      _focusCardDisplayInformation = null;
    });
  }

  void _resetAnimations() {
    _swipeAnimationController
      ..stop()
      ..reset();
    _swipeAssistController
      ..stop()
      ..reset();
    _swipeCancelAnimationController
      ..stop()
      ..reset();
    _rewindAnimationController
      ..stop()
      ..reset();
  }

  void _setState() {
    setState(() {});
  }

  @override
  void dispose() {
    _swipeCancelAnimationController.dispose();
    _swipeAnimationController.dispose();
    _swipeAssistController.dispose();
    _rewindAnimationController.dispose();
    _controller.removeListener(_setState);
    super.dispose();
  }

  double _distanceToAssist({
    required BuildContext context,
    required Offset difference,
    required SwipeDirection swipeDirection,
  }) {
    final deviceSize = MediaQuery.of(context).size;
    if (swipeDirection._isHorizontal) {
      double _backMoveDistance({
        required double moveDistance,
        required double maxWidth,
        required double maxHeight,
      }) {
        final cardAngle = _SwipeablePositioned._calculateAngle(
          moveDistance,
          maxWidth,
        ).abs();
        return math.cos(math.pi / 2 - cardAngle) * maxHeight;
      }

      double _remainingDistance({
        required double moveDistance,
        required double maxWidth,
        required double maxHeight,
      }) {
        final backMoveDistance = _backMoveDistance(
          moveDistance: moveDistance,
          maxHeight: maxHeight,
          maxWidth: maxWidth,
        );
        final diff = maxWidth - (moveDistance - backMoveDistance);
        return diff < 1
            ? moveDistance
            : _remainingDistance(
                moveDistance: moveDistance + diff,
                maxWidth: maxWidth,
                maxHeight: maxHeight,
              );
      }

      final maxWidth = _areConstraints?.maxWidth ?? deviceSize.width;
      final maxHeight = _areConstraints?.maxHeight ?? deviceSize.height;
      final maxDistance = _remainingDistance(
        moveDistance: maxWidth,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
      );
      return maxDistance - difference.dx.abs();
    } else {
      return deviceSize.height - difference.dy.abs();
    }
  }

  Offset _offsetToAssist({
    required Offset difference,
    required BuildContext context,
    required SwipeDirection swipeDirection,
    required double distToAssist,
  }) {
    final isHorizontal = swipeDirection._isHorizontal;
    if (isHorizontal) {
      final adjustedHorizontally = Offset(difference.dx * 2, difference.dy);
      final absX = adjustedHorizontally.dx.abs();
      final rate = distToAssist / absX;
      return adjustedHorizontally * rate;
    } else {
      final adjustedVertically = Offset(difference.dx, difference.dy * 2);
      final absY = adjustedVertically.dy.abs();
      final rate = distToAssist / absY;
      return adjustedVertically * rate;
    }
  }

  Duration _getSwipeAssistDuration({
    required SwipeDirection swipeDirection,
    required Offset difference,
    required double distToAssist,
  }) {
    final pixelPerMilliseconds = swipeDirection._isHorizontal ? 1.25 : 2.0;

    return Duration(
      milliseconds: math.min(
        distToAssist ~/ pixelPerMilliseconds,
        widget.swipeAssistDuration.inMilliseconds,
      ),
    );
  }

  Duration _getSwipeAnimationDuration({
    required SwipeDirection swipeDirection,
    required Offset difference,
    required double distToAssist,
  }) {
    final pixelPerMilliseconds = swipeDirection._isHorizontal ? 1 : 2;

    return Duration(
      milliseconds: math.min(distToAssist ~/ pixelPerMilliseconds, 650),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _assertLayout(constraints);
        _areConstraints = constraints;
        return GestureDetector(
          onPanStart: (d) {
            if (!_canSwipe) {
              return;
            }

            if (_swipeCancelAnimationController._animating) {
              _swipeCancelAnimationController
                ..stop()
                ..reset();
            }
            setState(() {
              _focusCardDisplayInformation = CardDisplayInformation(
                localPosition: d.localPosition,
                startPosition: d.globalPosition,
                currentPosition: d.globalPosition,
              );
            });
          },
          onPanUpdate: (d) {
            if (!_canSwipe) {
              return;
            }
            if (_swipeCancelAnimationController._animating) {
              _swipeCancelAnimationController
                ..stop()
                ..reset();
            }
            setState(() {
              final updated = _focusCardDisplayInformation?.copyWith(
                currentPosition: d.globalPosition,
              );
              _focusCardDisplayInformation = updated ??
                  CardDisplayInformation(
                    localPosition: d.localPosition,
                    startPosition: d.globalPosition,
                    currentPosition: d.globalPosition,
                  );
            });
          },
          onPanEnd: (d) {
            if (!_canSwipe) {
              return;
            }
            final swipeAssistDirection =
                _focusCardDisplayInformation?.swipeAssistDirection(
              constraints: constraints,
              horizontalSwipeThreshold: widget.horizontalSwipeThreshold,
              verticalSwipeThreshold: widget.verticalSwipeThreshold,
            );

            if (swipeAssistDirection == null) {
              _cancel();
              return;
            }

            bool _allowMoveNext() {
              final _focusCardProperty = _controller._focusCardProperty;
              if (_focusCardProperty == null) {
                return false;
              }
              return widget.onWillMoveNext?.call(
                    _focusCardProperty.data,
                    swipeAssistDirection,
                  ) ??
                  true;
            }

            if (!_allowMoveNext()) {
              _cancel();
              return;
            }
            _swipeNext(swipeAssistDirection);
          },
          child: Stack(
            clipBehavior: widget.stackClipBehaviour,
            children: _buildCards(
              context,
              constraints,
            ),
          ),
        );
      },
    );
  }

  void _assertLayout(BoxConstraints constraints) {
    assert(() {
      if (!constraints.hasBoundedHeight) {
        throw FlutterError('SwipeableStack was given unbounded height.');
      }
      if (!constraints.hasBoundedWidth) {
        throw FlutterError('SwipeableStack was given unbounded width.');
      }
      return true;
    }());
  }

  List<Widget> _buildCards(BuildContext context, BoxConstraints constraints) {
    final session =
        _focusCardDisplayInformation ?? CardDisplayInformation.notMoving();
    final cards = List<Widget>.generate(
        _controller._visibleCardProperties.length, (index) {
      final cp = _controller._visibleCardProperties[index];
      final child = widget.builder(
        context,
        cp.data,
        _areConstraints!,
      );
      return _SwipeablePositioned(
        key: child.key ?? ValueKey(cp.id),
        viewFraction: widget.viewFraction,
        displayInformation: session,
        swipeDirectionRate: session.swipeDirectionRate(
          constraints: constraints,
          horizontalSwipeThreshold: widget.horizontalSwipeThreshold,
          verticalSwipeThreshold: widget.verticalSwipeThreshold,
        ),
        index: index,
        areaConstraints: constraints,
        child: child,
      );
    }).reversed.toList();

    final overlay = _buildOverlay(
      constraints: constraints,
    );
    if (overlay != null) {
      cards.add(overlay);
    }

    // Stand by for rewinding.
    final rewindTargetCard = _rewindTargetCard(
      constraints: constraints,
    );
    if (rewindTargetCard != null) {
      cards.add(rewindTargetCard);
    }
    return cards;
  }

  Widget? _rewindTargetCard({
    required BoxConstraints constraints,
  }) {
    final _rewindTarget = _controller._rewindTarget;
    if (_rewindTarget == null) {
      return null;
    }
    final lastDisplayInformation = _rewindTarget.lastDisplayInformation;
    if (lastDisplayInformation == null) {
      return null;
    }
    final child = widget.builder(
      context,
      _rewindTarget.data,
      _areConstraints!,
    );
    return _SwipeablePositioned(
      key: child.key ?? ValueKey(_rewindTarget.id),
      viewFraction: widget.viewFraction,
      displayInformation: lastDisplayInformation,
      swipeDirectionRate: lastDisplayInformation.swipeDirectionRate(
        constraints: constraints,
        horizontalSwipeThreshold: widget.horizontalSwipeThreshold,
        verticalSwipeThreshold: widget.verticalSwipeThreshold,
      ),
      index: 0,
      areaConstraints: constraints,
      child: child,
    );
  }

  Widget? _buildOverlay({
    required BoxConstraints constraints,
  }) {
    if (_rewinding) {
      return null;
    }
    final _focusCardProperty = _controller._focusCardProperty;
    final swipeDirectionRate = _focusCardDisplayInformation?.swipeDirectionRate(
      constraints: constraints,
      horizontalSwipeThreshold: widget.horizontalSwipeThreshold,
      verticalSwipeThreshold: widget.verticalSwipeThreshold,
    );
    if (swipeDirectionRate == null || _focusCardProperty == null) {
      return null;
    }
    final overlay = widget.overlayBuilder?.call(
      context,
      constraints,
      _focusCardProperty.data,
      swipeDirectionRate.direction,
      swipeDirectionRate.rate,
    );
    if (overlay == null) {
      return null;
    }
    final displayInformation =
        _focusCardDisplayInformation ?? CardDisplayInformation.notMoving();
    return _SwipeablePositioned.overlay(
      viewFraction: widget.viewFraction,
      displayInformation: displayInformation,
      swipeDirectionRate: swipeDirectionRate,
      areaConstraints: constraints,
      child: overlay,
    );
  }

  void _swipeNext(SwipeDirection swipeDirection) {
    if (!_canSwipe) {
      return;
    }
    final _focusCardDisplayInformation = this._focusCardDisplayInformation;
    final _focusCardProperty = _controller._focusCardProperty;
    if (_focusCardDisplayInformation == null || _focusCardProperty == null) {
      return;
    }
    final distToAssist = _distanceToAssist(
      swipeDirection: swipeDirection,
      context: context,
      difference: _focusCardDisplayInformation.difference,
    );
    _swipeAssistController.duration = _getSwipeAssistDuration(
      distToAssist: distToAssist,
      swipeDirection: swipeDirection,
      difference: _focusCardDisplayInformation.difference,
    );

    final animation = _swipeAssistController._swipeAnimation(
      startPosition: _focusCardDisplayInformation.currentPosition,
      endPosition: _focusCardDisplayInformation.currentPosition +
          _offsetToAssist(
            distToAssist: distToAssist,
            difference: _focusCardDisplayInformation.difference,
            context: context,
            swipeDirection: swipeDirection,
          ),
    );

    void animate() {
      _animatePosition(animation);
    }

    animation.addListener(animate);
    _swipeAssistController.forward(from: 0).then(
      (_) {
        animation.removeListener(animate);
        widget.onSwipeCompleted?.call(
          _focusCardProperty.data,
          swipeDirection,
        );
        final cloned = this._focusCardDisplayInformation?.cloned();
        this._focusCardDisplayInformation = null;
        _controller._judge(
          targetId: _focusCardProperty.id,
          isJudged: true,
          lastCardDisplayInformation: cloned,
        );
      },
    ).catchError((dynamic c) {
      animation.removeListener(animate);
      setState(() {
        this._focusCardDisplayInformation = null;
      });
    });
  }

  void _next({
    required SwipeDirection swipeDirection,
    required bool shouldCallCompletionCallback,
    required bool ignoreOnWillMoveNext,
    Duration? duration,
  }) {
    if (!_canAnimationStart) {
      return;
    }
    final _focusCardProperty = _controller._focusCardProperty;
    if (_focusCardProperty == null) {
      return;
    }

    bool allowMoveNext() {
      if (ignoreOnWillMoveNext) {
        return true;
      }
      final onWillMoveNext = widget.onWillMoveNext;
      if (onWillMoveNext == null) {
        return true;
      }
      return onWillMoveNext(
        _focusCardProperty.data,
        swipeDirection,
      );
    }

    if (!allowMoveNext()) {
      return;
    }

    final startPosition = CardDisplayInformation.notMoving();
    setState(() {
      _focusCardDisplayInformation = startPosition;
    });
    final distToAssist = _distanceToAssist(
      swipeDirection: swipeDirection,
      context: context,
      difference: startPosition.difference,
    );
    _swipeAnimationController.duration = duration ??
        _getSwipeAnimationDuration(
          distToAssist: distToAssist,
          swipeDirection: swipeDirection,
          difference: startPosition.difference,
        );

    final animation = _swipeAnimationController._swipeAnimation(
      startPosition: startPosition.currentPosition,
      endPosition: _offsetToAssist(
        distToAssist: distToAssist,
        difference: swipeDirection._defaultOffset,
        context: context,
        swipeDirection: swipeDirection,
      ),
    );

    void animate() {
      _animatePosition(animation);
    }

    animation.addListener(animate);
    _swipeAnimationController.forward(from: 0).then(
      (_) {
        if (shouldCallCompletionCallback) {
          widget.onSwipeCompleted?.call(
            _focusCardProperty.data,
            swipeDirection,
          );
        }
        animation.removeListener(animate);
        final cloned = this._focusCardDisplayInformation?.cloned();
        this._focusCardDisplayInformation = null;
        _controller._judge(
          targetId: _focusCardProperty.id,
          isJudged: true,
          lastCardDisplayInformation: cloned,
        );
      },
    ).catchError((dynamic c) {
      animation.removeListener(animate);
      setState(() {
        this._focusCardDisplayInformation = null;
      });
    });
  }

  void _cancel() {
    final _focusCardDisplayInformation = this._focusCardDisplayInformation;
    if (_focusCardDisplayInformation == null) {
      return;
    }
    final cancelAnimation = _swipeCancelAnimationController._cancelAnimation(
      startPosition: _focusCardDisplayInformation.startPosition,
      currentPosition: _focusCardDisplayInformation.currentPosition,
    );
    void _animate() {
      _animatePosition(cancelAnimation);
    }

    cancelAnimation.addListener(_animate);
    _swipeCancelAnimationController.forward(from: 0).then(
      (_) {
        cancelAnimation.removeListener(_animate);
        setState(() {
          this._focusCardDisplayInformation = null;
        });
      },
    ).catchError((dynamic c) {
      cancelAnimation.removeListener(_animate);
      setState(() {
        this._focusCardDisplayInformation = null;
      });
    });
  }

  void _animatePosition(Animation<Offset> positionAnimation) {
    setState(() {
      _focusCardDisplayInformation = _focusCardDisplayInformation?.copyWith(
        currentPosition: positionAnimation.value,
      );
    });
  }

  void _rewind({
    required Duration duration,
  }) {
    if (!_canAnimationStart) {
      return;
    }
    final _rewindTarget = _controller._rewindTarget;
    if (_rewindTarget == null) {
      return;
    }
    void _prepareRewind() {
      this._focusCardDisplayInformation =
          _rewindTarget.lastDisplayInformation?.cloned();
      _controller._judge(
        targetId: _rewindTarget.id,
        isJudged: false,
        lastCardDisplayInformation: null,
      );
      setState(() {});
    }

    _prepareRewind();

    final _focusCardDisplayInformation = this._focusCardDisplayInformation;
    if (_focusCardDisplayInformation == null) {
      return;
    }
    _rewindAnimationController.duration = duration;
    final rewindAnimation = _rewindAnimationController._cancelAnimation(
      startPosition: _focusCardDisplayInformation.startPosition,
      currentPosition: _focusCardDisplayInformation.currentPosition,
    );
    void _animate() {
      _animatePosition(rewindAnimation);
    }

    rewindAnimation.addListener(_animate);
    _rewindAnimationController.forward(from: 0).then(
      (_) {
        rewindAnimation.removeListener(_animate);
        setState(() {
          this._focusCardDisplayInformation = null;
        });
      },
    ).catchError((dynamic c) {
      rewindAnimation.removeListener(_animate);
      setState(() {
        this._focusCardDisplayInformation = null;
      });
    });
  }
}

class _SwipeablePositioned extends StatelessWidget {
  const _SwipeablePositioned({
    required this.index,
    CardDisplayInformation? displayInformation,
    required this.areaConstraints,
    required this.child,
    required this.swipeDirectionRate,
    required this.viewFraction,
    Key? key,
  })  : _displayInformation = displayInformation,
        assert(0 <= viewFraction && viewFraction <= 1),
        super(key: key);

  static Widget overlay({
    required CardDisplayInformation? displayInformation,
    required BoxConstraints areaConstraints,
    required Widget child,
    required _SwipeRatePerThreshold swipeDirectionRate,
    required double viewFraction,
  }) {
    return _SwipeablePositioned(
      key: const ValueKey('overlay'),
      displayInformation: displayInformation,
      index: 0,
      viewFraction: viewFraction,
      areaConstraints: areaConstraints,
      swipeDirectionRate: swipeDirectionRate,
      child: IgnorePointer(
        child: child,
      ),
    );
  }

  final int index;
  final CardDisplayInformation? _displayInformation;
  final Widget child;
  final BoxConstraints areaConstraints;
  final _SwipeRatePerThreshold swipeDirectionRate;
  final double viewFraction;

  CardDisplayInformation get displayInformation =>
      _displayInformation ?? CardDisplayInformation.notMoving();

  Offset get _currentPositionDiff => displayInformation.difference;

  bool get _isFirst => index == 0;

  bool get _isSecond => index == 1;

  double get _rotationAngle => _isFirst
      ? _calculateAngle(_currentPositionDiff.dx, areaConstraints.maxWidth)
      : 0;

  static double _calculateAngle(double differenceX, double areaWidth) {
    return -differenceX / areaWidth * math.pi / 18;
  }

  Offset get _rotationOrigin =>
      _isFirst ? displayInformation.localPosition : Offset.zero;

  double get _animationRate => 1 - viewFraction;

  double _animationProgress() => Curves.easeOutCubic.transform(
        math.min(swipeDirectionRate.rate, 1),
      );

  BoxConstraints _constraints(BuildContext context) {
    if (_isFirst) {
      return areaConstraints;
    } else if (_isSecond) {
      return areaConstraints *
          (1 - _animationRate + _animationRate * _animationProgress());
    } else {
      return areaConstraints * (1 - _animationRate);
    }
  }

  Offset _preferredPosition(BuildContext context) {
    if (_isFirst) {
      return _currentPositionDiff;
    } else if (_isSecond) {
      final constraintsDiff =
          areaConstraints * (1 - _animationProgress()) * _animationRate / 2;
      return Offset(
        constraintsDiff.maxWidth,
        constraintsDiff.maxHeight,
      );
    } else {
      final maxDiff = areaConstraints * _animationRate / 2;
      return Offset(
        maxDiff.maxWidth,
        maxDiff.maxHeight,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final position = _preferredPosition(context);
    return Positioned(
      top: position.dy,
      left: position.dx,
      child: Transform.rotate(
        angle: _rotationAngle,
        alignment: Alignment.topLeft,
        origin: _rotationOrigin,
        child: ConstrainedBox(
          constraints: _constraints(context),
          child: IgnorePointer(
            ignoring: !_isFirst,
            child: child,
          ),
        ),
      ),
    );
  }
}
