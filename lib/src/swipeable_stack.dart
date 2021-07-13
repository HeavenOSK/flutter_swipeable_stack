import 'dart:math' as math;

import 'package:flutter/material.dart';
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
    Key? key,
  })  : controller = controller ?? SwipeableStackController(),
        super(key: controller?._swipeableStackStateKey);

  final SwipeableStackController controller;
  final ValueNotifier<List<T>> dataSet;
  final SwipeableStackItemBuilder<T> builder;

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
    return List.generate(_visibleCardProperties.length, (index) {
      final cp = _visibleCardProperties[index];
      return Positioned(
        key: ValueKey(cp.id),
        child: widget.builder(
          context,
          cp.data,
          _areConstraints!,
        ),
      );
    }).reversed.toList();
  }

  void _moveFocusForward() {
    final _focusCardProperty = this._focusCardProperty;
    if (_focusCardProperty == null) {
      return;
    }
    final index = _oldCardProperties.indexWhere(
      (cp) => cp.id == _focusCardProperty.id,
    );
    _oldCardProperties.replaceRange(
      index,
      index + 1,
      [_oldCardProperties[index].copyWith(isJudged: true)],
    );
    setState(() {});
  }

  void _moveFocusBack() {
    if (_oldCardProperties.isEmpty) {
      return;
    }
    int _focusIndex() {
      final focusId = _focusCardProperty?.id;
      if (focusId == null) {
        return _oldCardProperties.length;
      }
      return _oldCardProperties.indexWhere(
        (cp) => cp.id == focusId,
      );
    }

    final nextIndex = _focusIndex() - 1;
    if (nextIndex < 0) {
      return;
    }
    _oldCardProperties.replaceRange(
      nextIndex,
      nextIndex + 1,
      [_oldCardProperties[nextIndex].copyWith(isJudged: false)],
    );
    setState(() {});
  }
}
