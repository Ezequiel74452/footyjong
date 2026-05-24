import 'package:flutter_test/flutter_test.dart';
import 'package:footyjong/game/engine/game_state.dart';
import 'package:footyjong/game/models/models.dart';
import 'package:footyjong/game/engine/board_layout.dart';
import 'package:footyjong/game/engine/level_generator.dart';

void main() {
  group('GameState public API (renderer contract)', () {
    test('tilesByLayer is accessible after initialize', () {
      final layout = BoardLayout.pyramid;
      final config = TileConfig(36, 4);
      final state = GameState(layout: layout, config: config);
      state.initialize(seed: 42);

      expect(state.tilesByLayer, isNotNull);
      expect(state.tilesByLayer.length, layout.layers.length);
    });

    test('layerDefs matches layout layers', () {
      final layout = BoardLayout.pyramid;
      final config = TileConfig(36, 4);
      final state = GameState(layout: layout, config: config);
      state.initialize(seed: 42);

      expect(state.layerDefs.length, layout.layers.length);
      expect(state.layerDefs[0].rows, layout.layers[0].rows);
    });

    test('currentLayout returns the active layout', () {
      final layout = BoardLayout.cross;
      final config = TileConfig(50, 2);
      final state = GameState(layout: layout, config: config);
      state.initialize(seed: 42);

      expect(state.currentLayout.name, 'Cross');
    });

    test('currentConfig returns the active config', () {
      final layout = BoardLayout.hexagon;
      final config = TileConfig(18, 4);
      final state = GameState(layout: layout, config: config);
      state.initialize(seed: 42);

      expect(state.currentConfig.totalTiles, 72);
    });
  });
}
