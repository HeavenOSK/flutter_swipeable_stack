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

typedef SwipeableStackItemBuilder<T extends Identifiable> = Widget Function(
  BuildContext context,
  T data,
  BoxConstraints constraints,
);

class SwipeableStack<T extends Identifiable> extends StatefulWidget {
  const SwipeableStack({
    required this.dataSet,
    required this.builder,
    Key? key,
  }) : super(key: key);

  final ValueNotifier<List<T>> dataSet;
  final SwipeableStackItemBuilder<T> builder;

  @override
  _SwipeableStackState<T> createState() => _SwipeableStackState<T>();
}

class _SwipeableStackState<T extends Identifiable>
    extends State<SwipeableStack<T>> with TickerProviderStateMixin {
  late final List<CardProperty<T>> _oldCardProperties;
  BoxConstraints? _areConstraints;

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
          // TODO(heavenOSK): Manage removed items which is swiped.
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
    final notJudgedCardProperties =
        _oldCardProperties.where((element) => !element.isJudged).toList();
    final visibleCardProperties = notJudgedCardProperties.sublist(
      0,
      math.min(3, notJudgedCardProperties.length),
    );

    return List.generate(visibleCardProperties.length, (index) {
      final cp = visibleCardProperties[index];
      return widget.builder(
        context,
        cp.data,
        _areConstraints!,
      );
    }).reversed.toList();
  }
}
