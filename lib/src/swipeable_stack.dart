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

class _SwipeRatePerThreshold {
  _SwipeRatePerThreshold({
    required this.direction,
    required this.rate,
  }) : assert(rate >= 0);

  final SwipeDirection direction;
  final double rate;
}

typedef SwipeableStackItemBuilder<T extends Identifiable> = Widget Function(
  BuildContext context,
  T data,
  BoxConstraints constraints,
);

class SwipeableStack<T extends Identifiable> extends StatefulWidget {
  const SwipeableStack({
    required this.dataSets,
    required this.builder,
    Key? key,
  }) : super(key: key);

  final ValueNotifier<List<T>> dataSets;
  final SwipeableStackItemBuilder<T> builder;

  @override
  _SwipeableStackState<T> createState() => _SwipeableStackState<T>();
}

class _SwipeableStackState<T extends Identifiable>
    extends State<SwipeableStack<T>> with TickerProviderStateMixin {
  List<CardProperty<T>> _cardProperties = [];
  BoxConstraints? _areConstraints;

  @override
  void initState() {
    super.initState();
    _cardProperties = widget.dataSets.value
        .map((data) => CardProperty<T>(data: data))
        .toList();
  }

  @override
  void didUpdateWidget(covariant SwipeableStack<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    final difference = widget.dataSets.difference(oldWidget.dataSets);
    if (difference.isEmpty) {
      return;
    }
    for (final item in difference) {
      final added = oldWidget.dataSets.get(item.id);
      if (added != null) {
        _cardProperties.add(CardProperty<T>(data: added as T));
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
    return [];
    // return List.generate(visibleCardProperties.length, (index) {
    //   final cp = visibleCardProperties[index];
    //   return _buildCard(
    //     index: index,
    //     data: cp.data,
    //     child: widget.builder(
    //       context,
    //       cp.data,
    //       _areConstraints!,
    //     ),
    //     constraints: _areConstraints!,
    //   );
    // }).reversed.toList();
  }
}
