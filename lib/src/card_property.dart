import 'package:swipeable_stack/src/swipeable_stack_identifiable.dart';
import 'package:swipeable_stack/src/swipeable_stack_position.dart';

class CardProperty<T extends SwipeableStackIdentifiable>
    extends SwipeableStackIdentifiable {
  CardProperty({
    required this.data,
    this.lastPosition,
    this.isJudged = false,
  });

  final T data;
  final bool isJudged;
  final SwipeableStackPosition? lastPosition;

  @override
  String get id => data.id;

  CardProperty<T> copyWith({
    T? data,
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
