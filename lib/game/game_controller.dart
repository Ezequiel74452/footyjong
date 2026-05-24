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
  int _currentLevel = 1;
  int _currentScore = 0;
  bool _gameActive = false;

  /// The current level number (read-only from outside).
  int get currentLevel => _currentLevel;

  /// The cumulative score across all levels in this session.
  int get currentScore => _currentScore;

  /// Whether a game is in progress.
  bool get gameActive => _gameActive;

  final LevelGenerator _generator;
  LevelResult? _currentResult;

  GameController({int? seed}) : _generator = LevelGenerator(seed: seed);

  /// Initialises a fresh game at level 1 and generates the first layout.
  void startNewGame() {
    _initGame(level: 1);
  }

  /// Called when the current level is won.
  ///
  /// Adds [score] to the cumulative score, advances the level counter, and
  /// marks the game as inactive. [getCurrentLayout] returns `null` after
  /// this call until the next game is started.
  ///
  /// Must be called exactly once per winning sequence. Calling this more
  /// than once or without an active game is a no-op.
  void onGameWon(int score) {
    if (!_gameActive) return;
    assert(score >= 0, 'Score must be non-negative');
    _currentScore += score;
    _currentLevel++;
    _gameActive = false;
    _currentResult = null;
    notifyListeners();
  }

  /// The [LayoutDefinition] for the currently generated level, or `null` when
  /// no game is active (e.g. before [startNewGame] or after [onGameWon]).
  LayoutDefinition? getCurrentLayout() {
    return _currentResult?.layout;
  }

  /// Full reset to level 1 — intended for "Play Again".
  void resetGame() {
    _initGame(level: 1);
  }

  void _initGame({required int level}) {
    _currentLevel = level;
    _currentScore = 0;
    final result = _generator.generateLevel(level);
    _currentResult = result;
    _gameActive = true;
    notifyListeners();
  }

  @override
  void dispose() {
    super.dispose();
  }
}
