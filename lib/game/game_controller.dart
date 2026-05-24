import 'package:flutter/foundation.dart';
import 'package:footyjong/game/engine/level_generator.dart';
import 'package:footyjong/game/models/models.dart';

/// Controller that manages game lifecycle across screens.
///
/// Wraps a [LevelGenerator] and exposes level/score state so the UI layer
/// (GoRouter screens) can start a new game, react to a won level, and reset
/// for replay — all without recreating the generator (streak tracking is
/// preserved across calls).
class GameController extends ChangeNotifier {
  int currentLevel = 1;
  int currentScore = 0;
  bool gameActive = false;

  final LevelGenerator _generator = LevelGenerator();
  LevelResult? _currentResult;

  /// Resets everything to a fresh game at level 1 and generates the first layout.
  void startNewGame() {
    currentLevel = 1;
    currentScore = 0;
    gameActive = true;
    _currentResult = _generator.generateLevel(currentLevel);
    notifyListeners();
  }

  /// Called when the current level is won.
  ///
  /// Adds [score] to the cumulative score, advances the level counter, and
  /// marks the game as inactive so the UI can transition to a results screen.
  void onGameWon(int score) {
    currentScore += score;
    currentLevel++;
    gameActive = false;
    notifyListeners();
  }

  /// Returns the [LayoutDefinition] for the currently generated level.
  LayoutDefinition getCurrentLayout() {
    return _currentResult!.layout;
  }

  /// Full reset — same as [startNewGame], intended for "Play Again".
  void resetGame() {
    currentLevel = 1;
    currentScore = 0;
    gameActive = true;
    _currentResult = _generator.generateLevel(currentLevel);
    notifyListeners();
  }
}
