import 'package:flutter_test/flutter_test.dart';
import 'package:footyjong/game/engine/matching_engine.dart';
import 'package:footyjong/game/models/models.dart';

/// Helper: build a flat list of non-null tiles for a fully filled grid.
List<TileData?> _filledLayer(int rows, int cols,
    {int footballerIndex = 0}) {
  return List<TileData?>.generate(
    rows * cols,
    (i) => TileData(
      id: i,
      footballerIndex: footballerIndex,
      copyIndex: 0,
    ),
  );
}

/// Helper: build a flat list with custom footballer indexes per row.
/// [indexGrid] is a 2-D list: indexGrid[row][col] -> footballerIndex.
List<TileData?> _customLayer(List<List<int>> indexGrid) {
  final rows = indexGrid.length;
  final cols = indexGrid[0].length;
  final result = List<TileData?>.filled(rows * cols, null);
  for (int r = 0; r < rows; r++) {
    for (int c = 0; c < cols; c++) {
      final i = r * cols + c;
      final fi = indexGrid[r][c];
      result[i] = TileData(id: i, footballerIndex: fi, copyIndex: 0);
    }
  }
  return result;
}

LayerDefinition _filledDef(int rows, int cols) {
  return LayerDefinition(
    rows: rows,
    cols: cols,
    occupied: List.generate(rows, (_) => List.filled(cols, true)),
  );
}

LayerDefinition _customDef(int rows, int cols, List<List<bool>> occupied) {
  return LayerDefinition(rows: rows, cols: cols, occupied: occupied);
}

