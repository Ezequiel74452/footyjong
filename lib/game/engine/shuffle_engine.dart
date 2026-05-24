import 'dart:math';

import 'package:footyjong/game/models/models.dart';

import 'tile_set.dart';

/// Stateless utility for tile generation and random assignment to board
/// positions.
///
/// [generateTiles] delegates to [TileSet.generateTiles].
/// [assignToPositions] shuffles the tiles and places them into the occupied
/// cells of a [LayoutDefinition], returning the grid structure consumed by
/// [MatchingEngine].
class ShuffleEngine {
  ShuffleEngine._(); // prevent instantiation

  /// Create a full tile list from [config].
  ///
  /// Delegates directly to [TileSet.generateTiles].
  static List<TileData> generateTiles(TileConfig config) {
    return TileSet.generateTiles(config);
  }

  /// Randomly assign [tiles] to the occupied positions of [layout].
  ///
  /// Returns a `tilesByLayer` grid — a `List<List<TileData?>>` where
  /// `result[l][i]` corresponds to position `i = gridY * cols + gridX` on
  /// layer `l`.  Unoccupied cells remain `null`.
  ///
  /// If a [seed] is provided the shuffle is deterministic, which is useful
  /// for testing and replay.
  static List<List<TileData?>> assignToPositions(
    List<TileData> tiles,
    LayoutDefinition layout, {
    int? seed,
  }) {
    final random = seed != null ? Random(seed) : Random();
    final shuffled = List<TileData>.from(tiles)..shuffle(random);

    final result = <List<TileData?>>[];
    int tileIndex = 0;

    for (final layer in layout.layers) {
      final tileCount = layer.rows * layer.cols;
      final layerTiles = List<TileData?>.filled(tileCount, null);

      for (int r = 0; r < layer.rows; r++) {
        for (int c = 0; c < layer.cols; c++) {
          if (layer.occupied[r][c]) {
            layerTiles[r * layer.cols + c] = shuffled[tileIndex];
            tileIndex++;
          }
        }
      }

      result.add(layerTiles);
    }

    return result;
  }
}
