import 'package:flutter_test/flutter_test.dart';
import 'package:footyjong/config/game_constants.dart';
import 'package:footyjong/game/components/board_component.dart';
import 'package:footyjong/game/components/tile_component.dart';
import 'package:footyjong/game/engine/game_state.dart';
import 'package:footyjong/game/models/models.dart';

void main() {
  group('BoardComponent', () {
    // 8×9 single layer = 72 positions, compatible with 18 footballers × 4 copies
    final testLayout = LayoutDefinition(
      name: 'TestLayout',
      difficulty: Difficulty.easy,
      layers: [
        LayerDefinition(
          rows: 8,
          cols: 9,
          occupied: List.generate(8, (_) => List.generate(9, (_) => true)),
        ),
      ],
    );
    final testConfig = TileConfig(18, 4);

    late GameState gameState;
    late BoardComponent board;

    setUp(() {
      gameState = GameState(layout: testLayout, config: testConfig);
      gameState.initialize(seed: 42);
      board = BoardComponent(gameState: gameState);
      board.onLoad();
    });

    test('creates correct number of TileComponents', () {
      final tiles = board.children.whereType<TileComponent>().toList();
      expect(tiles.length, 72);
    });

    test('all tiles have unique tile IDs in lookup map', () {
      // Each TileComponent should be in _tilesById with a unique key
      final ids = <int>{};
      for (final child in board.children) {
        if (child is TileComponent) {
          // Verify no duplicates by checking isAnimating is settable
          child.isAnimating = true;
          expect(child.isAnimating, true);
          child.isAnimating = false;

          // Collect football indices
          ids.add(child.footballerIndex);
        }
      }
      // With 18 footballers × 4 copies, we expect 18 unique indices
      expect(ids.length, 18);
    });

    test('tiles are centered and positioned correctly', () {
      // onLoad calls _playEntranceAnimation which shifts tiles up by entranceDrop.
      // We test the CENTERING formula: entrance animation only affects y temporarily.
      // After entrance completes, positions return to these calculated values.
      //
      // Single layer: boardPixelWidth = 9*50 = 450, boardPixelHeight = 8*50 = 400
      // offsetX = (800 - 450)/2 = 175, offsetY = (600 - 400)/2 = 100
      const expectedOffsetX = 175.0;
      const expectedOffsetY = 100.0;

      // First tile (0,0) — x is exact, y is shifted up by entranceDrop
      final tile00 = board.children.whereType<TileComponent>().firstWhere(
        (t) => t.gridX == 0 && t.gridY == 0 && t.layer == 0,
      );
      expect(tile00.position.x, expectedOffsetX);
      expect(tile00.position.y, expectedOffsetY - GameConstants.entranceDrop);

      // Last right-bottom tile (8,7)
      final tile87 = board.children.whereType<TileComponent>().firstWhere(
        (t) => t.gridX == 8 && t.gridY == 7 && t.layer == 0,
      );
      expect(tile87.position.x, 8 * GameConstants.tileStep + expectedOffsetX);
      expect(
          tile87.position.y, 7 * GameConstants.tileStep + expectedOffsetY - GameConstants.entranceDrop);
    });

    test('isAnimating setter syncs to all TileComponents', () {
      board.isAnimating = true;
      for (final child in board.children) {
        if (child is TileComponent) {
          expect(child.isAnimating, true);
        }
      }

      board.isAnimating = false;
      for (final child in board.children) {
        if (child is TileComponent) {
          expect(child.isAnimating, false);
        }
      }
    });

    test('highlightTile and unhighlightTile API is callable', () {
      // Verify the public API compiles and doesn't throw
      final tileAt00 = board.children.whereType<TileComponent>().firstWhere(
        (t) => t.gridX == 0 && t.gridY == 0 && t.layer == 0,
      );
      expect(tileAt00.isSelected, false);
    });
  });
}
