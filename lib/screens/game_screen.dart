import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:go_router/go_router.dart';
import 'package:footyjong/config/game_constants.dart';
import 'package:footyjong/game/engine/board_layout.dart';
import 'package:footyjong/game/engine/game_state.dart';
import 'package:footyjong/game/footyjong_game.dart';
import 'package:footyjong/game/game_controller.dart';
import 'package:footyjong/game/models/models.dart';

/// Full-screen game view with a Flame [GameWidget] rendering the board and a
/// Flutter HUD overlay showing score and level.
///
/// Accepts a [GameController] that must have been initialised (via
/// [GameController.startNewGame] or [GameController.resetGame]) before this
/// screen is mounted. Reads the current layout and config from the controller
/// to construct a [GameState] for the [FootyJongGame].
///
/// A GoRouter redirect guard (in [main.dart]) ensures this screen is only
/// reached when [GameController.gameActive] is `true`, so the layout and
/// config are guaranteed non-null under normal navigation flow.
class GameScreen extends StatefulWidget {
  final GameController controller;

  const GameScreen({super.key, required this.controller});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late final FootyJongGame _game;

  @override
  void initState() {
    super.initState();
    final layout = widget.controller.getCurrentLayout();
    final config = widget.controller.getCurrentConfig();

    if (layout == null || config == null) {
      // Defensive: if redirect guard in main.dart fails (e.g. deep link),
      // redirect to home instead of crashing.
      _game = _createPlaceholderGame();
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go('/');
      });
      return;
    }

    _game = FootyJongGame(
      gameState: GameState(layout: layout, config: config),
      onGameWon: _onGameWon,
    );
  }

  /// Creates a minimal game instance so the widget tree doesn't crash when
  /// the redirect guard is bypassed (e.g. deep link to `/game` without an
  /// initialised controller). Will be disposed on the next frame when the
  /// redirect fires.
  FootyJongGame _createPlaceholderGame() {
    final fallbackLayout = BoardLayout.butterfly;
    const fallbackConfig = TileConfig(18, 4);
    return FootyJongGame(
      gameState: GameState(layout: fallbackLayout, config: fallbackConfig),
    );
  }

  /// Handles a game-won event: records the score, shuts down the game, and
  /// navigates to the results screen.
  ///
  /// The game is disposed synchronously BEFORE navigation so no stray event
  /// from an animation callback can fire after the state is already won.
  void _onGameWon() {
    if (!mounted) return;
    final score = _game.scoreNotifier.value;
    _game.onDispose(); // prevent any further event processing
    widget.controller.onGameWon(score);
    context.go('/results');
  }

  @override
  void dispose() {
    _game.onDispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: GameConstants.viewportBackground,
        body: Stack(
          children: [
            GameWidget(game: _game),
            // HUD overlay
            Positioned(
              top: 16,
              right: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  ValueListenableBuilder<int>(
                    valueListenable: _game.scoreNotifier,
                    builder: (context, score, _) {
                      return Text(
                        'Score: $score',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  ValueListenableBuilder<int>(
                    valueListenable: _game.levelNotifier,
                    builder: (context, level, _) {
                      return Text(
                        'Level: $level',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            // Quit button — visible escape from PopScope(canPop: false)
            Positioned(
              top: 16,
              left: 16,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white70),
                tooltip: 'Quit game',
                onPressed: () {
                  _game.onDispose();
                  widget.controller.resetGame();
                  context.go('/');
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
