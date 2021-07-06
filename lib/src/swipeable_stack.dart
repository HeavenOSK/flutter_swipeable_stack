import 'package:flutter/material.dart';
import 'package:swipeable_stack/src/card_property.dart';
import 'dart:math' as math;

import 'identifiable.dart';
import 'swipe_session.dart';

enum SwipeDirection {
  left,
  right,
  up,
  down,
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
  Offset get defaultOffset {
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

  bool get isHorizontal =>
      this == SwipeDirection.right || this == SwipeDirection.left;
}

extension _AnimationControllerX on AnimationController {
  bool get animating =>
      status == AnimationStatus.forward || status == AnimationStatus.reverse;

  Animation<Offset> cancelAnimation({
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

  Animation<Offset> swipeAnimation({
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

extension _SwipeSessionX on SwipeSession {
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

typedef SwipeableStackItemBuilder = Widget Function(
  BuildContext context,
  Identifiable dataSet,
  BoxConstraints constraints,
);

class SwipeableStack extends StatefulWidget {
  const SwipeableStack({
    required this.builder,
    this.dataSets = const [],
    this.viewFraction = _defaultViewFraction,
    this.horizontalSwipeThreshold = _defaultHorizontalSwipeThreshold,
    this.verticalSwipeThreshold = _defaultVerticalSwipeThreshold,
    Key? key,
  }) : super(key: key);

  final List<Identifiable> dataSets;
  final SwipeableStackItemBuilder builder;
  final double viewFraction;

  static const double _defaultHorizontalSwipeThreshold = 0.44;
  static const double _defaultVerticalSwipeThreshold = 0.32;
  static const double _defaultViewFraction = 0.92;

  final double horizontalSwipeThreshold;

  final double verticalSwipeThreshold;

  static const _defaultRewindDuration = Duration(milliseconds: 650);

  static const _defaultSwipeAssistDuration = Duration(milliseconds: 650);

  static const _defaultStackClipBehaviour = Clip.hardEdge;

  @override
  _SwipeableStackState createState() => _SwipeableStackState();
}

class _SwipeableStackState extends State<SwipeableStack>
    with TickerProviderStateMixin {
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

  bool get canSwipe =>
      !_swipeAssistController.animating &&
      !_swipeAnimationController.animating &&
      !_rewindAnimationController.animating;

  bool get canAnimationStart =>
      !_swipeAssistController.animating &&
      !_swipeAnimationController.animating &&
      !_swipeCancelAnimationController.animating &&
      !_rewindAnimationController.animating;

  List<CardProperty> _cardProperties = [];
  BoxConstraints? _areConstraints;
  SwipeSession? _currentSession;

  @override
  void initState() {
    super.initState();
    _cardProperties =
        widget.dataSets.map((data) => CardProperty(data: data)).toList();
  }

  @override
  void didUpdateWidget(covariant SwipeableStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    final difference = widget.dataSets.difference(oldWidget.dataSets);
    if (difference.isEmpty) {
      return;
    }
    for (final item in difference) {
      final added = oldWidget.dataSets.get(item.id);
      if (added != null) {
        _cardProperties.add(CardProperty(data: added));
        continue;
      }
      _cardProperties.removeWhere((element) => element.id == item.id);
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _assertLayout(constraints);
        _areConstraints = constraints;
        return Stack(
          children: _buildCards(
            context,
            constraints,
          ),
        );
      },
    );
  }

  void _assertLayout(BoxConstraints constraints) {
    assert(() {
      if (!constraints.hasBoundedHeight) {
        throw FlutterError('SwipableStack was given unbounded height.');
      }
      if (!constraints.hasBoundedWidth) {
        throw FlutterError('SwipableStack was given unbounded width.');
      }
      return true;
    }());
  }

  List<Widget> _buildCards(BuildContext context, BoxConstraints constraints) {
    final notJudgedCardProperties =
        _cardProperties.where((element) => !element.isJudged).toList();
    final visibleCardProperties = notJudgedCardProperties
        .sublist(math.min(3, notJudgedCardProperties.length));

    return List.generate(visibleCardProperties.length, (index) {
      final cp = visibleCardProperties[index];
      return _buildCard(
        index: index,
        data: cp.data,
        child: widget.builder(
          context,
          cp.data,
          _areConstraints!,
        ),
        constraints: _areConstraints!,
      );
    });
  }

  Widget _buildCard({
    required int index,
    required Identifiable data,
    required Widget child,
    required BoxConstraints constraints,
  }) {
    final session = _currentSession ?? SwipeSession.notMoving();
    return _SwipablePositioned(
      key: ValueKey(data.id),
      session: session,
      index: index,
      viewFraction: widget.viewFraction,
      swipeDirectionRate: session.swipeDirectionRate(
        constraints: constraints,
        horizontalSwipeThreshold: widget.horizontalSwipeThreshold,
        verticalSwipeThreshold: widget.verticalSwipeThreshold,
      ),
      areaConstraints: constraints,
      child: GestureDetector(
        key: child.key,
        onPanStart: (d) {
          if (!canSwipe) {
            return;
          }

          if (_swipeCancelAnimationController.animating) {
            _swipeCancelAnimationController
              ..stop()
              ..reset();
          }
          _currentSession = updateSwipe(
            SwipeSession(
              localPosition: d.localPosition,
              startPosition: d.globalPosition,
              currentPosition: d.globalPosition,
            ),
          );
        },
        onPanUpdate: (d) {
          if (!canSwipe) {
            return;
          }
          if (_swipeCancelAnimationController.animating) {
            _swipeCancelAnimationController
              ..stop()
              ..reset();
          }
          final updated = _currentSession?.copyWith(
            currentPosition: d.globalPosition,
          );
          widget.controller.updateSwipe(
            updated ??
                SwipeSession(
                  localPosition: d.localPosition,
                  startPosition: d.globalPosition,
                  currentPosition: d.globalPosition,
                ),
          );
        },
        onPanEnd: (d) {
          if (!canSwipe) {
            return;
          }
          final swipeAssistDirection = _currentSession?.swipeAssistDirection(
            constraints: constraints,
            horizontalSwipeThreshold: widget.horizontalSwipeThreshold,
            verticalSwipeThreshold: widget.verticalSwipeThreshold,
          );

          if (swipeAssistDirection == null) {
            _cancelSwipe();
            return;
          }
          final allowMoveNext = widget.onWillMoveNext?.call(
                _currentIndex,
                swipeAssistDirection,
              ) ??
              true;
          if (!allowMoveNext) {
            _cancelSwipe();
            return;
          }
          _swipeNext(swipeAssistDirection);
        },
        child: child,
      ),
    );
  }

  void _animatePosition(Animation<Offset> positionAnimation) {
    _updateSwipe(
      _currentSession?.copyWith(
        currentPosition: positionAnimation.value,
      ),
    );
  }

  void _updateSwipe(SwipeSession? session) {
    if (_currentSession == session) {
      return;
    }
    setState(() {
      _currentSession = session;
    });
  }

  void _cancelSwipe() {
    final currentSession = widget.controller.currentSession;
    if (currentSession == null) {
      return;
    }
    final cancelAnimation = _swipeCancelAnimationController.cancelAnimation(
      startPosition: currentSession.startPosition,
      currentPosition: currentSession.currentPosition,
    );
    void _animate() {
      _animatePosition(cancelAnimation);
    }

    cancelAnimation.addListener(_animate);
    _swipeCancelAnimationController.forward(from: 0).then(
          (_) {
        cancelAnimation.removeListener(_animate);
        widget.controller.cancelAction();
      },
    ).catchError((dynamic c) {
      cancelAnimation.removeListener(_animate);
      widget.controller.cancelAction();
    });
  }

  void _swipeNext(SwipeDirection swipeDirection) {
    if (!canSwipe) {
      return;
    }
    final currentSession = widget.controller.currentSession;
    if (currentSession == null) {
      return;
    }
    final distToAssist = _distanceToAssist(
      swipeDirection: swipeDirection,
      context: context,
      difference: currentSession.difference,
    );
    _swipeAssistController.duration = _getSwipeAssistDuration(
      distToAssist: distToAssist,
      swipeDirection: swipeDirection,
      difference: currentSession.difference,
    );

    final animation = _swipeAssistController.swipeAnimation(
      startPosition: currentSession.currentPosition,
      endPosition: currentSession.currentPosition +
          _offsetToAssist(
            distToAssist: distToAssist,
            difference: currentSession.difference,
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
        widget.controller.completeAction();
      },
    ).catchError((dynamic c) {
      animation.removeListener(animate);
      widget.controller.cancelAction();
    });
  }
  void completeAction() {

    _currentSessionState = null;
    notifyListeners();
  }
}

class _SwipablePositioned extends StatelessWidget {
  const _SwipablePositioned({
    required this.index,
    required this.session,
    required this.areaConstraints,
    required this.child,
    required this.swipeDirectionRate,
    required this.viewFraction,
    Key? key,
  })  : assert(0 <= viewFraction && viewFraction <= 1),
        super(key: key);

  static Widget overlay({
    required SwipeSession session,
    required BoxConstraints areaConstraints,
    required Widget child,
    required _SwipeRatePerThreshold swipeDirectionRate,
    required double viewFraction,
  }) {
    return _SwipablePositioned(
      key: const ValueKey('overlay'),
      session: session,
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
  final SwipeSession session;
  final Widget child;
  final BoxConstraints areaConstraints;
  final _SwipeRatePerThreshold swipeDirectionRate;
  final double viewFraction;

  Offset get _currentPositionDiff => session.difference;

  bool get _isFirst => index == 0;

  bool get _isSecond => index == 1;

  double get _rotationAngle => _isFirst
      ? calculateAngle(_currentPositionDiff.dx, areaConstraints.maxWidth)
      : 0;

  static double calculateAngle(double differenceX, double areaWidth) {
    return -differenceX / areaWidth * math.pi / 18;
  }

  Offset get _rotationOrigin => _isFirst ? session.localPosition : Offset.zero;

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
