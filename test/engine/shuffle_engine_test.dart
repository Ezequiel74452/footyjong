import 'package:flutter_test/flutter_test.dart';
import 'package:footyjong/game/engine/shuffle_engine.dart';
import 'package:footyjong/game/models/models.dart';

void main() {
  group('ShuffleEngine', () {
    // ---------------------------------------------------------------------------
    // generateTiles
    // ---------------------------------------------------------------------------
    test('generateTiles delegates to TileSet (correct count)', () {
      final config = TileConfig(18, 4);
      final tiles = ShuffleEngine.generateTiles(config);
      expect(tiles.length, 72);
    });

    test('generateTiles matches different configs', () {
      expect(ShuffleEngine.generateTiles(TileConfig(36, 4)).length, 144);
      expect(ShuffleEngine.generateTiles(TileConfig(50, 2)).length, 100);
    });

    // ---------------------------------------------------------------------------
    // assignToPositions — basic placement
    // ---------------------------------------------------------------------------
    test('assignToPositions fills all occupied positions', () {
      // Single-layer 2×2 layout = 4 positions
      final layout = LayoutDefinition(
        name: 'test-2x2',
        difficulty: Difficulty.easy,
        layers: [
          LayerDefinition(
            rows: 2,
            cols: 2,
            occupied: [
              [true, true],
              [true, true],
            ],
          ),
        ],
      );

      final tiles = ShuffleEngine.generateTiles(TileConfig(2, 2)); // 4 tiles
      final result = ShuffleEngine.assignToPositions(tiles, layout, seed: 42);

      // One layer, 4 positions
      expect(result.length, 1);
      expect(result[0].length, 4); // 2×2 = 4
      expect(result[0].where((t) => t != null).length, 4);
    });

    test('assignToPositions leaves unoccupied positions as null', () {
      // Single-layer 2×2 with only 2 occupied positions (diagonal)
      final layout = LayoutDefinition(
        name: 'test-diagonal',
        difficulty: Difficulty.easy,
        layers: [
          LayerDefinition(
            rows: 2,
            cols: 2,
            occupied: [
              [true, false],
              [false, true],
            ],
          ),
        ],
      );

      final tiles = ShuffleEngine.generateTiles(TileConfig(2, 1)); // 2 tiles
      final result = ShuffleEngine.assignToPositions(tiles, layout, seed: 42);

      expect(result[0].length, 4);
      expect(result[0].where((t) => t != null).length, 2);

      // Check the specific positions: (0,0) and (1,1) should have tiles
      final pos00 = result[0][0 * 2 + 0]; // row 0, col 0
      final pos11 = result[0][1 * 2 + 1]; // row 1, col 1
      final pos01 = result[0][0 * 2 + 1]; // row 0, col 1
      final pos10 = result[0][1 * 2 + 0]; // row 1, col 0

      expect(pos00, isNotNull);
      expect(pos11, isNotNull);
      expect(pos01, isNull);
      expect(pos10, isNull);
    });

    // ---------------------------------------------------------------------------
    // Determinism
    // ---------------------------------------------------------------------------
    test('same seed produces identical placement', () {
      final layout = LayoutDefinition(
        name: 'test-3x3',
        difficulty: Difficulty.easy,
        layers: [
          LayerDefinition(
            rows: 3,
            cols: 3,
            occupied: List.generate(3, (_) => List.filled(3, true)),
          ),
        ],
      );

      final tiles = ShuffleEngine.generateTiles(TileConfig(9, 1)); // 9 tiles

      final resultA = ShuffleEngine.assignToPositions(tiles, layout, seed: 777);
      final resultB = ShuffleEngine.assignToPositions(tiles, layout, seed: 777);

      // Flatten and compare tile IDs
      final flatA = resultA.expand((l) => l).map((t) => t!.id).toList();
      final flatB = resultB.expand((l) => l).map((t) => t!.id).toList();

      expect(flatA, orderedEquals(flatB));
    });

    test('different seed produces different placement', () {
      final layout = LayoutDefinition(
        name: 'test-3x3',
        difficulty: Difficulty.easy,
        layers: [
          LayerDefinition(
            rows: 3,
            cols: 3,
            occupied: List.generate(3, (_) => List.filled(3, true)),
          ),
        ],
      );

      final tiles = ShuffleEngine.generateTiles(TileConfig(9, 1)); // 9 tiles

      final resultA = ShuffleEngine.assignToPositions(tiles, layout, seed: 123);
      final resultB = ShuffleEngine.assignToPositions(tiles, layout, seed: 456);

      final flatA = resultA.expand((l) => l).map((t) => t!.id).toList();
      final flatB = resultB.expand((l) => l).map((t) => t!.id).toList();

      // Extremely unlikely that random seeds 123 and 456 produce the same
      // permutation of 9 elements.
      expect(flatA, isNot(orderedEquals(flatB)));
    });

    // ---------------------------------------------------------------------------
    // Integrity
    // ---------------------------------------------------------------------------
    test('all tiles are placed (no missing, no extras)', () {
      final layout = LayoutDefinition(
        name: 'test-4x4',
        difficulty: Difficulty.easy,
        layers: [
          LayerDefinition(
            rows: 4,
            cols: 4,
            occupied: List.generate(4, (_) => List.filled(4, true)),
          ),
        ],
      );

      final tiles = ShuffleEngine.generateTiles(TileConfig(8, 2)); // 16 tiles
      final result = ShuffleEngine.assignToPositions(tiles, layout, seed: 1);

      // Count non-null tiles
      final placed = <int>{};
      for (final layer in result) {
        for (final tile in layer) {
          if (tile != null) placed.add(tile.id);
        }
      }

      expect(placed.length, tiles.length);

      // All original tile IDs are present
      for (final tile in tiles) {
        expect(placed.contains(tile.id), isTrue);
      }
    });

    // ---------------------------------------------------------------------------
    // Multi-layer
    // ---------------------------------------------------------------------------
    test('works with multi-layer layout', () {
      // Layer 0: 3×3 filled (9 pos)
      // Layer 1: 2×2 filled (4 pos)
      // Total: 13 positions
      final layout = LayoutDefinition(
        name: 'test-multi',
        difficulty: Difficulty.medium,
        layers: [
          LayerDefinition(
            rows: 3,
            cols: 3,
            occupied: List.generate(3, (_) => List.filled(3, true)),
          ),
          LayerDefinition(
            rows: 2,
            cols: 2,
            occupied: List.generate(2, (_) => List.filled(2, true)),
          ),
        ],
      );

      final tiles = ShuffleEngine.generateTiles(TileConfig(13, 1)); // 13 tiles
      final result = ShuffleEngine.assignToPositions(tiles, layout, seed: 99);

      expect(result.length, 2);
      expect(result[0].length, 9); // 3×3
      expect(result[1].length, 4); // 2×2

      // All non-null in both layers
      final placedInLayer0 = result[0].where((t) => t != null).length;
      final placedInLayer1 = result[1].where((t) => t != null).length;
      expect(placedInLayer0, 9);
      expect(placedInLayer1, 4);

      // No duplicate tile IDs across layers
      final idSet = <int>{};
      for (final layer in result) {
        for (final tile in layer) {
          if (tile != null) {
            expect(idSet.contains(tile.id), isFalse,
                reason: 'Duplicate tile id ${tile.id}');
            idSet.add(tile.id);
          }
        }
      }
      expect(idSet.length, 13);
    });

    // ---------------------------------------------------------------------------
    // Empty layout
    // ---------------------------------------------------------------------------
    test('empty layout returns all-null layers', () {
      final layout = LayoutDefinition(
        name: 'test-empty',
        difficulty: Difficulty.easy,
        layers: [
          LayerDefinition(
            rows: 2,
            cols: 2,
            occupied: [
              [false, false],
              [false, false],
            ],
          ),
        ],
      );

      final tiles = ShuffleEngine.generateTiles(TileConfig(4, 1)); // 4 tiles
      // 4 tiles but 0 positions → this would crash (tileIndex out of range)
      // Instead use 0 tiles
      final result =
          ShuffleEngine.assignToPositions(<TileData>[], layout, seed: 0);

      expect(result.length, 1);
      expect(result[0].length, 4); // 2×2 grid
      expect(result[0].every((t) => t == null), isTrue);
    });

    test('no seed produces non-null random result', () {
      final layout = LayoutDefinition(
        name: 'test-2x2',
        difficulty: Difficulty.easy,
        layers: [
          LayerDefinition(
            rows: 2,
            cols: 2,
            occupied: [
              [true, true],
              [true, true],
            ],
          ),
        ],
      );

      final tiles = ShuffleEngine.generateTiles(TileConfig(4, 1)); // 4 tiles
      final result = ShuffleEngine.assignToPositions(tiles, layout);

      expect(result.length, 1);
      expect(result[0].where((t) => t != null).length, 4);
    });
  });
}
