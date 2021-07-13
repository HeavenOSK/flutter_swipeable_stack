import 'package:flutter/material.dart';

import 'identifiable.dart';
import 'swipeable_stack.dart';

typedef SwipeableStackItemBuilder<T extends Identifiable> = Widget Function(
  BuildContext context,
  T data,
  BoxConstraints constraints,
);

typedef SwipeCompletionCallback<T extends Identifiable> = void Function(
  T data,
  SwipeDirection direction,
);

typedef OnWillMoveNext<T extends Identifiable> = bool Function(
  T data,
  SwipeDirection swipeDirection,
);

typedef SwipeableStackOverlayBuilder<T extends Identifiable> = Widget Function(
  BuildContext context,
  BoxConstraints constraints,
  T data,
  SwipeDirection direction,
  double swipeProgress,
);
