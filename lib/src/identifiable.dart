abstract class SwipeableStackIdentifiable {
  String get id;

  @override
  bool operator ==(Object other) =>
      other is SwipeableStackIdentifiable && id == other.id;

  @override
  int get hashCode => runtimeType.hashCode ^ id.hashCode;
}
