import 'package:flutter_test/flutter_test.dart';
import 'package:footyjong/game/engine/tile_set.dart';
import 'package:footyjong/game/models/tile_config.dart';
import 'package:footyjong/game/models/tile_data.dart';

void main() {
  group('TileSet.generateTiles', () {
    test('generates correct count for 18x4 config (72 tiles)', () {
      final config = TileConfig(18, 4);
      final tiles = TileSet.generateTiles(config);
      expect(tiles.length, 72);
    });

    test('generates correct count for 36x2 config (72 tiles)', () {
      final config = TileConfig(36, 2);
      final tiles = TileSet.generateTiles(config);
      expect(tiles.length, 72);
    });

    test('generates correct count for 36x4 config (144 tiles)', () {
      final config = TileConfig(36, 4);
      final tiles = TileSet.generateTiles(config);
      expect(tiles.length, 144);
    });

    test('generates correct count for 24x6 config (144 tiles)', () {
      final config = TileConfig(24, 6);
      final tiles = TileSet.generateTiles(config);
      expect(tiles.length, 144);
    });

    test('generates correct count for 50x2 config (100 tiles)', () {
      final config = TileConfig(50, 2);
      final tiles = TileSet.generateTiles(config);
      expect(tiles.length, 100);
    });

    test('footballerIndex distribution is even', () {
      final config = TileConfig(18, 4);
      final tiles = TileSet.generateTiles(config);

      // Count tiles per footballer
      final counts = <int, int>{};
      for (final tile in tiles) {
        counts[tile.footballerIndex] = (counts[tile.footballerIndex] ?? 0) + 1;
      }

      // Every footballer should appear exactly 4 times (copiesPerFootballer)
      expect(counts.length, 18);
      for (final count in counts.values) {
        expect(count, 4);
      }
    });

    test('IDs are sequential and unique', () {
      final config = TileConfig(36, 4);
      final tiles = TileSet.generateTiles(config);

      expect(tiles.length, 144);
      for (int i = 0; i < tiles.length; i++) {
        expect(tiles[i].id, i);
      }
    });

    test('copyIndex cycles correctly per footballer', () {
      final config = TileConfig(5, 2); // 10 tiles, 2 copies of each
      final tiles = TileSet.generateTiles(config);

      for (int fi = 0; fi < config.numFootballers; fi++) {
        final footballerTiles = tiles
            .where((t) => t.footballerIndex == fi)
            .toList();

        expect(footballerTiles.length, 2);
        for (int ci = 0; ci < config.copiesPerFootballer; ci++) {
          expect(footballerTiles[ci].copyIndex, ci);
        }
      }
    });

    test('isMatchableWith returns true for same footballerIndex', () {
      final tile1 = TileData(id: 0, footballerIndex: 3, copyIndex: 0);
      final tile2 = TileData(id: 1, footballerIndex: 3, copyIndex: 1);
      expect(tile1.isMatchableWith(tile2), isTrue);
    });

    test('isMatchableWith returns false for different footballerIndex', () {
      final tile1 = TileData(id: 0, footballerIndex: 3, copyIndex: 0);
      final tile2 = TileData(id: 1, footballerIndex: 7, copyIndex: 0);
      expect(tile1.isMatchableWith(tile2), isFalse);
    });
  });
}
