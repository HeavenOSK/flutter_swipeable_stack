import 'package:collection/collection.dart';

abstract class Identifiable {
  String get id;

  @override
  bool operator ==(Object other) => other is Identifiable && id == other.id;

  @override
  int get hashCode => runtimeType.hashCode ^ id.hashCode;
}

extension DifferenceX on List<Identifiable> {
  Set<Identifiable> difference(List<Identifiable> oldData) {
    final newDataSet = Set<Identifiable>.from(this);
    final oldDataSet = Set<Identifiable>.from(oldData);
    return newDataSet.difference(oldDataSet);
  }

  Identifiable? get(String id) => this.firstWhereOrNull(
        (element) => element.id == id,
      );
}
