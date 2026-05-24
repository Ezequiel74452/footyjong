import 'package:flutter_test/flutter_test.dart';
import 'package:footyjong/game/engine/board_layout.dart';
import 'package:footyjong/game/models/models.dart';

void main() {
  group('BoardLayout — all 17 layouts', () {
    test('all layouts are accessible', () {
      expect(BoardLayout.all.length, 17);
    });

    test('each layout has at least 1 layer', () {
      for (final layout in BoardLayout.all) {
        expect(layout.layers.length, greaterThan(0),
            reason: '${layout.name} has no layers');
      }
    });

    test('each layout totalPositions equals sum of layer positionCounts', () {
      for (final layout in BoardLayout.all) {
        final computed = layout.layers.fold(0, (s, l) => s + l.positionCount);
        expect(layout.totalPositions, computed,
            reason: '${layout.name} totalPositions mismatch');
      }
    });

    test('each layout has a valid total (72, 100, or 144)', () {
      for (final layout in BoardLayout.all) {
        expect(
          [72, 100, 144].contains(layout.totalPositions),
          isTrue,
          reason: '${layout.name} has ${layout.totalPositions} positions',
        );
      }
    });

    test('no two layouts share the same name', () {
      final names = BoardLayout.all.map((l) => l.name).toList();
      expect(names.toSet().length, names.length);
    });

    test('each layout has the correct difficulty', () {
      final expected = <String, Difficulty>{
        'Pyramid': Difficulty.easy,
        'Flat Diamond': Difficulty.easy,
        'Cross': Difficulty.easy,
        'Hexagon': Difficulty.easy,
        'Butterfly': Difficulty.medium,
        'Windmill': Difficulty.medium,
        'Castle': Difficulty.medium,
        'Diamond Ring': Difficulty.medium,
        'Hourglass': Difficulty.medium,
        'Twin Peaks': Difficulty.medium,
        'Spiral': Difficulty.medium,
        'Bridge': Difficulty.medium,
        'Star': Difficulty.hard,
        'Dragon': Difficulty.hard,
        'Cobra': Difficulty.hard,
        'Volcano': Difficulty.hard,
        'Labyrinth': Difficulty.hard,
      };

      for (final layout in BoardLayout.all) {
        expect(layout.difficulty, expected[layout.name],
            reason: '${layout.name} difficulty mismatch');
      }
    });

    test('zOrder uniqueness within each layout — no duplicate positions', () {
      for (final layout in BoardLayout.all) {
        final zOrders = <int>{};
        for (var layerIdx = 0; layerIdx < layout.layers.length; layerIdx++) {
          final layer = layout.layers[layerIdx];
          for (var r = 0; r < layer.rows; r++) {
            for (var c = 0; c < layer.cols; c++) {
              if (layer.occupied[r][c]) {
                final pos = Position3D(gridX: c, gridY: r, layer: layerIdx);
                final z = pos.zOrder;
                expect(zOrders.contains(z), isFalse,
                    reason:
                        '${layout.name}: duplicate zOrder $z at layer $layerIdx ($r, $c)');
                zOrders.add(z);
              }
            }
          }
        }
      }
    });

    test('all layouts can be const-constructed', () {
      // The getters are const-accessibly returned via const LayoutDefinition
      // This test verifies no runtime error accessing any layout.
      for (final layout in BoardLayout.all) {
        expect(layout, isA<LayoutDefinition>());
      }
    });
  });

  // ---------------------------------------------------------------------------
  // Individual layout spot-checks
  // ---------------------------------------------------------------------------

  group('Pyramid', () {
    test('has 144 positions', () {
      final layout = BoardLayout.pyramid;
      expect(layout.totalPositions, 144);
      expect(layout.difficulty, Difficulty.easy);
      expect(layout.name, 'Pyramid');
      expect(layout.layers.length, 5);
    });
  });

  group('Flat Diamond', () {
    test('has 144 positions', () {
      final layout = BoardLayout.flatDiamond;
      expect(layout.totalPositions, 144);
      expect(layout.difficulty, Difficulty.easy);
      expect(layout.name, 'Flat Diamond');
      expect(layout.layers.length, 1);
    });
  });

  group('Cross', () {
    test('has 100 positions', () {
      final layout = BoardLayout.cross;
      expect(layout.totalPositions, 100);
      expect(layout.difficulty, Difficulty.easy);
      expect(layout.name, 'Cross');
      expect(layout.layers.length, 1);
    });
  });

  group('Hexagon', () {
    test('has 72 positions', () {
      final layout = BoardLayout.hexagon;
      expect(layout.totalPositions, 72);
      expect(layout.difficulty, Difficulty.easy);
      expect(layout.name, 'Hexagon');
      expect(layout.layers.length, 1);
    });
  });

  group('Butterfly', () {
    test('has 72 positions', () {
      final layout = BoardLayout.butterfly;
      expect(layout.totalPositions, 72);
      expect(layout.difficulty, Difficulty.medium);
      expect(layout.name, 'Butterfly');
      expect(layout.layers.length, 1);
    });
  });

  group('Windmill', () {
    test('has 144 positions', () {
      final layout = BoardLayout.windmill;
      expect(layout.totalPositions, 144);
      expect(layout.difficulty, Difficulty.medium);
      expect(layout.name, 'Windmill');
      expect(layout.layers.length, 2);
    });
  });

  group('Castle', () {
    test('has 144 positions', () {
      final layout = BoardLayout.castle;
      expect(layout.totalPositions, 144);
      expect(layout.difficulty, Difficulty.medium);
      expect(layout.name, 'Castle');
      expect(layout.layers.length, 2);
    });
  });

  group('Diamond Ring', () {
    test('has 144 positions', () {
      final layout = BoardLayout.diamondRing;
      expect(layout.totalPositions, 144);
      expect(layout.difficulty, Difficulty.medium);
      expect(layout.name, 'Diamond Ring');
      expect(layout.layers.length, 2);
    });
  });

  group('Hourglass', () {
    test('has 144 positions', () {
      final layout = BoardLayout.hourglass;
      expect(layout.totalPositions, 144);
      expect(layout.difficulty, Difficulty.medium);
      expect(layout.name, 'Hourglass');
      expect(layout.layers.length, 3);
    });
  });

  group('Twin Peaks', () {
    test('has 144 positions', () {
      final layout = BoardLayout.twinPeaks;
      expect(layout.totalPositions, 144);
      expect(layout.difficulty, Difficulty.medium);
      expect(layout.name, 'Twin Peaks');
      expect(layout.layers.length, 2);
    });
  });

  group('Spiral', () {
    test('has 144 positions', () {
      final layout = BoardLayout.spiral;
      expect(layout.totalPositions, 144);
      expect(layout.difficulty, Difficulty.medium);
      expect(layout.name, 'Spiral');
      expect(layout.layers.length, 2);
    });
  });

  group('Bridge', () {
    test('has 100 positions', () {
      final layout = BoardLayout.bridge;
      expect(layout.totalPositions, 100);
      expect(layout.difficulty, Difficulty.medium);
      expect(layout.name, 'Bridge');
      expect(layout.layers.length, 2);
    });
  });

  group('Star', () {
    test('has 144 positions', () {
      final layout = BoardLayout.star;
      expect(layout.totalPositions, 144);
      expect(layout.difficulty, Difficulty.hard);
      expect(layout.name, 'Star');
      expect(layout.layers.length, 4);
    });
  });

  group('Dragon', () {
    test('has 144 positions', () {
      final layout = BoardLayout.dragon;
      expect(layout.totalPositions, 144);
      expect(layout.difficulty, Difficulty.hard);
      expect(layout.name, 'Dragon');
      expect(layout.layers.length, 2);
    });
  });

  group('Cobra', () {
    test('has 144 positions', () {
      final layout = BoardLayout.cobra;
      expect(layout.totalPositions, 144);
      expect(layout.difficulty, Difficulty.hard);
      expect(layout.name, 'Cobra');
      expect(layout.layers.length, 3);
    });
  });

  group('Volcano', () {
    test('has 72 positions', () {
      final layout = BoardLayout.volcano;
      expect(layout.totalPositions, 72);
      expect(layout.difficulty, Difficulty.hard);
      expect(layout.name, 'Volcano');
      expect(layout.layers.length, 4);
    });
  });

  group('Labyrinth', () {
    test('has 100 positions', () {
      final layout = BoardLayout.labyrinth;
      expect(layout.totalPositions, 100);
      expect(layout.difficulty, Difficulty.hard);
      expect(layout.name, 'Labyrinth');
      expect(layout.layers.length, 2);
    });
  });
}
