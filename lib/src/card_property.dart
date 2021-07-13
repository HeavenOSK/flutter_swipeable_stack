import 'package:swipeable_stack/src/card_display_information.dart';
import 'package:swipeable_stack/src/identifiable.dart';

class CardProperty<T extends Identifiable> extends Identifiable {
  CardProperty({
    required this.data,
    this.displayInformation,
    this.isJudged = false,
  });

  final T data;
  final bool isJudged;
  final CardDisplayInformation? displayInformation;

  @override
  String get id => data.id;

  CardProperty<T> copyWith({
    T? data,
    bool? isJudged,
    CardDisplayInformation? displayInformation,
  }) {
    return CardProperty(
      data: data ?? this.data,
      isJudged: isJudged ?? this.isJudged,
      displayInformation: displayInformation ?? this.displayInformation,
    );
  }
}
