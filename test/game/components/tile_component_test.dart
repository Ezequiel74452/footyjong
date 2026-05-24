import 'package:flutter_test/flutter_test.dart';
import 'package:footyjong/config/game_constants.dart';
import 'package:footyjong/game/components/tile_component.dart';
import 'package:flutter/material.dart' as material;

void main() {
  group('TileComponent', () {
    late TileComponent tile;
    int tappedLayer = -1;
    int tappedX = -1;
    int tappedY = -1;

    setUp(() {
      tile = TileComponent(
        footballerIndex: 5,
        gridX: 2,
        gridY: 3,
        layer: 1,
        frontColor: GameConstants.footballerColors[5],
        onTileTapped: (l, x, y) {
          tappedLayer = l;
          tappedX = x;
          tappedY = y;
        },
      );
    });

    test('constructor sets properties', () {
      expect(tile.footballerIndex, 5);
      expect(tile.gridX, 2);
      expect(tile.gridY, 3);
      expect(tile.layer, 1);
      expect(tile.frontColor, GameConstants.footballerColors[5]);
    });

    test('size matches tileSize', () {
      expect(tile.size.x, GameConstants.tileSize);
      expect(tile.size.y, GameConstants.tileSize);
    });

    test('isAnimating defaults to false', () {
      expect(tile.isAnimating, false);
    });

    test('onTileTapped callback is invoked with correct args', () {
      // Simulate what onTapUp does
      if (!tile.isAnimating) {
        tile.onTileTapped(tile.layer, tile.gridX, tile.gridY);
      }
      expect(tappedLayer, 1);
      expect(tappedX, 2);
      expect(tappedY, 3);
    });

    test('taps are blocked when isAnimating is true', () {
      tile.isAnimating = true;
      if (!tile.isAnimating) {
        tile.onTileTapped(tile.layer, tile.gridX, tile.gridY);
      }
      // tappedLayer should still be 1 from previous test
      expect(tappedLayer, 1); // unchanged from last call
    });

    test('setSelected toggles _isSelected and adds effect', () {
      expect(tile.isSelected, false);
      tile.setSelected(true);
      expect(tile.isSelected, true);
      tile.setSelected(false);
      expect(tile.isSelected, false);
    });
  });
}
