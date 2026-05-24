class Position3D {
  final int gridX;
  final int gridY;
  final int layer;
  int get zOrder => layer * 10000 + gridY * 100 + gridX;

  const Position3D({
    required this.gridX,
    required this.gridY,
    required this.layer,
  });

  @override
  bool operator ==(Object other) =>
      other is Position3D &&
      other.gridX == gridX &&
      other.gridY == gridY &&
      other.layer == layer;

  @override
  int get hashCode => Object.hash(gridX, gridY, layer);
}
