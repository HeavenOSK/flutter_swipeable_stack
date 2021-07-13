import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:swipeable_stack/src/card_display_information.dart';
import 'package:swipeable_stack/src/card_property.dart';

import 'identifiable.dart';

enum SwipeDirection {
  left,
  right,
  up,
  down,
}

class SwipeableStackController {
  SwipeableStackController();

  /// The key for [SwipableStack] to control.
  final _swipeableStackStateKey = GlobalKey<_SwipeableStackState>();

  void next() {
    _swipeableStackStateKey.currentState?._moveFocusForward();
  }

  void rewind() {
    _swipeableStackStateKey.currentState?._moveFocusBack();
  }
}

extension _ReplaceAt<E> on List<E> {
  void replaceAt(
    int index, {
    required E replacement,
  }) =>
      this.replaceRange(index, index + 1, [replacement]);
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

typedef SwipeableStackItemBuilder<T extends Identifiable> = Widget Function(
  BuildContext context,
  T data,
  BoxConstraints constraints,
);

class SwipeableStack<T extends Identifiable> extends StatefulWidget {
  SwipeableStack({
    SwipeableStackController? controller,
    required this.dataSet,
    required this.builder,
    this.horizontalSwipeThreshold = _defaultHorizontalSwipeThreshold,
    this.verticalSwipeThreshold = _defaultVerticalSwipeThreshold,
    this.viewFraction = _defaultViewFraction,
  })  : controller = controller ?? SwipeableStackController(),
        super(key: controller?._swipeableStackStateKey);

  final SwipeableStackController controller;
  final ValueNotifier<List<T>> dataSet;
  final SwipeableStackItemBuilder<T> builder;
  final double viewFraction;

  final double horizontalSwipeThreshold;

  final double verticalSwipeThreshold;

  static const double _defaultHorizontalSwipeThreshold = 0.44;
  static const double _defaultVerticalSwipeThreshold = 0.32;
  static const double _defaultViewFraction = 0.92;

  static const _defaultRewindDuration = Duration(milliseconds: 650);

  static const _defaultSwipeAssistDuration = Duration(milliseconds: 650);

  static const _defaultStackClipBehaviour = Clip.hardEdge;

  @override
  _SwipeableStackState<T> createState() => _SwipeableStackState<T>();
}

class _SwipeableStackState<T extends Identifiable>
    extends State<SwipeableStack<T>> with TickerProviderStateMixin {
  late final List<CardProperty<T>> _oldCardProperties;
  BoxConstraints? _areConstraints;

  List<CardProperty<T>> get _visibleCardProperties {
    final notJudgedCardProperties =
        _oldCardProperties.where((element) => !element.isJudged).toList();
    return notJudgedCardProperties.sublist(
      0,
      math.min(3, notJudgedCardProperties.length),
    );
  }

  CardProperty<T>? get _focusCardProperty =>
      _visibleCardProperties.isNotEmpty ? _visibleCardProperties.first : null;

  CardDisplayInformation? _focusCardDisplayInformation;

  int? get _focusIndex {
    final focusId = _focusCardProperty?.id;
    if (focusId == null) {
      return null;
    }
    return _oldCardProperties.indexWhere(
      (cp) => cp.id == focusId,
    );
  }

  @override
  void initState() {
    super.initState();
    _oldCardProperties = widget.dataSet.value
        .map((data) => CardProperty<T>(data: data))
        .toList();
    widget.dataSet.addListener(
      () {
        final newCardProperties = widget.dataSet.value
            .map((data) => CardProperty<T>(data: data))
            .toList();
        final removed = _oldCardProperties.removedDifference(
          newData: newCardProperties,
        );
        final added = _oldCardProperties.addedDifference(
          newData: newCardProperties,
        );
        for (final item in removed) {
          _oldCardProperties.removeWhere((element) => element.id == item.id);
        }
        for (final item in added) {
          _oldCardProperties.add(item);
        }
        setState(() {});
      },
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
            // if (!_canSwipe) {
            //   return;
            // }
            //
            // if (_swipeCancelAnimationController._animating) {
            //   _swipeCancelAnimationController
            //     ..stop()
            //     ..reset();
            // }
            setState(() {
              _focusCardDisplayInformation = CardDisplayInformation(
                localPosition: d.localPosition,
                startPosition: d.globalPosition,
                currentPosition: d.globalPosition,
              );
            });
          },
          onPanUpdate: (d) {
            // if (!_canSwipe) {
            //   return;
            // }
            // if (_swipeCancelAnimationController._animating) {
            //   _swipeCancelAnimationController
            //     ..stop()
            //     ..reset();
            // }
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
            // if (!_canSwipe) {
            //   return;
            // }
            // final swipeAssistDirection = _currentSession?.swipeAssistDirection(
            //   constraints: constraints,
            //   horizontalSwipeThreshold: widget.horizontalSwipeThreshold,
            //   verticalSwipeThreshold: widget.verticalSwipeThreshold,
            // );

            // if (swipeAssistDirection == null) {
            //   _cancelSwipe();
            //   return;
            // }
          },
          child: Stack(
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
    return List.generate(_visibleCardProperties.length, (index) {
      final cp = _visibleCardProperties[index];
      final child = widget.builder(
        context,
        cp.data,
        _areConstraints!,
      );
      return _SwipablePositioned(
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
  }

  void _moveFocusForward() {
    final _focusIndex = this._focusIndex;
    if (_focusIndex == null) {
      return;
    }
    _oldCardProperties.replaceAt(
      _focusIndex,
      replacement: _oldCardProperties[_focusIndex].copyWith(
        isJudged: true,
      ),
    );
    setState(() {});
  }

  void _moveFocusBack() {
    final focusIndex = _focusIndex ?? _oldCardProperties.length;
    final nextIndex = focusIndex - 1;
    if (nextIndex < 0) {
      return;
    }
    _oldCardProperties.replaceAt(
      nextIndex,
      replacement: _oldCardProperties[nextIndex].copyWith(
        isJudged: false,
      ),
    );
    setState(() {});
  }
}

class _SwipablePositioned extends StatelessWidget {
  const _SwipablePositioned({
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
