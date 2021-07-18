import 'package:flutter/material.dart';

import 'swipe_direction.dart';
import 'swipeable_stack.dart';
import 'swipeable_stack_identifiable.dart';

/// A callback to build Widget with a [data].
typedef SwipeableStackItemBuilder<D extends SwipeableStackIdentifiable> = Widget
    Function(
  BuildContext context,
  D data,
  BoxConstraints constraints,
);

/// A callback to show as a card with a [data].
typedef SwipeCompletionCallback<D extends SwipeableStackIdentifiable> = void
    Function(
  D data,
  SwipeDirection direction,
);

/// A callback for [SwipeableStack.onWillMoveNext].
typedef OnWillMoveNext<D extends SwipeableStackIdentifiable> = bool Function(
  D data,
  SwipeDirection swipeDirection,
);

/// A callback for [SwipeableStack.overlayBuilder].
typedef SwipeableStackOverlayBuilder<D extends SwipeableStackIdentifiable>
    = Widget Function(
  BuildContext context,
  BoxConstraints constraints,
  D data,
  SwipeDirection direction,
  double swipeProgress,
);
