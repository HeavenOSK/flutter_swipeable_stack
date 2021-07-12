import 'package:swipeable_stack/src/identifiable.dart';

class CardProperty<T extends Identifiable> extends Identifiable {
  CardProperty({
    required this.data,
    this.isJudged = false,
  });

  final T data;
  final bool isJudged;

  @override
  String get id => data.id;

  CardProperty<T> copyWithJudged({
    required bool isJudged,
  }) {
    return CardProperty(
      data: data,
      isJudged: isJudged,
    );
  }
}
