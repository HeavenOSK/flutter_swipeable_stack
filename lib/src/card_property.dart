import 'package:swipeable_stack/src/identifiable.dart';

class CardProperty extends Identifiable {
  CardProperty({
    required this.data,
    this.isJudged = false,
  });

  final Identifiable data;
  final bool isJudged;

  @override
  String get id => data.id;

  CardProperty copyWithJudged({
    required bool isJudged,
  }) {
    return CardProperty(
      data: data,
      isJudged: isJudged,
    );
  }
}
