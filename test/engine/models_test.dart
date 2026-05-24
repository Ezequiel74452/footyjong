import 'package:flutter_test/flutter_test.dart';
import 'package:footyjong/game/models/tile_config.dart';
import 'package:footyjong/game/models/position_3d.dart';
import 'package:footyjong/game/models/layer_definition.dart';
import 'package:footyjong/game/models/layout_definition.dart';

void main() {
  group('TileConfig', () {
    test('totalTiles for all 5 available configs', () {
      final expected = {
        TileConfig(18, 4): 72,
        TileConfig(36, 2): 72,
        TileConfig(36, 4): 144,
        TileConfig(24, 6): 144,
        TileConfig(50, 2): 100,
      };

      for (final config in TileConfig.availableConfigs) {
        expect(config.totalTiles, expected[config],
            reason: '${config.numFootballers}x${config.copiesPerFootballer}');
      }
    });

    test('availableConfigs contains exactly 5 configs', () {
      expect(TileConfig.availableConfigs.length, 5);
    });
  });

  group('Position3D', () {
    test('zOrder is layer-dominant', () {
      // Any position on layer 1 has higher zOrder than any position on layer 0
      final p1 = Position3D(gridX: 0, gridY: 0, layer: 0);
      final p2 = Position3D(gridX: 99, gridY: 99, layer: 1);
      expect(p2.zOrder > p1.zOrder, isTrue);
    });

    test('zOrder distinguishes positions within same layer', () {
      final p1 = Position3D(gridX: 5, gridY: 3, layer: 0);
      final p2 = Position3D(gridX: 5, gridY: 4, layer: 0);
      final p3 = Position3D(gridX: 6, gridY: 3, layer: 0);
      expect(p1.zOrder, lessThan(p2.zOrder));
      expect(p1.zOrder, lessThan(p3.zOrder));
    });

    test('zOrder produces unique values', () {
      final positions = <Position3D>[
        Position3D(gridX: 1, gridY: 2, layer: 0),
        Position3D(gridX: 2, gridY: 1, layer: 0),
        Position3D(gridX: 0, gridY: 0, layer: 1),
        Position3D(gridX: 99, gridY: 99, layer: 2),
        Position3D(gridX: 50, gridY: 50, layer: 5),
      ];

      final zOrders = positions.map((p) => p.zOrder).toSet();
      expect(zOrders.length, positions.length);
    });

    test('equality', () {
      final a = Position3D(gridX: 3, gridY: 7, layer: 2);
      final b = Position3D(gridX: 3, gridY: 7, layer: 2);
      final c = Position3D(gridX: 3, gridY: 7, layer: 1);

      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });

    test('hashCode is consistent with equality', () {
      final a = Position3D(gridX: 3, gridY: 7, layer: 2);
      final b = Position3D(gridX: 3, gridY: 7, layer: 2);
      expect(a.hashCode, equals(b.hashCode));
    });

    test('hashCode differs for different positions', () {
      final a = Position3D(gridX: 3, gridY: 7, layer: 2);
      final b = Position3D(gridX: 4, gridY: 7, layer: 2);
      final c = Position3D(gridX: 3, gridY: 8, layer: 2);
      final d = Position3D(gridX: 3, gridY: 7, layer: 3);

      final hashes = {a.hashCode, b.hashCode, c.hashCode, d.hashCode};
      // At minimum layer change should differ, and typically all differ
      expect(hashes.length, greaterThanOrEqualTo(3));
    });
  });

  group('LayerDefinition', () {
    test('positionCount counts occupied cells only', () {
      final layer = LayerDefinition(
        rows: 3,
        cols: 3,
        occupied: [
          [true, false, true],
          [false, true, false],
          [true, false, true],
        ],
      );

      expect(layer.positionCount, 5);
    });

    test('positionCount returns 0 for fully empty layer', () {
      final layer = LayerDefinition(
        rows: 2,
        cols: 2,
        occupied: [
          [false, false],
          [false, false],
        ],
      );

      expect(layer.positionCount, 0);
    });

    test('positionCount returns rows*cols for fully filled layer', () {
      final layer = LayerDefinition(
        rows: 4,
        cols: 5,
        occupied: List.generate(4, (_) => List.generate(5, (_) => true)),
      );

      expect(layer.positionCount, 20);
    });
  });

  group('LayoutDefinition', () {
    test('totalPositions sums all layer positionCounts', () {
      final layout = LayoutDefinition(
        name: 'test',
        difficulty: Difficulty.medium,
        layers: [
          LayerDefinition(
            rows: 3,
            cols: 3,
            occupied: [
              [true, false, true],
              [false, true, false],
              [true, false, true],
            ],
          ),
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

      expect(layout.totalPositions, 5 + 4);
    });

    test('isCompatibleWith returns true when positions match totalTiles', () {
      final layout = LayoutDefinition(
        name: '72-tile layout',
        difficulty: Difficulty.easy,
        layers: [
          LayerDefinition(
            rows: 6,
            cols: 6,
            occupied: List.generate(6, (_) => List.generate(6, (_) => true)),
          ),
          LayerDefinition(
            rows: 6,
            cols: 6,
            occupied: List.generate(6, (_) => List.generate(6, (_) => true)),
          ),
        ],
      );

      expect(layout.totalPositions, 72);
      expect(layout.isCompatibleWith(TileConfig(18, 4)), isTrue);
      expect(layout.isCompatibleWith(TileConfig(36, 2)), isTrue);
    });

    test('isCompatibleWith returns false when positions mismatch', () {
      final layout = LayoutDefinition(
        name: '100-tile layout',
        difficulty: Difficulty.hard,
        layers: [
          LayerDefinition(
            rows: 10,
            cols: 10,
            occupied: List.generate(10, (_) => List.generate(10, (_) => true)),
          ),
        ],
      );

      expect(layout.totalPositions, 100);
      expect(layout.isCompatibleWith(TileConfig(18, 4)), isFalse); // 72 != 100
      expect(layout.isCompatibleWith(TileConfig(50, 2)), isTrue); // 100 == 100
    });
  });

  group('Difficulty enum', () {
    test('has exactly three values', () {
      expect(Difficulty.values, [Difficulty.easy, Difficulty.medium, Difficulty.hard]);
    });
  });
}
