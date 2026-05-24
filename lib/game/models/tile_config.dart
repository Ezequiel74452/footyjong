class TileConfig {
  final int numFootballers;
  final int copiesPerFootballer;
  int get totalTiles => numFootballers * copiesPerFootballer;

  const TileConfig(this.numFootballers, this.copiesPerFootballer);

  static const List<TileConfig> availableConfigs = [
    TileConfig(18, 4), // 72 tiles
    TileConfig(36, 2), // 72 tiles
    TileConfig(36, 4), // 144 tiles
    TileConfig(24, 6), // 144 tiles
    TileConfig(50, 2), // 100 tiles
  ];
}
