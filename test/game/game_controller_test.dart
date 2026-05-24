import 'package:flutter_test/flutter_test.dart';
import 'package:footyjong/game/engine/level_generator.dart';
import 'package:footyjong/game/game_controller.dart';
import 'package:footyjong/game/models/models.dart';

void main() {
  group('GameController', () {
    // ---------------------------------------------------------------------------
    // Test 1: startNewGame creates a valid layout with initial state
    // ---------------------------------------------------------------------------
    test('startNewGame creates a valid layout with initial state', () {
      final controller = GameController();

      controller.startNewGame();

      expect(controller.currentLevel, 1);
      expect(controller.currentScore, 0);
      expect(controller.gameActive, isTrue);

      final layout = controller.getCurrentLayout();
      expect(layout, isA<LayoutDefinition>());
    });

    // ---------------------------------------------------------------------------
    // Test 2: onGameWon increments level and updates score
    // ---------------------------------------------------------------------------
    test('onGameWon increments level and updates score', () {
      final controller = GameController();
      controller.startNewGame();

      controller.onGameWon(500);

      expect(controller.currentLevel, 2);
      expect(controller.currentScore, 500);
      expect(controller.gameActive, isFalse);
    });

    // ---------------------------------------------------------------------------
    // Test 3: resetGame resets to initial state
    // ---------------------------------------------------------------------------
    test('resetGame resets to initial state', () {
      final controller = GameController();
      controller.startNewGame();
      controller.onGameWon(300);

      controller.resetGame();

      expect(controller.currentLevel, 1);
      expect(controller.currentScore, 0);
      expect(controller.gameActive, isTrue);

      final layout = controller.getCurrentLayout();
      expect(layout, isA<LayoutDefinition>());
    });

    // ---------------------------------------------------------------------------
    // Test 4: LevelGenerator streaks persist across multiple startNewGame calls
    // ---------------------------------------------------------------------------
    test(
        'LevelGenerator streaks persist across multiple startNewGame calls',
        () {
      final controller = GameController();
      int maxEasyStreak = 0;
      int currentEasyStreak = 0;

      // Generate many level-1 layouts — the generator's streak tracking
      // should prevent more than maxEasyStreak consecutive easy layouts.
      for (int i = 0; i < 100; i++) {
        controller.startNewGame();
        final layout = controller.getCurrentLayout();
        if (layout.difficulty == Difficulty.easy) {
          currentEasyStreak++;
          if (currentEasyStreak > maxEasyStreak) {
            maxEasyStreak = currentEasyStreak;
          }
        } else {
          currentEasyStreak = 0;
        }
      }

      // If a new LevelGenerator were created each call the streak counter
      // would reset, allowing easy to appear 3+ times in a row.
      expect(maxEasyStreak, lessThanOrEqualTo(LevelGenerator.maxEasyStreak));
    });
  });
}
