class TileData {
  final int id;
  final int footballerIndex;
  final int copyIndex;

  bool isMatchableWith(TileData other) =>
      footballerIndex == other.footballerIndex;

  const TileData({
    required this.id,
    required this.footballerIndex,
    required this.copyIndex,
  });
}
