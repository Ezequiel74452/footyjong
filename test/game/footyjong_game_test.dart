import 'package:flutter_test/flutter_test.dart';
import 'package:footyjong/game/components/board_component.dart';
import 'package:footyjong/game/components/tile_component.dart';
import 'package:footyjong/game/engine/game_state.dart';
import 'package:footyjong/game/footyjong_game.dart';
import 'package:footyjong/game/models/models.dart';

/// Single-layer 8×9 layout (72 positions) compatible with [TileConfig](18, 4).
LayoutDefinition _testLayout() => LayoutDefinition(
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

/// Manually invokes the board lifecycle so tests don't need a running game
/// loop.  [game.onLoad()] adds [BoardComponent] as a child but does NOT
/// call [BoardComponent.onLoad] — Flame normally defers that to the next
/// tick of the game loop.
void _loadBoard(FootyJongGame game) {
  game.board.onLoad();
}

void main() {
  group('FootyJongGame deadlock', () {
    test('deadlockedNotifier starts as false', () {
      final gameState = GameState(layout: _testLayout(), config: TileConfig(18, 4));
      gameState.initialize(seed: 42);
      final game = FootyJongGame(gameState: gameState);
      game.onLoad();
      _loadBoard(game);

      expect(game.deadlockedNotifier.value, false);
    });

    test('deadlockedNotifier reflects gameState.phase after reshuffle', () {
      final gameState = GameState(layout: _testLayout(), config: TileConfig(18, 4));
      gameState.initialize(seed: 42);
      final game = FootyJongGame(gameState: gameState);
      game.onLoad();
      _loadBoard(game);

      // Initially not deadlocked
      expect(game.deadlockedNotifier.value, false);

      // Call reshuffle — after reshuffle, deadlockedNotifier must match
      // gameState.phase (true if deadlocked, false otherwise).
      game.reshuffle();

      expect(
        game.deadlockedNotifier.value,
        gameState.phase == GamePhase.deadlocked,
      );
    });

    test('reshuffle rebuilds board tiles', () {
      final gameState = GameState(layout: _testLayout(), config: TileConfig(18, 4));
      gameState.initialize(seed: 42);
      final game = FootyJongGame(gameState: gameState);
      game.onLoad();
      _loadBoard(game);

      // Capture tiles before reshuffle
      final board = game.board;
      final tilesBefore = board.children.whereType<TileComponent>().toList();
      expect(tilesBefore.length, 72);

      game.reshuffle();

      // Tiles should be replaced with new instances
      final tilesAfter = board.children.whereType<TileComponent>().toList();
      expect(tilesAfter.length, 72);
      for (final oldTile in tilesBefore) {
        expect(board.children.contains(oldTile), isFalse);
      }
    });

    test('timerNotifier is initially null', () {
      final gameState = GameState(layout: _testLayout(), config: TileConfig(18, 4));
      gameState.initialize(seed: 42);
      final game = FootyJongGame(gameState: gameState);
      game.onLoad();

      expect(game.timerNotifier.value, isNull);
    });
  });
}
