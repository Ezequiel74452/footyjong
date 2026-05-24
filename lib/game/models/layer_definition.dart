class LayerDefinition {
  final int rows;
  final int cols;
  final List<List<bool>> occupied;

  int get positionCount {
    int count = 0;
    for (final row in occupied) {
      for (final cell in row) {
        if (cell) count++;
      }
    }
    return count;
  }

  const LayerDefinition({
    required this.rows,
    required this.cols,
    required this.occupied,
  });
}
