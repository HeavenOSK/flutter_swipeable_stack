import 'package:flutter/material.dart';

const double _fingerHeight = 50;

class SwipeableStackPosition {
  const SwipeableStackPosition({
    required this.start,
    required this.current,
    required this.local,
  });

  factory SwipeableStackPosition.notMoving() {
    return const SwipeableStackPosition(
      start: Offset.zero,
      current: Offset.zero,
      local: Offset.zero,
    );
  }

  /// The start point of swipe action.
  final Offset start;

  /// The current point of swipe action.
  final Offset current;

  /// The point which user is touching in the component.
  final Offset local;

  @override
  bool operator ==(Object other) =>
      other is SwipeableStackPosition &&
      start == other.start &&
      current == other.current &&
      local == other.local;

  @override
  int get hashCode =>
      runtimeType.hashCode ^ start.hashCode ^ current.hashCode ^ local.hashCode;

  @override
  String toString() => '$SwipeableStackPosition('
      'start:$start,'
      'current:$current,'
      'local:$local'
      ')';

  SwipeableStackPosition cloned() => SwipeableStackPosition(
        start: start,
        current: current,
        local: local,
      );

  SwipeableStackPosition copyWith({
    Offset? startPosition,
    Offset? currentPosition,
    Offset? localPosition,
  }) =>
      SwipeableStackPosition(
        start: startPosition ?? this.start,
        current: currentPosition ?? this.current,
        local: localPosition ?? this.local,
      );

  /// Difference offset from [start] to [current] .
  Offset get difference {
    return current - start;
  }

  /// Adjusted [local] for user's finger.
  Offset? get localFingerPosition {
    return local + const Offset(0, -_fingerHeight);
  }
}
