import 'swipeable_stack.dart';
import 'swipeable_stack_identifiable.dart';
import 'swipeable_stack_position.dart';

/// A class which has [data] & metadata for [SwipeableStack].
class CardProperty<D extends SwipeableStackIdentifiable>
    extends SwipeableStackIdentifiable {
  CardProperty({
    required this.data,
    this.lastPosition,
    this.isJudged = false,
  });

  final D data;
  final bool isJudged;
  final SwipeableStackPosition? lastPosition;

  @override
  String get id => data.id;

  CardProperty<D> copyWith({
    D? data,
    bool? isJudged,
    SwipeableStackPosition? lastPosition,
  }) {
    return CardProperty(
      data: data ?? this.data,
      isJudged: isJudged ?? this.isJudged,
      lastPosition: lastPosition ?? this.lastPosition,
    );
  }
}
