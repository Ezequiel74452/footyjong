import 'package:flutter_test/flutter_test.dart';
import 'package:footyjong/game/engine/level_generator.dart';
import 'package:footyjong/game/game_controller.dart';
import 'package:footyjong/game/models/models.dart';

void main() {
  group('GameController', () {
    // Use a fixed seed so streak tests are deterministic.
    const int fixedSeed = 42;

    // ---------------------------------------------------------------------------
    // Test 1: startNewGame creates a valid layout with initial state
    // ---------------------------------------------------------------------------
    test('startNewGame creates a valid layout with initial state', () {
      final controller = GameController(seed: fixedSeed);

      controller.startNewGame();

      expect(controller.currentLevel, 1);
      expect(controller.currentScore, 0);
      expect(controller.gameActive, isTrue);

      final layout = controller.getCurrentLayout();
      expect(layout, isA<LayoutDefinition>());
      expect(layout!.layers, isNotEmpty);
    });

    // ---------------------------------------------------------------------------
    // Test 2: onGameWon records the score and marks game inactive
    // ---------------------------------------------------------------------------
    test('onGameWon records score and marks game inactive', () {
      final controller = GameController(seed: fixedSeed);
      controller.startNewGame();

      controller.onGameWon(500);

      // currentLevel stays at the level that was just completed
      expect(controller.currentLevel, 1);
      expect(controller.currentScore, 500);
      expect(controller.gameActive, isFalse);
      expect(controller.getCurrentLayout(), isNull);
    });

    // ---------------------------------------------------------------------------
    // Test 3: resetGame resets to initial state
    // ---------------------------------------------------------------------------
    test('resetGame resets to initial state', () {
      final controller = GameController(seed: fixedSeed);
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
      final controller = GameController(seed: fixedSeed);
      int maxEasyStreak = 0;
      int currentEasyStreak = 0;

      for (int i = 0; i < 100; i++) {
        controller.startNewGame();
        final layout = controller.getCurrentLayout()!;
        if (layout.difficulty == Difficulty.easy) {
          currentEasyStreak++;
          if (currentEasyStreak > maxEasyStreak) {
            maxEasyStreak = currentEasyStreak;
          }
        } else {
          currentEasyStreak = 0;
        }
      }

      expect(maxEasyStreak, lessThanOrEqualTo(LevelGenerator.maxEasyStreak));
    });

    // ---------------------------------------------------------------------------
    // Test 5: getCurrentLayout returns null before any game starts
    // ---------------------------------------------------------------------------
    test('getCurrentLayout returns null before startNewGame', () {
      final controller = GameController(seed: fixedSeed);

      expect(controller.getCurrentLayout(), isNull);
    });

    // ---------------------------------------------------------------------------
    // Test 6: onGameWon is idempotent — second call is a no-op
    // ---------------------------------------------------------------------------
    test('onGameWon is idempotent', () {
      final controller = GameController(seed: fixedSeed);
      controller.startNewGame();

      controller.onGameWon(500);
      controller.onGameWon(200); // should be ignored

      expect(controller.currentLevel, 1);
      expect(controller.currentScore, 500);
      expect(controller.gameActive, isFalse);
    });

    // ---------------------------------------------------------------------------
    // Test 7: onGameWon with zero score is valid
    // ---------------------------------------------------------------------------
    test('onGameWon with zero score is accepted', () {
      final controller = GameController(seed: fixedSeed);
      controller.startNewGame();

      controller.onGameWon(0);

      expect(controller.currentLevel, 1);
      expect(controller.currentScore, 0);
      expect(controller.gameActive, isFalse);
    });

    // ---------------------------------------------------------------------------
    // Test 8: resetGame works without a preceding startNewGame
    // ---------------------------------------------------------------------------
    test('resetGame works without prior startNewGame', () {
      final controller = GameController(seed: fixedSeed);

      controller.resetGame();

      expect(controller.currentLevel, 1);
      expect(controller.currentScore, 0);
      expect(controller.gameActive, isTrue);
      expect(controller.getCurrentLayout(), isA<LayoutDefinition>());
    });

    // ---------------------------------------------------------------------------
    // Test 9: onGameWon without active game is a no-op
    // ---------------------------------------------------------------------------
    test('onGameWon without active game is a no-op', () {
      final controller = GameController(seed: fixedSeed);

      controller.onGameWon(500);

      expect(controller.currentLevel, 1);
      expect(controller.currentScore, 0);
      expect(controller.gameActive, isFalse);
    });
  });
}
