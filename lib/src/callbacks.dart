import 'package:flutter/material.dart';

import 'swipe_direction.dart';
import 'swipeable_stack_identifiable.dart';

typedef SwipeableStackItemBuilder<T extends SwipeableStackIdentifiable> = Widget
    Function(
  BuildContext context,
  T data,
  BoxConstraints constraints,
);

typedef SwipeCompletionCallback<T extends SwipeableStackIdentifiable> = void
    Function(
  T data,
  SwipeDirection direction,
);

typedef OnWillMoveNext<T extends SwipeableStackIdentifiable> = bool Function(
  T data,
  SwipeDirection swipeDirection,
);

typedef SwipeableStackOverlayBuilder<T extends SwipeableStackIdentifiable>
    = Widget Function(
  BuildContext context,
  BoxConstraints constraints,
  T data,
  SwipeDirection direction,
  double swipeProgress,
);
