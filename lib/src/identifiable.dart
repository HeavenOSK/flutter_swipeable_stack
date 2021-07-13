abstract class SwipeableStackIdentifiable {
  String get id;

  @override
  bool operator ==(Object other) =>
      other is SwipeableStackIdentifiable && id == other.id;

  @override
  int get hashCode => runtimeType.hashCode ^ id.hashCode;
}

extension DifferenceX on List<SwipeableStackIdentifiable> {
  Set<T> addedDifference<T extends SwipeableStackIdentifiable>({
    required List<T> newData,
  }) {
    final oldDataSet = Set<T>.from(this);
    final newDataSet = Set<T>.from(newData);
    return newDataSet.difference(oldDataSet);
  }

  Set<T> removedDifference<T extends SwipeableStackIdentifiable>({
    required List<T> newData,
  }) {
    final oldDataSet = Set<T>.from(this);
    final newDataSet = Set<T>.from(newData);
    return oldDataSet.difference(newDataSet);
  }
}
