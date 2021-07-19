import 'swipeable_stack.dart';

/// An abstract class to identify the data for [SwipeableStack].
abstract class SwipeableStackIdentifiable {
  /// A string to identify the data.
  String get id;
  @override
  bool operator ==(Object other) =>
      other is SwipeableStackIdentifiable && id == other.id;

  @override
  int get hashCode => runtimeType.hashCode ^ id.hashCode;
}