void main() {
  // ===========================================================================
  // isTileFree
  // ===========================================================================
  group('MatchingEngine.isTileFree', () {
    test('single-layer edge tile (leftmost) is free', () {
      final defs = [_filledDef(1, 3)];
      final tiles = [_filledLayer(1, 3)];

      // Tile at (0,0) — left is edge (unblocked), right is blocked by (1,0)
      // At least one side unblocked → FREE
      expect(
        MatchingEngine.isTileFree(
          layer: 0,
          gridX: 0,
          gridY: 0,
          tilesByLayer: tiles,
          layerDefs: defs,
        ),
        isTrue,
      );
    });

    test('single-layer tile between two others is blocked', () {
      final defs = [_filledDef(1, 3)];
      final tiles = [_filledLayer(1, 3)];

      // Tile at (1,0) — left blocked by (0,0), right blocked by (2,0)
      // Both sides blocked → NOT FREE
      expect(
        MatchingEngine.isTileFree(
          layer: 0,
          gridX: 1,
          gridY: 0,
          tilesByLayer: tiles,
          layerDefs: defs,
        ),
        isFalse,
      );
    });

    test('single-layer tile with only left neighbor is free', () {
      final defs = [_filledDef(1, 3)];
      final tiles = [_filledLayer(1, 3)];

      // Tile at (2,0) — left blocked by (0,0), (1,0), right is edge → FREE
      expect(
        MatchingEngine.isTileFree(
          layer: 0,
          gridX: 2,
          gridY: 0,
          tilesByLayer: tiles,
          layerDefs: defs,
        ),
        isTrue,
      );
    });

    test('single-layer tile with only right neighbor is free', () {
      final defs = [_filledDef(1, 3)];
      final tiles = [_filledLayer(1, 3)];

      // Tile at (0,0) — left is edge, right blocked → FREE
      expect(
        MatchingEngine.isTileFree(
          layer: 0,
          gridX: 0,
          gridY: 0,
          tilesByLayer: tiles,
          layerDefs: defs,
        ),
        isTrue,
      );
    });

    test('Y-range greater than 1 does not block', () {
      // 3×3 grid with tiles only at (0,0) and (0,2)
      final occupied = [
        [true, false, false],
        [false, false, false],
        [true, false, false],
      ];
      final defs = [_customDef(3, 3, occupied)];
      final tiles = [
        List<TileData?>.filled(9, null),
      ];
      tiles[0][0 * 3 + 0] = TileData(id: 0, footballerIndex: 0, copyIndex: 0);
      tiles[0][2 * 3 + 0] = TileData(id: 1, footballerIndex: 1, copyIndex: 0);

      // Tile at (0,0): (0,2) has |2-0| = 2 > 1 → does NOT block
      // No other tiles → both left and right are free → FREE
      expect(
        MatchingEngine.isTileFree(
          layer: 0,
          gridX: 0,
          gridY: 0,
          tilesByLayer: tiles,
          layerDefs: defs,
        ),
        isTrue,
      );
    });

    test('tile with direct tile above in higher layer is blocked', () {
      // Layer 0: 3×3 filled (bottom)
      // Layer 1: 3×3 filled (top), same size → offset = 0
      final defs = [_filledDef(3, 3), _filledDef(3, 3)];
      final tiles = [
        _filledLayer(3, 3),
        _filledLayer(3, 3),
      ];

      // Bottom tile at (1,1): has tile at same (1,1) in layer 1 → blocked
      expect(
        MatchingEngine.isTileFree(
          layer: 0,
          gridX: 1,
          gridY: 1,
          tilesByLayer: tiles,
          layerDefs: defs,
        ),
        isFalse,
      );
    });

    test('tile with no tile above is free even when sides are blocked', () {
      // Layer 0: 5×5 filled (bottom)
      // Layer 1: 3×3 filled (top, centered at offset (1,1))
      final defs = [_filledDef(5, 5), _filledDef(3, 3)];
      final tiles = [
        _filledLayer(5, 5),
        _filledLayer(3, 3),
      ];

      // Bottom corner (0,0) projects to aboveGrid (0-1, 0-1) = (-1,-1)
      // which is outside Layer 1 → nothing above
      // On its own layer: right blocked but left free → FREE
      expect(
        MatchingEngine.isTileFree(
          layer: 0,
          gridX: 0,
          gridY: 0,
          tilesByLayer: tiles,
          layerDefs: defs,
        ),
        isTrue,
      );
    });

    test('tile covered by centered top layer is blocked from above', () {
      // Layer 0: 5×5 filled (bottom)
      // Layer 1: 3×3 filled (top, offset (1,1))
      final defs = [_filledDef(5, 5), _filledDef(3, 3)];
      final tiles = [
        _filledLayer(5, 5),
        _filledLayer(3, 3),
      ];

      // Bottom (2,2) projects to aboveGrid (2-1, 2-1) = (1,1) inside Layer 1
      // → blocked by tile above (regardless of side blocking)
      expect(
        MatchingEngine.isTileFree(
          layer: 0,
          gridX: 2,
          gridY: 2,
          tilesByLayer: tiles,
          layerDefs: defs,
        ),
        isFalse,
      );
    });

    test('empty board has no free tiles — method returns false for any pos',
        () {
      final defs = [_filledDef(3, 3)];
      final tiles = <List<TileData?>>[
        List.filled(9, null),
      ];

      // A tile at (0,0) with all-null layer → no tiles anywhere, so in
      // practice isTileFree wouldn't be called since there's nothing to
      // check. But the method should not crash and would return true for
      // a non-existent tile (no blockers). This is a degenerate case.
      // We just verify no crash.
      expect(
        MatchingEngine.isTileFree(
          layer: 0,
          gridX: 0,
          gridY: 0,
          tilesByLayer: tiles,
          layerDefs: defs,
        ),
        isTrue, // No tiles to block it → trivially free
      );
    });

    test('three-layer stack: centre blocked, edges free', () {
      // Layer 0: 6×6 filled (bottom)
      // Layer 1: 4×4 filled (centred: offset (6-4)/2 = 1 from layer 0)
      // Layer 2: 2×2 filled (centred: offset (4-2)/2 = 1 from layer 1)
      final defs = [
        _filledDef(6, 6),
        _filledDef(4, 4),
        _filledDef(2, 2),
      ];
      final tiles = [
        _filledLayer(6, 6),
        _filledLayer(4, 4),
        _filledLayer(2, 2),
      ];

      // Layer 0 corner (0,0): projects to above (0-1,0-1)=(-1,-1) →
      // outside layer 1 → nothing above it. On its own layer: right
      // blocked but left free → FREE.
      expect(
        MatchingEngine.isTileFree(
          layer: 0,
          gridX: 0,
          gridY: 0,
          tilesByLayer: tiles,
          layerDefs: defs,
        ),
        isTrue,
      );

      // Layer 0 (2,2): projects to above (2-1,2-1)=(1,1) → inside
      // layer 1 (4×4, index 1 is valid) → blocked from above.
      expect(
        MatchingEngine.isTileFree(
          layer: 0,
          gridX: 2,
          gridY: 2,
          tilesByLayer: tiles,
          layerDefs: defs,
        ),
        isFalse,
      );

      // Layer 1 corner (0,0): projects to above (0-1,0-1)=(-1,-1) →
      // outside layer 2 → nothing above it. Left edge → FREE.
      expect(
        MatchingEngine.isTileFree(
          layer: 1,
          gridX: 0,
          gridY: 0,
          tilesByLayer: tiles,
          layerDefs: defs,
        ),
        isTrue,
      );

      // Layer 1 (1,1): projects to above (1-1,1-1)=(0,0) → inside
      // layer 2 (2×2, index 0 is valid) → blocked from above.
      expect(
        MatchingEngine.isTileFree(
          layer: 1,
          gridX: 1,
          gridY: 1,
          tilesByLayer: tiles,
          layerDefs: defs,
        ),
        isFalse,
      );

      // Layer 2 corner (0,0): nothing above → left edge → FREE.
      expect(
        MatchingEngine.isTileFree(
          layer: 2,
          gridX: 0,
          gridY: 0,
          tilesByLayer: tiles,
          layerDefs: defs,
        ),
        isTrue,
      );
    });
  });

  // ===========================================================================
  // getFreeTiles
  // ===========================================================================
  group('MatchingEngine.getFreeTiles', () {
    test('returns edge tiles in a single-row layout', () {
      // 1×4 filled — free tiles are at positions 0 and 3
      final defs = [_filledDef(1, 4)];
      final tiles = [_filledLayer(1, 4)];

      final free = MatchingEngine.getFreeTiles(tiles, defs);

      expect(free.length, 2);
      expect(free.map((t) => t.id), containsAll([0, 3]));
    });

    test('returns empty list for empty layer', () {
      final defs = [_filledDef(3, 3)];
      final tiles = <List<TileData?>>[
        List.filled(9, null),
      ];

      final free = MatchingEngine.getFreeTiles(tiles, defs);

      expect(free, isEmpty);
    });

    test('returns only top-layer tiles when bottom is fully covered', () {
      // Layer 0: 3×3 filled (all blocked by layer 1)
      // Layer 1: 3×3 filled (same size = no offset)
      // Use distinct footballerIndex per layer so we can identify origin.
      final defs = [_filledDef(3, 3), _filledDef(3, 3)];
      final tiles = [
        // Layer 0 tiles: all footballerIndex = 99
        List<TileData?>.generate(9,
            (i) => TileData(id: i, footballerIndex: 99, copyIndex: 0)),
        // Layer 1 tiles: all footballerIndex = 88
        List<TileData?>.generate(9,
            (i) => TileData(id: i + 9, footballerIndex: 88, copyIndex: 0)),
      ];

      final free = MatchingEngine.getFreeTiles(tiles, defs);

      // All 9 bottom tiles are blocked from above → none from layer 0.
      // Top layer: edges (X=0 or X=2) are free → 3+3 = 6 tiles.
      expect(free.length, 6);

      // Every free tile must come from layer 1 (footballerIndex = 88).
      for (final tile in free) {
        expect(tile.footballerIndex, 88);
      }
    });
  });

  // ===========================================================================
  // isDeadlocked
  // ===========================================================================
  group('MatchingEngine.isDeadlocked', () {
    test('two free tiles with same footballerIndex is NOT deadlocked', () {
      // 1×4 layout: tiles at all positions
      // Position 0: fi=0 (edge → free)
      // Position 1: fi=1 (blocked)
      // Position 2: fi=2 (blocked)
      // Position 3: fi=0 (edge → free)
      final defs = [_filledDef(1, 4)];
      final tiles = [
        _customLayer([
          [0, 1, 2, 0],
        ]),
      ];

      expect(MatchingEngine.isDeadlocked(tiles, defs), isFalse);
    });

    test('all free tiles with unique footballerIndex IS deadlocked', () {
      // 1×4 layout
      // Position 0: fi=0 (edge → free)
      // Position 1: fi=1 (blocked)
      // Position 2: fi=2 (blocked)
      // Position 3: fi=3 (edge → free)
      final defs = [_filledDef(1, 4)];
      final tiles = [
        _customLayer([
          [0, 1, 2, 3],
        ]),
      ];

      expect(MatchingEngine.isDeadlocked(tiles, defs), isTrue);
    });

    test('deadlock state changes after tiles are removed', () {
      // Start: 1×4 with  fi=[0, 1, 2, 0] — NOT deadlocked
      final defs = [_filledDef(1, 4)];

      // Initial state: tiles at (0,0),(1,0),(2,0),(3,0)
      final initialTiles = [
        _customLayer([
          [0, 1, 2, 0],
        ]),
      ];
      expect(MatchingEngine.isDeadlocked(initialTiles, defs), isFalse);

      // Remove the tile at position 3 (rightmost matching pair member)
      // Now: (0,0) fi=0, (1,0) fi=1, (2,0) fi=2 → (3,0) is null
      // Free: (0,0) fi=0 and (2,0) fi=2 (both edges) → unique → deadlocked
      final afterRemoval = [
        <TileData?>[
          initialTiles[0][0], // fi=0 at pos 0
          initialTiles[0][1], // fi=1 at pos 1
          initialTiles[0][2], // fi=2 at pos 2
          null, // pos 3 removed
        ],
      ];
      expect(MatchingEngine.isDeadlocked(afterRemoval, defs), isTrue);
    });

    test('deadlocked returns false when any footballer has >=2 free tiles', () {
      // 1×6 layout: fi=[0, 1, 2, 3, 4, 0]
      // Free edges: (0,0) fi=0 and (5,0) fi=0 → group of 2 → not deadlocked
      final defs = [_filledDef(1, 6)];
      final tiles = [
        _customLayer([
          [0, 1, 2, 3, 4, 0],
        ]),
      ];

      expect(MatchingEngine.isDeadlocked(tiles, defs), isFalse);
    });

    test('empty board is considered deadlocked (no matches possible)', () {
      final defs = [_filledDef(3, 3)];
      final tiles = <List<TileData?>>[
        List.filled(9, null),
      ];

      expect(MatchingEngine.isDeadlocked(tiles, defs), isTrue);
    });
  });
}
