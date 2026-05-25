import 'dart:async';
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
/// Flutter HUD overlay showing timer, score, level, reshuffle, and forfeit.
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
  Timer? _timer;
  int _elapsedSeconds = 0;

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

    _startTimer();
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

  void _startTimer() {
    _elapsedSeconds = 0;
    _game.timerNotifier.value = Duration.zero;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      _elapsedSeconds++;
      _game.timerNotifier.value = Duration(seconds: _elapsedSeconds);
    });
  }

  /// Handles a game-won event: records the elapsed time and score, shuts down
  /// the game, and navigates to the results screen.
  ///
  /// The game is disposed synchronously BEFORE navigation so no stray event
  /// from an animation callback can fire after the state is already won.
  void _onGameWon() {
    if (!mounted) return;
    _timer?.cancel();
    final elapsed = Duration(seconds: _elapsedSeconds);
    final score = _game.scoreNotifier.value;
    _game.onDispose(); // prevent any further event processing
    widget.controller.onGameWon(score, elapsed: elapsed);
    context.go('/results');
  }

  /// Shows a forfeit confirmation dialog.  On confirm, the game is disposed,
  /// the controller is reset, and the player is navigated home.
  void _onForfeit() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Forfeit'),
        content: const Text('Are you sure you want to forfeit?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _timer?.cancel();
              _game.onDispose();
              widget.controller.resetGame();
              context.go('/');
            },
            child: const Text('Forfeit'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
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
            // HUD overlay — top right: timer, score, level, reshuffle
            Positioned(
              top: 16,
              right: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Timer (MM:SS format)
                  ValueListenableBuilder<Duration?>(
                    valueListenable: _game.timerNotifier,
                    builder: (_, duration, __) {
                      return Text(
                        _formatDuration(duration),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  ValueListenableBuilder<int>(
                    valueListenable: _game.scoreNotifier,
                    builder: (_, score, __) {
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
                    builder: (_, level, __) {
                      return Text(
                        'Level: $level',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  // Reshuffle button — visible only when deadlocked
                  ValueListenableBuilder<bool>(
                    valueListenable: _game.deadlockedNotifier,
                    builder: (_, isDeadlocked, __) {
                      if (!isDeadlocked) {
                        return const SizedBox.shrink();
                      }
                      return Column(
                        children: [
                          const Text(
                            'No valid moves!',
                            style: TextStyle(
                              color: Colors.redAccent,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton.icon(
                            onPressed: _game.reshuffle,
                            icon: const Icon(Icons.shuffle, size: 18),
                            label: const Text('Reshuffle'),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
            // Top-left: quit button + forfeit button
            Positioned(
              top: 16,
              left: 16,
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70),
                    tooltip: 'Quit game',
                    onPressed: () {
                      _timer?.cancel();
                      _game.onDispose();
                      widget.controller.resetGame();
                      context.go('/');
                    },
                  ),
                  TextButton(
                    onPressed: _onForfeit,
                    child: const Text(
                      'Forfeit',
                      style: TextStyle(color: Colors.white54, fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Formats a [Duration] as `MM:SS`.  Returns `00:00` for `null`.
  String _formatDuration(Duration? d) {
    if (d == null) return '00:00';
    final twoDigitMinutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final twoDigitSeconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$twoDigitMinutes:$twoDigitSeconds';
  }
}
