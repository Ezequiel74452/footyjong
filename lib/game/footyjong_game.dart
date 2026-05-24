import 'dart:async';
import 'dart:ui' show Paint;
import 'package:flame/camera.dart';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:footyjong/config/game_constants.dart';
import 'package:footyjong/game/components/board_component.dart';
import 'package:footyjong/game/engine/game_state.dart';

/// Top-level Flame game for FootyJong.
///
/// Owns the game loop, sets up a [FixedResolutionViewport] (800×600), creates
/// the [BoardComponent] from [GameState], and dispatches [GameEvent]s to the
/// board's animation handlers.  Exposes [ValueNotifier]s for the Flutter HUD.
class FootyJongGame extends FlameGame {
  final GameState gameState;
  late final BoardComponent board;

  /// Optional callback fired after the game is won (gated via
  /// [SchedulerBinding.instance.addPostFrameCallback] to avoid navigating
  /// during a sync StreamController dispatch, and to let the victory
  /// animation render for at least one frame before the callback fires).
  /// Guarded by a disposal flag so it never fires after [onDispose].
  final VoidCallback? onGameWon;

  /// HUD bridges — Flutter widgets listen to these via [ValueListenableBuilder].
  final ValueNotifier<int> scoreNotifier = ValueNotifier<int>(0);
  final ValueNotifier<int> levelNotifier = ValueNotifier<int>(1);

  StreamSubscription<GameEvent>? _eventSub;
  bool _disposed = false;

  FootyJongGame({required this.gameState, this.onGameWon});

  @override
  FutureOr<void> onLoad() {
    // Fixed-resolution viewport with letterboxing
    camera.viewport = FixedResolutionViewport(
      resolution: Vector2(
        GameConstants.viewportWidth,
        GameConstants.viewportHeight,
      ),
    );

    // Board background
    add(RectangleComponent(
      size: Vector2(GameConstants.viewportWidth, GameConstants.viewportHeight),
      paint: Paint()..color = GameConstants.viewportBackground,
    ));

    // Initialize the engine and build the visual board
    gameState.initialize(seed: DateTime.now().millisecondsSinceEpoch);
    board = BoardComponent(gameState: gameState);
    add(board);

    // React to engine events
    _eventSub = gameState.events.listen(_onEvent);
  }

  void _onEvent(GameEvent event) {
    switch (event) {
      case TileSelected(:final tile, :final position):
        board.highlightTile(tile.id);
      case TileDeselected(:final tile):
        board.unhighlightTile(tile.id);
      case MatchSuccess(:final tileA, :final tileB):
        board.animateMatchRemoval(tileA.id, tileB.id);
        scoreNotifier.value = gameState.score;
      case MatchFailed(:final tileA, :final tileB):
        board.animateShake(tileA.id, tileB.id);
      case DeadlockDetected():
        board.showDeadlockUI();
      case GameWon(:final score, :final level):
        board.animateVictory();
        scoreNotifier.value = score;
        levelNotifier.value = level + 1;
        SchedulerBinding.instance.addPostFrameCallback((_) {
          if (!_disposed) onGameWon?.call();
        });
    }
  }

  @override
  void onDispose() {
    _disposed = true;
    _eventSub?.cancel();
    gameState.dispose();
    super.onDispose();
  }
}
