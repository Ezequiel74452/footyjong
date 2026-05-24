import 'package:footyjong/game/models/models.dart';

/// Stateless utility for Mahjong Solitaire tile-matching logic.
///
/// All methods are static. No state is held — the board state is passed in
/// explicitly as [tilesByLayer] and [layerDefs] every call.
class MatchingEngine {
  MatchingEngine._(); // prevent instantiation

  /// A tile is free (selectable) when **both** conditions hold:
  ///
  /// 1. **No tile in a higher layer** overlaps its projected (gridX, gridY)
  ///    position. Higher layers are centred over the current layer, so the
  ///    projected position is computed with a centering offset.
  ///
  /// 2. **At least one side (left OR right) is unblocked** on its own layer.
  ///    Two tiles block each other when their Y-ranges overlap (within 1 cell)
  ///    AND the other tile sits on the opposite X side.
  static bool isTileFree({
    required int layer,
    required int gridX,
    required int gridY,
    required List<List<TileData?>> tilesByLayer,
    required List<LayerDefinition> layerDefs,
  }) {
    // -----------------------------------------------------------------------
    // 1. Check higher layers — any tile at the projected (gridX, gridY)
    //    position blocks the current tile.
    // -----------------------------------------------------------------------
    for (int l = layer + 1; l < tilesByLayer.length; l++) {
      final aboveDef = layerDefs[l];
      final currentDef = layerDefs[layer];

      // Higher layers are centred.  Compute how many cells the higher layer
      // is inset from each edge of the current layer.
      // Example: current 5×5, above 3×3 → inset of (5-3)/2 = 1 on each side.
      // A tile at current (0,0) projects to above (-1,-1) → outside → not
      // covered.
      final offsetX = (currentDef.cols - aboveDef.cols) ~/ 2;
      final offsetY = (currentDef.rows - aboveDef.rows) ~/ 2;

      // Where does (gridX, gridY) project into the higher layer?
      final aboveGridX = gridX - offsetX;
      final aboveGridY = gridY - offsetY;

      // If the projected cell is inside the higher layer's bounds AND a tile
      // exists there, the current tile is blocked from above.
      if (aboveGridX >= 0 &&
          aboveGridX < aboveDef.cols &&
          aboveGridY >= 0 &&
          aboveGridY < aboveDef.rows) {
        final tileIndex = aboveGridY * aboveDef.cols + aboveGridX;
        if (tileIndex < tilesByLayer[l].length &&
            tilesByLayer[l][tileIndex] != null) {
          return false;
        }
      }
    }

    // -----------------------------------------------------------------------
    // 2. Check left / right blocking on the SAME layer.
    // -----------------------------------------------------------------------
    bool leftBlocked = false;
    bool rightBlocked = false;

    final tilesOnLayer = tilesByLayer[layer];
    final def = layerDefs[layer];

    for (int i = 0; i < tilesOnLayer.length; i++) {
      final otherTile = tilesOnLayer[i];
      if (otherTile == null) continue;

      final otherX = i % def.cols;
      final otherY = i ~/ def.cols;

      // Skip the tile itself.
      if (otherX == gridX && otherY == gridY) continue;

      // Two tiles block each other when their Y-ranges overlap (within a
      // 1-cell tolerance) and they sit on opposite X sides.
      if ((otherY - gridY).abs() <= 1) {
        if (otherX < gridX) leftBlocked = true;
        if (otherX > gridX) rightBlocked = true;
      }
    }

    // A tile is free when at least one side is unblocked.
    return !(leftBlocked && rightBlocked);
  }

  /// Returns `true` when no more matches are possible among currently free
  /// tiles — i.e. every free tile has a unique [TileData.footballerIndex].
  static bool isDeadlocked(
    List<List<TileData?>> tilesByLayer,
    List<LayerDefinition> layerDefs,
  ) {
    final free = getFreeTiles(tilesByLayer, layerDefs);

    // Group free tiles by footballerIndex.
    final groups = <int, int>{};
    for (final tile in free) {
      groups[tile.footballerIndex] =
          (groups[tile.footballerIndex] ?? 0) + 1;
    }

    // If any footballer has ≥ 2 free tiles, a match is possible.
    for (final count in groups.values) {
      if (count >= 2) return false;
    }

    return true;
  }

  /// Returns every tile that is currently free (selectable) on the board.
  static List<TileData> getFreeTiles(
    List<List<TileData?>> tilesByLayer,
    List<LayerDefinition> layerDefs,
  ) {
    final free = <TileData>[];
    for (int l = 0; l < tilesByLayer.length; l++) {
      final def = layerDefs[l];
      final tilesOnLayer = tilesByLayer[l];
      for (int i = 0; i < tilesOnLayer.length; i++) {
        final tile = tilesOnLayer[i];
        if (tile == null) continue;
        final gridX = i % def.cols;
        final gridY = i ~/ def.cols;
        if (isTileFree(
          layer: l,
          gridX: gridX,
          gridY: gridY,
          tilesByLayer: tilesByLayer,
          layerDefs: layerDefs,
        )) {
          free.add(tile);
        }
      }
    }
    return free;
  }
}
