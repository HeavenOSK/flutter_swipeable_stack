import 'package:collection/collection.dart';

abstract class Identifiable {
  String get id;

  @override
  bool operator ==(Object other) => other is Identifiable && id == other.id;

  @override
  int get hashCode => runtimeType.hashCode ^ id.hashCode;
}

extension DifferenceX on List<Identifiable> {
  Set<T> addedDifference<T extends Identifiable>({
    required List<T> newData,
  }) {
    final oldDataSet = Set<T>.from(this);
    final newDataSet = Set<T>.from(newData);
    return newDataSet.difference(oldDataSet);
  }

  Set<T> removedDifference<T extends Identifiable>({
    required List<T> newData,
  }) {
    final oldDataSet = Set<T>.from(this);
    final newDataSet = Set<T>.from(newData);
    return oldDataSet.difference(newDataSet);
  }

  Identifiable? get(String id) => this.firstWhereOrNull(
        (element) => element.id == id,
      );
}
