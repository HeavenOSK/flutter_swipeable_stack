import 'package:flutter/material.dart';

import 'identifiable.dart';

enum SwipeDirection {
  left,
  right,
  up,
  down,
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
    Key? key,
  }) : super(key: key);

  final List<Identifiable> dataSets;
  final SwipeableStackItemBuilder builder;

  @override
  _SwipeableStackState createState() => _SwipeableStackState();
}

class _SwipeableStackState extends State<SwipeableStack>
    with TickerProviderStateMixin {
  List<Identifiable> _dataSets = [];

  @override
  void initState() {
    super.initState();
    _dataSets = widget.dataSets;
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
        _dataSets.add(added);
        continue;
      }
      _dataSets.removeWhere((element) => element.id == item.id);
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
